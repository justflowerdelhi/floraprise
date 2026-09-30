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

    [Fact]
    public async Task Workspace_PaymentStatusUnpaid_ReturnsPartiallyPaidAndUnpaidOrdersAcrossDeliveryWalkInPickup()
    {
        await using var db = CreateDb();

        // 1. Delivery order with partial payment (₹1000 total, ₹170 paid, ₹830 outstanding)
        var custUbaid = new Customer(_companyId, "ubaid", null, "9574184092");
        var deliveryOrder = new Order(
            _companyId,
            custUbaid.Id,
            DateTime.UtcNow.AddHours(4),
            "Flower Street 123",
            "560001",
            "ubaid",
            "9574184092");
        deliveryOrder.SetImportedOrderNumber("ORD-DELIVERY-PARTIAL");
        deliveryOrder.AddItem(Guid.NewGuid(), "Deluxe Bouquet", 1, 1000m);
        deliveryOrder.MarkPartiallyPaid(170m);
        var deliveryPayment = new Payment(_companyId, deliveryOrder.Id, PaymentMethod.Cash, 170m);
        deliveryPayment.Approve(null, null);

        // 2. Walk-in order with partial payment (₹10000 total, ₹5000 paid, ₹5000 outstanding)
        var custWalkIn = new Customer(_companyId, "Walkin Customer", null, "9876543211");
        var walkInOrder = new Order(_companyId, custWalkIn.Id, DateTime.UtcNow, string.Empty, string.Empty, string.Empty, string.Empty);
        walkInOrder.SetImportedOrderNumber("ORD-WALKIN-PARTIAL");
        walkInOrder.AddItem(Guid.NewGuid(), "Roses", 1, 10000m);
        walkInOrder.MarkPartiallyPaid(5000m);
        var walkInPayment = new Payment(_companyId, walkInOrder.Id, PaymentMethod.Upi, 5000m);
        walkInPayment.Approve(null, null);

        // 3. Pickup order with zero payment / unpaid (₹8000 total, ₹0 paid, ₹8000 outstanding)
        var custPickup = new Customer(_companyId, "Pickup Customer", null, "9876543212");
        var pickupOrder = new Order(_companyId, custPickup.Id, DateTime.UtcNow.AddDays(1), string.Empty, string.Empty, string.Empty, string.Empty);
        pickupOrder.SetImportedOrderNumber("ORD-PICKUP-UNPAID");
        pickupOrder.AddItem(Guid.NewGuid(), "Lilies", 1, 8000m);

        // 4. Fully paid order (₹500 total, ₹500 paid, ₹0 outstanding)
        var custPaid = new Customer(_companyId, "Paid Customer", null, "9876543213");
        var paidOrder = new Order(_companyId, custPaid.Id, DateTime.UtcNow, string.Empty, string.Empty, string.Empty, string.Empty);
        paidOrder.SetImportedOrderNumber("ORD-FULLY-PAID");
        paidOrder.AddItem(Guid.NewGuid(), "Orchids", 1, 500m);
        paidOrder.MarkPaid();
        var fullPayment = new Payment(_companyId, paidOrder.Id, PaymentMethod.Cash, 500m);
        fullPayment.Approve(null, null);

        db.AddRange(custUbaid, deliveryOrder, deliveryPayment,
                    custWalkIn, walkInOrder, walkInPayment,
                    custPickup, pickupOrder,
                    custPaid, paidOrder, fullPayment);
        await db.SaveChangesAsync();

        var controller = Controller(db);
        var request = new MobileOrderWorkspaceRequest
        {
            PaymentStatus = "unpaid",
            PageSize = 20
        };

        var result = await controller.Workspace(request, CancellationToken.None);
        var response = AssertOk<MobileOrderWorkspaceResponse>(result);

        Assert.Equal(3, response.TotalCount);
        Assert.Equal(3, response.Items.Count);

        var deliveryItem = Assert.Single(response.Items, i => i.OrderNumber == "ORD-DELIVERY-PARTIAL");
        Assert.Equal("ubaid", deliveryItem.CustomerName);
        Assert.Equal("9574184092", deliveryItem.CustomerPhone);
        Assert.Equal("delivery", deliveryItem.FulfilmentType);
        Assert.Equal(1000m, deliveryItem.TotalAmount);
        Assert.Equal(170m, deliveryItem.PaidAmount);
        Assert.Equal(830m, deliveryItem.BalanceDue);
        Assert.Equal("PartiallyPaid", deliveryItem.PaymentStatus);

        var walkInItem = Assert.Single(response.Items, i => i.OrderNumber == "ORD-WALKIN-PARTIAL");
        Assert.Equal(10000m, walkInItem.TotalAmount);
        Assert.Equal(5000m, walkInItem.PaidAmount);
        Assert.Equal(5000m, walkInItem.BalanceDue);

        var pickupItem = Assert.Single(response.Items, i => i.OrderNumber == "ORD-PICKUP-UNPAID");
        Assert.Equal(8000m, pickupItem.TotalAmount);
        Assert.Equal(0m, pickupItem.PaidAmount);
        Assert.Equal(8000m, pickupItem.BalanceDue);

        Assert.DoesNotContain(response.Items, i => i.OrderNumber == "ORD-FULLY-PAID");
    }

    [Fact]
    public async Task Workspace_And_Detail_ReturnEventSaleFulfilmentType()
    {
        await using var db = CreateDb();
        var seeded = SeedOrder(db, orderNumber: "ORD-EVENT-101", paymentAmount: 500m);
        seeded.Order.AddInternalNote("[fulfilment:event_sale]");
        await db.SaveChangesAsync();

        var workspaceResult = await Controller(db).Workspace(new MobileOrderWorkspaceRequest { PageSize = 20 }, CancellationToken.None);
        var workspaceResponse = AssertOk<MobileOrderWorkspaceResponse>(workspaceResult);
        var item = Assert.Single(workspaceResponse.Items, i => i.OrderNumber == "ORD-EVENT-101");
        Assert.Equal("event_sale", item.FulfilmentType);

        var detailResult = await Controller(db).GetById(seeded.Order.Id, CancellationToken.None);
        var detail = AssertOk<MobileOrderDetailDto>(detailResult);
        Assert.Equal("event_sale", detail.FulfilmentType);
    }

    [Fact]
    public async Task Workspace_FulfilmentTypeEventSaleFilter_ReturnsOnlyEventSales()
    {
        await using var db = CreateDb();
        var eventOrder = SeedOrder(db, orderNumber: "ORD-EVENT-ONLY", paymentAmount: 500m);
        eventOrder.Order.AddInternalNote("[fulfilment:event_sale]");

        var normalDelivery = SeedOrder(db, orderNumber: "ORD-DELIVERY-ONLY", paymentAmount: 100m);

        await db.SaveChangesAsync();

        // 1. Filter by event_sale -> only returns ORD-EVENT-ONLY
        var eventResult = await Controller(db).Workspace(new MobileOrderWorkspaceRequest { FulfilmentType = "event_sale" }, CancellationToken.None);
        var eventResponse = AssertOk<MobileOrderWorkspaceResponse>(eventResult);
        var filteredEvent = Assert.Single(eventResponse.Items);
        Assert.Equal("ORD-EVENT-ONLY", filteredEvent.OrderNumber);
        Assert.Equal("event_sale", filteredEvent.FulfilmentType);

        // 2. Filter by delivery -> only returns ORD-DELIVERY-ONLY
        var deliveryResult = await Controller(db).Workspace(new MobileOrderWorkspaceRequest { FulfilmentType = "delivery" }, CancellationToken.None);
        var deliveryResponse = AssertOk<MobileOrderWorkspaceResponse>(deliveryResult);
        var filteredDelivery = Assert.Single(deliveryResponse.Items);
        Assert.Equal("ORD-DELIVERY-ONLY", filteredDelivery.OrderNumber);
        Assert.Equal("delivery", filteredDelivery.FulfilmentType);
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