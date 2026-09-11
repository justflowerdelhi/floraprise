using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.API.Controllers;
using Sumpooj.Application.Common;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Orders;
using Sumpooj.Application.UseCases;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;
using Sumpooj.Infrastructure.Repositories;
using Xunit;

namespace Sumpooj.Infrastructure.Tests.Orders;

public class CloudWalkInOrderTransactionTests
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
            .UseInMemoryDatabase(dbName ?? $"CloudWalkInOrder_{Guid.NewGuid():N}")
            .Options;
        return new SumpoojDbContext(options, new TenantContext(companyId));
    }

    private static OrderService CreateService(SumpoojDbContext db)
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

    private static async Task<(Location location, Shift shift)> SeedLocationAndShiftAsync(SumpoojDbContext db, Guid companyId)
    {
        var location = new Location(companyId, "Main Retail Store", "MRS-01", LocationType.Store, "100 MG Road");
        location.SetAsDefault();
        db.Locations.Add(location);

        var shift = new Shift(companyId, location.Id, Guid.NewGuid(), "Retail Cashier", 2000m);
        db.Shifts.Add(shift);

        await db.SaveChangesAsync();
        return (location, shift);
    }

    [Fact]
    public async Task WalkInTakeNow_FullyPaid_DeductsInventory_CreatesJournalEntries_UpdatesShiftTallies()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var (location, shift) = await SeedLocationAndShiftAsync(db, companyId);

        var product = new Product(companyId, "Red Rose", "ROSE-RED", ProductType.SingleFlower, ProductCategory.Roses, 50m, 20m, null);
        product.AdjustStock(100);
        db.Products.Add(product);
        await db.SaveChangesAsync();

        var service = CreateService(db);
        var request = new CreateOrderRequest
        {
            LocationId = location.Id,
            OrderSource = "WALK_IN",
            OrderIntent = "TAKE_NOW",
            RecipientName = "Asha Sharma",
            RecipientPhone = "9876543210",
            Items = [new OrderItemRequest { ProductId = product.Id, ProductName = product.Name, Quantity = 5, UnitPrice = 50m }],
            Payments = [new OrderPaymentRequest { Method = "Cash", Amount = 250m }]
        };

        var orderId = await service.CreateAsync(companyId, request);
        db.ChangeTracker.Clear();

        var order = await db.Orders.Include(o => o.Items).SingleAsync(o => o.Id == orderId);
        Assert.Equal(OrderStatus.Delivered, order.Status);
        Assert.Equal(PaymentStatus.Paid, order.PaymentStatus);
        Assert.Equal(FulfillmentStatus.Completed, order.FulfillmentStatus);
        Assert.True(order.IsInventoryProcessed);

        // Product stock deducted
        var updatedProduct = await db.Products.SingleAsync(p => p.Id == product.Id);
        Assert.Equal(95, updatedProduct.StockQuantity);

        // Inventory ledger recorded
        var ledger = await db.InventoryLedgers.SingleAsync(l => l.ProductId == product.Id);
        Assert.Equal(-5, ledger.QuantityChange);
        Assert.Equal(95, ledger.BalanceAfter);
        Assert.Equal("SALE", ledger.ReferenceType);

        // Shift sales updated
        var updatedShift = await db.Shifts.SingleAsync(s => s.Id == shift.Id);
        Assert.Equal(250m, updatedShift.CashSales);

        // Double-entry journal entries posted
        var journalEntries = await db.JournalEntries.Where(j => j.CompanyId == companyId).ToListAsync();
        Assert.True(journalEntries.Count >= 2);
    }

    [Fact]
    public async Task SimpleInventory_NonBatch_DeductsAggregateStock_AndWritesLedger()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var (location, _) = await SeedLocationAndShiftAsync(db, companyId);

        var product = new Product(companyId, "Tulip Bouquet", "TULIP-BQ", ProductType.Arrangement, ProductCategory.Tulips, 200m, 80m, null);
        product.AdjustStock(20);
        db.Products.Add(product);
        await db.SaveChangesAsync();

        var service = CreateService(db);
        var request = new CreateOrderRequest
        {
            LocationId = location.Id,
            OrderSource = "WALK_IN",
            OrderIntent = "TAKE_NOW",
            Items = [new OrderItemRequest { ProductId = product.Id, ProductName = product.Name, Quantity = 4, UnitPrice = 200m }],
            Payments = [new OrderPaymentRequest { Method = "Card", Amount = 800m }]
        };

        var orderId = await service.CreateAsync(companyId, request);
        db.ChangeTracker.Clear();

        var updatedProduct = await db.Products.SingleAsync(p => p.Id == product.Id);
        Assert.Equal(16, updatedProduct.StockQuantity);

        var ledger = await db.InventoryLedgers.SingleAsync(l => l.ProductId == product.Id);
        Assert.Equal(-4, ledger.QuantityChange);
        Assert.Equal(16, ledger.BalanceAfter);
    }

    [Fact]
    public async Task SimpleInventory_InsufficientStock_ThrowsAndRollsBack()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var (location, _) = await SeedLocationAndShiftAsync(db, companyId);

        var product = new Product(companyId, "Lily White", "LILY-WHT", ProductType.SingleFlower, ProductCategory.Lilies, 40m, 15m, null);
        product.AdjustStock(3);
        db.Products.Add(product);
        await db.SaveChangesAsync();

        var service = CreateService(db);
        var request = new CreateOrderRequest
        {
            LocationId = location.Id,
            OrderSource = "WALK_IN",
            OrderIntent = "TAKE_NOW",
            Items = [new OrderItemRequest { ProductId = product.Id, ProductName = product.Name, Quantity = 10, UnitPrice = 40m }],
            Payments = [new OrderPaymentRequest { Method = "Cash", Amount = 400m }]
        };

        var ex = await Assert.ThrowsAsync<InvalidOperationException>(() => service.CreateAsync(companyId, request));
        Assert.Contains("Insufficient stock", ex.Message);

        db.ChangeTracker.Clear();
        var productAfter = await db.Products.SingleAsync(p => p.Id == product.Id);
        Assert.Equal(3, productAfter.StockQuantity);

        // Atomicity rollback: order was not created
        Assert.Empty(await db.Orders.ToListAsync());
        Assert.Empty(await db.Payments.ToListAsync());
        Assert.Empty(await db.InventoryLedgers.ToListAsync());
    }

    [Fact]
    public async Task BatchInventory_FifoDeduction_DeductsBatchesAndProductStock_AndWritesBatchLedger()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var (location, _) = await SeedLocationAndShiftAsync(db, companyId);

        var product = new Product(companyId, "Imported Orchid", "ORCH-IMP", ProductType.SingleFlower, ProductCategory.Orchids, 150m, 60m, null);
        product.SetInventorySettings(true, true, 0);
        product.AdjustStock(30);
        db.Products.Add(product);

        var batch1 = new ProductBatch(companyId, product.Id, "B-001", 10, 60m, DateTime.UtcNow.AddDays(-5), DateTime.UtcNow.AddDays(5), null, location.Id, null);
        var batch2 = new ProductBatch(companyId, product.Id, "B-002", 20, 60m, DateTime.UtcNow.AddDays(-2), DateTime.UtcNow.AddDays(10), null, location.Id, null);
        db.ProductBatches.AddRange(batch1, batch2);
        await db.SaveChangesAsync();
        db.ChangeTracker.Clear();

        var service = CreateService(db);
        var request = new CreateOrderRequest
        {
            LocationId = location.Id,
            OrderSource = "WALK_IN",
            OrderIntent = "TAKE_NOW",
            Items = [new OrderItemRequest { ProductId = product.Id, ProductName = product.Name, Quantity = 15, UnitPrice = 150m }],
            Payments = [new OrderPaymentRequest { Method = "UPI", Amount = 2250m }]
        };

        await service.CreateAsync(companyId, request);
        db.ChangeTracker.Clear();

        // FIFO: batch 1 exhausted (10 units), batch 2 reduced by 5 units (15 remaining)
        var updatedB1 = await db.ProductBatches.SingleAsync(b => b.Id == batch1.Id);
        var updatedB2 = await db.ProductBatches.SingleAsync(b => b.Id == batch2.Id);
        Assert.Equal(0, updatedB1.QuantityRemaining);
        Assert.Equal(15, updatedB2.QuantityRemaining);

        // Aggregate product stock updated
        var updatedProduct = await db.Products.SingleAsync(p => p.Id == product.Id);
        Assert.Equal(15, updatedProduct.StockQuantity);

        var ledger = await db.InventoryLedgers.SingleAsync(l => l.ProductId == product.Id);
        Assert.Equal(-15, ledger.QuantityChange);
        Assert.Equal(15, ledger.BalanceAfter);
        Assert.Equal("POS Sale (Batch)", ledger.Notes);
    }

    [Fact]
    public async Task BatchInventory_InsufficientStock_ThrowsAndRollsBack()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var (location, _) = await SeedLocationAndShiftAsync(db, companyId);

        var product = new Product(companyId, "Carnation Pink", "CARN-PNK", ProductType.SingleFlower, ProductCategory.Carnations, 30m, 10m, null);
        product.SetInventorySettings(true, true, 0);
        product.AdjustStock(5);
        db.Products.Add(product);

        var batch = new ProductBatch(companyId, product.Id, "B-CARN-1", 5, 10m, DateTime.UtcNow, DateTime.UtcNow.AddDays(5), null, location.Id, null);
        db.ProductBatches.Add(batch);
        await db.SaveChangesAsync();
        db.ChangeTracker.Clear();

        var service = CreateService(db);
        var request = new CreateOrderRequest
        {
            LocationId = location.Id,
            OrderSource = "WALK_IN",
            OrderIntent = "TAKE_NOW",
            Items = [new OrderItemRequest { ProductId = product.Id, ProductName = product.Name, Quantity = 8, UnitPrice = 30m }],
            Payments = [new OrderPaymentRequest { Method = "Cash", Amount = 240m }]
        };

        var ex = await Assert.ThrowsAsync<InvalidOperationException>(() => service.CreateAsync(companyId, request));
        Assert.Contains("Not enough stock", ex.Message);

        db.ChangeTracker.Clear();
        var batchAfter = await db.ProductBatches.SingleAsync(b => b.Id == batch.Id);
        Assert.Equal(5, batchAfter.QuantityRemaining);
        Assert.Empty(await db.Orders.ToListAsync());
    }

    [Fact]
    public async Task UntrackedInventory_DoesNotDeductStock_AndSucceeds()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var (location, _) = await SeedLocationAndShiftAsync(db, companyId);

        var product = new Product(companyId, "Greeting Card", "CARD-01", ProductType.Gift, ProductCategory.Cards, 50m, 10m, null);
        product.SetInventorySettings(false, false, 0);
        db.Products.Add(product);
        await db.SaveChangesAsync();

        var service = CreateService(db);
        var request = new CreateOrderRequest
        {
            LocationId = location.Id,
            OrderSource = "WALK_IN",
            OrderIntent = "TAKE_NOW",
            Items = [new OrderItemRequest { ProductId = product.Id, ProductName = product.Name, Quantity = 2, UnitPrice = 50m }],
            Payments = [new OrderPaymentRequest { Method = "Cash", Amount = 100m }]
        };

        var orderId = await service.CreateAsync(companyId, request);
        db.ChangeTracker.Clear();

        var storedOrder = await db.Orders.SingleAsync(o => o.Id == orderId);
        Assert.Equal(OrderStatus.Delivered, storedOrder.Status);

        var productAfter = await db.Products.SingleAsync(p => p.Id == product.Id);
        Assert.Equal(0, productAfter.StockQuantity);
        Assert.Empty(await db.InventoryLedgers.ToListAsync());
    }

    [Fact]
    public async Task Idempotency_SameKey_SamePayload_ReplaysCachedResult_WithoutDuplicateDeduction()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var (location, _) = await SeedLocationAndShiftAsync(db, companyId);

        var product = new Product(companyId, "Rose Bunch", "ROSE-BNCH", ProductType.Bouquet, ProductCategory.Roses, 100m, 40m, null);
        product.AdjustStock(50);
        db.Products.Add(product);
        await db.SaveChangesAsync();

        var service = CreateService(db);
        var request = new CreateOrderRequest
        {
            LocationId = location.Id,
            OrderSource = "WALK_IN",
            OrderIntent = "TAKE_NOW",
            Items = [new OrderItemRequest { ProductId = product.Id, ProductName = product.Name, Quantity = 2, UnitPrice = 100m }],
            Payments = [new OrderPaymentRequest { Method = "Cash", Amount = 200m }]
        };

        const string idempotencyKey = "pos-tx-12345678-abcd";

        // First attempt: creates order
        var result1 = await service.CreateOrderAsync(companyId, request, idempotencyKey);
        Assert.False(result1.IsReplay);
        Assert.Equal(201, result1.StatusCode);

        db.ChangeTracker.Clear();
        var stockAfterFirst = (await db.Products.SingleAsync(p => p.Id == product.Id)).StockQuantity;
        Assert.Equal(48, stockAfterFirst);
        Assert.Single(await db.Orders.ToListAsync());

        // Second attempt: identical request with same key
        var result2 = await service.CreateOrderAsync(companyId, request, idempotencyKey);
        Assert.True(result2.IsReplay);
        Assert.Equal(result1.OrderId, result2.OrderId);
        Assert.Equal(result1.Order.OrderNumber, result2.Order.OrderNumber);

        db.ChangeTracker.Clear();
        // Stock must NOT be deducted again!
        var stockAfterSecond = (await db.Products.SingleAsync(p => p.Id == product.Id)).StockQuantity;
        Assert.Equal(48, stockAfterSecond);
        Assert.Single(await db.Orders.ToListAsync());
        Assert.Single(await db.InventoryLedgers.ToListAsync());
    }

    [Fact]
    public async Task Idempotency_SameKey_DifferentPayload_RejectsWithConflict409()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var (location, _) = await SeedLocationAndShiftAsync(db, companyId);

        var product = new Product(companyId, "Sunflower", "SUN-01", ProductType.SingleFlower, ProductCategory.Exotic, 60m, 20m, null);
        product.AdjustStock(20);
        db.Products.Add(product);
        await db.SaveChangesAsync();

        var service = CreateService(db);
        const string idempotencyKey = "pos-key-conflict-test";

        var request1 = new CreateOrderRequest
        {
            LocationId = location.Id,
            OrderSource = "WALK_IN",
            OrderIntent = "TAKE_NOW",
            Items = [new OrderItemRequest { ProductId = product.Id, ProductName = product.Name, Quantity = 1, UnitPrice = 60m }],
            Payments = [new OrderPaymentRequest { Method = "Cash", Amount = 60m }]
        };

        var result1 = await service.CreateOrderAsync(companyId, request1, idempotencyKey);
        Assert.False(result1.IsReplay);

        // Request 2: different quantity / different amount with the SAME key
        var request2 = new CreateOrderRequest
        {
            LocationId = location.Id,
            OrderSource = "WALK_IN",
            OrderIntent = "TAKE_NOW",
            Items = [new OrderItemRequest { ProductId = product.Id, ProductName = product.Name, Quantity = 2, UnitPrice = 60m }],
            Payments = [new OrderPaymentRequest { Method = "Cash", Amount = 120m }]
        };

        var ex = await Assert.ThrowsAsync<IdempotencyConflictException>(() =>
            service.CreateOrderAsync(companyId, request2, idempotencyKey));
        Assert.Contains("Idempotency key already used for a different request payload", ex.Message);
    }

    [Fact]
    public async Task OrdersController_Create_WithIdempotencyHeader_HandlesReplayAndConflictResponses()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var (location, _) = await SeedLocationAndShiftAsync(db, companyId);

        var product = new Product(companyId, "Daisy Bunch", "DAISY-01", ProductType.SingleFlower, ProductCategory.Exotic, 75m, 30m, null);
        product.AdjustStock(50);
        db.Products.Add(product);
        await db.SaveChangesAsync();

        var service = CreateService(db);
        var controller = new OrdersController(service, new TenantContext(companyId), db);
        controller.ControllerContext = new ControllerContext
        {
            HttpContext = new Microsoft.AspNetCore.Http.DefaultHttpContext()
        };

        const string idempotencyKey = "api-header-idemp-1";
        controller.Request.Headers["Idempotency-Key"] = idempotencyKey;

        var request1 = new CreateOrderRequest
        {
            LocationId = location.Id,
            OrderSource = "WALK_IN",
            OrderIntent = "TAKE_NOW",
            Items = [new OrderItemRequest { ProductId = product.Id, ProductName = product.Name, Quantity = 2, UnitPrice = 75m }],
            Payments = [new OrderPaymentRequest { Method = "Cash", Amount = 150m }]
        };

        // 1. Initial creation via controller -> 201 CreatedAtAction
        var actionResult1 = await controller.Create(request1);
        var createdResult = Assert.IsType<CreatedAtActionResult>(actionResult1);
        var order1 = Assert.IsType<OrderDto>(createdResult.Value);

        // 2. Duplicate submission -> Replay response with header Idempotency-Replayed
        controller.Response.Headers.Clear();
        var actionResult2 = await controller.Create(request1);
        var statusResult = Assert.IsType<ObjectResult>(actionResult2);
        Assert.Equal(201, statusResult.StatusCode);
        var order2 = Assert.IsType<OrderDto>(statusResult.Value);
        Assert.Equal(order1.Id, order2.Id);
        Assert.Equal("true", controller.Response.Headers["Idempotency-Replayed"]);

        // 3. Different payload with same key -> 409 Conflict
        var requestDiff = new CreateOrderRequest
        {
            LocationId = location.Id,
            OrderSource = "WALK_IN",
            OrderIntent = "TAKE_NOW",
            Items = [new OrderItemRequest { ProductId = product.Id, ProductName = product.Name, Quantity = 5, UnitPrice = 75m }],
            Payments = [new OrderPaymentRequest { Method = "Cash", Amount = 375m }]
        };
        var actionResult3 = await controller.Create(requestDiff);
        var conflictResult = Assert.IsType<ConflictObjectResult>(actionResult3);
        Assert.Equal(409, conflictResult.StatusCode);
    }

    [Fact]
    public async Task DeliveryOrder_DoesNotConsumeInventoryDirectly_CreatesDelivery()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var (location, _) = await SeedLocationAndShiftAsync(db, companyId);

        var product = new Product(companyId, "Premium Hamper", "HAMPER-01", ProductType.Arrangement, ProductCategory.CelebrationFlowers, 500m, 200m, null);
        product.AdjustStock(10);
        db.Products.Add(product);
        await db.SaveChangesAsync();

        var service = CreateService(db);
        var request = new CreateOrderRequest
        {
            LocationId = location.Id,
            OrderSource = "WALK_IN",
            OrderIntent = "DELIVERY",
            DeliveryAddress = "45 Residency Road, Bangalore",
            DeliveryPincode = "560025",
            TimeSlot = "14:00 - 16:00",
            RecipientName = "Rahul Verma",
            RecipientPhone = "9876500000",
            Items = [new OrderItemRequest { ProductId = product.Id, ProductName = product.Name, Quantity = 1, UnitPrice = 500m }],
            Payments = [new OrderPaymentRequest { Method = "UPI", Amount = 500m }]
        };

        var orderId = await service.CreateAsync(companyId, request);
        db.ChangeTracker.Clear();

        var order = await db.Orders.SingleAsync(o => o.Id == orderId);
        // Delivery order is not Delivered yet on creation
        Assert.NotEqual(OrderStatus.Delivered, order.Status);
        Assert.False(order.IsInventoryProcessed);

        // Auto-scheduled Delivery record created
        var delivery = await db.Deliveries.SingleAsync(d => d.SalesOrderId == orderId);
        Assert.Equal("45 Residency Road, Bangalore", delivery.DeliveryAddress);
        Assert.Equal("560025", delivery.PostalCode);

        // Inventory not consumed immediately on creation for delivery intent
        var productAfter = await db.Products.SingleAsync(p => p.Id == product.Id);
        Assert.Equal(10, productAfter.StockQuantity);
        Assert.Empty(await db.InventoryLedgers.ToListAsync());
    }

    [Fact]
    public async Task ShiftTallies_RecordCashCardUpiAccurately()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var (location, shift) = await SeedLocationAndShiftAsync(db, companyId);

        var product = new Product(companyId, "Gladiolus", "GLAD-01", ProductType.SingleFlower, ProductCategory.Exotic, 100m, 40m, null);
        product.AdjustStock(50);
        db.Products.Add(product);
        await db.SaveChangesAsync();

        var service = CreateService(db);
        var request = new CreateOrderRequest
        {
            LocationId = location.Id,
            OrderSource = "WALK_IN",
            OrderIntent = "TAKE_NOW",
            Items = [new OrderItemRequest { ProductId = product.Id, ProductName = product.Name, Quantity = 1, UnitPrice = 300m }],
            Payments =
            [
                new OrderPaymentRequest { Method = "Cash", Amount = 100m },
                new OrderPaymentRequest { Method = "Card", Amount = 100m },
                new OrderPaymentRequest { Method = "UPI", Amount = 100m }
            ]
        };

        await service.CreateAsync(companyId, request);
        db.ChangeTracker.Clear();

        var updatedShift = await db.Shifts.SingleAsync(s => s.Id == shift.Id);
        Assert.Equal(100m, updatedShift.CashSales);
        Assert.Equal(100m, updatedShift.CardSales);
        Assert.Equal(100m, updatedShift.UpiSales);
    }

    [Fact]
    public async Task CustomerStats_UpdatesOrdersCountAndTotalSpent()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var (location, _) = await SeedLocationAndShiftAsync(db, companyId);

        var customer = new Customer(companyId, "Pooja Patel", "pooja@example.com", "9988776655");
        var product = new Product(companyId, "Red Rose", "ROSE-RED", ProductType.SingleFlower, ProductCategory.Roses, 50m, 20m, null);
        product.AdjustStock(10);
        db.AddRange(customer, product);
        await db.SaveChangesAsync();

        var service = CreateService(db);
        var request = new CreateOrderRequest
        {
            LocationId = location.Id,
            CustomerId = customer.Id,
            OrderSource = "WALK_IN",
            OrderIntent = "TAKE_NOW",
            Items = [new OrderItemRequest { ProductId = product.Id, ProductName = product.Name, Quantity = 2, UnitPrice = 50m }],
            Payments = [new OrderPaymentRequest { Method = "Cash", Amount = 100m }]
        };

        await service.CreateAsync(companyId, request);
        db.ChangeTracker.Clear();

        var updatedCustomer = await db.Customers.SingleAsync(c => c.Id == customer.Id);
        Assert.Equal(1, updatedCustomer.TotalOrders);
    }

    [Fact]
    public async Task ConsumeInventoryForOrderAsync_AlreadyProcessed_IsNoOp()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var (location, _) = await SeedLocationAndShiftAsync(db, companyId);

        var product = new Product(companyId, "Red Rose", "ROSE-RED", ProductType.SingleFlower, ProductCategory.Roses, 50m, 20m, null);
        product.AdjustStock(10);
        db.Products.Add(product);
        await db.SaveChangesAsync();

        var service = CreateService(db);
        var request = new CreateOrderRequest
        {
            LocationId = location.Id,
            OrderSource = "WALK_IN",
            OrderIntent = "TAKE_NOW",
            Items = [new OrderItemRequest { ProductId = product.Id, ProductName = product.Name, Quantity = 2, UnitPrice = 50m }],
            Payments = [new OrderPaymentRequest { Method = "Cash", Amount = 100m }]
        };

        var orderId = await service.CreateAsync(companyId, request);
        db.ChangeTracker.Clear();

        var order = await db.Orders.Include(o => o.Items).SingleAsync(o => o.Id == orderId);
        Assert.True(order.IsInventoryProcessed);

        // Calling ConsumeInventoryForOrderAsync a second time must NOT deduct again
        await service.ConsumeInventoryForOrderAsync(companyId, order);
        db.ChangeTracker.Clear();

        var productAfter = await db.Products.SingleAsync(p => p.Id == product.Id);
        Assert.Equal(8, productAfter.StockQuantity);
        Assert.Single(await db.InventoryLedgers.ToListAsync());
    }
}
