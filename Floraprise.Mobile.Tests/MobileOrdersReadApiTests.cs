using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.EntityFrameworkCore.Storage;
using Sumpooj.API.Controllers.Mobile;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Mobile;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;
using Xunit;

namespace Floraprise.Mobile.Tests;

public sealed class MobileOrdersReadApiTests : IDisposable
{
    private readonly Guid _companyId = Guid.NewGuid();
    private readonly Guid _otherCompanyId = Guid.NewGuid();
    private readonly string _databaseName = $"MobileOrdersRead_{Guid.NewGuid():N}";
    private readonly InMemoryDatabaseRoot _databaseRoot = new();

    public void Dispose()
    {
    }

    [Fact]
    public async Task Workspace_ReturnsCloudOrderListFields()
    {
        await using var db = CreateDb();
        var seeded = SeedOrder(db, orderNumber: "ORD-MOBILE-1", paymentAmount: 40m);
        var designer = new Staff(_companyId, "Design Lead", StaffRole.Designer, null, "9000000001", null);
        var driver = new Staff(_companyId, "Driver One", StaffRole.Driver, null, "9000000002", null);
        seeded.Order.Confirm();
        seeded.Order.StartProcessing(designer.Id);
        var delivery = new Delivery(_companyId, seeded.Order.Id, seeded.Order.DeliveryDate, "10 AM", "Main Street");
        delivery.AssignDeliveryPerson(driver.Id);
        db.AddRange(designer, driver, delivery);
        await db.SaveChangesAsync();

        var result = await Controller(db).Workspace(new MobileOrderWorkspaceRequest { PageSize = 20 }, CancellationToken.None);

        var response = AssertOk<MobileOrderWorkspaceResponse>(result);
        var item = Assert.Single(response.Items);
        Assert.Equal(seeded.Order.Id, item.Id);
        Assert.Equal("ORD-MOBILE-1", item.OrderNumber);
        Assert.Equal("Customer One", item.CustomerName);
        Assert.Equal("9876543210", item.CustomerPhone);
        Assert.Equal("Recipient One", item.RecipientName);
        Assert.Equal("9988776655", item.RecipientPhone);
        Assert.Equal("delivery", item.FulfilmentType);
        Assert.Equal("preparing", item.Status);
        Assert.Equal("Paid", item.PaymentStatus);
        Assert.Equal(100m, item.TotalAmount);
        Assert.Equal(40m, item.PaidAmount);
        Assert.Equal(60m, item.BalanceDue);
        Assert.Equal("Design Lead", item.DesignerName);
        Assert.Equal("Driver One", item.DeliveryPersonName);
    }

    [Fact]
    public async Task DetailByGuid_ReturnsItemsPaymentsDeliveryAndTimeline()
    {
        await using var db = CreateDb();
        var seeded = SeedOrder(db, orderNumber: "ORD-MOBILE-DETAIL", paymentAmount: 100m);
        var driver = new Staff(_companyId, "Driver Two", StaffRole.Driver, null, "9000000003", null);
        var delivery = new Delivery(_companyId, seeded.Order.Id, seeded.Order.DeliveryDate, "Evening", "Detail Street");
        delivery.AssignDeliveryPerson(driver.Id);
        db.AddRange(driver, delivery, new DeliveryTimeline(delivery.Id, "Assigned", "Driver assigned"));
        await db.SaveChangesAsync();

        var result = await Controller(db).GetById(seeded.Order.Id, CancellationToken.None);

        var detail = AssertOk<MobileOrderDetailDto>(result);
        Assert.Equal(seeded.Order.Id, detail.Id);
        Assert.Equal("ORD-MOBILE-DETAIL", detail.OrderNumber);
        Assert.Equal("9876543210", detail.CustomerPhone);
        Assert.Equal("delivery", detail.FulfilmentType);
        Assert.Equal(100m, detail.PaidAmount);
        Assert.Equal(0m, detail.BalanceDue);
        Assert.Single(detail.Items);
        Assert.Single(detail.Payments);
        Assert.NotNull(detail.DeliverySummary);
        Assert.Equal("Driver Two", detail.DeliverySummary!.DeliveryPersonName);
        Assert.Contains(detail.Timeline, t => t.Source == "delivery" && t.Status == "Assigned");
    }

    [Fact]
    public async Task DetailByGuid_UsesLegacyIdentityDesignerAssignmentWhenStaffAssignmentIsMissing()
    {
        await using var db = CreateDb();
        var seeded = SeedOrder(db, orderNumber: "ORD-LEGACY-DESIGNER", paymentAmount: 100m);
        var identityUserId = Guid.NewGuid();
        var designer = new Staff(_companyId, "Legacy Designer", StaffRole.Designer, null, "9000000004", null);
        designer.LinkIdentityUser(identityUserId);
        seeded.Order.Confirm();
        seeded.Order.StartProcessing(identityUserId);
        db.Add(designer);
        await db.SaveChangesAsync();

        var detail = AssertOk<MobileOrderDetailDto>(
            await Controller(db).GetById(seeded.Order.Id, CancellationToken.None));

        Assert.Null(detail.AssignedDesignerStaffId);
        Assert.Equal(identityUserId, detail.AssignedDesignerId);
        Assert.Equal("Legacy Designer", detail.AssignedDesignerName);
    }

    [Fact]
    public async Task DetailByOrderNumber_ReturnsSameOrder()
    {
        await using var db = CreateDb();
        var seeded = SeedOrder(db, orderNumber: "ORD-BY-NUMBER", paymentAmount: 25m);
        await db.SaveChangesAsync();

        var result = await Controller(db).GetByOrderNumber("ORD-BY-NUMBER", CancellationToken.None);

        var detail = AssertOk<MobileOrderDetailDto>(result);
        Assert.Equal(seeded.Order.Id, detail.Id);
        Assert.Equal("ORD-BY-NUMBER", detail.OrderNumber);
    }

    [Fact]
    public async Task PaidAndBalance_UseApprovedPaymentsOnly()
    {
        await using var db = CreateDb();
        var seeded = SeedOrder(db, orderNumber: "ORD-BALANCE", paymentAmount: 40m);
        db.Payments.Add(new Payment(_companyId, seeded.Order.Id, PaymentMethod.Upi, 30m));
        await db.SaveChangesAsync();

        var result = await Controller(db).GetById(seeded.Order.Id, CancellationToken.None);

        var detail = AssertOk<MobileOrderDetailDto>(result);
        Assert.Equal(40m, detail.PaidAmount);
        Assert.Equal(60m, detail.BalanceDue);
        Assert.Equal(2, detail.Payments.Count);
    }

    [Fact]
    public async Task CompanyIsolation_HidesOtherCompanyOrders()
    {
        await using var db = CreateDb();
        var own = SeedOrder(db, orderNumber: "ORD-OWN", paymentAmount: 10m);
        var other = SeedOrder(db, companyId: _otherCompanyId, orderNumber: "ORD-OTHER", paymentAmount: 100m);
        await db.SaveChangesAsync();

        var workspace = AssertOk<MobileOrderWorkspaceResponse>(
            await Controller(db).Workspace(new MobileOrderWorkspaceRequest(), CancellationToken.None));
        var hiddenDetail = await Controller(db).GetById(other.Order.Id, CancellationToken.None);

        var item = Assert.Single(workspace.Items);
        Assert.Equal(own.Order.Id, item.Id);
        Assert.IsType<NotFoundResult>(hiddenDetail);
    }

    private SumpoojDbContext CreateDb(Guid? companyId = null)
    {
        var options = new DbContextOptionsBuilder<SumpoojDbContext>()
            .UseInMemoryDatabase(_databaseName, _databaseRoot)
            .ConfigureWarnings(warnings => warnings.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options;
        return new SumpoojDbContext(options, new TestTenantContext(companyId ?? _companyId));
    }

    private MobileOrdersController Controller(SumpoojDbContext db, Guid? companyId = null) =>
        new(db, new TestTenantContext(companyId ?? _companyId));

    private SeededOrder SeedOrder(SumpoojDbContext db, string orderNumber, decimal paymentAmount, Guid? companyId = null)
    {
        var resolvedCompanyId = companyId ?? _companyId;
        var customer = new Customer(resolvedCompanyId, "Customer One", null, "9876543210");
        var order = new Order(
            resolvedCompanyId,
            customer.Id,
            DateTime.UtcNow.AddHours(2),
            "Main Street",
            "560001",
            "Recipient One",
            "9988776655");
        order.SetImportedOrderNumber(orderNumber);
        order.AddItem(Guid.NewGuid(), "Rose Bouquet", 1, 100m);
        order.MarkPaid();
        var payment = new Payment(resolvedCompanyId, order.Id, PaymentMethod.Cash, paymentAmount);
        payment.Approve(null, null);
        db.AddRange(customer, order, payment);
        return new SeededOrder(order, customer);
    }

    private static T AssertOk<T>(IActionResult result)
    {
        var ok = Assert.IsType<OkObjectResult>(result);
        return Assert.IsType<T>(ok.Value);
    }

    private sealed record SeededOrder(Order Order, Customer Customer);

    private sealed class TestTenantContext : ITenantContext
    {
        public TestTenantContext(Guid companyId) => CompanyId = companyId;
        public Guid? CompanyId { get; }
        public string? Region => null;
        public bool IsPlatformUser => false;
    }
}