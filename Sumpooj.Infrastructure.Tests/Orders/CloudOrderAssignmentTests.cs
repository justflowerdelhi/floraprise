using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.API.Controllers;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.UseCases;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;
using Sumpooj.Infrastructure.Repositories;

namespace Sumpooj.Infrastructure.Tests.Orders;

public class CloudOrderAssignmentTests
{
    private sealed class TenantContext(Guid companyId) : ITenantContext
    {
        public Guid? CompanyId => companyId;
        public bool IsPlatformUser => false;
        public string? Region => null;
    }

    private sealed class FakeDeliveryRepository : IDeliveryRepository
    {
        public List<Delivery> Deliveries { get; } = [];

        public Task<Delivery?> GetBySalesOrderIdAsync(Guid salesOrderId) =>
            Task.FromResult(Deliveries.FirstOrDefault(d => d.SalesOrderId == salesOrderId));

        public Task AddAsync(Delivery delivery)
        {
            Deliveries.Add(delivery);
            return Task.CompletedTask;
        }

        public Task UpdateAsync(Delivery delivery) => Task.CompletedTask;

        public Task<Delivery?> GetByIdAsync(Guid id) => throw new NotSupportedException();
        public Task<IReadOnlyList<Delivery>> GetAllAsync() => throw new NotSupportedException();
        public Task<IReadOnlyList<Delivery>> GetByDateAsync(DateTime date) => throw new NotSupportedException();
        public Task<List<Delivery>> GetByIdsAsync(List<Guid> ids) => throw new NotSupportedException();
        public Task<int> GetDeliveryCountByDriverAsync(Guid driverId, DateTime from, DateTime to) => throw new NotSupportedException();
        public Task<int> GetCompletedDeliveryCountByDriverAsync(Guid driverId, DateTime from, DateTime to) => throw new NotSupportedException();
    }

    [Fact]
    public async Task AssignDesignerPersistsAndStartsProcessingForAConfirmedOrder()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var order = await SeedOrderAsync(db, companyId, confirm: true);
        var designer = await SeedDesignerAsync(db, companyId);

        await CreateService(db).AssignDesignerStaffAsync(companyId, order.Id, designer.Id);

        db.ChangeTracker.Clear();
        var stored = await db.Orders.SingleAsync();
        Assert.Equal(designer.Id, stored.AssignedDesignerStaffId);
        Assert.Null(stored.AssignedToUserId);
        Assert.Equal(OrderStatus.Processing, stored.Status);
    }

    [Fact]
    public async Task AssignDesignerPersistsForANonConfirmedOrderWithoutChangingStatus()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);

        // POS-synced orders are not Confirmed; this path used to throw and surface as HTTP 500.
        var order = await SeedOrderAsync(db, companyId, confirm: false);
        Assert.Equal(OrderStatus.Pending, order.Status);
        var designer = await SeedDesignerAsync(db, companyId);

        await CreateService(db).AssignDesignerStaffAsync(companyId, order.Id, designer.Id);

        db.ChangeTracker.Clear();
        var stored = await db.Orders.SingleAsync();
        Assert.Equal(designer.Id, stored.AssignedDesignerStaffId);
        Assert.Null(stored.AssignedToUserId);
        Assert.Equal(OrderStatus.Pending, stored.Status);
    }

    [Fact]
    public async Task AssignDesignerReturnsConflictNotServerErrorForDeliveredOrders()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var order = await SeedOrderAsync(db, companyId, confirm: true);
        order.MarkDeliveredDirect();
        var designer = await SeedDesignerAsync(db, companyId);
        await db.SaveChangesAsync();

        var controller = new OrdersController(CreateService(db), new TenantContext(companyId), db);
        var result = await controller.AssignDesigner(
            order.Id,
            new AssignStaffRequest { StaffId = designer.Id });

        Assert.IsType<ConflictObjectResult>(result);
    }

    [Fact]
    public async Task AssignDesignerReturnsNotFoundForAnUnknownOrder()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var controller = new OrdersController(CreateService(db), new TenantContext(companyId), db);

        var result = await controller.AssignDesigner(
            Guid.NewGuid(),
            new AssignStaffRequest { StaffId = Guid.NewGuid() });

        Assert.IsType<NotFoundObjectResult>(result);
    }

    [Fact]
    public async Task AssignDesignerRejectsAnInactiveOrForeignCompanyStaffMember()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var order = await SeedOrderAsync(db, companyId, confirm: true);
        var foreignDesigner = new Staff(Guid.NewGuid(), "Foreign", StaffRole.Designer, null, null, null);
        db.Staff.Add(foreignDesigner);
        await db.SaveChangesAsync();
        var controller = new OrdersController(CreateService(db), new TenantContext(companyId), db);

        var result = await controller.AssignDesigner(order.Id, new AssignStaffRequest { StaffId = foreignDesigner.Id });

        Assert.IsType<NotFoundObjectResult>(result);
    }

    [Fact]
    public async Task AssignDesignerEndpoint_AssignsAnActiveDesignerFromTheOrderCompany()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var order = await SeedOrderAsync(db, companyId, confirm: true);
        var designer = await SeedDesignerAsync(db, companyId);
        var controller = new OrdersController(CreateService(db), new TenantContext(companyId), db);

        var result = await controller.AssignDesigner(order.Id, new AssignStaffRequest { StaffId = designer.Id });

        Assert.IsType<NoContentResult>(result);
        db.ChangeTracker.Clear();
        var stored = await db.Orders.SingleAsync();
        Assert.Equal(designer.Id, stored.AssignedDesignerStaffId);
        Assert.Null(stored.AssignedToUserId);
    }

    [Fact]
    public async Task AssignDesignerEndpoint_RejectsAnInactiveDesigner()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var order = await SeedOrderAsync(db, companyId, confirm: true);
        var designer = await SeedDesignerAsync(db, companyId);
        designer.Deactivate();
        await db.SaveChangesAsync();
        var controller = new OrdersController(CreateService(db), new TenantContext(companyId), db);

        var result = await controller.AssignDesigner(order.Id, new AssignStaffRequest { StaffId = designer.Id });

        Assert.IsType<NotFoundObjectResult>(result);
    }

    [Fact]
    public async Task AssignDriverPersistsDeliveryPersonAndCreatesTheDeliveryRecord()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var order = await SeedOrderAsync(db, companyId, confirm: true);
        var deliveries = new FakeDeliveryRepository();
        var driverId = Guid.NewGuid();

        await CreateService(db, deliveries).AssignDriverAsync(companyId, order.Id, driverId);

        db.ChangeTracker.Clear();
        var stored = await db.Orders.SingleAsync();
        Assert.Equal(driverId, stored.DeliveryPersonId);

        // The tracking link the app requests is minted from this Delivery record.
        var delivery = Assert.Single(deliveries.Deliveries);
        Assert.Equal(order.Id, delivery.SalesOrderId);
        Assert.Equal(companyId, delivery.CompanyId);
    }

    private static async Task<Order> SeedOrderAsync(SumpoojDbContext db, Guid companyId, bool confirm)
    {
        var customer = new Customer(companyId, "Cloud Customer", null, "9876543210");
        var order = new Order(
            companyId,
            customer.Id,
            new DateTime(2026, 9, 20, 0, 0, 0, DateTimeKind.Utc),
            "1 Old Road",
            "560002",
            "Asha",
            "9876543210");
        order.AddItem(Guid.NewGuid(), "Rose Bunch", 2, 100m);
        if (confirm) order.Confirm();

        db.AddRange(customer, order);
        await db.SaveChangesAsync();
        return order;
    }

    private static async Task<Staff> SeedDesignerAsync(SumpoojDbContext db, Guid companyId)
    {
        var designer = new Staff(companyId, "Cloud Designer", StaffRole.Designer, null, "9000000001", null);
        db.Staff.Add(designer);
        await db.SaveChangesAsync();
        return designer;
    }

    private static OrderService CreateService(
        SumpoojDbContext db,
        IDeliveryRepository? deliveryRepository = null)
    {
        return new OrderService(
            new OrderRepository(db),
            null!, null!, null!, null!, null!, null!, null!, null!, null!, null!,
            deliveryRepository!,
            null!);
    }

    private static SumpoojDbContext CreateDb(Guid companyId)
    {
        var options = new DbContextOptionsBuilder<SumpoojDbContext>()
            .UseInMemoryDatabase($"CloudOrderAssignment_{Guid.NewGuid():N}")
            .Options;
        return new SumpoojDbContext(options, new TenantContext(companyId));
    }
}
