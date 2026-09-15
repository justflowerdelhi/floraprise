using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.API.Controllers.Mobile;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Mobile;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;
using Xunit;

namespace Sumpooj.Infrastructure.Tests.Mobile;

public class MobileDashboardSummaryTests
{
    private sealed class TenantContext(Guid companyId) : ITenantContext
    {
        public Guid? CompanyId => companyId;
        public bool IsPlatformUser => false;
        public string? Region => null;
    }

    private static SumpoojDbContext CreateDb(Guid companyId)
    {
        var options = new DbContextOptionsBuilder<SumpoojDbContext>()
            .UseInMemoryDatabase($"MobileDashboardSummary_{Guid.NewGuid():N}")
            .Options;
        return new SumpoojDbContext(options, new TenantContext(companyId));
    }

    private static async Task<Customer> SeedCustomerAsync(
        SumpoojDbContext db,
        Guid companyId,
        string name)
    {
        var customer = new Customer(companyId, name, null, "9876500000");
        db.Customers.Add(customer);
        await db.SaveChangesAsync();
        return customer;
    }

    private static async Task<Order> SeedOrderAsync(
        SumpoojDbContext db,
        Guid companyId,
        Guid customerId,
        decimal totalAmount,
        DateTime orderDateUtc,
        OrderStatus status,
        PaymentStatus paymentStatus = PaymentStatus.Unpaid,
        string? deliveryAddress = null,
        DateTime? deliveryDateUtc = null)
    {
        var order = new Order(
            companyId,
            customerId,
            deliveryDateUtc ?? orderDateUtc,
            deliveryAddress,
            "560001",
            "Recipient",
            "9876500001");
        order.GetType().GetProperty(nameof(Order.OrderDate))!.SetValue(order, orderDateUtc);
        order.GetType().GetProperty(nameof(Order.DeliveryDate))!.SetValue(order, deliveryDateUtc ?? orderDateUtc);
        order.GetType().GetProperty(nameof(Order.TotalAmount))!.SetValue(order, totalAmount);
        order.GetType().GetProperty(nameof(Order.Status))!.SetValue(order, status);
        order.GetType().GetProperty(nameof(Order.PaymentStatus))!.SetValue(order, paymentStatus);
        db.Orders.Add(order);
        await db.SaveChangesAsync();
        return order;
    }

    private static async Task<Payment> SeedPaymentAsync(
        SumpoojDbContext db,
        Guid companyId,
        Guid orderId,
        PaymentMethod method,
        decimal amount,
        PaymentTransactionStatus status = PaymentTransactionStatus.Approved)
    {
        var payment = new Payment(companyId, orderId, method, amount);
        if (status == PaymentTransactionStatus.Approved)
        {
            payment.Approve("txn", "auth");
        }
        else
        {
            payment.GetType().GetProperty(nameof(Payment.Status))!.SetValue(payment, status);
        }
        db.Payments.Add(payment);
        await db.SaveChangesAsync();
        return payment;
    }

    private static async Task<Expense> SeedExpenseAsync(
        SumpoojDbContext db,
        Guid companyId,
        decimal amount,
        DateTime expenseDateUtc)
    {
        var expense = new Expense(companyId, "Supplies", amount, "Test", expenseDateUtc);
        db.Expenses.Add(expense);
        await db.SaveChangesAsync();
        return expense;
    }

    [Fact]
    public async Task GetSummary_AggregatesDailyMetrics()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var customer = await SeedCustomerAsync(db, companyId, "Daily Customer");
        var today = new DateTime(2026, 9, 8, 10, 0, 0, DateTimeKind.Utc);
        var deliveryOrder = await SeedOrderAsync(
            db,
            companyId,
            customer.Id,
            120m,
            today,
            OrderStatus.Processing,
            PaymentStatus.Paid,
            deliveryAddress: "12 Street");
        var pickupOrder = await SeedOrderAsync(
            db,
            companyId,
            customer.Id,
            80m,
            today,
            OrderStatus.ReadyForDelivery,
            PaymentStatus.PartiallyPaid,
            deliveryDateUtc: today);
        await SeedPaymentAsync(db, companyId, deliveryOrder.Id, PaymentMethod.Cash, 70m);
        await SeedPaymentAsync(db, companyId, deliveryOrder.Id, PaymentMethod.Card, 30m);
        await SeedPaymentAsync(db, companyId, pickupOrder.Id, PaymentMethod.Upi, 40m);
        await SeedExpenseAsync(db, companyId, 15m, today);

        var controller = new MobileDashboardController(db, new TenantContext(companyId));
        var result = await controller.GetSummary(today, today, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var dto = Assert.IsType<MobileDashboardSummaryDto>(ok.Value);
        Assert.Equal(20000, dto.TotalSalesPaise);
        Assert.Equal(2, dto.OrderCount);
        Assert.Equal(7000, dto.CashPaise);
        Assert.Equal(4000, dto.UpiPaise);
        Assert.Equal(3000, dto.CardPaise);
        Assert.Equal(0, dto.CreditPaise);
        Assert.Equal(0, dto.PendingOrderCount);
        Assert.Equal(1, dto.PreparingOrderCount);
        Assert.Equal(1, dto.ReadyOrderCount);
        Assert.Equal(0, dto.OutForDeliveryCount);
        Assert.Equal(1, dto.DeliveryCount);
        Assert.Equal(1, dto.PickupCount);
        Assert.Equal(1500, dto.ExpensePaise);
    }

    [Fact]
    public async Task GetSummary_SupportsDateRangeAndCreditSales()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var customer = await SeedCustomerAsync(db, companyId, "Range Customer");
        // Use times safely within IST business-day boundaries (IST = UTC+5:30).
        var start = new DateTime(2026, 9, 1, 10, 0, 0, DateTimeKind.Utc);
        var end = new DateTime(2026, 9, 3, 10, 0, 0, DateTimeKind.Utc);
        var order1 = await SeedOrderAsync(db, companyId, customer.Id, 50m, start, OrderStatus.Pending, PaymentStatus.Credit, deliveryAddress: null, deliveryDateUtc: start);
        var order2 = await SeedOrderAsync(db, companyId, customer.Id, 150m, end, OrderStatus.OutForDelivery, PaymentStatus.Paid, deliveryAddress: "123 Street", deliveryDateUtc: end);
        await SeedPaymentAsync(db, companyId, order2.Id, PaymentMethod.Card, 150m);
        await SeedExpenseAsync(db, companyId, 20m, end);

        var controller = new MobileDashboardController(db, new TenantContext(companyId));
        var result = await controller.GetSummary(start, end, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var dto = Assert.IsType<MobileDashboardSummaryDto>(ok.Value);
        Assert.Equal(20000, dto.TotalSalesPaise);
        Assert.Equal(2, dto.OrderCount);
        Assert.Equal(0, dto.CashPaise);
        Assert.Equal(0, dto.UpiPaise);
        Assert.Equal(15000, dto.CardPaise);
        Assert.Equal(5000, dto.CreditPaise);
        Assert.Equal(1, dto.PendingOrderCount);
        Assert.Equal(0, dto.PreparingOrderCount);
        Assert.Equal(0, dto.ReadyOrderCount);
        Assert.Equal(1, dto.OutForDeliveryCount);
        Assert.Equal(1, dto.DeliveryCount);
        Assert.Equal(1, dto.PickupCount);
        Assert.Equal(2000, dto.ExpensePaise);
    }

    [Fact]
    public async Task GetSummary_ReturnsZeroesForEmptyPeriod()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var customer = await SeedCustomerAsync(db, companyId, "Empty Period");
        var outside = new DateTime(2026, 9, 1, 10, 0, 0, DateTimeKind.Utc);
        await SeedOrderAsync(db, companyId, customer.Id, 90m, outside, OrderStatus.Processing);

        var controller = new MobileDashboardController(db, new TenantContext(companyId));
        var result = await controller.GetSummary(
            new DateTime(2026, 9, 10, 0, 0, 0, DateTimeKind.Utc),
            new DateTime(2026, 9, 10, 23, 59, 59, DateTimeKind.Utc),
            CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var dto = Assert.IsType<MobileDashboardSummaryDto>(ok.Value);
        Assert.Equal(0, dto.TotalSalesPaise);
        Assert.Equal(0, dto.OrderCount);
        Assert.Equal(0, dto.CashPaise);
        Assert.Equal(0, dto.UpiPaise);
        Assert.Equal(0, dto.CardPaise);
        Assert.Equal(0, dto.CreditPaise);
        Assert.Equal(0, dto.PendingOrderCount);
        Assert.Equal(0, dto.PreparingOrderCount);
        Assert.Equal(0, dto.ReadyOrderCount);
        Assert.Equal(0, dto.OutForDeliveryCount);
        Assert.Equal(0, dto.DeliveryCount);
        Assert.Equal(0, dto.PickupCount);
        Assert.Equal(0, dto.ExpensePaise);
    }

    [Fact]
    public async Task GetSummary_DoesNotLeakOtherTenantData()
    {
        var companyId = Guid.NewGuid();
        var otherCompanyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var ownCustomer = await SeedCustomerAsync(db, companyId, "Own Customer");
        var otherCustomer = await SeedCustomerAsync(db, otherCompanyId, "Other Customer");
        var today = new DateTime(2026, 9, 8, 10, 0, 0, DateTimeKind.Utc);
        var ownOrder = await SeedOrderAsync(db, companyId, ownCustomer.Id, 60m, today, OrderStatus.Processing);
        var otherOrder = await SeedOrderAsync(db, otherCompanyId, otherCustomer.Id, 999m, today, OrderStatus.Processing);
        await SeedPaymentAsync(db, companyId, ownOrder.Id, PaymentMethod.Cash, 10m);
        await SeedPaymentAsync(db, otherCompanyId, otherOrder.Id, PaymentMethod.Card, 999m);
        await SeedExpenseAsync(db, otherCompanyId, 25m, today);

        var controller = new MobileDashboardController(db, new TenantContext(companyId));
        var result = await controller.GetSummary(today, today, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var dto = Assert.IsType<MobileDashboardSummaryDto>(ok.Value);
        Assert.Equal(6000, dto.TotalSalesPaise);
        Assert.Equal(1, dto.OrderCount);
        Assert.Equal(1000, dto.CashPaise);
        Assert.Equal(0, dto.CardPaise);
        Assert.Equal(0, dto.ExpensePaise);
    }
}
