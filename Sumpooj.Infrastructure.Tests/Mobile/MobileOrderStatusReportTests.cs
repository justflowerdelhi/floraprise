using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.API.Controllers.Mobile;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Mobile;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;
using Xunit;

namespace Sumpooj.Infrastructure.Tests.Mobile;

public class MobileOrderStatusReportTests
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
            .UseInMemoryDatabase($"MobileOrderStatusReport_{Guid.NewGuid():N}")
            .Options;
        return new SumpoojDbContext(options, new TenantContext(companyId));
    }

    private static async Task<Order> SeedOrderAsync(
        SumpoojDbContext db,
        Guid companyId,
        OrderStatus status,
        DateTime? orderDate = null,
        DateTime? deliveryDate = null,
        string? deliveryAddress = null,
        string? timeSlot = null,
        bool hasDeliveryRecord = false,
        bool isActive = true)
    {
        var customer = new Customer(
            companyId,
            "Test Customer",
            "test@example.com",
            "9876543210");
        db.Customers.Add(customer);

        var oDate = orderDate ?? DateTime.UtcNow;
        var dDate = deliveryDate ?? oDate;

        var order = new Order(
            companyId,
            customer.Id,
            dDate,
            deliveryAddress,
            null,
            "Recipient",
            "9876543210");

        // Set order date via reflection since OrderDate has a private setter
        typeof(Order).GetProperty(nameof(Order.OrderDate))?.SetValue(order, oDate);

        if (!isActive)
        {
            typeof(Order).GetProperty(nameof(Order.IsActive))?.SetValue(order, false);
        }

        if (!string.IsNullOrWhiteSpace(timeSlot))
        {
            order.SetTimeSlot(timeSlot);
        }

        // Transition status to target
        switch (status)
        {
            case OrderStatus.Confirmed:
                order.Confirm();
                break;
            case OrderStatus.Processing:
                order.Confirm();
                order.StartProcessing();
                break;
            case OrderStatus.ReadyForDelivery:
                order.Confirm();
                order.StartProcessing();
                order.MarkReadyForDelivery();
                break;
            case OrderStatus.OutForDelivery:
                order.Confirm();
                order.StartProcessing();
                order.MarkReadyForDelivery();
                order.MarkOutForDelivery();
                break;
            case OrderStatus.Delivered:
                order.Confirm();
                order.StartProcessing();
                order.MarkReadyForDelivery();
                order.MarkOutForDelivery();
                order.MarkDelivered();
                break;
            case OrderStatus.Cancelled:
                order.Cancel("Test cancellation");
                break;
            case OrderStatus.AutoCreated:
                order.MarkAutoCreated();
                break;
            case OrderStatus.Pending:
            default:
                break;
        }

        db.Orders.Add(order);

        if (hasDeliveryRecord)
        {
            var delivery = new Delivery(
                companyId,
                order.Id,
                dDate,
                "10:00 - 12:00",
                "123 Delivery St");
            db.Deliveries.Add(delivery);
        }

        await db.SaveChangesAsync();
        return order;
    }

    [Fact]
    public async Task GetStatusReport_ReturnsAccurateStatusCounts()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);

        await SeedOrderAsync(db, companyId, OrderStatus.Pending);
        await SeedOrderAsync(db, companyId, OrderStatus.AutoCreated);
        await SeedOrderAsync(db, companyId, OrderStatus.Confirmed);
        await SeedOrderAsync(db, companyId, OrderStatus.Processing);
        await SeedOrderAsync(db, companyId, OrderStatus.ReadyForDelivery);
        await SeedOrderAsync(db, companyId, OrderStatus.OutForDelivery);
        await SeedOrderAsync(db, companyId, OrderStatus.Delivered);
        await SeedOrderAsync(db, companyId, OrderStatus.Cancelled);

        var controller = new MobileOrdersController(db, new TenantContext(companyId));
        var result = await controller.GetStatusReport(null, null, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var report = Assert.IsType<MobileOrderStatusReportDto>(ok.Value);

        Assert.Equal(2, report.Pending);     // Pending + AutoCreated
        Assert.Equal(2, report.InProgress);  // Confirmed + Processing
        Assert.Equal(2, report.Ready);       // ReadyForDelivery + OutForDelivery
        Assert.Equal(1, report.Completed);   // Delivered
        Assert.Equal(1, report.Cancelled);   // Cancelled
        Assert.Equal(8, report.Total);
    }

    [Fact]
    public async Task GetStatusReport_ReturnsAccurateFulfillmentCounts()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);

        var now = DateTime.UtcNow;

        // Delivery 1: Has delivery address
        await SeedOrderAsync(db, companyId, OrderStatus.Confirmed, orderDate: now, deliveryDate: now, deliveryAddress: "456 Rose Lane");

        // Delivery 2: Has delivery record
        await SeedOrderAsync(db, companyId, OrderStatus.Confirmed, orderDate: now, deliveryDate: now, hasDeliveryRecord: true);

        // Pickup 1: Future delivery date
        await SeedOrderAsync(db, companyId, OrderStatus.Confirmed, orderDate: now, deliveryDate: now.AddDays(2));

        // Pickup 2: Has time slot
        await SeedOrderAsync(db, companyId, OrderStatus.Confirmed, orderDate: now, deliveryDate: now, timeSlot: "14:00 - 16:00");

        // TakeAway: Same day, no delivery address, no time slot, no delivery record
        await SeedOrderAsync(db, companyId, OrderStatus.Confirmed, orderDate: now, deliveryDate: now);

        var controller = new MobileOrdersController(db, new TenantContext(companyId));
        var result = await controller.GetStatusReport(null, null, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var report = Assert.IsType<MobileOrderStatusReportDto>(ok.Value);

        Assert.Equal(2, report.Fulfillment.Delivery);
        Assert.Equal(2, report.Fulfillment.Pickup);
        Assert.Equal(1, report.Fulfillment.TakeAway);
        Assert.Equal(5, report.Total);
    }

    [Fact]
    public async Task GetStatusReport_EnforcesTenantIsolation()
    {
        var companyA = Guid.NewGuid();
        var companyB = Guid.NewGuid();

        await using var db = CreateDb(companyA);

        await SeedOrderAsync(db, companyA, OrderStatus.Pending);
        await SeedOrderAsync(db, companyA, OrderStatus.Delivered);

        // Other tenant's orders
        await SeedOrderAsync(db, companyB, OrderStatus.Cancelled);
        await SeedOrderAsync(db, companyB, OrderStatus.Processing);
        await SeedOrderAsync(db, companyB, OrderStatus.ReadyForDelivery);

        // Query Company A
        var controllerA = new MobileOrdersController(db, new TenantContext(companyA));
        var resultA = await controllerA.GetStatusReport(null, null, CancellationToken.None);
        var okA = Assert.IsType<OkObjectResult>(resultA);
        var reportA = Assert.IsType<MobileOrderStatusReportDto>(okA.Value);

        Assert.Equal(1, reportA.Pending);
        Assert.Equal(1, reportA.Completed);
        Assert.Equal(0, reportA.Cancelled);
        Assert.Equal(0, reportA.InProgress);
        Assert.Equal(0, reportA.Ready);
        Assert.Equal(2, reportA.Total);
    }

    [Fact]
    public async Task GetStatusReport_ReturnsAllZeros_WhenNoOrdersFound()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);

        var controller = new MobileOrdersController(db, new TenantContext(companyId));
        var result = await controller.GetStatusReport(null, null, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var report = Assert.IsType<MobileOrderStatusReportDto>(ok.Value);

        Assert.Equal(0, report.Pending);
        Assert.Equal(0, report.InProgress);
        Assert.Equal(0, report.Ready);
        Assert.Equal(0, report.Completed);
        Assert.Equal(0, report.Cancelled);
        Assert.Equal(0, report.Total);
        Assert.Equal(0, report.Fulfillment.Delivery);
        Assert.Equal(0, report.Fulfillment.Pickup);
        Assert.Equal(0, report.Fulfillment.TakeAway);
    }

    [Fact]
    public async Task GetStatusReport_FiltersByDateRange()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);

        var baseDate = new DateTime(2026, 9, 1, 10, 0, 0, DateTimeKind.Utc);

        // Before range
        await SeedOrderAsync(db, companyId, OrderStatus.Pending, orderDate: baseDate.AddDays(-5));

        // In range
        await SeedOrderAsync(db, companyId, OrderStatus.Confirmed, orderDate: baseDate.AddDays(1));
        await SeedOrderAsync(db, companyId, OrderStatus.Delivered, orderDate: baseDate.AddDays(2));

        // After range
        await SeedOrderAsync(db, companyId, OrderStatus.ReadyForDelivery, orderDate: baseDate.AddDays(10));

        var controller = new MobileOrdersController(db, new TenantContext(companyId));
        var result = await controller.GetStatusReport(
            baseDate,
            baseDate.AddDays(3),
            CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var report = Assert.IsType<MobileOrderStatusReportDto>(ok.Value);

        Assert.Equal(0, report.Pending);
        Assert.Equal(1, report.InProgress); // Confirmed
        Assert.Equal(1, report.Completed);  // Delivered
        Assert.Equal(0, report.Ready);
        Assert.Equal(2, report.Total);
    }
}
