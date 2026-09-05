using System.Security.Claims;
using System.Text.Json;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.EntityFrameworkCore.Storage;
using Npgsql;
using Sumpooj.API.Controllers.Mobile;
using Sumpooj.API.Services.Mobile;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Mobile;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;
using Xunit;

namespace Floraprise.Mobile.Tests;

public sealed class MobilePosSaleSyncTests : IDisposable
{
    private readonly Guid _companyId = Guid.NewGuid();
    private readonly Guid _otherCompanyId = Guid.NewGuid();
    private readonly Guid _mobileUserId = Guid.NewGuid();
    private readonly Guid _identityUserId = Guid.NewGuid();
    private readonly string _databaseName = $"MobilePosSync_{Guid.NewGuid():N}";
    private readonly InMemoryDatabaseRoot _databaseRoot = new();

    public void Dispose()
    {
    }

    [Fact]
    public async Task SuccessfulSingleLineSale_CreatesOrderReceiptAuditAndCloudInventoryDeduction()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        var batch = SeedBatch(db, product.Id, quantityRemaining: 7);
        await db.SaveChangesAsync();
        var request = Request(product);

        var response = await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "hash-1");

        var order = await db.Orders.Include(o => o.Items).SingleAsync(o => o.Id == response.CloudOrderId);
        var receipt = await db.PosSaleSyncReceipts.SingleAsync();
        Assert.Equal("completed", response.SyncStatus);
        Assert.Equal(request.ClientSyncId, response.ClientSyncId);
        Assert.Equal(order.Id, receipt.CloudOrderId);
        Assert.Equal(9.99m, order.TotalAmount);
        Assert.Equal(9.99m, order.Items.Single().LineSubtotal);
        var posLine = await db.PosSaleSyncOrderLines.SingleAsync();
        Assert.Equal(product.Id, posLine.CloudProductId);
        Assert.Equal(101, posLine.LocalProductId);
        Assert.Equal("product", posLine.Source);
        Assert.Equal(9.99m, posLine.UnitPrice);
        Assert.Equal(9.99m, posLine.LineSubtotal);
        Assert.Equal(9.99m, posLine.LineTotal);
        Assert.Equal(9, product.StockQuantity);
        Assert.Equal(7, batch.QuantityRemaining);
        var ledger = await db.InventoryLedgers.SingleAsync();
        Assert.Equal(product.Id, ledger.ProductId);
        Assert.Equal("SALE", ledger.ReferenceType);
        Assert.Equal(-1, ledger.QuantityChange);
        Assert.Equal(9, ledger.BalanceAfter);
        Assert.Single(db.PosSaleSyncInventoryTransactions);
    }

    [Fact]
    public async Task MultiLineSale_PersistsBothOrderItems()
    {
        await using var db = CreateDb();
        var first = SeedProduct(db, sku: "ROSE");
        var second = SeedProduct(db, sku: "LILY", name: "Lily");
        await db.SaveChangesAsync();
        var request = Request(first);
        request.Lines.Add(Line(second, id: 2, localProductId: 202, unitPricePaise: 500, subtotalPaise: 500, totalPaise: 500));
        request.InventoryTransactions.Add(Inventory(second, id: 2, localProductId: 202));
        request.Order.SubtotalPaise = 1499;
        request.Order.GrandTotalPaise = 1499;
        request.Payments.Single().AmountPaise = 1499;

        var response = await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "hash-2");

        var order = await db.Orders.Include(o => o.Items).SingleAsync(o => o.Id == response.CloudOrderId);
        Assert.Equal(2, order.Items.Count);
        Assert.Equal(2, await db.PosSaleSyncOrderLines.CountAsync());
        Assert.Equal(2, await db.PosSaleSyncInventoryTransactions.CountAsync());
    }

    [Fact]
    public async Task ManualServicePosLine_IsStoredOnlyInPosSaleSyncOrderLines()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();
        var request = Request(product);
        request.Lines = [ManualLine(id: 1, description: "Delivery Charge")];
        request.InventoryTransactions = [];
        request.Order.SubtotalPaise = 250;
        request.Order.GrandTotalPaise = 250;
        request.Payments.Single().AmountPaise = 250;

        var response = await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "manual-hash");

        var order = await db.Orders.Include(o => o.Items).SingleAsync(o => o.Id == response.CloudOrderId);
        var posLine = await db.PosSaleSyncOrderLines.SingleAsync();
        Assert.Empty(order.Items);
        Assert.Null(posLine.CloudProductId);
        Assert.Null(posLine.LocalProductId);
        Assert.Equal("manual", posLine.Source);
        Assert.Equal("Delivery Charge", posLine.Description);
        Assert.Equal(2.50m, posLine.LineTotal);
        Assert.Empty(db.Products.Where(p => p.Id == Guid.Empty));
    }

    [Fact]
    public async Task MixedProductAndManualSale_PreservesEveryPosLineWithoutFakeProduct()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();
        var request = Request(product);
        request.Lines.Add(ManualLine(id: 2, description: "Gift Wrap", unitPricePaise: 125));
        request.Order.SubtotalPaise = 1124;
        request.Order.GrandTotalPaise = 1124;
        request.Payments.Single().AmountPaise = 1124;

        var response = await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "mixed-hash");

        var order = await db.Orders.Include(o => o.Items).SingleAsync(o => o.Id == response.CloudOrderId);
        var posLines = await db.PosSaleSyncOrderLines.OrderBy(l => l.LocalOrderLineId).ToListAsync();
        Assert.Single(order.Items);
        Assert.Equal(2, posLines.Count);
        Assert.Equal(product.Id, posLines[0].CloudProductId);
        Assert.Null(posLines[1].CloudProductId);
        Assert.Equal("Gift Wrap", posLines[1].Description);
        Assert.Equal(1.25m, posLines[1].UnitPrice);
        Assert.Equal(1.25m, posLines[1].LineSubtotal);
        Assert.Equal(1.25m, posLines[1].LineTotal);
    }

    [Fact]
    public async Task FinancialReconciliationIncludesManualServiceLines()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();
        var request = Request(product);
        request.Lines.Add(ManualLine(id: 2, description: "Service", unitPricePaise: 125));
        request.Order.SubtotalPaise = 999;
        request.Order.GrandTotalPaise = 999;

        await Assert.ThrowsAsync<ArgumentException>(() => Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "bad-manual-finance"));
        Assert.Empty(db.PosSaleSyncOrderLines);
    }

    [Fact]
    public async Task MultiPaymentSale_PersistsAllApprovedPayments()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();
        var request = Request(product);
        request.Payments =
        [
            new PosSalePaymentSnapshot { Id = 1, Method = "cash", AmountPaise = 500, Reference = "CASH-1" },
            new PosSalePaymentSnapshot { Id = 2, Method = "upi", AmountPaise = 499, Reference = "UPI-1" }
        ];

        await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "hash-3");

        var payments = await db.Payments.OrderBy(p => p.Amount).ToListAsync();
        Assert.Equal(2, payments.Count);
        Assert.All(payments, p => Assert.Equal(PaymentTransactionStatus.Approved, p.Status));
    }

    [Fact]
    public async Task AnonymousSale_ReturnsNullCloudCustomerId()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();
        var request = Request(product);
        request.Order.CustomerName = null;
        request.Order.CustomerPhone = null;

        var response = await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "hash-4");

        Assert.Null(response.CloudCustomerId);
        Assert.Equal("Walk-In Customer", (await db.Customers.SingleAsync()).Name);
    }

    [Fact]
    public async Task CustomerSale_UsesCompanyScopedCustomer()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        var customer = new Customer(_companyId, "Known", null, "9999999999");
        db.Customers.Add(customer);
        await db.SaveChangesAsync();
        var request = Request(product);
        request.Order.CloudCustomerId = customer.Id;
        request.Order.CustomerName = "Changed Name";

        var response = await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "hash-5");

        Assert.Equal(customer.Id, response.CloudCustomerId);
        Assert.Equal("Known", (await db.Customers.SingleAsync(c => c.Id == customer.Id)).Name);
    }

    [Fact]
    public async Task ExactPaisePrecision_IsPersistedAsDecimalAmount()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();

        await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", Request(product), "hash-6");

        Assert.Equal(9.99m, (await db.Payments.SingleAsync()).Amount);
        Assert.Equal(9.99m, (await db.Orders.SingleAsync()).TotalAmount);
    }

    [Fact]
    public async Task PaymentReferenceAndIdentityUserId_ArePersistedFromServerContext()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();
        var request = Request(product);
        request.Payments.Single().Reference = "POS-REF-123";

        await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "hash-7");

        var payment = await db.Payments.SingleAsync();
        Assert.Equal("POS-REF-123", payment.Reference);
        Assert.Equal(_identityUserId, payment.ProcessedByUserId);
    }

    [Fact]
    public async Task OldMobileJwtWithoutIdentityUserId_IsRejected()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();
        var controller = Controller(db, Principal(
            new Claim("client_type", "mobile"),
            new Claim("mobile_user_id", _mobileUserId.ToString()),
            new Claim("device_id", "device-1")));

        var result = await controller.Sync(Json(Request(product)), CancellationToken.None);

        var problem = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status401Unauthorized, problem.StatusCode);
        Assert.Empty(db.Orders);
    }

    [Fact]
    public async Task WrongCompanyProduct_IsRejected()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db, companyId: _otherCompanyId);
        await db.SaveChangesAsync();

        await Assert.ThrowsAsync<KeyNotFoundException>(() => Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", Request(product), "hash-8"));
        Assert.Empty(db.Orders);
    }

    [Fact]
    public async Task WrongCompanyCustomer_IsRejected()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        var customer = new Customer(_otherCompanyId, "Other", null, "999");
        db.Customers.Add(customer);
        await db.SaveChangesAsync();
        var request = Request(product);
        request.Order.CloudCustomerId = customer.Id;

        await Assert.ThrowsAsync<KeyNotFoundException>(() => Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "hash-9"));
        Assert.Empty(db.Orders);
    }

    [Fact]
    public async Task DuplicateClientIds_AreRejected()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();
        var duplicateLines = Request(product);
        duplicateLines.Lines.Add(Line(product, id: 1, localProductId: 202));
        var duplicatePayments = Request(product);
        duplicatePayments.Payments.Add(new PosSalePaymentSnapshot { Id = 1, Method = "cash", AmountPaise = 0 });
        var duplicateInventory = Request(product);
        duplicateInventory.InventoryTransactions.Add(Inventory(product, id: 1, localProductId: 202));

        await Assert.ThrowsAsync<ArgumentException>(() => Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", duplicateLines, "hash-10a"));
        await Assert.ThrowsAsync<ArgumentException>(() => Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", duplicatePayments, "hash-10b"));
        await Assert.ThrowsAsync<ArgumentException>(() => Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", duplicateInventory, "hash-10c"));
        Assert.Empty(db.Orders);
    }

    [Fact]
    public async Task SameClientSyncIdSamePayload_ReturnsOriginalResult()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();
        var service = Service(db);
        var request = Request(product);

        var first = await service.SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "same-hash");
        var second = await service.SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "same-hash");

        Assert.Equal(first.CloudOrderId, second.CloudOrderId);
        Assert.Equal(first.CloudCustomerId, second.CloudCustomerId);
        Assert.Single(db.Orders);
        Assert.Equal(9, (await db.Products.SingleAsync()).StockQuantity);
        Assert.Single(db.InventoryLedgers);
    }

    [Fact]
    public async Task SameClientSyncIdChangedPayload_ReturnsConflict()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();
        var service = Service(db);
        var request = Request(product);
        await service.SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "same-hash");

        await Assert.ThrowsAsync<InvalidOperationException>(() => service.SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "changed-hash"));
        Assert.Single(db.Orders);
    }

    [Fact]
    public async Task ConcurrentIdenticalRequests_CreateOneOrder()
    {
        await using (var seed = CreateDb())
        {
            SeedProduct(seed);
            await seed.SaveChangesAsync();
        }
        await using var firstDb = CreateDb();
        await using var secondDb = CreateDb();
        var product = await firstDb.Products.SingleAsync();
        var firstService = new PosSaleSyncService(
            firstDb,
            useInProcessLock: false,
            idempotencyRetryAttempts: 10,
            idempotencyRetryDelay: TimeSpan.FromMilliseconds(20));
        var secondService = new PosSaleSyncService(
            secondDb,
            useInProcessLock: false,
            idempotencyRetryAttempts: 10,
            idempotencyRetryDelay: TimeSpan.FromMilliseconds(20));
        var firstRequest = Request(product);
        var secondRequest = Request(product);

        var results = await Task.WhenAll(
            firstService.SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", firstRequest, "concurrent-hash"),
            secondService.SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", secondRequest, "concurrent-hash"));

        await using var verify = CreateDb();
        Assert.Equal(results[0].CloudOrderId, results[1].CloudOrderId);
        Assert.Single(verify.Orders);
        Assert.Single(verify.PosSaleSyncReceipts);
        Assert.Single(verify.OrderItems);
        Assert.Single(verify.Payments);
        Assert.Single(verify.PosSaleSyncOrderLines);
        Assert.Single(verify.PosSaleSyncInventoryTransactions);
    }

    [Fact]
    public async Task FailureCases_RollBackAllPendingSaleRows()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();

        await Assert.ThrowsAsync<ArgumentException>(() => Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", Request(product, duplicateLineId: true), "fail-item"));
        await Assert.ThrowsAsync<ArgumentException>(() => Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", Request(product, duplicatePaymentId: true), "fail-payment"));
        await Assert.ThrowsAsync<KeyNotFoundException>(() => Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", Request(product, badInventoryProduct: true), "fail-inventory"));

        Assert.Empty(db.Orders);
        Assert.Empty(db.Payments);
        Assert.Empty(db.PosSaleSyncReceipts);
        Assert.Empty(db.PosSaleSyncOrderLines);
        Assert.Empty(db.PosSaleSyncInventoryTransactions);
    }

    [Fact]
    public async Task PosLineSnapshot_RollsBackWithTransactionFailure()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();

        await Assert.ThrowsAsync<KeyNotFoundException>(() => Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", Request(product, badInventoryProduct: true), "line-rollback"));

        Assert.Empty(db.Orders);
        Assert.Empty(db.PosSaleSyncReceipts);
        Assert.Empty(db.PosSaleSyncOrderLines);
        Assert.Empty(db.PosSaleSyncInventoryTransactions);
    }

    [Fact]
    public async Task CustomerCreation_RollsBackIfLaterSalePersistenceFails()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();
        var request = Request(product, badInventoryProduct: true);
        request.Order.CustomerName = "New Customer";
        request.Order.CustomerPhone = "9999990000";

        await Assert.ThrowsAsync<KeyNotFoundException>(() => Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "hash-customer-rollback"));

        Assert.Empty(db.Customers);
        Assert.Empty(db.Orders);
        Assert.Empty(db.PosSaleSyncReceipts);
    }

    [Fact]
    public async Task PostgreSql23505LoserRecovery_ReturnsExistingReceiptWhenSameHashAppearsAfterRetry()
    {
        await using var db = CreateDb();
        var order = SeedOrder(db);
        var service = new PosSaleSyncService(db, useInProcessLock: false, idempotencyRetryAttempts: 5, idempotencyRetryDelay: TimeSpan.FromMilliseconds(1));
        var exception = UniqueViolation("IX_PosSaleSyncReceipts_CompanyId_ClientSyncId");

        var recovery = service.RecoverFromUniqueViolationAsync(exception, _companyId, "sync-appears", "hash", CancellationToken.None);
        await Task.Delay(5);
        await using (var winnerDb = CreateDb())
        {
            winnerDb.PosSaleSyncReceipts.Add(new PosSaleSyncReceipt(_companyId, "sync-appears", 42, "device-1", order.Id, null, "hash", DateTime.UtcNow));
            await winnerDb.SaveChangesAsync();
        }

        var response = await recovery;
        Assert.Equal(order.Id, response.CloudOrderId);
    }

    [Fact]
    public async Task PostgreSql23505LoserRecovery_DifferentHashReturnsConflict()
    {
        await using var db = CreateDb();
        var order = SeedOrder(db);
        db.PosSaleSyncReceipts.Add(new PosSaleSyncReceipt(_companyId, "sync-conflict", 42, "device-1", order.Id, null, "original", DateTime.UtcNow));
        await db.SaveChangesAsync();
        var service = new PosSaleSyncService(db, useInProcessLock: false, idempotencyRetryAttempts: 1, idempotencyRetryDelay: TimeSpan.Zero);

        await Assert.ThrowsAsync<InvalidOperationException>(() => service.RecoverFromUniqueViolationAsync(
            UniqueViolation("IX_PosSaleSyncReceipts_CompanyId_ClientSyncId"), _companyId, "sync-conflict", "changed", CancellationToken.None));
    }

    [Fact]
    public async Task PostgreSql23505LoserRecovery_NoReceiptAfterRetryReturnsSafeConflict()
    {
        await using var db = CreateDb();
        var service = new PosSaleSyncService(db, useInProcessLock: false, idempotencyRetryAttempts: 1, idempotencyRetryDelay: TimeSpan.Zero);

        var error = await Assert.ThrowsAsync<InvalidOperationException>(() => service.RecoverFromUniqueViolationAsync(
            UniqueViolation("IX_PosSaleSyncReceipts_CompanyId_ClientSyncId"), _companyId, "missing-sync", "hash", CancellationToken.None));
        Assert.Contains("idempotency conflict", error.Message);
    }

    [Fact]
    public async Task PostgreSql23505UnrelatedUniqueViolation_IsNotTreatedAsIdempotentReplay()
    {
        await using var db = CreateDb();
        var order = SeedOrder(db);
        db.PosSaleSyncReceipts.Add(new PosSaleSyncReceipt(_companyId, "sync-unrelated", 42, "device-1", order.Id, null, "hash", DateTime.UtcNow));
        await db.SaveChangesAsync();
        var service = new PosSaleSyncService(db, useInProcessLock: false, idempotencyRetryAttempts: 1, idempotencyRetryDelay: TimeSpan.Zero);

        var error = await Assert.ThrowsAsync<InvalidOperationException>(() => service.RecoverFromUniqueViolationAsync(
            UniqueViolation("IX_PosSaleSyncOrderLines_PosSaleSyncReceiptId_ClientOrderLineId"), _companyId, "sync-unrelated", "hash", CancellationToken.None));
        Assert.Contains("duplicate business identity", error.Message);
    }

    [Fact]
    public async Task LocalOrderIdDuplicateProtection_WorksPerCompanyAndDevice()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();
        var service = Service(db);
        await service.SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", Request(product), "hash-local-1");
        var second = Request(product, clientSyncId: "sync-other");

        await Assert.ThrowsAsync<InvalidOperationException>(() => service.SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", second, "hash-local-2"));
        Assert.Single(db.Orders);
    }

    [Fact]
    public async Task FinancialMismatch_ReturnsBadRequestFromController()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();
        var request = Request(product);
        request.Payments.Single().AmountPaise = 998;
        var controller = Controller(db, Principal(
            new Claim("company_id", _companyId.ToString()),
            new Claim("mobile_user_id", _mobileUserId.ToString()),
            new Claim("identity_user_id", _identityUserId.ToString()),
            new Claim("device_id", "device-1"),
            new Claim("client_type", "mobile")));

        var result = await controller.Sync(Json(request), CancellationToken.None);

        var problem = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status400BadRequest, problem.StatusCode);
        Assert.Empty(db.Orders);
    }

    private SumpoojDbContext CreateDb(Guid? companyId = null)
    {
        var options = new DbContextOptionsBuilder<SumpoojDbContext>()
            .UseInMemoryDatabase(_databaseName, _databaseRoot)
            .ConfigureWarnings(warnings => warnings.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options;
        return new SumpoojDbContext(options, new TestTenantContext(companyId ?? _companyId));
    }

    private PosSaleSyncService Service(SumpoojDbContext db) => new(db);

    private MobilePosSalesController Controller(SumpoojDbContext db, ClaimsPrincipal user) => new(Service(db), new TestTenantContext(_companyId))
    {
        ControllerContext = new ControllerContext { HttpContext = new DefaultHttpContext { User = user } }
    };

    private ClaimsPrincipal Principal(params Claim[] claims) => new(new ClaimsIdentity(claims, "test"));

    private Product SeedProduct(SumpoojDbContext db, Guid? companyId = null, string sku = "ROSE", string name = "Rose")
    {
        var product = new Product(companyId ?? _companyId, name, sku, ProductType.SingleFlower, ProductCategory.Roses, 10m, 5m, null);
        product.AdjustStock(10);
        db.Products.Add(product);
        return product;
    }

    private ProductBatch SeedBatch(SumpoojDbContext db, Guid productId, int quantityRemaining)
    {
        var batch = new ProductBatch(_companyId, productId, "BATCH-1", quantityRemaining, 5m, DateTime.UtcNow, null, null, null, null);
        db.ProductBatches.Add(batch);
        return batch;
    }

    private Order SeedOrder(SumpoojDbContext db)
    {
        var customer = new Customer(_companyId, "Receipt Customer", null, "999");
        var order = new Order(_companyId, customer.Id, DateTime.UtcNow, null, null, null, null);
        db.AddRange(customer, order);
        return order;
    }

    private PosSaleSyncRequest Request(
        Product product,
        string clientSyncId = "sync-1",
        bool duplicateLineId = false,
        bool duplicatePaymentId = false,
        bool badInventoryProduct = false)
    {
        var request = new PosSaleSyncRequest
        {
            ClientSyncId = clientSyncId,
            LocalOrderId = 42,
            Order = new PosSaleOrderSnapshot
            {
                OrderNo = $"POS-{clientSyncId}",
                CustomerName = "POS Customer",
                CustomerPhone = "9876543210",
                Source = "walkIn",
                Channel = "retail",
                FulfilmentType = "take_away",
                SubtotalPaise = 999,
                GstTotalPaise = 0,
                DiscountTotalPaise = 0,
                GrandTotalPaise = 999,
                RoundOffPaise = 0,
                RewardDiscountAmountPaise = 0,
                RewardPointsEarned = 0,
                RewardPointsRedeemed = 0,
                IsPaid = 1,
                ConfirmedAt = DateTime.UtcNow
            },
            Lines = [Line(product)],
            Payments = [new PosSalePaymentSnapshot { Id = 1, Method = "cash", AmountPaise = 999, Reference = "REF-1" }],
            InventoryTransactions = [Inventory(badInventoryProduct ? new Product(_otherCompanyId, "Other", "OTHER", ProductType.SingleFlower, ProductCategory.Roses, 1m, 1m, null) : product)]
        };
        if (duplicateLineId)
            request.Lines.Add(Line(product, id: 1, localProductId: 202));
        if (duplicatePaymentId)
            request.Payments.Add(new PosSalePaymentSnapshot { Id = 1, Method = "cash", AmountPaise = 0 });
        return request;
    }

    private static PosSaleLineSnapshot Line(Product product, int id = 1, int localProductId = 101, int unitPricePaise = 999, int subtotalPaise = 999, int totalPaise = 999) => new()
    {
        Id = id,
        ProductId = localProductId,
        LocalProductId = localProductId,
        CloudProductId = product.Id,
        Description = product.Name,
        Qty = 1,
        UnitPricePaise = unitPricePaise,
        GstPercent = 0,
        DiscountPaise = 0,
        LineSubtotalPaise = subtotalPaise,
        LineGstPaise = 0,
        LineTotalPaise = totalPaise,
        Source = "product"
    };

    private static PosSaleLineSnapshot ManualLine(int id, string description, int unitPricePaise = 250) => new()
    {
        Id = id,
        ProductId = null,
        LocalProductId = null,
        CloudProductId = null,
        Description = description,
        Qty = 1,
        UnitPricePaise = unitPricePaise,
        GstPercent = 0,
        DiscountPaise = 0,
        LineSubtotalPaise = unitPricePaise,
        LineGstPaise = 0,
        LineTotalPaise = unitPricePaise,
        Source = "manual",
        DesignRef = "DESIGN-LOCAL-1"
    };

    private static PosSaleInventoryTransactionSnapshot Inventory(Product product, int id = 1, int localProductId = 101) => new()
    {
        Id = id,
        ProductId = localProductId,
        LocalProductId = localProductId,
        CloudProductId = product.Id,
        Qty = 1,
        CreatedAt = DateTime.UtcNow
    };

    private static JsonElement Json(PosSaleSyncRequest request) => JsonDocument.Parse(JsonSerializer.Serialize(request)).RootElement.Clone();

    private static DbUpdateException UniqueViolation(string constraintName) => new(
        "duplicate key",
        new PostgresException(
            "duplicate key value violates unique constraint",
            "ERROR",
            "ERROR",
            PostgresErrorCodes.UniqueViolation,
            constraintName: constraintName));

    private sealed class TestTenantContext : ITenantContext
    {
        public TestTenantContext(Guid companyId) => CompanyId = companyId;
        public Guid? CompanyId { get; }
        public string? Region => null;
        public bool IsPlatformUser => false;
    }
}
