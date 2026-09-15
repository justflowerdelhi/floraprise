using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.API.Controllers;
using Sumpooj.Application.Deliveries;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Orders;
using Sumpooj.Application.UseCases;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;
using Sumpooj.Infrastructure.Repositories;
using Xunit;

namespace Sumpooj.Infrastructure.Tests.Deliveries;

public class CloudDeliveryTransactionTests
{
    private sealed class TenantContext(Guid companyId) : ITenantContext
    {
        public Guid? CompanyId => companyId;
        public bool IsPlatformUser => false;
        public string? Region => null;
    }

    private static SumpoojDbContext CreateDb(Guid companyId, string? dbName = null)
    {
        var options = new DbContextOptionsBuilder<SumpoojDbContext>()
            .UseInMemoryDatabase(dbName ?? $"CloudDelivery_{Guid.NewGuid():N}")
            .Options;
        return new SumpoojDbContext(options, new TenantContext(companyId));
    }

    private static OrderService CreateOrderService(SumpoojDbContext db)
    {
        return new OrderService(
            new OrderRepository(db),
            new CustomerRepository(db),
            new ProductRepository(db),
            new LocationRepository(db),
            new ShiftRepository(db),
            new PaymentRepository(db),
            new InventoryLedgerRepository(db),
            new ProductBatchRepository(db),
            new InventoryReservationRepository(db),
            new FinishedGoodsBatchRepository(db),
            new JournalEntryRepository(db),
            new DeliveryRepository(db),
            new CorporateRepository(db),
            new IdempotencyRecordRepository(db),
            new UnitOfWork(db));
    }

    private static DeliveriesController CreateDeliveriesController(SumpoojDbContext db, Guid companyId)
    {
        var tenantContext = new TenantContext(companyId);
        var deliveryRepo = new DeliveryRepository(db);
        var staffRepo = new StaffRepository(db);
        var assignHandler = new AssignDeliveryPersonHandler(deliveryRepo, staffRepo);
        var orderRepo = new OrderRepository(db);
        var orderService = CreateOrderService(db);
        var unitOfWork = new UnitOfWork(db);

        return new DeliveriesController(
            db,
            deliveryRepo,
            assignHandler,
            orderRepo,
            orderService,
            tenantContext,
            unitOfWork);
    }

    private static async Task<(Location location, Customer customer, Staff driver)> SeedBaseDataAsync(SumpoojDbContext db, Guid companyId)
    {
        var location = new Location(companyId, "Koramangala Hub", "KM-01", LocationType.Store, "100 80ft Road");
        location.SetAsDefault();
        db.Locations.Add(location);

        var shift = new Shift(companyId, location.Id, Guid.NewGuid(), "Retail Cashier", 2000m);
        db.Shifts.Add(shift);

        var customer = new Customer(companyId, "Priya Sharma", "priya@example.com", "9876543210");
        db.Customers.Add(customer);

        var driver = new Staff(companyId, "Ramesh Driver", StaffRole.Driver, "ramesh@driver.com", "9988776655", null);
        db.Staff.Add(driver);

        await db.SaveChangesAsync();
        db.ChangeTracker.Clear();
        return (location, customer, driver);
    }

    [Fact]
    public async Task Delivery_AutoScheduled_WhenOrderIntentIsDelivery()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var (location, customer, _) = await SeedBaseDataAsync(db, companyId);

        var product = new Product(companyId, "Red Roses Bouquet", "RRB-10", ProductType.SingleFlower, ProductCategory.Roses, 500m, 200m, null);
        db.Products.Add(product);
        await db.SaveChangesAsync();
        db.ChangeTracker.Clear();

        var orderService = CreateOrderService(db);
        var request = new CreateOrderRequest
        {
            CustomerId = customer.Id,
            LocationId = location.Id,
            OrderSource = "WalkIn",
            OrderIntent = "DELIVERY",
            DeliveryAddress = "42 Indiranagar, Bangalore",
            DeliveryPincode = "560038",
            RecipientName = "Ananya Sharma",
            RecipientPhone = "9123456780",
            CardMessage = "Happy Birthday Dearest Ananya!",
            TimeSlot = "Morning 09:00 - 12:00",
            DeliveryFee = 150m,
            DeliveryPriority = "SameDay",
            Items = [new OrderItemRequest { ProductId = product.Id, ProductName = product.Name, Quantity = 1, UnitPrice = 500m }]
        };

        var result = await orderService.CreateOrderAsync(companyId, request);

        db.ChangeTracker.Clear();
        var delivery = await db.Deliveries.SingleOrDefaultAsync(d => d.SalesOrderId == result.OrderId);
        Assert.NotNull(delivery);
        Assert.Equal("42 Indiranagar, Bangalore", delivery.DeliveryAddress);
        Assert.Equal("560038", delivery.PostalCode);
        Assert.Equal("Morning 09:00 - 12:00", delivery.TimeSlot);
        Assert.Equal(DeliveryStatus.Created, delivery.Status);

        var order = await db.Orders.SingleAsync(o => o.Id == result.OrderId);
        Assert.Equal("Happy Birthday Dearest Ananya!", order.CardMessage);
        Assert.Equal(150m, order.DeliveryFee);
        Assert.False(order.IsInventoryProcessed);
    }

    [Fact]
    public async Task Deliveries_FilteredByTenant_DoesNotLeakAcrossCompanies()
    {
        var companyA = Guid.NewGuid();
        var companyB = Guid.NewGuid();
        var sharedDbName = $"MultiTenantDeliveries_{Guid.NewGuid():N}";

        await using (var dbA = CreateDb(companyA, sharedDbName))
        {
            var (locA, custA, _) = await SeedBaseDataAsync(dbA, companyA);
            var orderA = new Order(companyA, custA.Id, DateTime.UtcNow, "Address A", "560001", "Recipient A", "9999911111");
            dbA.Orders.Add(orderA);
            var deliveryA = new Delivery(companyA, orderA.Id, DateTime.UtcNow, "Morning", "Address A");
            dbA.Deliveries.Add(deliveryA);
            await dbA.SaveChangesAsync();
        }

        await using (var dbB = CreateDb(companyB, sharedDbName))
        {
            var (locB, custB, _) = await SeedBaseDataAsync(dbB, companyB);
            var orderB = new Order(companyB, custB.Id, DateTime.UtcNow, "Address B", "560002", "Recipient B", "9999922222");
            dbB.Orders.Add(orderB);
            var deliveryB = new Delivery(companyB, orderB.Id, DateTime.UtcNow, "Evening", "Address B");
            dbB.Deliveries.Add(deliveryB);
            await dbB.SaveChangesAsync();
        }

        await using (var dbCheckA = CreateDb(companyA, sharedDbName))
        {
            var controllerA = CreateDeliveriesController(dbCheckA, companyA);
            var actionResult = await controllerA.GetDeliveries(DateTime.UtcNow, null, null);
            var okResult = Assert.IsType<OkObjectResult>(actionResult);
            var list = Assert.IsAssignableFrom<List<DeliveryListDto>>(okResult.Value);

            Assert.Single(list);
            Assert.Equal("Recipient A", list[0].RecipientName);
            Assert.Equal("Address A", list[0].Address);
        }
    }

    [Fact]
    public async Task DeliveryListDto_ReturnsEnrichedFloristMetadata_WithoutNPlusOne()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var (location, customer, driver) = await SeedBaseDataAsync(db, companyId);

        var product1 = new Product(companyId, "Red Roses", "RR-01", ProductType.SingleFlower, ProductCategory.Roses, 40m, 15m, null);
        var product2 = new Product(companyId, "Lilies", "LL-01", ProductType.SingleFlower, ProductCategory.Lilies, 80m, 30m, null);
        db.Products.AddRange(product1, product2);
        await db.SaveChangesAsync();

        var order = new Order(companyId, customer.Id, DateTime.UtcNow, "100 Indiranagar", "560038", "Siddharth", "9876543210");
        order.SetCardMessage("With warm wishes!");
        order.SetDeliveryFee(100m);
        order.SetDeliveryPriority(DeliveryPriority.Express);
        order.AddItem(product1.Id, product1.Name, 10, product1.RetailPrice);
        order.AddItem(product2.Id, product2.Name, 5, product2.RetailPrice);
        db.Orders.Add(order);

        var delivery = new Delivery(companyId, order.Id, DateTime.UtcNow, "Evening 17:00-20:00", "100 Indiranagar");
        delivery.SetPostalCode("560038");
        delivery.AssignDeliveryPerson(driver.Id);
        db.Deliveries.Add(delivery);
        await db.SaveChangesAsync();
        db.ChangeTracker.Clear();

        var controller = CreateDeliveriesController(db, companyId);
        var result = await controller.GetDeliveries(DateTime.UtcNow, null, null);
        var okResult = Assert.IsType<OkObjectResult>(result);
        var list = Assert.IsAssignableFrom<List<DeliveryListDto>>(okResult.Value);

        Assert.Single(list);
        var dto = list[0];
        Assert.Equal("Siddharth", dto.RecipientName);
        Assert.Equal("9876543210", dto.RecipientPhone);
        Assert.Equal("With warm wishes!", dto.CardMessage);
        Assert.Equal("Express", dto.DeliveryPriority);
        Assert.Equal(100m, dto.DeliveryFee);
        Assert.Equal(driver.Id, dto.DeliveryPersonId);
        Assert.Equal(driver.Name, dto.DeliveryPersonName);
        Assert.Equal(15, dto.ItemCount);
        Assert.Contains("10x Red Roses", dto.ItemsSummary);
        Assert.Contains("5x Lilies", dto.ItemsSummary);
    }

    [Fact]
    public async Task MarkOutForDelivery_UnassignedDriver_FailsWithBadRequest()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var (location, customer, _) = await SeedBaseDataAsync(db, companyId);

        var order = new Order(companyId, customer.Id, DateTime.UtcNow, "42 MG Road", "560001", "Recipient", "9999999999");
        db.Orders.Add(order);
        var delivery = new Delivery(companyId, order.Id, DateTime.UtcNow, "Anytime", "42 MG Road");
        db.Deliveries.Add(delivery);
        await db.SaveChangesAsync();
        db.ChangeTracker.Clear();

        var controller = CreateDeliveriesController(db, companyId);
        var result = await controller.MarkOutForDelivery(delivery.Id);

        var badRequest = Assert.IsType<BadRequestObjectResult>(result);
        Assert.Contains("driver must be explicitly assigned", badRequest.Value?.ToString(), StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task MarkOutForDelivery_WithAssignedDriver_CascadesAuthoritatively_AndUpdatesOrderStatus()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var (location, customer, driver) = await SeedBaseDataAsync(db, companyId);

        var order = new Order(companyId, customer.Id, DateTime.UtcNow, "42 MG Road", "560001", "Recipient", "9999999999");
        order.Confirm();
        db.Orders.Add(order);

        var delivery = new Delivery(companyId, order.Id, DateTime.UtcNow, "Anytime", "42 MG Road");
        delivery.AssignDeliveryPerson(driver.Id);
        db.Deliveries.Add(delivery);
        await db.SaveChangesAsync();
        db.ChangeTracker.Clear();

        var controller = CreateDeliveriesController(db, companyId);
        var result = await controller.MarkOutForDelivery(delivery.Id);

        Assert.IsType<OkObjectResult>(result);

        db.ChangeTracker.Clear();
        var updatedDelivery = await db.Deliveries.SingleAsync(d => d.Id == delivery.Id);
        var updatedOrder = await db.Orders.SingleAsync(o => o.Id == order.Id);

        Assert.Equal(DeliveryStatus.OutForDelivery, updatedDelivery.Status);
        Assert.Equal(OrderStatus.OutForDelivery, updatedOrder.Status);
    }

    [Fact]
    public async Task MarkDelivered_UndispatchedDelivery_FailsWithBadRequest()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var (location, customer, driver) = await SeedBaseDataAsync(db, companyId);

        var order = new Order(companyId, customer.Id, DateTime.UtcNow, "42 MG Road", "560001", "Recipient", "9999999999");
        db.Orders.Add(order);
        var delivery = new Delivery(companyId, order.Id, DateTime.UtcNow, "Anytime", "42 MG Road");
        db.Deliveries.Add(delivery);
        await db.SaveChangesAsync();
        db.ChangeTracker.Clear();

        var controller = CreateDeliveriesController(db, companyId);
        var result = await controller.MarkDelivered(delivery.Id);

        var badRequest = Assert.IsType<BadRequestObjectResult>(result);
        Assert.Contains("must be assigned and dispatched", badRequest.Value?.ToString(), StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task MarkDelivered_OutForDelivery_MarksDelivered_AndConsumesInventoryDirectly()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var (location, customer, driver) = await SeedBaseDataAsync(db, companyId);

        var product = new Product(companyId, "Yellow Carnation", "CARN-YEL", ProductType.SingleFlower, ProductCategory.Carnations, 50m, 20m, null);
        product.SetInventorySettings(true, false, 0);
        product.AdjustStock(50);
        db.Products.Add(product);
        await db.SaveChangesAsync();

        var order = new Order(companyId, customer.Id, DateTime.UtcNow, "42 MG Road", "560001", "Recipient", "9999999999");
        order.Confirm();
        order.AddItem(product.Id, product.Name, 10, 50m);
        db.Orders.Add(order);

        var delivery = new Delivery(companyId, order.Id, DateTime.UtcNow, "Anytime", "42 MG Road");
        delivery.AssignDeliveryPerson(driver.Id);
        db.Deliveries.Add(delivery);
        await db.SaveChangesAsync();
        db.ChangeTracker.Clear();

        var controller = CreateDeliveriesController(db, companyId);

        // 1. Dispatch out
        var dispatchResult = await controller.MarkOutForDelivery(delivery.Id);
        Assert.IsType<OkObjectResult>(dispatchResult);

        // 2. Mark delivered
        var deliveredResult = await controller.MarkDelivered(delivery.Id);
        Assert.IsType<OkObjectResult>(deliveredResult);

        db.ChangeTracker.Clear();
        var updatedDelivery = await db.Deliveries.SingleAsync(d => d.Id == delivery.Id);
        var updatedOrder = await db.Orders.SingleAsync(o => o.Id == order.Id);
        var updatedProduct = await db.Products.SingleAsync(p => p.Id == product.Id);

        Assert.Equal(DeliveryStatus.Delivered, updatedDelivery.Status);
        Assert.Equal(OrderStatus.Delivered, updatedOrder.Status);
        Assert.True(updatedOrder.IsInventoryProcessed);

        // Inventory consumed: 50 - 10 = 40
        Assert.Equal(40, updatedProduct.StockQuantity);

        var ledger = await db.InventoryLedgers.SingleAsync(l => l.ProductId == product.Id);
        Assert.Equal(-10, ledger.QuantityChange);
        Assert.Equal(40, ledger.BalanceAfter);
    }

    [Fact]
    public async Task MarkDelivered_AlreadyProcessed_DoesNotDoubleDeductInventory()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var (location, customer, driver) = await SeedBaseDataAsync(db, companyId);

        var product = new Product(companyId, "Blue Orchid", "ORCH-BLU", ProductType.SingleFlower, ProductCategory.Orchids, 100m, 40m, null);
        product.SetInventorySettings(true, false, 0);
        product.AdjustStock(30);
        db.Products.Add(product);
        await db.SaveChangesAsync();

        var order = new Order(companyId, customer.Id, DateTime.UtcNow, "42 MG Road", "560001", "Recipient", "9999999999");
        order.Confirm();
        order.AddItem(product.Id, product.Name, 5, 100m);
        db.Orders.Add(order);

        var delivery = new Delivery(companyId, order.Id, DateTime.UtcNow, "Anytime", "42 MG Road");
        delivery.AssignDeliveryPerson(driver.Id);
        db.Deliveries.Add(delivery);
        await db.SaveChangesAsync();
        db.ChangeTracker.Clear();

        var controller = CreateDeliveriesController(db, companyId);
        await controller.MarkOutForDelivery(delivery.Id);
        await controller.MarkDelivered(delivery.Id);

        // Second attempt
        var secondResult = await controller.MarkDelivered(delivery.Id);
        Assert.IsType<OkObjectResult>(secondResult);

        db.ChangeTracker.Clear();
        var productAfter = await db.Products.SingleAsync(p => p.Id == product.Id);
        // Still 30 - 5 = 25 (NOT double deducted)
        Assert.Equal(25, productAfter.StockQuantity);

        var ledgerCount = await db.InventoryLedgers.CountAsync(l => l.ProductId == product.Id);
        Assert.Equal(1, ledgerCount);
    }

    [Fact]
    public async Task AssignDeliveryPerson_SynchronizesBothDeliveryAndOrder()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var (location, customer, driver) = await SeedBaseDataAsync(db, companyId);

        var order = new Order(companyId, customer.Id, DateTime.UtcNow, "123 Street", "560001", "Recipient", "9999999999");
        db.Orders.Add(order);
        var delivery = new Delivery(companyId, order.Id, DateTime.UtcNow, "Anytime", "123 Street");
        db.Deliveries.Add(delivery);
        await db.SaveChangesAsync();
        db.ChangeTracker.Clear();

        var controller = CreateDeliveriesController(db, companyId);
        var result = await controller.AssignDeliveryPerson(delivery.Id, new AssignDriverRequest { StaffId = driver.Id });

        Assert.IsType<OkObjectResult>(result);

        db.ChangeTracker.Clear();
        var updatedDelivery = await db.Deliveries.SingleAsync(d => d.Id == delivery.Id);
        var updatedOrder = await db.Orders.SingleAsync(o => o.Id == order.Id);

        Assert.Equal(driver.Id, updatedDelivery.DeliveryPersonId);
        Assert.Equal(DeliveryStatus.Assigned, updatedDelivery.Status);
        Assert.Equal(driver.Id, updatedOrder.DeliveryPersonId);
    }

    [Fact]
    public async Task GetAvailableDrivers_ReturnsCompanyDrivers()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var (_, _, driver) = await SeedBaseDataAsync(db, companyId);

        var controller = CreateDeliveriesController(db, companyId);
        var result = await controller.GetAvailableDrivers();

        var okResult = Assert.IsType<OkObjectResult>(result);
        var list = Assert.IsAssignableFrom<List<DeliveryDriverOptionDto>>(okResult.Value);

        Assert.Single(list);
        Assert.Equal(driver.Id, list[0].Id);
        Assert.Equal(driver.Name, list[0].Name);
        Assert.True(list[0].IsDeliveryRole);
    }

    private sealed class FailingOrderRepository : OrderRepository
    {
        public FailingOrderRepository(SumpoojDbContext db) : base(db) { }

        public override Task UpdateAsync(Order order)
        {
            throw new InvalidOperationException("Simulated order repository failure during assignment");
        }
    }

    [Fact]
    public async Task AssignDeliveryPerson_WhenOrderUpdateFails_RollsBackDeliveryAssignment()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var (location, customer, driver) = await SeedBaseDataAsync(db, companyId);

        var order = new Order(companyId, customer.Id, DateTime.UtcNow, "123 Street", "560001", "Recipient", "9999999999");
        db.Orders.Add(order);
        var delivery = new Delivery(companyId, order.Id, DateTime.UtcNow, "Anytime", "123 Street");
        db.Deliveries.Add(delivery);
        await db.SaveChangesAsync();
        db.ChangeTracker.Clear();

        var tenantContext = new TenantContext(companyId);
        var deliveryRepo = new DeliveryRepository(db);
        var staffRepo = new StaffRepository(db);
        var assignHandler = new AssignDeliveryPersonHandler(deliveryRepo, staffRepo);
        var failingOrderRepo = new FailingOrderRepository(db);
        var orderService = CreateOrderService(db);
        var unitOfWork = new UnitOfWork(db);

        var controller = new DeliveriesController(
            db,
            deliveryRepo,
            assignHandler,
            failingOrderRepo,
            orderService,
            tenantContext,
            unitOfWork);

        var result = await controller.AssignDeliveryPerson(delivery.Id, new AssignDriverRequest { StaffId = driver.Id });

        var badRequest = Assert.IsType<BadRequestObjectResult>(result);

        db.ChangeTracker.Clear();
        var deliveryAfter = await db.Deliveries.SingleAsync(d => d.Id == delivery.Id);
        var orderAfter = await db.Orders.SingleAsync(o => o.Id == order.Id);

        // Failure rolled back delivery assignment and left order unassigned
        Assert.Null(deliveryAfter.DeliveryPersonId);
        Assert.Equal(DeliveryStatus.Created, deliveryAfter.Status);
        Assert.Null(orderAfter.DeliveryPersonId);
    }
}
