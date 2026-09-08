using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.API.Controllers.Mobile;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Mobile;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;
using Xunit;

namespace Sumpooj.Infrastructure.Tests.Orders;

public class CloudCustomerStatisticsTests
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
            .UseInMemoryDatabase($"CloudCustomerStatistics_{Guid.NewGuid():N}")
            .Options;
        return new SumpoojDbContext(options, new TenantContext(companyId));
    }

    private static async Task<Customer> SeedCustomerAsync(
        SumpoojDbContext db,
        Guid companyId,
        string name,
        string phone)
    {
        var customer = new Customer(companyId, name, null, phone);
        db.Customers.Add(customer);
        await db.SaveChangesAsync();
        return customer;
    }

    private static async Task<Order> SeedOrderAsync(
        SumpoojDbContext db,
        Guid companyId,
        Guid customerId,
        decimal totalAmount,
        DateTime orderDateUtc)
    {
        var order = new Order(
            companyId,
            customerId,
            orderDateUtc,
            "123 Main Street",
            "560001",
            "Recipient",
            "9876543210");
        order.GetType().GetProperty(nameof(Order.OrderDate))!.SetValue(order, orderDateUtc);
        order.GetType().GetProperty(nameof(Order.TotalAmount))!.SetValue(order, totalAmount);
        db.Orders.Add(order);
        await db.SaveChangesAsync();
        return order;
    }

    private static async Task<Payment> SeedApprovedPaymentAsync(
        SumpoojDbContext db,
        Guid companyId,
        Guid orderId,
        decimal amount)
    {
        var payment = new Payment(companyId, orderId, PaymentMethod.Cash, amount);
        payment.Approve("txn-1", "auth-1");
        db.Payments.Add(payment);
        await db.SaveChangesAsync();
        return payment;
    }

    [Fact]
    public async Task GetStatistics_ReturnsAggregatesForCustomer()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var customer = await SeedCustomerAsync(db, companyId, "Asha Rao", "9876501234");
        var olderOrder = await SeedOrderAsync(
            db,
            companyId,
            customer.Id,
            120m,
            new DateTime(2026, 9, 1, 10, 0, 0, DateTimeKind.Utc));
        var newerOrder = await SeedOrderAsync(
            db,
            companyId,
            customer.Id,
            80m,
            new DateTime(2026, 9, 7, 18, 30, 0, DateTimeKind.Utc));
        await SeedApprovedPaymentAsync(db, companyId, olderOrder.Id, 70m);
        await SeedApprovedPaymentAsync(db, companyId, newerOrder.Id, 50m);

        var controller = new MobileCustomersController(db, new TenantContext(companyId));
        var result = await controller.GetStatistics(customer.Id, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var dto = Assert.IsType<MobileCustomerStatisticsDto>(ok.Value);
        Assert.Equal(customer.Id, dto.CustomerId);
        Assert.Equal(2, dto.TotalOrders);
        Assert.Equal(new DateTime(2026, 9, 7, 18, 30, 0, DateTimeKind.Utc), dto.LastOrderAt);
        Assert.Equal(20000, dto.LifetimePurchasePaise);
        Assert.Equal(8000, dto.PendingPaymentPaise);
    }

    [Fact]
    public async Task GetStatistics_ReturnsZeroesForCustomerWithoutOrders()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var customer = await SeedCustomerAsync(db, companyId, "No Orders", "9876500000");

        var controller = new MobileCustomersController(db, new TenantContext(companyId));
        var result = await controller.GetStatistics(customer.Id, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var dto = Assert.IsType<MobileCustomerStatisticsDto>(ok.Value);
        Assert.Equal(customer.Id, dto.CustomerId);
        Assert.Equal(0, dto.TotalOrders);
        Assert.Null(dto.LastOrderAt);
        Assert.Equal(0, dto.LifetimePurchasePaise);
        Assert.Equal(0, dto.PendingPaymentPaise);
    }

    [Fact]
    public async Task GetStatistics_ReturnsNotFoundForCrossTenantCustomer()
    {
        var companyId = Guid.NewGuid();
        var otherCompanyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var customer = await SeedCustomerAsync(db, otherCompanyId, "Other Tenant", "9876509999");
        await SeedOrderAsync(db, otherCompanyId, customer.Id, 200m, DateTime.UtcNow);

        var controller = new MobileCustomersController(db, new TenantContext(companyId));
        var result = await controller.GetStatistics(customer.Id, CancellationToken.None);

        Assert.IsType<NotFoundResult>(result);
    }

    [Fact]
    public async Task GetStatistics_IncludesPendingPaymentFromApprovedPaymentsOnly()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var customer = await SeedCustomerAsync(db, companyId, "Pending Payment", "9876507777");
        var order = await SeedOrderAsync(
            db,
            companyId,
            customer.Id,
            300m,
            new DateTime(2026, 9, 5, 9, 0, 0, DateTimeKind.Utc));
        await SeedApprovedPaymentAsync(db, companyId, order.Id, 100m);

        var controller = new MobileCustomersController(db, new TenantContext(companyId));
        var result = await controller.GetStatistics(customer.Id, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var dto = Assert.IsType<MobileCustomerStatisticsDto>(ok.Value);
        Assert.Equal(1, dto.TotalOrders);
        Assert.Equal(30000, dto.LifetimePurchasePaise);
        Assert.Equal(20000, dto.PendingPaymentPaise);
    }
}
