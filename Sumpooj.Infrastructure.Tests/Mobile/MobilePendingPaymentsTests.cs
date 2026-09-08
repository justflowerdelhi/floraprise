using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.API.Controllers.Mobile;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Mobile;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;
using Xunit;

namespace Sumpooj.Infrastructure.Tests.Mobile;

public class MobilePendingPaymentsTests
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
            .UseInMemoryDatabase($"MobilePendingPayments_{Guid.NewGuid():N}")
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
        PaymentStatus paymentStatus)
    {
        var order = new Order(
            companyId,
            customerId,
            DateTime.UtcNow,
            "123 Street",
            "560001",
            "Recipient",
            "9876500001");
        order.GetType().GetProperty(nameof(Order.TotalAmount))!.SetValue(order, totalAmount);
        order.GetType().GetProperty(nameof(Order.PaymentStatus))!.SetValue(order, paymentStatus);
        db.Orders.Add(order);
        await db.SaveChangesAsync();
        return order;
    }

    private static async Task<Payment> SeedPaymentAsync(
        SumpoojDbContext db,
        Guid companyId,
        Guid orderId,
        decimal amount,
        PaymentTransactionStatus status = PaymentTransactionStatus.Approved)
    {
        var payment = new Payment(companyId, orderId, PaymentMethod.Cash, amount);
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

    [Fact]
    public async Task GetPendingPayments_ReturnsCountAndAmount()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var customer = await SeedCustomerAsync(db, companyId, "Pending Customer");
        var pendingOrder = await SeedOrderAsync(db, companyId, customer.Id, 250m, PaymentStatus.Unpaid);
        var partialOrder = await SeedOrderAsync(db, companyId, customer.Id, 400m, PaymentStatus.PartiallyPaid);
        await SeedPaymentAsync(db, companyId, partialOrder.Id, 100m);

        var controller = new MobilePendingPaymentsController(db, new TenantContext(companyId));
        var result = await controller.GetPendingPayments(CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var dto = Assert.IsType<MobilePendingPaymentsDto>(ok.Value);
        Assert.Equal(2, dto.PendingOrderCount);
        Assert.Equal(55000, dto.PendingPaymentPaise);
    }

    [Fact]
    public async Task GetPendingPayments_ReturnsZeroWhenNothingIsPending()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var customer = await SeedCustomerAsync(db, companyId, "Settled Customer");
        var paidOrder = await SeedOrderAsync(db, companyId, customer.Id, 180m, PaymentStatus.Paid);
        await SeedPaymentAsync(db, companyId, paidOrder.Id, 180m);

        var controller = new MobilePendingPaymentsController(db, new TenantContext(companyId));
        var result = await controller.GetPendingPayments(CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var dto = Assert.IsType<MobilePendingPaymentsDto>(ok.Value);
        Assert.Equal(0, dto.PendingOrderCount);
        Assert.Equal(0, dto.PendingPaymentPaise);
    }

    [Fact]
    public async Task GetPendingPayments_DoesNotLeakOtherTenantData()
    {
        var companyId = Guid.NewGuid();
        var otherCompanyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var ownCustomer = await SeedCustomerAsync(db, companyId, "Own Customer");
        var otherCustomer = await SeedCustomerAsync(db, otherCompanyId, "Other Customer");
        var ownPending = await SeedOrderAsync(db, companyId, ownCustomer.Id, 90m, PaymentStatus.Unpaid);
        var otherPending = await SeedOrderAsync(db, otherCompanyId, otherCustomer.Id, 900m, PaymentStatus.Unpaid);
        await SeedPaymentAsync(db, companyId, ownPending.Id, 10m);
        await SeedPaymentAsync(db, otherCompanyId, otherPending.Id, 900m);

        var controller = new MobilePendingPaymentsController(db, new TenantContext(companyId));
        var result = await controller.GetPendingPayments(CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var dto = Assert.IsType<MobilePendingPaymentsDto>(ok.Value);
        Assert.Equal(1, dto.PendingOrderCount);
        Assert.Equal(8000, dto.PendingPaymentPaise);
    }

    [Fact]
    public async Task GetPendingPayments_UsesApprovedPaymentsOnly()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var customer = await SeedCustomerAsync(db, companyId, "Partial Approval");
        var order = await SeedOrderAsync(db, companyId, customer.Id, 300m, PaymentStatus.PartiallyPaid);
        await SeedPaymentAsync(db, companyId, order.Id, 50m, PaymentTransactionStatus.Pending);
        await SeedPaymentAsync(db, companyId, order.Id, 200m, PaymentTransactionStatus.Approved);

        var controller = new MobilePendingPaymentsController(db, new TenantContext(companyId));
        var result = await controller.GetPendingPayments(CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var dto = Assert.IsType<MobilePendingPaymentsDto>(ok.Value);
        Assert.Equal(1, dto.PendingOrderCount);
        Assert.Equal(10000, dto.PendingPaymentPaise);
    }
}
