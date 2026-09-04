using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Tests.Inventory;

public class PosSalesSyncPersistenceTests
{
    private sealed class TenantContext(Guid companyId) : ITenantContext
    {
        public Guid? CompanyId => companyId;
        public bool IsPlatformUser => false;
        public string? Region => null;
    }

    [Fact]
    public async Task PosPersistenceFieldsAndReceiptPersistWithoutChangingExistingEntities()
    {
        var companyId = Guid.NewGuid();
        var customer = new Customer(companyId, "Customer", null, "9876543210");
        var product = new Product(companyId, "Rose", "ROSE", ProductType.SingleFlower, ProductCategory.Roses, 10m, 5m, null);
        var order = new Order(companyId, customer.Id, DateTime.UtcNow, null, null, null, null);
        order.AddItem(product.Id, product.Name, 1, 9.99m);
        var item = order.Items.Single();
        item.SetPosFinancialDetails("line-1", 12m, "percentage", 10m, 1m, 8.99m, 1m);
        order.SetPosFinancialDetails(0.01m, 1.23m);
        var payment = new Payment(companyId, order.Id, PaymentMethod.Cash, 9.99m);
        payment.SetPosReference("payment-1", "POS-REF-001");
        var ledger = new InventoryLedger(companyId, product.Id, "legacy", "SALE", -1, 5, null);
        var receipt = new PosSaleSyncReceipt(companyId, "sync-1", 42, "device-1", order.Id, null, "hash", DateTime.UtcNow);
        var inventoryAudit = new PosSaleSyncInventoryTransaction(companyId, receipt.Id, "inventory-1", order.Id, product.Id, 1, DateTime.UtcNow);

        await using var db = CreateDb(companyId);
        db.AddRange(customer, product, order, payment, ledger, receipt, inventoryAudit);
        await db.SaveChangesAsync();
        db.ChangeTracker.Clear();

        var storedOrder = await db.Orders.Include(x => x.Items).SingleAsync();
        var storedItem = storedOrder.Items.Single();
        var storedPayment = await db.Payments.SingleAsync();
        var storedLedger = await db.InventoryLedgers.SingleAsync();
        var storedReceipt = await db.PosSaleSyncReceipts.SingleAsync();
        var storedAudit = await db.PosSaleSyncInventoryTransactions.SingleAsync();

        Assert.Equal(0.01m, storedOrder.PosRoundOffAmount);
        Assert.Equal(1.23m, storedOrder.RewardDiscountAmount);
        Assert.Equal("line-1", storedItem.ClientOrderLineId);
        Assert.Equal(12m, storedItem.TaxRatePercent);
        Assert.Equal("percentage", storedItem.DiscountType);
        Assert.Equal(10m, storedItem.DiscountValue);
        Assert.Equal(1m, storedItem.DiscountAmount);
        Assert.Equal(8.99m, storedItem.LineSubtotal);
        Assert.Equal(1m, storedItem.LineTaxAmount);
        Assert.Equal("payment-1", storedPayment.ClientPaymentId);
        Assert.Equal("POS-REF-001", storedPayment.Reference);
        Assert.Equal("SALE", storedLedger.ReferenceType);
        Assert.Null(storedReceipt.CloudCustomerId);
        Assert.Equal("inventory-1", storedAudit.ClientInventoryTransactionId);
        Assert.Equal(0, product.StockQuantity);
    }

    [Fact]
    public async Task PosSyncModelDefinesCompanyScopedIdempotencyConstraints()
    {
        await using var db = CreateDb(Guid.NewGuid());
        var receipt = db.Model.FindEntityType(typeof(PosSaleSyncReceipt))!;
        var inventory = db.Model.FindEntityType(typeof(PosSaleSyncInventoryTransaction))!;
        var payment = db.Model.FindEntityType(typeof(Payment))!;
        var item = db.Model.FindEntityType(typeof(OrderItem))!;

        Assert.Contains(receipt.GetIndexes(), index => index.IsUnique && index.Properties.Select(x => x.Name).SequenceEqual(["CompanyId", "ClientSyncId"]));
        Assert.Contains(receipt.GetIndexes(), index => index.IsUnique && index.Properties.Select(x => x.Name).SequenceEqual(["CompanyId", "DeviceId", "LocalOrderId"]));
        Assert.Contains(inventory.GetIndexes(), index => index.IsUnique && index.Properties.Select(x => x.Name).SequenceEqual(["CompanyId", "ClientInventoryTransactionId"]));
        Assert.Contains(payment.GetIndexes(), index => index.IsUnique && index.Properties.Select(x => x.Name).SequenceEqual(["OrderId", "ClientPaymentId"]));
        Assert.Contains(item.GetIndexes(), index => index.IsUnique && index.Properties.Select(x => x.Name).SequenceEqual(["OrderId", "ClientOrderLineId"]));
    }

    private static SumpoojDbContext CreateDb(Guid companyId)
    {
        var options = new DbContextOptionsBuilder<SumpoojDbContext>()
            .UseInMemoryDatabase($"PosPersistence_{Guid.NewGuid():N}")
            .Options;
        return new SumpoojDbContext(options, new TenantContext(companyId));
    }
}
