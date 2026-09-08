using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.API.Controllers;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Orders;
using Sumpooj.Application.UseCases;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;
using Sumpooj.Infrastructure.Repositories;

namespace Sumpooj.Infrastructure.Tests.Orders;

public class CloudOrderEditTests
{
    private sealed class TenantContext(Guid companyId) : ITenantContext
    {
        public Guid? CompanyId => companyId;
        public bool IsPlatformUser => false;
        public string? Region => null;
    }

    [Fact]
    public async Task UpdateDetailsAppliesSuppliedFieldsAndLeavesNullsUnchanged()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var order = await SeedOrderAsync(db, companyId);
        var service = CreateService(db);

        await service.UpdateDetailsAsync(companyId, order.Id, new UpdateOrderDetailsRequest
        {
            DeliveryDate = new DateTime(2026, 10, 1, 9, 30, 0, DateTimeKind.Utc),
            TimeSlot = "10:00 - 12:00",
            DeliveryAddress = "12 New Street",
            DeliveryPincode = "560001",
            RecipientName = "Riya",
            CardMessage = "Happy Birthday",
        });

        db.ChangeTracker.Clear();
        var stored = await db.Orders.SingleAsync();
        Assert.Equal(new DateTime(2026, 10, 1, 9, 30, 0, DateTimeKind.Utc), stored.DeliveryDate);
        Assert.Equal("10:00 - 12:00", stored.TimeSlot);
        Assert.Equal("12 New Street", stored.DeliveryAddress);
        Assert.Equal("560001", stored.DeliveryPincode);
        Assert.Equal("Riya", stored.RecipientName);
        Assert.Equal("Happy Birthday", stored.CardMessage);
        Assert.Equal("9876543210", stored.RecipientPhone);
    }

    [Fact]
    public async Task ReplaceItemsSwapsLinesAndRecalculatesTotals()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var order = await SeedOrderAsync(db, companyId);
        var newProductId = Guid.NewGuid();
        var service = CreateService(db);

        await service.ReplaceItemsAsync(companyId, order.Id, new ReplaceOrderItemsRequest
        {
            Items =
            [
                new ReplaceOrderItemRequest
                {
                    ProductId = newProductId,
                    ProductName = "Lily Bunch",
                    Quantity = 3,
                    UnitPrice = 150m,
                    TaxRatePercent = 5m,
                    DiscountType = "percentage",
                    DiscountValue = 10m,
                    DiscountAmount = 45m,
                    LineSubtotal = 405m,
                    LineTaxAmount = 20.25m,
                },
            ],
            TaxAmount = 20.25m,
        });

        db.ChangeTracker.Clear();
        var stored = await db.Orders.Include(o => o.Items).SingleAsync();
        var line = Assert.Single(stored.Items);
        Assert.Equal(newProductId, line.ProductId);
        Assert.Equal(3, line.Quantity);
        Assert.Equal(450m, line.TotalPrice);
        Assert.Equal("percentage", line.DiscountType);
        Assert.Equal(450m, stored.SubTotal);
        Assert.Equal(20.25m, stored.TaxAmount);
        Assert.Equal(470.25m, stored.TotalAmount);
    }

    [Fact]
    public async Task ReplaceItemsRejectsEmptyAndInvalidLines()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var order = await SeedOrderAsync(db, companyId);
        var service = CreateService(db);

        await Assert.ThrowsAsync<ArgumentException>(() =>
            service.ReplaceItemsAsync(companyId, order.Id, new ReplaceOrderItemsRequest()));

        await Assert.ThrowsAsync<ArgumentException>(() =>
            service.ReplaceItemsAsync(companyId, order.Id, new ReplaceOrderItemsRequest
            {
                Items = [new ReplaceOrderItemRequest { ProductId = Guid.NewGuid(), ProductName = "X", Quantity = 0, UnitPrice = 10m }],
            }));
    }

    [Fact]
    public async Task UpdateFinancialsAppliesDiscountFeeAndRewards()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var order = await SeedOrderAsync(db, companyId);
        var service = CreateService(db);

        await service.UpdateFinancialsAsync(companyId, order.Id, new UpdateOrderFinancialsRequest
        {
            DiscountAmount = 40m,
            DeliveryFee = 60m,
            RewardPointsRedeemed = 25,
            RewardDiscountAmount = 12.5m,
        });

        db.ChangeTracker.Clear();
        var stored = await db.Orders.SingleAsync();
        Assert.Equal(40m, stored.DiscountAmount);
        Assert.Equal(60m, stored.DeliveryFee);
        Assert.Equal(25, stored.RewardPointsRedeemed);
        Assert.Equal(12.5m, stored.RewardDiscountAmount);
        Assert.Equal(220m, stored.TotalAmount);
    }

    [Fact]
    public async Task DeliveredOrCancelledOrdersRejectAllEdits()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var delivered = await SeedOrderAsync(db, companyId);
        delivered.MarkDeliveredDirect();
        await db.SaveChangesAsync();
        var service = CreateService(db);

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            service.UpdateDetailsAsync(companyId, delivered.Id, new UpdateOrderDetailsRequest { CardMessage = "nope" }));
        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            service.ReplaceItemsAsync(companyId, delivered.Id, new ReplaceOrderItemsRequest
            {
                Items = [new ReplaceOrderItemRequest { ProductId = Guid.NewGuid(), ProductName = "X", Quantity = 1, UnitPrice = 10m }],
            }));
        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            service.UpdateFinancialsAsync(companyId, delivered.Id, new UpdateOrderFinancialsRequest { DiscountAmount = 1m }));
    }

    [Fact]
    public async Task EditsAreCompanyScoped()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var order = await SeedOrderAsync(db, companyId);
        var service = CreateService(db);

        await Assert.ThrowsAsync<KeyNotFoundException>(() =>
            service.UpdateDetailsAsync(Guid.NewGuid(), order.Id, new UpdateOrderDetailsRequest { CardMessage = "x" }));
    }

    [Fact]
    public async Task FullCloudEditSequenceSucceedsAcrossSeparateRequestScopes()
    {
        var companyId = Guid.NewGuid();
        var databaseName = $"CloudOrderEditSequence_{Guid.NewGuid():N}";
        Guid orderId;

        await using (var seedDb = CreateDb(companyId, databaseName))
        {
            var order = await SeedOrderAsync(seedDb, companyId);
            orderId = order.Id;
        }

        // Each Cloud edit call arrives as its own HTTP request, so each gets a fresh context.
        await using (var db = CreateDb(companyId, databaseName))
        {
            await CreateService(db).UpdateDetailsAsync(companyId, orderId, new UpdateOrderDetailsRequest
            {
                DeliveryDate = new DateTime(2026, 10, 1, 9, 30, 0, DateTimeKind.Utc),
                TimeSlot = string.Empty,
                DeliveryAddress = "12 New Street",
                DeliveryPincode = "560001",
                RecipientName = "Riya",
                RecipientPhone = "9876500002",
                CardMessage = string.Empty,
            });
        }

        await using (var db = CreateDb(companyId, databaseName))
        {
            await CreateService(db).ReplaceItemsAsync(companyId, orderId, new ReplaceOrderItemsRequest
            {
                Items =
                [
                    new ReplaceOrderItemRequest
                    {
                        ProductId = Guid.NewGuid(),
                        ProductName = "Lily Bunch",
                        Quantity = 3,
                        UnitPrice = 150m,
                        DiscountAmount = 45m,
                        TaxRatePercent = 5m,
                        LineSubtotal = 405m,
                        LineTaxAmount = 20.25m,
                    },
                ],
                TaxAmount = 20.25m,
            });
        }

        await using (var db = CreateDb(companyId, databaseName))
        {
            await CreateService(db).UpdateFinancialsAsync(companyId, orderId, new UpdateOrderFinancialsRequest
            {
                DiscountAmount = 40m,
                DeliveryFee = 60m,
                RewardPointsRedeemed = 25,
                RewardDiscountAmount = 12.5m,
            });
        }

        await using var verifyDb = CreateDb(companyId, databaseName);
        var stored = await verifyDb.Orders.Include(o => o.Items).SingleAsync();
        Assert.Equal("12 New Street", stored.DeliveryAddress);
        Assert.Equal("Lily Bunch", Assert.Single(stored.Items).ProductName);
        Assert.Equal(40m, stored.DiscountAmount);
        Assert.Equal(60m, stored.DeliveryFee);
        Assert.Equal(25, stored.RewardPointsRedeemed);
    }

    [Fact]
    public async Task AllEditEndpointsMapArgumentFailuresToBadRequestNotServerError()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var order = await SeedOrderAsync(db, companyId);
        var controller = new OrdersController(CreateService(db), new TenantContext(companyId), db);

        // A null body binds to null; without an ArgumentException catch this surfaced as a 500.
        Assert.IsType<BadRequestObjectResult>(await controller.UpdateDetails(order.Id, null!));
        Assert.IsType<BadRequestObjectResult>(await controller.ReplaceItems(order.Id, null!));
        Assert.IsType<BadRequestObjectResult>(await controller.UpdateFinancials(order.Id, null!));
    }

    [Fact]
    public async Task ReplaceItemsDeletesOldRowsAndNeverNullsTheRequiredOrderFk()
    {
        var companyId = Guid.NewGuid();
        var databaseName = $"ReplaceItemsFk_{Guid.NewGuid():N}";
        Guid orderId;
        Guid oldItemId;

        await using (var seedDb = CreateDb(companyId, databaseName))
        {
            var order = await SeedOrderAsync(seedDb, companyId);
            orderId = order.Id;
            oldItemId = order.Items.Single().Id;
        }

        var firstProductId = Guid.NewGuid();
        var secondProductId = Guid.NewGuid();

        await using (var db = CreateDb(companyId, databaseName))
        {
            // 1. Replacing existing items succeeds.
            await CreateService(db).ReplaceItemsAsync(companyId, orderId, new ReplaceOrderItemsRequest
            {
                Items =
                [
                    new ReplaceOrderItemRequest
                    {
                        ProductId = firstProductId,
                        ProductName = "Lily Bunch",
                        Quantity = 3,
                        UnitPrice = 150m,
                    },
                    new ReplaceOrderItemRequest
                    {
                        ProductId = secondProductId,
                        ProductName = "Orchid Stem",
                        Quantity = 2,
                        UnitPrice = 100m,
                    },
                ],
                TaxAmount = 32.5m,
            });

            // No tracked line may be left holding a null required FK.
            foreach (var entry in db.ChangeTracker.Entries<OrderItem>())
            {
                Assert.NotNull(entry.Property("OrderId").CurrentValue);
            }
        }

        await using var verifyDb = CreateDb(companyId, databaseName);
        var stored = await verifyDb.Orders.Include(o => o.Items).SingleAsync();
        var storedItems = await verifyDb.Set<OrderItem>().ToListAsync();

        // 2. Old items are removed.
        Assert.DoesNotContain(storedItems, i => i.Id == oldItemId);
        Assert.Equal(2, storedItems.Count);

        // 3. New items carry the correct, non-null OrderId.
        foreach (var item in storedItems)
        {
            var orderFk = verifyDb.Entry(item).Property("OrderId").CurrentValue;
            Assert.Equal(orderId, Assert.IsType<Guid>(orderFk));
        }
        Assert.Contains(storedItems, i => i.ProductId == firstProductId);
        Assert.Contains(storedItems, i => i.ProductId == secondProductId);

        // 4. Order totals update.
        Assert.Equal(650m, stored.SubTotal);
        Assert.Equal(32.5m, stored.TaxAmount);
        Assert.Equal(682.5m, stored.TotalAmount);
        Assert.Equal(2, stored.Items.Count);
    }

    [Fact]
    public async Task ReplaceItemsLeavesOrderUntouchedWhenTheRequestFails()
    {
        var companyId = Guid.NewGuid();
        var databaseName = $"ReplaceItemsRollback_{Guid.NewGuid():N}";
        Guid orderId;
        Guid originalItemId;

        await using (var seedDb = CreateDb(companyId, databaseName))
        {
            var order = await SeedOrderAsync(seedDb, companyId);
            orderId = order.Id;
            originalItemId = order.Items.Single().Id;
        }

        await using (var db = CreateDb(companyId, databaseName))
        {
            // 5. A rejected request must not delete the old lines or move totals.
            await Assert.ThrowsAsync<ArgumentException>(() =>
                CreateService(db).ReplaceItemsAsync(companyId, orderId, new ReplaceOrderItemsRequest
                {
                    Items =
                    [
                        new ReplaceOrderItemRequest
                        {
                            ProductId = Guid.NewGuid(),
                            ProductName = "Valid Line",
                            Quantity = 1,
                            UnitPrice = 50m,
                        },
                        new ReplaceOrderItemRequest
                        {
                            ProductId = Guid.NewGuid(),
                            ProductName = "Invalid Line",
                            Quantity = 0,
                            UnitPrice = 50m,
                        },
                    ],
                }));
        }

        await using var verifyDb = CreateDb(companyId, databaseName);
        var stored = await verifyDb.Orders.Include(o => o.Items).SingleAsync();
        Assert.Equal(originalItemId, Assert.Single(stored.Items).Id);
        Assert.Equal(200m, stored.SubTotal);
        Assert.Equal(200m, stored.TotalAmount);
    }

    private static async Task<Order> SeedOrderAsync(SumpoojDbContext db, Guid companyId)
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
        order.Confirm();

        db.AddRange(customer, order);
        await db.SaveChangesAsync();
        return order;
    }

    private static OrderService CreateService(SumpoojDbContext db)
    {
        return new OrderService(
            new OrderRepository(db),
            null!, null!, null!, null!, null!, null!, null!, null!, null!, null!, null!, null!);
    }

    private static SumpoojDbContext CreateDb(Guid companyId, string? databaseName = null)
    {
        var options = new DbContextOptionsBuilder<SumpoojDbContext>()
            .UseInMemoryDatabase(databaseName ?? $"CloudOrderEdit_{Guid.NewGuid():N}")
            .Options;
        return new SumpoojDbContext(options, new TenantContext(companyId));
    }
}
