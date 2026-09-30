using System.Security.Claims;
using System.Text.Json;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.EntityFrameworkCore.Storage;
using Npgsql;
using Sumpooj.API.Controllers;
using Sumpooj.API.Controllers.Mobile;
using Sumpooj.API.Services.Mobile;
using Sumpooj.Application.Accounting;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Mobile;
using Sumpooj.Application.UseCases;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;
using Sumpooj.Infrastructure.Repositories;
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
        Assert.Equal(order.Id.ToString(), ledger.Reference);
        Assert.Equal(-1, ledger.QuantityChange);
        Assert.Equal(9, ledger.BalanceAfter);
        Assert.Single(db.PosSaleSyncInventoryTransactions);
    }

    [Fact]
    public async Task CashSale_CreatesOneCloudCashBookCashInEntry()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();
        var request = Request(product);
        request.Order.OrderNo = "POS-CASH-600";
        request.Order.SubtotalPaise = 60000;
        request.Order.GrandTotalPaise = 60000;
        request.Lines.Single().UnitPricePaise = 60000;
        request.Lines.Single().LineSubtotalPaise = 60000;
        request.Lines.Single().LineTotalPaise = 60000;
        request.Payments.Single().AmountPaise = 60000;

        await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "cash-600-hash");

        var cashBook = await db.CashBookEntries.SingleAsync();
        Assert.Equal(CashBookTransactionType.CashSale, cashBook.TransactionType);
        Assert.Equal(600m, cashBook.Amount);
        Assert.Equal(600m, cashBook.CashIn);
        Assert.Equal(0m, cashBook.CashOut);
        Assert.Equal(600m, cashBook.RunningBalance);
        Assert.Contains("POS-CASH-600", cashBook.Description);
    }

    [Fact]
    public async Task PosSale_WithEarlyMorningIstBusinessDate_SetsCashBookDateToLocalCalendarDate()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();
        var request = Request(product, clientSyncId: "sync-ist-morning");
        request.Order.OrderNo = "POS-IST-001";
        // ConfirmedAt in UTC: 2026-09-08 21:00:00Z (02:30 AM on 2026-09-09 in IST)
        request.Order.ConfirmedAt = new DateTime(2026, 9, 8, 21, 0, 0, DateTimeKind.Utc);
        // BusinessDate explicitly sent as local date: 2026-09-09
        request.Order.BusinessDate = new DateTime(2026, 9, 9, 0, 0, 0, DateTimeKind.Utc);

        await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "ist-morning-hash");

        var cashBook = await db.CashBookEntries.SingleAsync();
        Assert.Equal(CashBookTransactionType.CashSale, cashBook.TransactionType);
        Assert.Equal(new DateTime(2026, 9, 9, 0, 0, 0, DateTimeKind.Utc), cashBook.Date);
        Assert.NotEqual(new DateTime(2026, 9, 8, 0, 0, 0, DateTimeKind.Utc), cashBook.Date);
    }

    [Fact]
    public async Task EarlyMorningIstSale_At0153_BelongsToSept9_AndIsIncludedInDashboardCashBookAndDayClose()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();

        var request = Request(product, clientSyncId: "sync-ist-0153");
        request.Order.OrderNo = "POS-0153-IST";
        // Sale occurred at 01:53 AM IST on 2026-09-09 (which is 20:23 UTC on 2026-09-08)
        request.Order.ConfirmedAt = new DateTime(2026, 9, 8, 20, 23, 0, DateTimeKind.Utc);
        request.Order.BusinessDate = new DateTime(2026, 9, 9, 0, 0, 0, DateTimeKind.Utc);
        request.Payments.Single().Method = "cash";
        request.Payments.Single().AmountPaise = 999;

        var response = await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "ist-0153-hash");

        // 1. Order date belongs to Sept 9
        var order = await db.Orders.SingleAsync(o => o.Id == response.CloudOrderId);
        Assert.Equal(new DateTime(2026, 9, 9, 0, 0, 0, DateTimeKind.Utc).Date, order.OrderDate.Date);

        // 2. Cash Book date is Sept 9
        var cashBook = await db.CashBookEntries.SingleAsync();
        Assert.Equal(CashBookTransactionType.CashSale, cashBook.TransactionType);
        Assert.Equal(new DateTime(2026, 9, 9, 0, 0, 0, DateTimeKind.Utc), cashBook.Date);
        Assert.Equal(9.99m, cashBook.Amount);

        // 3. Dashboard summary for Sept 9 includes the sale
        var dashboardController = new MobileDashboardController(db, new TestTenantContext(_companyId));
        var dashboardResult = await dashboardController.GetSummary(
            new DateTime(2026, 9, 9, 0, 0, 0, DateTimeKind.Utc),
            new DateTime(2026, 9, 9, 0, 0, 0, DateTimeKind.Utc),
            CancellationToken.None);
        var okDashboard = Assert.IsType<OkObjectResult>(dashboardResult);
        var summary = Assert.IsType<MobileDashboardSummaryDto>(okDashboard.Value);
        Assert.Equal(999, summary.TotalSalesPaise);
        Assert.Equal(1, summary.OrderCount);
        Assert.Equal(999, summary.CashPaise);

        // 4. Cash Book API returns the entry for Sept 9
        var financeController = new MobileFinanceController(db, new TestTenantContext(_companyId));
        var cashBookResult = await financeController.GetCashBook(new DateTime(2026, 9, 9, 0, 0, 0, DateTimeKind.Utc), null, null, null);
        var okCashBook = Assert.IsType<OkObjectResult>(cashBookResult);
        var entries = Assert.IsAssignableFrom<IEnumerable<CashBookEntryDto>>(okCashBook.Value);
        Assert.Single(entries);

        // 5. Day Close summary includes the sale
        var dayCloseRepo = new DayCloseRepository(db);
        var dayCloseSummary = await dayCloseRepo.GetSummaryAsync(_companyId, new DateTime(2026, 9, 9, 0, 0, 0, DateTimeKind.Utc));
        Assert.Equal(9.99m, dayCloseSummary.CashSales);

        var orderRepo = new OrderRepository(db);
        var paymentRepo = new PaymentRepository(db);
        var locationRepo = new LocationRepository(db);
        var dayCloseService = new DayCloseService(dayCloseRepo, orderRepo, paymentRepo, locationRepo, dayCloseRepo);
        var serviceSummary = await dayCloseService.GetSummaryAsync(_companyId, Guid.Empty, new DateTime(2026, 9, 9, 0, 0, 0, DateTimeKind.Utc));
        var totalOrders = (int)(serviceSummary.GetType().GetProperty("totalOrders")?.GetValue(serviceSummary) ?? 0);
        var totalSales = (decimal)(serviceSummary.GetType().GetProperty("totalSales")?.GetValue(serviceSummary) ?? 0m);
        var cashSales = (decimal)(serviceSummary.GetType().GetProperty("cashSales")?.GetValue(serviceSummary) ?? 0m);
        Assert.Equal(1, totalOrders);
        Assert.Equal(9.99m, totalSales);
        Assert.Equal(9.99m, cashSales);
    }

    [Fact]
    public async Task PosSale_FallbackToConfirmedAt_WhenBusinessDateMissing()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();

        var request = Request(product, clientSyncId: "sync-confirmed-at-fallback");
        request.Order.OrderNo = "POS-FALLBACK-001";
        request.Order.BusinessDate = null;
        request.Order.ConfirmedAt = new DateTime(2026, 9, 9, 1, 53, 0, DateTimeKind.Unspecified);

        var response = await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "fallback-hash");

        var order = await db.Orders.SingleAsync(o => o.Id == response.CloudOrderId);
        Assert.Equal(new DateTime(2026, 9, 9, 0, 0, 0, DateTimeKind.Utc).Date, order.OrderDate.Date);

        var cashBook = await db.CashBookEntries.SingleAsync();
        Assert.Equal(new DateTime(2026, 9, 9, 0, 0, 0, DateTimeKind.Utc), cashBook.Date);
    }

    [Fact]
    public void ResolveBusinessDate_NeverFallsBackToRawUtcNowDate()
    {
        var order = new PosSaleOrderSnapshot
        {
            BusinessDate = null,
            ConfirmedAt = null
        };

        var resolved = PosSaleSyncService.ResolveBusinessDate(order);
        var serverLocal = PosSaleSyncService.GetServerLocalBusinessDate();

        Assert.Equal(serverLocal, resolved);
        Assert.Equal(DateTimeKind.Utc, resolved.Kind);
    }

    [Fact]
    public async Task NormalDaytimeSale_CorrectAcrossDashboardCashBookAndDayClose()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();

        var request = Request(product, clientSyncId: "sync-daytime-1430");
        request.Order.OrderNo = "POS-DAYTIME-001";
        request.Order.ConfirmedAt = new DateTime(2026, 9, 9, 14, 30, 0, DateTimeKind.Utc);
        request.Order.BusinessDate = new DateTime(2026, 9, 9, 0, 0, 0, DateTimeKind.Utc);

        var response = await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "daytime-hash");

        var order = await db.Orders.SingleAsync(o => o.Id == response.CloudOrderId);
        Assert.Equal(new DateTime(2026, 9, 9, 0, 0, 0, DateTimeKind.Utc).Date, order.OrderDate.Date);

        var cashBook = await db.CashBookEntries.SingleAsync();
        Assert.Equal(new DateTime(2026, 9, 9, 0, 0, 0, DateTimeKind.Utc), cashBook.Date);

        var dashboardController = new MobileDashboardController(db, new TestTenantContext(_companyId));
        var dashboardResult = await dashboardController.GetSummary(
            new DateTime(2026, 9, 9, 0, 0, 0, DateTimeKind.Utc),
            new DateTime(2026, 9, 9, 0, 0, 0, DateTimeKind.Utc),
            CancellationToken.None);
        var summary = Assert.IsType<MobileDashboardSummaryDto>(Assert.IsType<OkObjectResult>(dashboardResult).Value);
        Assert.Equal(1, summary.OrderCount);
        Assert.Equal(999, summary.CashPaise);

        var dayCloseRepo = new DayCloseRepository(db);
        var dayCloseSummary = await dayCloseRepo.GetSummaryAsync(_companyId, new DateTime(2026, 9, 9, 0, 0, 0, DateTimeKind.Utc));
        Assert.Equal(9.99m, dayCloseSummary.CashSales);
    }

    [Fact]
    public async Task UpiAndCardSale_ExcludedFromCashBook_IncludedInDashboardAndDayClose()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();

        var request = Request(product, clientSyncId: "sync-upi-card");
        request.Order.OrderNo = "POS-UPICARD-001";
        request.Order.ConfirmedAt = new DateTime(2026, 9, 8, 20, 23, 0, DateTimeKind.Utc);
        request.Order.BusinessDate = new DateTime(2026, 9, 9, 0, 0, 0, DateTimeKind.Utc);
        request.Payments =
        [
            new PosSalePaymentSnapshot { Id = 1, Method = "upi", AmountPaise = 400, Reference = "UPI-1" },
            new PosSalePaymentSnapshot { Id = 2, Method = "card", AmountPaise = 599, Reference = "CARD-1" }
        ];

        var response = await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "upicard-hash");

        // 1. Zero CashBook entries
        Assert.Empty(db.CashBookEntries);

        // 2. Dashboard includes UPI and Card
        var dashboardController = new MobileDashboardController(db, new TestTenantContext(_companyId));
        var dashboardResult = await dashboardController.GetSummary(
            new DateTime(2026, 9, 9, 0, 0, 0, DateTimeKind.Utc),
            new DateTime(2026, 9, 9, 0, 0, 0, DateTimeKind.Utc),
            CancellationToken.None);
        var summary = Assert.IsType<MobileDashboardSummaryDto>(Assert.IsType<OkObjectResult>(dashboardResult).Value);
        Assert.Equal(1, summary.OrderCount);
        Assert.Equal(0, summary.CashPaise);
        Assert.Equal(400, summary.UpiPaise);
        Assert.Equal(599, summary.CardPaise);
        Assert.Equal(999, summary.TotalSalesPaise);

        // 3. Day Close includes UPI and Card sales
        var dayCloseRepo = new DayCloseRepository(db);
        var orderRepo = new OrderRepository(db);
        var paymentRepo = new PaymentRepository(db);
        var locationRepo = new LocationRepository(db);
        var dayCloseService = new DayCloseService(dayCloseRepo, orderRepo, paymentRepo, locationRepo, dayCloseRepo);
        var serviceSummary = await dayCloseService.GetSummaryAsync(_companyId, Guid.Empty, new DateTime(2026, 9, 9, 0, 0, 0, DateTimeKind.Utc));
        var totalOrders = (int)(serviceSummary.GetType().GetProperty("totalOrders")?.GetValue(serviceSummary) ?? 0);
        var cardSales = (decimal)(serviceSummary.GetType().GetProperty("cardSales")?.GetValue(serviceSummary) ?? 0m);
        var upiSales = (decimal)(serviceSummary.GetType().GetProperty("upiSales")?.GetValue(serviceSummary) ?? 0m);
        var cashSales = (decimal)(serviceSummary.GetType().GetProperty("cashSales")?.GetValue(serviceSummary) ?? 0m);
        Assert.Equal(1, totalOrders);
        Assert.Equal(5.99m, cardSales);
        Assert.Equal(4.00m, upiSales);
        Assert.Equal(0m, cashSales);
    }

    [Fact]
    public async Task IdempotentRetry_DoesNotDuplicateAcrossDashboardCashBookOrDayClose()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();

        var request = Request(product, clientSyncId: "sync-idempotent-full");
        request.Order.OrderNo = "POS-IDEM-001";
        request.Order.ConfirmedAt = new DateTime(2026, 9, 8, 20, 23, 0, DateTimeKind.Utc);
        request.Order.BusinessDate = new DateTime(2026, 9, 9, 0, 0, 0, DateTimeKind.Utc);

        var service = Service(db);
        await service.SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "idem-full-hash");
        await service.SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "idem-full-hash");

        Assert.Single(db.Orders);
        Assert.Single(db.CashBookEntries);
        Assert.Single(db.Payments);

        var dashboardController = new MobileDashboardController(db, new TestTenantContext(_companyId));
        var dashboardResult = await dashboardController.GetSummary(
            new DateTime(2026, 9, 9, 0, 0, 0, DateTimeKind.Utc),
            new DateTime(2026, 9, 9, 0, 0, 0, DateTimeKind.Utc),
            CancellationToken.None);
        var summary = Assert.IsType<MobileDashboardSummaryDto>(Assert.IsType<OkObjectResult>(dashboardResult).Value);
        Assert.Equal(1, summary.OrderCount);
        Assert.Equal(999, summary.CashPaise);

        var dayCloseRepo = new DayCloseRepository(db);
        var orderRepo = new OrderRepository(db);
        var paymentRepo = new PaymentRepository(db);
        var locationRepo = new LocationRepository(db);
        var dayCloseService = new DayCloseService(dayCloseRepo, orderRepo, paymentRepo, locationRepo, dayCloseRepo);
        var serviceSummary = await dayCloseService.GetSummaryAsync(_companyId, Guid.Empty, new DateTime(2026, 9, 9, 0, 0, 0, DateTimeKind.Utc));
        var totalOrders = (int)(serviceSummary.GetType().GetProperty("totalOrders")?.GetValue(serviceSummary) ?? 0);
        var cashSales = (decimal)(serviceSummary.GetType().GetProperty("cashSales")?.GetValue(serviceSummary) ?? 0m);
        Assert.Equal(1, totalOrders);
        Assert.Equal(9.99m, cashSales);
    }

    [Fact]
    public async Task NonCashSale_CreatesNoCloudCashBookEntry()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();
        var request = Request(product, clientSyncId: "sync-upi");
        request.Payments.Single().Method = "upi";

        await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "upi-hash");

        Assert.Empty(db.CashBookEntries);
    }

    [Fact]
    public async Task MultiPaymentSale_PostsOnlyCashPortionToCloudCashBook()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();
        var request = Request(product, clientSyncId: "sync-mixed-payment");
        request.Order.SubtotalPaise = 60000;
        request.Order.GrandTotalPaise = 60000;
        request.Lines.Single().UnitPricePaise = 60000;
        request.Lines.Single().LineSubtotalPaise = 60000;
        request.Lines.Single().LineTotalPaise = 60000;
        request.Payments =
        [
            new PosSalePaymentSnapshot { Id = 1, Method = "cash", AmountPaise = 20000, Reference = "CASH-1" },
            new PosSalePaymentSnapshot { Id = 2, Method = "upi", AmountPaise = 40000, Reference = "UPI-1" }
        ];

        await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "mixed-payment-hash");

        var cashBook = await db.CashBookEntries.SingleAsync();
        Assert.Equal(CashBookTransactionType.CashSale, cashBook.TransactionType);
        Assert.Equal(200m, cashBook.Amount);
        Assert.Equal(200m, cashBook.CashIn);
        Assert.Equal(0m, cashBook.CashOut);
    }

    [Fact]
    public async Task SameClientSyncIdRetry_DoesNotDuplicateCloudCashBookEntry()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();
        var request = Request(product, clientSyncId: "sync-cash-retry");
        var service = Service(db);

        await service.SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "retry-cash-hash");
        await service.SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "retry-cash-hash");

        Assert.Single(db.PosSaleSyncReceipts);
        Assert.Single(db.CashBookEntries);
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
        Assert.Equal(9, (await db.Products.SingleAsync(p => p.Id == first.Id)).StockQuantity);
        Assert.Equal(9, (await db.Products.SingleAsync(p => p.Id == second.Id)).StockQuantity);
        Assert.Equal(2, await db.InventoryLedgers.CountAsync());
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
        Assert.Equal(9, (await verify.Products.SingleAsync()).StockQuantity);
        Assert.Single(verify.InventoryLedgers);
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
    public async Task InsufficientCloudStock_RollsBackOrderPaymentInventoryAndLedger()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db, startingStock: 0);
        await db.SaveChangesAsync();

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", Request(product), "insufficient-stock"));

        Assert.Empty(db.Orders);
        Assert.Empty(db.Payments);
        Assert.Empty(db.PosSaleSyncReceipts);
        Assert.Empty(db.PosSaleSyncOrderLines);
        Assert.Empty(db.PosSaleSyncInventoryTransactions);
        Assert.Empty(db.InventoryLedgers);
        Assert.Equal(0, (await db.Products.SingleAsync()).StockQuantity);
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
    public async Task TwoDevices_SameCompany_BothLocalInventoryTransactionId1_BothSyncSuccessfully()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db, startingStock: 10);
        await db.SaveChangesAsync();
        var service = Service(db);

        // Device 1 performs sale with local inventory transaction id=1
        var dev1Request = Request(product, clientSyncId: "dev1-sync-1");
        dev1Request.LocalOrderId = 1;
        dev1Request.InventoryTransactions.Single().Id = 1;
        var dev1Result = await service.SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", dev1Request, "hash-dev1-1");
        Assert.Equal("completed", dev1Result.SyncStatus);

        // Device 2 performs sale for SAME company with local inventory transaction id=1
        var dev2Request = Request(product, clientSyncId: "dev2-sync-1");
        dev2Request.LocalOrderId = 1;
        dev2Request.InventoryTransactions.Single().Id = 1;
        var dev2Result = await service.SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-2", dev2Request, "hash-dev2-1");
        Assert.Equal("completed", dev2Result.SyncStatus);

        // Verify both inventory audit records exist with namespaced IDs and do not collide
        var inventoryTxns = await db.PosSaleSyncInventoryTransactions.ToListAsync();
        Assert.Equal(2, inventoryTxns.Count);
        Assert.Contains(inventoryTxns, t => t.ClientInventoryTransactionId == "dev1-sync-1:1");
        Assert.Contains(inventoryTxns, t => t.ClientInventoryTransactionId == "dev2-sync-1:1");
        Assert.Equal(2, inventoryTxns.Select(t => t.ClientInventoryTransactionId).Distinct().Count());
    }

    [Fact]
    public async Task FreshInstallOrSequenceReset_SaleWithId1_Succeeds()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db, startingStock: 10);
        await db.SaveChangesAsync();
        var service = Service(db);

        // Existing sale before reinstall with local id=1
        var initialRequest = Request(product, clientSyncId: "old-install-sync-1");
        initialRequest.LocalOrderId = 1;
        initialRequest.InventoryTransactions.Single().Id = 1;
        await service.SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-original", initialRequest, "hash-old-1");

        // Fresh install: device wiped, local SQLite sequence reset, new device ID & new clientSyncId, but local id is again 1
        var freshInstallRequest = Request(product, clientSyncId: "fresh-install-sync-1");
        freshInstallRequest.LocalOrderId = 1;
        freshInstallRequest.InventoryTransactions.Single().Id = 1;
        var freshResult = await service.SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-reinstalled", freshInstallRequest, "hash-fresh-1");

        Assert.Equal("completed", freshResult.SyncStatus);
        var inventoryTxns = await db.PosSaleSyncInventoryTransactions.ToListAsync();
        Assert.Equal(2, inventoryTxns.Count);
        Assert.Contains(inventoryTxns, t => t.ClientInventoryTransactionId == "fresh-install-sync-1:1");
        Assert.Contains(inventoryTxns, t => t.ClientInventoryTransactionId == "old-install-sync-1:1");
        Assert.Equal(2, inventoryTxns.Select(t => t.ClientInventoryTransactionId).Distinct().Count());
    }

    [Fact]
    public async Task ExactRetry_WithSameClientSyncId_RemainsIdempotent()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db, startingStock: 10);
        await db.SaveChangesAsync();
        var service = Service(db);

        var request = Request(product, clientSyncId: "retry-test-sync");
        request.LocalOrderId = 10;
        request.InventoryTransactions.Single().Id = 1;

        // First attempt
        var firstResponse = await service.SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "hash-exact-match");
        Assert.Equal("completed", firstResponse.SyncStatus);

        // Second attempt with exact same ClientSyncId and payload hash
        var secondResponse = await service.SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "hash-exact-match");
        Assert.Equal("completed", secondResponse.SyncStatus);
        Assert.Equal(firstResponse.CloudOrderId, secondResponse.CloudOrderId);

        // Ensure no duplicate records were created
        Assert.Single(db.Orders);
        Assert.Single(db.PosSaleSyncReceipts);
        Assert.Single(db.PosSaleSyncInventoryTransactions);
        Assert.Equal(9, (await db.Products.SingleAsync()).StockQuantity);
    }

    [Fact]
    public async Task SameClientSyncId_WithModifiedPayload_RemainsRejected()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db, startingStock: 10);
        await db.SaveChangesAsync();
        var service = Service(db);

        var request = Request(product, clientSyncId: "conflict-test-sync");
        request.LocalOrderId = 15;
        request.InventoryTransactions.Single().Id = 1;

        // First attempt succeeds
        var firstResponse = await service.SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "hash-original");
        Assert.Equal("completed", firstResponse.SyncStatus);

        // Modified payload with same ClientSyncId
        var modifiedRequest = Request(product, clientSyncId: "conflict-test-sync");
        modifiedRequest.LocalOrderId = 15;
        modifiedRequest.InventoryTransactions.Single().Id = 1;

        var ex = await Assert.ThrowsAsync<InvalidOperationException>(() =>
            service.SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", modifiedRequest, "hash-different"));

        Assert.Contains("ClientSyncId was already used with a different payload", ex.Message);
    }

    [Fact]
    public async Task FinancialMismatch_ReturnsBadRequestFromController()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();
        var request = Request(product);
        request.Payments.Single().AmountPaise = 1000;
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

    [Fact]
    public async Task FullCashSale_CreatesPaidOrder_AndOneCashPayment_AndCashBookEntry()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();
        var request = Request(product, clientSyncId: "sync-full-cash");
        request.Order.SubtotalPaise = 100000;
        request.Order.GrandTotalPaise = 100000;
        request.Lines.Single().UnitPricePaise = 100000;
        request.Lines.Single().LineSubtotalPaise = 100000;
        request.Lines.Single().LineTotalPaise = 100000;
        request.Payments = [new PosSalePaymentSnapshot { Id = 1, Method = "cash", AmountPaise = 100000, Reference = "CASH-1" }];

        var response = await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "full-cash-hash");

        var order = await db.Orders.SingleAsync(o => o.Id == response.CloudOrderId);
        Assert.Equal(PaymentStatus.Paid, order.PaymentStatus);
        Assert.Equal(1000m, order.TotalAmount);

        var payments = await db.Payments.Where(p => p.OrderId == order.Id).ToListAsync();
        Assert.Single(payments);
        Assert.Equal(PaymentMethod.Cash, payments.Single().Method);
        Assert.Equal(1000m, payments.Single().Amount);

        var cashBook = await db.CashBookEntries.SingleAsync();
        Assert.Equal(1000m, cashBook.Amount);
    }

    [Fact]
    public async Task FullUpiSale_CreatesPaidOrder_AndOneUpiPayment_AndZeroCashBookEntries()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();
        var request = Request(product, clientSyncId: "sync-full-upi");
        request.Order.SubtotalPaise = 100000;
        request.Order.GrandTotalPaise = 100000;
        request.Lines.Single().UnitPricePaise = 100000;
        request.Lines.Single().LineSubtotalPaise = 100000;
        request.Lines.Single().LineTotalPaise = 100000;
        request.Payments = [new PosSalePaymentSnapshot { Id = 1, Method = "upi", AmountPaise = 100000, Reference = "UPI-1" }];

        var response = await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "full-upi-hash");

        var order = await db.Orders.SingleAsync(o => o.Id == response.CloudOrderId);
        Assert.Equal(PaymentStatus.Paid, order.PaymentStatus);
        Assert.Equal(1000m, order.TotalAmount);

        var payments = await db.Payments.Where(p => p.OrderId == order.Id).ToListAsync();
        Assert.Single(payments);
        Assert.Equal(PaymentMethod.Upi, payments.Single().Method);
        Assert.Equal(1000m, payments.Single().Amount);

        Assert.Empty(db.CashBookEntries);
    }

    [Fact]
    public async Task SplitCashAndCreditSale_CreatesPartiallyPaidOrder_AndOnlyCashPayment_AndNeverCreditPayment()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();
        var request = Request(product, clientSyncId: "sync-split-cash-credit");
        request.Order.SubtotalPaise = 100000;
        request.Order.GrandTotalPaise = 100000;
        request.Order.CustomerName = "Alice Customer";
        request.Order.CustomerPhone = "9876543210";
        request.Lines.Single().UnitPricePaise = 100000;
        request.Lines.Single().LineSubtotalPaise = 100000;
        request.Lines.Single().LineTotalPaise = 100000;
        request.Payments =
        [
            new PosSalePaymentSnapshot { Id = 1, Method = "cash", AmountPaise = 60000, Reference = "CASH-SPLIT" },
            new PosSalePaymentSnapshot { Id = 2, Method = "credit", AmountPaise = 40000, Reference = "CREDIT-SPLIT" }
        ];

        var response = await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "split-cash-credit-hash");

        var order = await db.Orders.SingleAsync(o => o.Id == response.CloudOrderId);
        Assert.Equal(PaymentStatus.PartiallyPaid, order.PaymentStatus);
        Assert.Equal(1000m, order.TotalAmount);

        // Crucial: exactly ONE payment entity created for Cash 600, NEVER a second payment for credit 400
        var payments = await db.Payments.Where(p => p.OrderId == order.Id).ToListAsync();
        Assert.Single(payments);
        Assert.Equal(PaymentMethod.Cash, payments.Single().Method);
        Assert.Equal(600m, payments.Single().Amount);

        // CashBook contains only the cash tender of 600
        var cashBook = await db.CashBookEntries.SingleAsync();
        Assert.Equal(600m, cashBook.Amount);

        // Dynamic pending payments API reports 400 outstanding
        var pendingController = new MobilePendingPaymentsController(db, new TestTenantContext(_companyId));
        var pendingResult = Assert.IsType<OkObjectResult>(await pendingController.GetPendingPayments(CancellationToken.None));
        var pendingDto = Assert.IsType<MobilePendingPaymentsDto>(pendingResult.Value);
        Assert.Equal(1, pendingDto.PendingOrderCount);
        Assert.Equal(40000, pendingDto.PendingPaymentPaise);
    }

    [Fact]
    public async Task FullCreditSale_CreatesCreditOrder_AndZeroPaymentEntities_AndZeroCashBookEntries()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();
        var request = Request(product, clientSyncId: "sync-full-credit");
        request.Order.SubtotalPaise = 100000;
        request.Order.GrandTotalPaise = 100000;
        request.Order.CustomerName = "Bob Credit";
        request.Order.CustomerPhone = "9123456780";
        request.Lines.Single().UnitPricePaise = 100000;
        request.Lines.Single().LineSubtotalPaise = 100000;
        request.Lines.Single().LineTotalPaise = 100000;
        request.Payments =
        [
            new PosSalePaymentSnapshot { Id = 1, Method = "credit", AmountPaise = 100000, Reference = "CREDIT-FULL" }
        ];

        var response = await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "full-credit-hash");

        var order = await db.Orders.SingleAsync(o => o.Id == response.CloudOrderId);
        Assert.Equal(PaymentStatus.Credit, order.PaymentStatus);
        Assert.Equal(1000m, order.TotalAmount);

        // Zero Payment entities
        Assert.Empty(db.Payments.Where(p => p.OrderId == order.Id));
        // Zero CashBook entries
        Assert.Empty(db.CashBookEntries);

        // Dynamic pending payments API reports 1000 outstanding
        var pendingController = new MobilePendingPaymentsController(db, new TestTenantContext(_companyId));
        var pendingResult = Assert.IsType<OkObjectResult>(await pendingController.GetPendingPayments(CancellationToken.None));
        var pendingDto = Assert.IsType<MobilePendingPaymentsDto>(pendingResult.Value);
        Assert.Equal(1, pendingDto.PendingOrderCount);
        Assert.Equal(100000, pendingDto.PendingPaymentPaise);
    }

    [Fact]
    public async Task SplitUpiAndCreditSale_CreatesPartiallyPaidOrder_AndOneUpiPayment()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();
        var request = Request(product, clientSyncId: "sync-upi-credit");
        request.Order.SubtotalPaise = 100000;
        request.Order.GrandTotalPaise = 100000;
        request.Order.CustomerName = "Charlie UPI";
        request.Order.CustomerPhone = "9234567890";
        request.Lines.Single().UnitPricePaise = 100000;
        request.Lines.Single().LineSubtotalPaise = 100000;
        request.Lines.Single().LineTotalPaise = 100000;
        request.Payments =
        [
            new PosSalePaymentSnapshot { Id = 1, Method = "upi", AmountPaise = 70000, Reference = "UPI-700" },
            new PosSalePaymentSnapshot { Id = 2, Method = "credit", AmountPaise = 30000, Reference = "CREDIT-300" }
        ];

        var response = await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "upi-credit-hash");

        var order = await db.Orders.SingleAsync(o => o.Id == response.CloudOrderId);
        Assert.Equal(PaymentStatus.PartiallyPaid, order.PaymentStatus);

        var payments = await db.Payments.Where(p => p.OrderId == order.Id).ToListAsync();
        Assert.Single(payments);
        Assert.Equal(PaymentMethod.Upi, payments.Single().Method);
        Assert.Equal(700m, payments.Single().Amount);
        Assert.Empty(db.CashBookEntries);

        var pendingController = new MobilePendingPaymentsController(db, new TestTenantContext(_companyId));
        var pendingResult = Assert.IsType<OkObjectResult>(await pendingController.GetPendingPayments(CancellationToken.None));
        var pendingDto = Assert.IsType<MobilePendingPaymentsDto>(pendingResult.Value);
        Assert.Equal(1, pendingDto.PendingOrderCount);
        Assert.Equal(30000, pendingDto.PendingPaymentPaise);
    }

    [Fact]
    public async Task CashUpiAndCreditSale_CreatesPartiallyPaidOrder_AndTwoPayments_AndOnlyCashPortionInCashBook()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();
        var request = Request(product, clientSyncId: "sync-cash-upi-credit");
        request.Order.SubtotalPaise = 100000;
        request.Order.GrandTotalPaise = 100000;
        request.Order.CustomerName = "David Multi";
        request.Order.CustomerPhone = "9345678901";
        request.Lines.Single().UnitPricePaise = 100000;
        request.Lines.Single().LineSubtotalPaise = 100000;
        request.Lines.Single().LineTotalPaise = 100000;
        request.Payments =
        [
            new PosSalePaymentSnapshot { Id = 1, Method = "cash", AmountPaise = 40000, Reference = "CASH-400" },
            new PosSalePaymentSnapshot { Id = 2, Method = "upi", AmountPaise = 30000, Reference = "UPI-300" },
            new PosSalePaymentSnapshot { Id = 3, Method = "credit", AmountPaise = 30000, Reference = "CREDIT-300" }
        ];

        var response = await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "cash-upi-credit-hash");

        var order = await db.Orders.SingleAsync(o => o.Id == response.CloudOrderId);
        Assert.Equal(PaymentStatus.PartiallyPaid, order.PaymentStatus);

        var payments = await db.Payments.Where(p => p.OrderId == order.Id).OrderBy(p => p.Amount).ToListAsync();
        Assert.Equal(2, payments.Count);
        Assert.Equal(PaymentMethod.Upi, payments[0].Method);
        Assert.Equal(300m, payments[0].Amount);
        Assert.Equal(PaymentMethod.Cash, payments[1].Method);
        Assert.Equal(400m, payments[1].Amount);

        var cashBook = await db.CashBookEntries.SingleAsync();
        Assert.Equal(400m, cashBook.Amount);

        var pendingController = new MobilePendingPaymentsController(db, new TestTenantContext(_companyId));
        var pendingResult = Assert.IsType<OkObjectResult>(await pendingController.GetPendingPayments(CancellationToken.None));
        var pendingDto = Assert.IsType<MobilePendingPaymentsDto>(pendingResult.Value);
        Assert.Equal(1, pendingDto.PendingOrderCount);
        Assert.Equal(30000, pendingDto.PendingPaymentPaise);
    }

    [Fact]
    public async Task PaymentTotalExceedingGrandTotal_IsRejected()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();
        var request = Request(product, clientSyncId: "sync-overpaid");
        request.Order.SubtotalPaise = 100000;
        request.Order.GrandTotalPaise = 100000;
        request.Lines.Single().UnitPricePaise = 100000;
        request.Lines.Single().LineSubtotalPaise = 100000;
        request.Lines.Single().LineTotalPaise = 100000;
        request.Payments = [new PosSalePaymentSnapshot { Id = 1, Method = "cash", AmountPaise = 110000, Reference = "CASH-OVER" }];

        var ex = await Assert.ThrowsAsync<ArgumentException>(() =>
            Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "overpaid-hash"));

        Assert.Equal("Payment total cannot exceed grand total.", ex.Message);
        Assert.Empty(db.Orders);
    }

    [Fact]
    public async Task ContradictoryCreditAllocation_IsRejected()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();
        var request = Request(product, clientSyncId: "sync-bad-alloc");
        request.Order.SubtotalPaise = 100000;
        request.Order.GrandTotalPaise = 100000;
        request.Lines.Single().UnitPricePaise = 100000;
        request.Lines.Single().LineSubtotalPaise = 100000;
        request.Lines.Single().LineTotalPaise = 100000;
        request.Payments =
        [
            new PosSalePaymentSnapshot { Id = 1, Method = "cash", AmountPaise = 60000, Reference = "CASH-600" },
            new PosSalePaymentSnapshot { Id = 2, Method = "credit", AmountPaise = 30000, Reference = "CREDIT-300" }
        ];

        var ex = await Assert.ThrowsAsync<ArgumentException>(() =>
            Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "bad-alloc-hash"));

        Assert.Equal("Payment allocations do not reconcile with grand total.", ex.Message);
        Assert.Empty(db.Orders);
    }

    [Fact]
    public async Task CreditSaleWithoutCustomerIdentification_IsRejected()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();
        var request = Request(product, clientSyncId: "sync-credit-no-cust");
        request.Order.SubtotalPaise = 100000;
        request.Order.GrandTotalPaise = 100000;
        request.Order.CustomerName = null;
        request.Order.CustomerPhone = null;
        request.Order.CloudCustomerId = null;
        request.Lines.Single().UnitPricePaise = 100000;
        request.Lines.Single().LineSubtotalPaise = 100000;
        request.Lines.Single().LineTotalPaise = 100000;
        request.Payments =
        [
            new PosSalePaymentSnapshot { Id = 1, Method = "cash", AmountPaise = 60000, Reference = "CASH-600" },
            new PosSalePaymentSnapshot { Id = 2, Method = "credit", AmountPaise = 40000, Reference = "CREDIT-400" }
        ];

        var ex = await Assert.ThrowsAsync<ArgumentException>(() =>
            Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "no-cust-hash"));

        Assert.Equal("Customer identification is required for credit or partial payment transactions.", ex.Message);
        Assert.Empty(db.Orders);
    }

    [Fact]
    public async Task CreditSaleWithGenericWalkInNameAndNoPhone_IsRejected()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();
        var request = Request(product, clientSyncId: "sync-credit-walkin-name");
        request.Order.SubtotalPaise = 100000;
        request.Order.GrandTotalPaise = 100000;
        request.Order.CustomerName = "Walk-In Customer";
        request.Order.CustomerPhone = null;
        request.Order.CloudCustomerId = null;
        request.Lines.Single().UnitPricePaise = 100000;
        request.Lines.Single().LineSubtotalPaise = 100000;
        request.Lines.Single().LineTotalPaise = 100000;
        request.Payments =
        [
            new PosSalePaymentSnapshot { Id = 1, Method = "credit", AmountPaise = 100000, Reference = "CREDIT-1000" }
        ];

        var ex = await Assert.ThrowsAsync<ArgumentException>(() =>
            Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "walkin-name-hash"));

        Assert.Equal("Customer identification is required for credit or partial payment transactions.", ex.Message);
        Assert.Empty(db.Orders);
    }

    [Fact]
    public async Task CreditSaleRetry_WithSameClientSyncId_RemainsIdempotentWithoutDuplicatingReceivables()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();
        var request = Request(product, clientSyncId: "sync-credit-retry");
        request.Order.SubtotalPaise = 100000;
        request.Order.GrandTotalPaise = 100000;
        request.Order.CustomerName = "Emma Credit";
        request.Order.CustomerPhone = "9456789012";
        request.Lines.Single().UnitPricePaise = 100000;
        request.Lines.Single().LineSubtotalPaise = 100000;
        request.Lines.Single().LineTotalPaise = 100000;
        request.Payments =
        [
            new PosSalePaymentSnapshot { Id = 1, Method = "cash", AmountPaise = 60000, Reference = "CASH-600" },
            new PosSalePaymentSnapshot { Id = 2, Method = "credit", AmountPaise = 40000, Reference = "CREDIT-400" }
        ];

        var service = Service(db);
        var res1 = await service.SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "credit-retry-hash");
        var res2 = await service.SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "credit-retry-hash");

        Assert.Equal(res1.CloudOrderId, res2.CloudOrderId);
        Assert.Single(db.Orders);
        Assert.Single(db.Payments);
        Assert.Single(db.CashBookEntries);

        var pendingController = new MobilePendingPaymentsController(db, new TestTenantContext(_companyId));
        var pendingResult = Assert.IsType<OkObjectResult>(await pendingController.GetPendingPayments(CancellationToken.None));
        var pendingDto = Assert.IsType<MobilePendingPaymentsDto>(pendingResult.Value);
        Assert.Equal(1, pendingDto.PendingOrderCount);
        Assert.Equal(40000, pendingDto.PendingPaymentPaise);
    }

    [Fact]
    public async Task DirectPostPaymentsCollection_ReducesPendingPaymentWithoutDuplicateOrderRevenue()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();
        var request = Request(product, clientSyncId: "sync-collect-flow");
        request.Order.SubtotalPaise = 100000;
        request.Order.GrandTotalPaise = 100000;
        request.Order.CustomerName = "Frank Receivable";
        request.Order.CustomerPhone = "9567890123";
        request.Lines.Single().UnitPricePaise = 100000;
        request.Lines.Single().LineSubtotalPaise = 100000;
        request.Lines.Single().LineTotalPaise = 100000;
        request.Payments =
        [
            new PosSalePaymentSnapshot { Id = 1, Method = "cash", AmountPaise = 60000, Reference = "CASH-600" },
            new PosSalePaymentSnapshot { Id = 2, Method = "credit", AmountPaise = 40000, Reference = "CREDIT-400" }
        ];

        var response = await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "collect-flow-hash");

        var pendingController = new MobilePendingPaymentsController(db, new TestTenantContext(_companyId));
        var pending1 = Assert.IsType<MobilePendingPaymentsDto>(Assert.IsType<OkObjectResult>(await pendingController.GetPendingPayments(CancellationToken.None)).Value);
        Assert.Equal(40000, pending1.PendingPaymentPaise);

        // Later collection via /api/payments creates an approved payment for the remaining 400
        var collectionPayment = new Payment(_companyId, response.CloudOrderId, PaymentMethod.Cash, 400m);
        collectionPayment.Approve(null, null);
        db.Payments.Add(collectionPayment);
        await db.SaveChangesAsync();

        var pending2 = Assert.IsType<MobilePendingPaymentsDto>(Assert.IsType<OkObjectResult>(await pendingController.GetPendingPayments(CancellationToken.None)).Value);
        Assert.Equal(0, pending2.PendingPaymentPaise);
        Assert.Equal(0, pending2.PendingOrderCount);
    }

    private SumpoojDbContext CreateDb(Guid? companyId = null)
    {
        var options = new DbContextOptionsBuilder<SumpoojDbContext>()
            .UseInMemoryDatabase(_databaseName, _databaseRoot)
            .ConfigureWarnings(warnings => warnings.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options;
        return new SumpoojDbContext(options, new TestTenantContext(companyId ?? _companyId));
    }

    private (SumpoojDbContext db, SqliteConnection connection) CreateSqliteDb(Guid? companyId = null)
    {
        var connection = new SqliteConnection("DataSource=:memory:");
        connection.Open();
        using (var cmd = connection.CreateCommand())
        {
            cmd.CommandText = "PRAGMA foreign_keys = ON;";
            cmd.ExecuteNonQuery();
        }

        var options = new DbContextOptionsBuilder<SumpoojDbContext>()
            .UseSqlite(connection)
            .Options;

        var db = new SumpoojDbContext(options, new TestTenantContext(companyId ?? _companyId));
        db.Database.EnsureCreated();
        return (db, connection);
    }

    private PosSaleSyncService Service(SumpoojDbContext db) => new(db);

    private MobilePosSalesController Controller(SumpoojDbContext db, ClaimsPrincipal user) => new(Service(db), new TestTenantContext(_companyId))
    {
        ControllerContext = new ControllerContext { HttpContext = new DefaultHttpContext { User = user } }
    };

    private ClaimsPrincipal Principal(params Claim[] claims) => new(new ClaimsIdentity(claims, "test"));

    private Product SeedProduct(SumpoojDbContext db, Guid? companyId = null, string sku = "ROSE", string name = "Rose", int startingStock = 10)
    {
        var product = new Product(companyId ?? _companyId, name, sku, ProductType.SingleFlower, ProductCategory.Roses, 10m, 5m, null);
        product.AdjustStock(startingStock);
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

    [Fact]
    public async Task Test1_DesignOnly_CreatesOrderItemWithNullProductId_PreservesDesignRefAndFinancials_NoInventoryDeduction()
    {
        await using var db = CreateDb();
        var designRef = "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBD...";
        var request = new PosSaleSyncRequest
        {
            ClientSyncId = "DESIGN-ONLY-SYNC-1",
            LocalOrderId = 1001,
            Order = new PosSaleOrderSnapshot
            {
                OrderNo = "POS-ORD-DESIGN-1",
                CustomerPhone = "9876543210",
                SubtotalPaise = 254237,
                GstTotalPaise = 45763,
                DiscountTotalPaise = 0,
                GrandTotalPaise = 300000,
                RoundOffPaise = 0,
                RewardDiscountAmountPaise = 0,
                RewardPointsEarned = 0,
                RewardPointsRedeemed = 0,
                IsPaid = 1,
                ConfirmedAt = DateTime.UtcNow
            },
            Lines = [DesignLine(1, "150 mix roses", unitPricePaise: 300000, subtotalPaise: 254237, gstPaise: 45763, gstPercent: 18, designRef: designRef)],
            Payments = [new PosSalePaymentSnapshot { Id = 1, Method = "cash", AmountPaise = 300000, Reference = "CASH-3000" }],
            InventoryTransactions = []
        };

        var response = await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "design-hash-1");

        Assert.Equal("completed", response.SyncStatus);
        var order = await db.Orders.Include(o => o.Items).SingleAsync(o => o.Id == response.CloudOrderId);
        Assert.Single(order.Items);
        var orderItem = order.Items.Single();
        Assert.Null(orderItem.ProductId);
        Assert.Equal("150 mix roses", orderItem.ProductName);
        Assert.Equal(1, orderItem.Quantity);
        Assert.Equal(3000m, orderItem.UnitPrice);
        Assert.Equal(3000m, orderItem.TotalPrice);
        Assert.Equal(18m, orderItem.TaxRatePercent);
        Assert.Equal(2542.37m, orderItem.LineSubtotal);
        Assert.Equal(457.63m, orderItem.LineTaxAmount);

        // PosSaleSyncOrderLine check
        var posLine = await db.PosSaleSyncOrderLines.SingleAsync(l => l.CloudOrderId == order.Id);
        Assert.Equal("design", posLine.Source);
        Assert.Null(posLine.CloudProductId);
        Assert.Equal("150 mix roses", posLine.Description);
        Assert.Equal(designRef, posLine.DesignRef);

        // Inventory check: no inventory deduction for design line
        Assert.Empty(db.InventoryLedgers);
        Assert.Empty(db.PosSaleSyncInventoryTransactions);
    }

    [Fact]
    public async Task Test2_NormalProduct_PreservesExistingCatalogueOrderItemBehavior()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();
        var request = Request(product);

        var response = await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "normal-product-hash");

        Assert.Equal("completed", response.SyncStatus);
        var order = await db.Orders.Include(o => o.Items).SingleAsync(o => o.Id == response.CloudOrderId);
        Assert.Single(order.Items);
        var orderItem = order.Items.Single();
        Assert.Equal(product.Id, orderItem.ProductId);
        Assert.Equal(product.Name, orderItem.ProductName);
        Assert.Equal(9.99m, orderItem.UnitPrice);

        var posLine = await db.PosSaleSyncOrderLines.SingleAsync(l => l.CloudOrderId == order.Id);
        Assert.Equal(product.Id, posLine.CloudProductId);
        Assert.Equal("product", posLine.Source);
        Assert.Single(db.InventoryLedgers);
    }

    [Fact]
    public async Task Test3_MixedOrder_CreatesBothOrderItems_ProcessesInventoryOnlyForProduct()
    {
        await using var db = CreateDb();
        var productA = SeedProduct(db, sku: "PROD-A", name: "Product A", startingStock: 20);
        await db.SaveChangesAsync();

        var designRef = "data:image/jpeg;base64,mixed-design-image";
        var request = new PosSaleSyncRequest
        {
            ClientSyncId = "MIXED-ORDER-SYNC-1",
            LocalOrderId = 1002,
            Order = new PosSaleOrderSnapshot
            {
                OrderNo = "POS-ORD-MIXED-1",
                CustomerPhone = "9876543210",
                SubtotalPaise = 304237,
                GstTotalPaise = 45763,
                DiscountTotalPaise = 0,
                GrandTotalPaise = 350000,
                RoundOffPaise = 0,
                RewardDiscountAmountPaise = 0,
                RewardPointsEarned = 0,
                RewardPointsRedeemed = 0,
                IsPaid = 1,
                ConfirmedAt = DateTime.UtcNow
            },
            Lines = [
                Line(productA, id: 1, localProductId: 101, unitPricePaise: 50000, subtotalPaise: 50000, totalPaise: 50000),
                DesignLine(2, "150 mix roses", unitPricePaise: 300000, subtotalPaise: 254237, gstPaise: 45763, gstPercent: 18, designRef: designRef)
            ],
            Payments = [new PosSalePaymentSnapshot { Id = 1, Method = "cash", AmountPaise = 350000, Reference = "CASH-3500" }],
            InventoryTransactions = [Inventory(productA, id: 1, localProductId: 101)]
        };

        var response = await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "mixed-hash-1");

        Assert.Equal("completed", response.SyncStatus);
        var order = await db.Orders.Include(o => o.Items).SingleAsync(o => o.Id == response.CloudOrderId);
        Assert.Equal(2, order.Items.Count);

        var productLine = order.Items.Single(i => i.ProductId == productA.Id);
        Assert.Equal("Product A", productLine.ProductName);
        Assert.Equal(500m, productLine.UnitPrice);

        var designLine = order.Items.Single(i => i.ProductId == null);
        Assert.Equal("150 mix roses", designLine.ProductName);
        Assert.Equal(3000m, designLine.UnitPrice);

        var posLines = await db.PosSaleSyncOrderLines.Where(l => l.CloudOrderId == order.Id).ToListAsync();
        Assert.Equal(2, posLines.Count);
        Assert.Contains(posLines, l => l.Source == "product" && l.CloudProductId == productA.Id);
        Assert.Contains(posLines, l => l.Source == "design" && l.CloudProductId == null && l.DesignRef == designRef);

        // Inventory should only be deducted for Product A (1 transaction, 1 ledger record)
        var ledgers = await db.InventoryLedgers.Where(l => l.Reference == order.Id.ToString()).ToListAsync();
        Assert.Single(ledgers);
        Assert.Equal(productA.Id, ledgers[0].ProductId);
        Assert.Equal(-1, ledgers[0].QuantityChange);
    }

    [Fact]
    public async Task Test4_GetOrderDetail_ReturnsDesignItemWithImageUrlAndDescription()
    {
        await using var db = CreateDb();
        var designRef = "data:image/jpeg;base64,design-rose-image";
        var request = new PosSaleSyncRequest
        {
            ClientSyncId = "DESIGN-DETAIL-SYNC-1",
            LocalOrderId = 1003,
            Order = new PosSaleOrderSnapshot
            {
                OrderNo = "POS-ORD-DESIGN-DETAIL-1",
                CustomerPhone = "9876543210",
                SubtotalPaise = 254237,
                GstTotalPaise = 45763,
                DiscountTotalPaise = 0,
                GrandTotalPaise = 300000,
                RoundOffPaise = 0,
                RewardDiscountAmountPaise = 0,
                RewardPointsEarned = 0,
                RewardPointsRedeemed = 0,
                IsPaid = 1,
                ConfirmedAt = DateTime.UtcNow
            },
            Lines = [DesignLine(1, "150 mix roses", unitPricePaise: 300000, subtotalPaise: 254237, gstPaise: 45763, gstPercent: 18, designRef: designRef)],
            Payments = [new PosSalePaymentSnapshot { Id = 1, Method = "cash", AmountPaise = 300000, Reference = "CASH-3000" }],
            InventoryTransactions = []
        };

        var response = await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "design-detail-hash");

        var controller = OrdersController(db);
        var actionResult = await controller.GetById(response.CloudOrderId, CancellationToken.None);
        var okResult = Assert.IsType<OkObjectResult>(actionResult);
        var dto = Assert.IsType<MobileOrderDetailDto>(okResult.Value);

        Assert.Single(dto.Items);
        var itemDto = dto.Items[0];
        Assert.Null(itemDto.ProductId);
        Assert.Equal("150 mix roses", itemDto.ProductName);
        Assert.Equal(1, itemDto.Quantity);
        Assert.Equal(3000m, itemDto.UnitPrice);
        Assert.Equal(designRef, itemDto.ImageUrl);
    }

    [Fact]
    public async Task Test5_GetOrderDetail_MixedOrder_ReturnsBothNormalProductAndDesignWithImages()
    {
        await using var db = CreateDb();
        var productA = SeedProduct(db, sku: "PROD-A", name: "Product A", startingStock: 20);
        await db.SaveChangesAsync();

        var designRef = "data:image/jpeg;base64,mixed-detail-image";
        var request = new PosSaleSyncRequest
        {
            ClientSyncId = "MIXED-DETAIL-SYNC-1",
            LocalOrderId = 1004,
            Order = new PosSaleOrderSnapshot
            {
                OrderNo = "POS-ORD-MIXED-DETAIL-1",
                CustomerPhone = "9876543210",
                SubtotalPaise = 304237,
                GstTotalPaise = 45763,
                DiscountTotalPaise = 0,
                GrandTotalPaise = 350000,
                RoundOffPaise = 0,
                RewardDiscountAmountPaise = 0,
                RewardPointsEarned = 0,
                RewardPointsRedeemed = 0,
                IsPaid = 1,
                ConfirmedAt = DateTime.UtcNow
            },
            Lines = [
                Line(productA, id: 1, localProductId: 101, unitPricePaise: 50000, subtotalPaise: 50000, totalPaise: 50000),
                DesignLine(2, "150 mix roses", unitPricePaise: 300000, subtotalPaise: 254237, gstPaise: 45763, gstPercent: 18, designRef: designRef)
            ],
            Payments = [new PosSalePaymentSnapshot { Id = 1, Method = "cash", AmountPaise = 350000, Reference = "CASH-3500" }],
            InventoryTransactions = [Inventory(productA, id: 1, localProductId: 101)]
        };

        var response = await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "mixed-detail-hash");

        var controller = OrdersController(db);
        var actionResult = await controller.GetById(response.CloudOrderId, CancellationToken.None);
        var okResult = Assert.IsType<OkObjectResult>(actionResult);
        var dto = Assert.IsType<MobileOrderDetailDto>(okResult.Value);

        Assert.Equal(2, dto.Items.Count);
        var prodItem = dto.Items.Single(i => i.ProductId == productA.Id);
        Assert.Equal("Product A", prodItem.ProductName);

        var designItem = dto.Items.Single(i => i.ProductId == null);
        Assert.Equal("150 mix roses", designItem.ProductName);
        Assert.Equal(3000m, designItem.UnitPrice);
        Assert.Equal(designRef, designItem.ImageUrl);
    }

    [Fact]
    public async Task Test6_HistoricalBuggedOrder_WithPosSaleSyncOrderLinesOnly_ReturnsSynthesizedDesignItemWithoutDuplicates()
    {
        await using var db = CreateDb();
        var customer = new Customer(_companyId, "Customer One", null, "9876543210");
        db.Customers.Add(customer);
        var order = new Order(_companyId, customer.Id, DateTime.UtcNow.AddHours(2), "Main Street", "560001", "Recipient One", "9988776655");
        order.SetImportedOrderNumber("POS-HISTORICAL-1");
        order.SetImportedPosFinancials(2542.37m, 457.63m, 0m, 3000m, 0m, 0m, 0, 0);
        order.MarkPaid();
        db.Orders.Add(order);

        var receipt = new PosSaleSyncReceipt(_companyId, "HISTORICAL-SYNC-1", 999, "device-1", order.Id, customer.Id, "hash", DateTime.UtcNow);
        db.PosSaleSyncReceipts.Add(receipt);

        var designRef = "data:image/jpeg;base64,historical-design-image";
        db.PosSaleSyncOrderLines.Add(new PosSaleSyncOrderLine(
            _companyId,
            receipt.Id,
            order.Id,
            "HISTORICAL-SYNC-1:line:1",
            1,
            null,
            null,
            "design",
            designRef,
            "150 mix roses",
            1,
            3000m,
            18m,
            null,
            null,
            0m,
            2542.37m,
            457.63m,
            3000m));

        await db.SaveChangesAsync();

        // 1. When OrderItems has 0 items (historical bug state), detail API synthesizes the item from PosSaleSyncOrderLines
        var controller = OrdersController(db);
        var actionResult = await controller.GetById(order.Id, CancellationToken.None);
        var okResult = Assert.IsType<OkObjectResult>(actionResult);
        var dto = Assert.IsType<MobileOrderDetailDto>(okResult.Value);

        Assert.Single(dto.Items);
        Assert.Equal("150 mix roses", dto.Items[0].ProductName);
        Assert.Equal(3000m, dto.Items[0].UnitPrice);
        Assert.Equal(designRef, dto.Items[0].ImageUrl);

        // 2. If OrderItem is present with matching ClientOrderLineId, verify NO duplicate is created
        var order2 = new Order(_companyId, customer.Id, DateTime.UtcNow.AddHours(2), "Main Street", "560001", "Recipient One", "9988776655");
        order2.SetImportedOrderNumber("POS-HISTORICAL-2");
        order2.SetImportedPosFinancials(2542.37m, 457.63m, 0m, 3000m, 0m, 0m, 0, 0);
        order2.MarkPaid();
        order2.AddItem(null, "150 mix roses", 1, 3000m);
        order2.Items.Single().SetPosFinancialDetails("HISTORICAL-SYNC-2:line:1", 18m, null, null, 0m, 2542.37m, 457.63m);
        db.Orders.Add(order2);

        var receipt2 = new PosSaleSyncReceipt(_companyId, "HISTORICAL-SYNC-2", 1000, "device-1", order2.Id, customer.Id, "hash2", DateTime.UtcNow);
        db.PosSaleSyncReceipts.Add(receipt2);

        db.PosSaleSyncOrderLines.Add(new PosSaleSyncOrderLine(
            _companyId,
            receipt2.Id,
            order2.Id,
            "HISTORICAL-SYNC-2:line:1",
            1,
            null,
            null,
            "design",
            designRef,
            "150 mix roses",
            1,
            3000m,
            18m,
            null,
            null,
            0m,
            2542.37m,
            457.63m,
            3000m));

        await db.SaveChangesAsync();

        var actionResult2 = await controller.GetById(order2.Id, CancellationToken.None);
        var okResult2 = Assert.IsType<OkObjectResult>(actionResult2);
        var dto2 = Assert.IsType<MobileOrderDetailDto>(okResult2.Value);

        Assert.Single(dto2.Items); // Exactly 1 item, NO duplicate
        Assert.Equal("150 mix roses", dto2.Items[0].ProductName);
        Assert.Equal(designRef, dto2.Items[0].ImageUrl);
    }

    [Fact]
    public async Task FinishedGoodsBatchSale_DeductsBatchStock_CreatesOrderItem_AndPreservesProductStock()
    {
        await using var db = CreateDb();
        var rawProduct = SeedProduct(db);
        rawProduct.AdjustStock(40); // 10 + 40 = 50
        var finishedBatch = new FinishedGoodsBatch(
            _companyId,
            Guid.NewGuid(),
            "100 Red Roses Bouquet",
            "FGB-ROSE-100",
            "890123456",
            quantityProduced: 5,
            expectedExpiry: DateTime.UtcNow.AddDays(7),
            locationId: Guid.NewGuid(),
            locationName: "Main Store",
            totalCost: 1000m);
        db.FinishedGoodsBatches.Add(finishedBatch);
        await db.SaveChangesAsync();

        var request = new PosSaleSyncRequest
        {
            ClientSyncId = "finished-good-sync-1",
            LocalOrderId = 701,
            Order = new PosSaleOrderSnapshot
            {
                OrderNo = "POS-FG-1",
                GrandTotalPaise = 250000,
                SubtotalPaise = 250000,
                GstTotalPaise = 0,
                DiscountTotalPaise = 0,
                RoundOffPaise = 0,
                RewardDiscountAmountPaise = 0,
                RewardPointsEarned = 0,
                RewardPointsRedeemed = 0,
                CustomerName = "Walk-in",
                CustomerPhone = "9988776655"
            },
            Lines = new List<PosSaleLineSnapshot>
            {
                new()
                {
                    Id = 1,
                    ProductId = null,
                    LocalProductId = null,
                    CloudProductId = finishedBatch.Id,
                    Description = "100 Red Roses Bouquet",
                    Qty = 2,
                    UnitPricePaise = 125000,
                    GstPercent = 0,
                    DiscountPaise = 0,
                    LineSubtotalPaise = 250000,
                    LineGstPaise = 0,
                    LineTotalPaise = 250000,
                    Source = "product"
                }
            },
            InventoryTransactions = new List<PosSaleInventoryTransactionSnapshot>
            {
                new()
                {
                    Id = 1,
                    ProductId = 1,
                    LocalProductId = 1,
                    CloudProductId = finishedBatch.Id,
                    Qty = 2,
                    CreatedAt = DateTime.UtcNow
                }
            },
            Payments = new List<PosSalePaymentSnapshot>
            {
                new()
                {
                    Id = 1,
                    Method = "Cash",
                    AmountPaise = 250000,
                    Reference = "CASH-FG-1"
                }
            }
        };

        var response = await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "fg-hash-1");

        Assert.Equal("completed", response.SyncStatus);
        var order = await db.Orders.Include(o => o.Items).SingleAsync(o => o.Id == response.CloudOrderId);
        Assert.Single(order.Items);
        var item = order.Items.First();
        Assert.Equal("100 Red Roses Bouquet", item.ProductName);
        Assert.NotNull(item.ProductId);
        Assert.NotEqual(finishedBatch.Id, item.ProductId);
        var catalogueProduct = await db.Products.SingleAsync(p => p.Id == item.ProductId.Value);
        Assert.Equal("100 Red Roses Bouquet", catalogueProduct.Name);
        Assert.False(catalogueProduct.TrackInventory);
        Assert.Equal(2, item.Quantity);
        Assert.Equal(1250m, item.UnitPrice);

        var inventoryTx = await db.PosSaleSyncInventoryTransactions.SingleAsync(t => t.CloudOrderId == order.Id);
        Assert.Equal(catalogueProduct.Id, inventoryTx.ProductId);
        Assert.NotEqual(finishedBatch.Id, inventoryTx.ProductId);
        Assert.Equal(2, inventoryTx.Quantity);

        var orderLine = await db.PosSaleSyncOrderLines.SingleAsync(l => l.CloudOrderId == order.Id);
        Assert.Equal(catalogueProduct.Id, orderLine.CloudProductId);
        Assert.NotEqual(finishedBatch.Id, orderLine.CloudProductId);

        var updatedBatch = await db.FinishedGoodsBatches.SingleAsync(b => b.Id == finishedBatch.Id);
        Assert.Equal(3, updatedBatch.QuantityAvailable); // 5 - 2 = 3

        var updatedRawProduct = await db.Products.SingleAsync(p => p.Id == rawProduct.Id);
        Assert.Equal(50, updatedRawProduct.StockQuantity); // Untouched
    }

    [Fact]
    public async Task FinishedGoodsBatchSale_WithExistingCatalogueProduct_ReusesCatalogueProductId()
    {
        await using var db = CreateDb();
        var existingBouquetProduct = new Product(
            _companyId,
            "Luxury Orchid Basket",
            "BQ-ORCHID-01",
            ProductType.Bouquet,
            ProductCategory.Orchids,
            500m,
            250m,
            "Hand-crafted orchid basket");
        existingBouquetProduct.UpdateBasicInfo("Luxury Orchid Basket", "BQ-ORCHID-01", "890999001", null, null);
        existingBouquetProduct.SetInventorySettings(false, false, 0);
        db.Products.Add(existingBouquetProduct);

        var finishedBatch = new FinishedGoodsBatch(
            _companyId,
            Guid.NewGuid(),
            "Luxury Orchid Basket",
            "FGB-ORCHID-001",
            "890999001",
            quantityProduced: 4,
            expectedExpiry: DateTime.UtcNow.AddDays(5),
            locationId: Guid.NewGuid(),
            locationName: "Main Store",
            totalCost: 250m);
        db.FinishedGoodsBatches.Add(finishedBatch);
        await db.SaveChangesAsync();

        var request = new PosSaleSyncRequest
        {
            ClientSyncId = "existing-product-fg-sync",
            LocalOrderId = 705,
            Order = new PosSaleOrderSnapshot
            {
                OrderNo = "POS-FG-5",
                GrandTotalPaise = 50000,
                SubtotalPaise = 50000,
                CustomerPhone = "9988776655"
            },
            Lines = new List<PosSaleLineSnapshot>
            {
                new()
                {
                    Id = 1,
                    CloudProductId = finishedBatch.Id,
                    Description = "Luxury Orchid Basket",
                    Qty = 1,
                    UnitPricePaise = 50000,
                    LineSubtotalPaise = 50000,
                    LineTotalPaise = 50000,
                    Source = "product"
                }
            },
            InventoryTransactions = new List<PosSaleInventoryTransactionSnapshot>
            {
                new()
                {
                    Id = 1,
                    CloudProductId = finishedBatch.Id,
                    Qty = 1,
                    CreatedAt = DateTime.UtcNow
                }
            },
            Payments = new List<PosSalePaymentSnapshot>
            {
                new() { Id = 1, Method = "Cash", AmountPaise = 50000 }
            }
        };

        var response = await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "existing-fg-hash");
        Assert.Equal("completed", response.SyncStatus);

        var order = await db.Orders.Include(o => o.Items).SingleAsync(o => o.Id == response.CloudOrderId);
        Assert.Equal(existingBouquetProduct.Id, order.Items.Single().ProductId);

        var inventoryTx = await db.PosSaleSyncInventoryTransactions.SingleAsync(t => t.CloudOrderId == order.Id);
        Assert.Equal(existingBouquetProduct.Id, inventoryTx.ProductId);

        var orderLine = await db.PosSaleSyncOrderLines.SingleAsync(l => l.CloudOrderId == order.Id);
        Assert.Equal(existingBouquetProduct.Id, orderLine.CloudProductId);
        Assert.NotEqual(finishedBatch.Id, orderLine.CloudProductId);

        // Ensure no redundant Product was created
        var bouquetProductsCount = await db.Products.CountAsync(p => p.CompanyId == _companyId && p.Name == "Luxury Orchid Basket");
        Assert.Equal(1, bouquetProductsCount);
    }

    [Fact]
    public async Task ReadyBouquetPosSale_PreservesProductsForeignKeyAndRelationalIntegrity()
    {
        await using var db = CreateDb();
        var rawFlower = SeedProduct(db, name: "Red Rose Stem", sku: "RAW-ROSE-01", startingStock: 100);
        var finishedBatch = new FinishedGoodsBatch(
            _companyId,
            Guid.NewGuid(),
            "Grand Celebration Bouquet",
            "FGB-GRAND-01",
            "890123499",
            quantityProduced: 10,
            expectedExpiry: DateTime.UtcNow.AddDays(5),
            locationId: Guid.NewGuid(),
            locationName: "Main Store",
            totalCost: 2000m);
        db.FinishedGoodsBatches.Add(finishedBatch);
        await db.SaveChangesAsync();

        // Flutter sends FinishedGoodsBatch.Id in cloudProductId
        var request = new PosSaleSyncRequest
        {
            ClientSyncId = "ready-bouquet-relational-fk-sync",
            LocalOrderId = 901,
            Order = new PosSaleOrderSnapshot
            {
                OrderNo = "POS-REL-901",
                GrandTotalPaise = 300000,
                SubtotalPaise = 300000,
                GstTotalPaise = 0,
                DiscountTotalPaise = 0,
                RoundOffPaise = 0,
                RewardDiscountAmountPaise = 0,
                RewardPointsEarned = 0,
                RewardPointsRedeemed = 0,
                CustomerName = "Walk-in",
                CustomerPhone = "9988776655"
            },
            Lines = new List<PosSaleLineSnapshot>
            {
                new()
                {
                    Id = 1,
                    CloudProductId = finishedBatch.Id,
                    Description = "Grand Celebration Bouquet",
                    Qty = 2,
                    UnitPricePaise = 150000,
                    LineSubtotalPaise = 300000,
                    LineTotalPaise = 300000,
                    Source = "product"
                }
            },
            InventoryTransactions = new List<PosSaleInventoryTransactionSnapshot>
            {
                new()
                {
                    Id = 1,
                    CloudProductId = finishedBatch.Id,
                    Qty = 2,
                    CreatedAt = DateTime.UtcNow
                }
            },
            Payments = new List<PosSalePaymentSnapshot>
            {
                new() { Id = 1, Method = "Cash", AmountPaise = 300000 }
            }
        };

        var response = await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "relational-fk-hash");
        Assert.Equal("completed", response.SyncStatus);

        // Verify EF model definition has FK on CloudProductId pointing to Products
        var orderLineEntity = db.Model.FindEntityType(typeof(PosSaleSyncOrderLine))!;
        var cloudProductFk = orderLineEntity.GetForeignKeys()
            .Single(f => f.Properties.Any(p => p.Name == nameof(PosSaleSyncOrderLine.CloudProductId)));
        Assert.Equal(typeof(Product), cloudProductFk.PrincipalEntityType.ClrType);

        // 1. Verify PosSaleSyncOrderLine.CloudProductId matches an existing catalogue product in db.Products
        var orderLine = await db.PosSaleSyncOrderLines.SingleAsync(l => l.CloudOrderId == response.CloudOrderId);
        Assert.NotNull(orderLine.CloudProductId);
        Assert.NotEqual(finishedBatch.Id, orderLine.CloudProductId);

        var catalogueProduct = await db.Products.SingleAsync(p => p.Id == orderLine.CloudProductId!.Value);
        Assert.Equal("Grand Celebration Bouquet", catalogueProduct.Name);
        Assert.Equal(ProductType.Bouquet, catalogueProduct.ProductType);
        Assert.Equal(ProductCategory.MixedFlowers, catalogueProduct.Category);
        Assert.False(catalogueProduct.TrackInventory);

        // 2. Verify OrderItem uses the catalogue Product.Id and not FinishedGoodsBatch.Id
        var order = await db.Orders.Include(o => o.Items).SingleAsync(o => o.Id == response.CloudOrderId);
        var orderItem = Assert.Single(order.Items);
        Assert.Equal(catalogueProduct.Id, orderItem.ProductId);
        Assert.NotEqual(finishedBatch.Id, orderItem.ProductId);

        // 3. Verify InventoryTransaction uses the catalogue Product.Id and not FinishedGoodsBatch.Id
        var inventoryTx = await db.PosSaleSyncInventoryTransactions.SingleAsync(t => t.CloudOrderId == response.CloudOrderId);
        Assert.Equal(catalogueProduct.Id, inventoryTx.ProductId);
        Assert.NotEqual(finishedBatch.Id, inventoryTx.ProductId);

        // 4. Verify FinishedGoodsBatch.QuantityAvailable decreases exactly once (10 - 2 = 8)
        var updatedBatch = await db.FinishedGoodsBatches.SingleAsync(b => b.Id == finishedBatch.Id);
        Assert.Equal(8, updatedBatch.QuantityAvailable);

        // 5. Verify Product.StockQuantity is NOT decreased
        var updatedRaw = await db.Products.SingleAsync(p => p.Id == rawFlower.Id);
        Assert.Equal(100, updatedRaw.StockQuantity);
        Assert.Equal(0, catalogueProduct.StockQuantity);
    }

    [Fact]
    public async Task ReadyBouquetPosSale_RelationalSqlite_EnforcesProductForeignKeys()
    {
        var (db, connection) = CreateSqliteDb();
        await using (connection)
        await using (db)
        {
            var rawFlower = SeedProduct(db, name: "Red Rose Stem", sku: "RAW-ROSE-SQLITE-01", startingStock: 100);
            var finishedBatch = new FinishedGoodsBatch(
                _companyId,
                Guid.NewGuid(),
                "Grand Celebration Bouquet",
                "FGB-GRAND-SQLITE-01",
                "890123497",
                quantityProduced: 10,
                expectedExpiry: DateTime.UtcNow.AddDays(5),
                locationId: Guid.NewGuid(),
                locationName: "Main Store",
                totalCost: 2000m);
            db.FinishedGoodsBatches.Add(finishedBatch);
            await db.SaveChangesAsync();

            // Flutter sends FinishedGoodsBatch.Id in cloudProductId
            var request = new PosSaleSyncRequest
            {
                ClientSyncId = "ready-bouquet-sqlite-fk-sync",
                LocalOrderId = 902,
                Order = new PosSaleOrderSnapshot
                {
                    OrderNo = "POS-SQLITE-902",
                    GrandTotalPaise = 300000,
                    SubtotalPaise = 300000,
                    GstTotalPaise = 0,
                    DiscountTotalPaise = 0,
                    RoundOffPaise = 0,
                    RewardDiscountAmountPaise = 0,
                    RewardPointsEarned = 0,
                    RewardPointsRedeemed = 0,
                    CustomerName = "Walk-in",
                    CustomerPhone = "9988776655"
                },
                Lines = new List<PosSaleLineSnapshot>
                {
                    new()
                    {
                        Id = 1,
                        CloudProductId = finishedBatch.Id,
                        Description = "Grand Celebration Bouquet",
                        Qty = 2,
                        UnitPricePaise = 150000,
                        LineSubtotalPaise = 300000,
                        LineTotalPaise = 300000,
                        Source = "product"
                    }
                },
                InventoryTransactions = new List<PosSaleInventoryTransactionSnapshot>
                {
                    new()
                    {
                        Id = 1,
                        CloudProductId = finishedBatch.Id,
                        Qty = 2,
                        CreatedAt = DateTime.UtcNow
                    }
                },
                Payments = new List<PosSalePaymentSnapshot>
                {
                    new() { Id = 1, Method = "Cash", AmountPaise = 300000 }
                }
            };

            var response = await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "sqlite-fk-hash");
            Assert.Equal("completed", response.SyncStatus);

            // 1. Verify PosSaleSyncOrderLine.CloudProductId matches an existing catalogue product in db.Products
            var orderLine = await db.PosSaleSyncOrderLines.SingleAsync(l => l.CloudOrderId == response.CloudOrderId);
            Assert.NotNull(orderLine.CloudProductId);
            Assert.NotEqual(finishedBatch.Id, orderLine.CloudProductId);

            var catalogueProduct = await db.Products.SingleAsync(p => p.Id == orderLine.CloudProductId!.Value);
            Assert.Equal("Grand Celebration Bouquet", catalogueProduct.Name);
            Assert.Equal(catalogueProduct.Id, orderLine.CloudProductId);

            // 2. Verify OrderItem uses the catalogue Product.Id and not FinishedGoodsBatch.Id
            var order = await db.Orders.Include(o => o.Items).SingleAsync(o => o.Id == response.CloudOrderId);
            var orderItem = Assert.Single(order.Items);
            Assert.Equal(catalogueProduct.Id, orderItem.ProductId);
            Assert.NotEqual(finishedBatch.Id, orderItem.ProductId);

            // 3. Verify InventoryTransaction uses the catalogue Product.Id and not FinishedGoodsBatch.Id
            var inventoryTx = await db.PosSaleSyncInventoryTransactions.SingleAsync(t => t.CloudOrderId == response.CloudOrderId);
            Assert.Equal(catalogueProduct.Id, inventoryTx.ProductId);
            Assert.NotEqual(finishedBatch.Id, inventoryTx.ProductId);

            // 4. Verify FinishedGoodsBatch.QuantityAvailable decreases exactly once (10 - 2 = 8)
            var updatedBatch = await db.FinishedGoodsBatches.SingleAsync(b => b.Id == finishedBatch.Id);
            Assert.Equal(8, updatedBatch.QuantityAvailable);

            // 5. Verify Product.StockQuantity is NOT decreased
            var updatedRaw = await db.Products.SingleAsync(p => p.Id == rawFlower.Id);
            Assert.Equal(100, updatedRaw.StockQuantity);
            Assert.Equal(0, catalogueProduct.StockQuantity);
        }
    }

    [Fact]
    public async Task ReadyBouquetPosSale_RelationalSqlite_RejectsFinishedBatchIdAsCloudProductId()
    {
        var (db, connection) = CreateSqliteDb();
        await using (connection)
        await using (db)
        {
            var customer = new Customer(_companyId, "Walk-in Customer", null, "9988776655");
            db.Customers.Add(customer);

            var order = new Order(_companyId, customer.Id, DateTime.UtcNow, null, null, null, null);
            order.SetImportedOrderNumber("POS-SQLITE-ERR");
            order.SetImportedPosFinancials(3000m, 0m, 0m, 3000m, 0m, 0m, 0, 0);
            db.Orders.Add(order);

            var receipt = new PosSaleSyncReceipt(_companyId, "sync-negative-sqlite-test", 903, "device-1", order.Id, customer.Id, "hash-neg-sqlite", DateTime.UtcNow);
            db.PosSaleSyncReceipts.Add(receipt);

            var finishedBatch = new FinishedGoodsBatch(
                _companyId,
                Guid.NewGuid(),
                "Grand Celebration Bouquet",
                "FGB-GRAND-SQLITE-ERR",
                "890123496",
                quantityProduced: 10,
                expectedExpiry: DateTime.UtcNow.AddDays(5),
                locationId: Guid.NewGuid(),
                locationName: "Main Store",
                totalCost: 2000m);
            db.FinishedGoodsBatches.Add(finishedBatch);

            await db.SaveChangesAsync();

            // Deliberately simulate the old production bug:
            // PosSaleSyncOrderLine.CloudProductId is assigned FinishedGoodsBatch.Id (which does not exist in Products table)
            var buggyOrderLine = new PosSaleSyncOrderLine(
                _companyId,
                receipt.Id,
                order.Id,
                "sync-negative-sqlite-test:1",
                1,
                null,
                finishedBatch.Id, // FinishedGoodsBatch.Id passed instead of catalogue Product.Id!
                "product",
                null,
                "Grand Celebration Bouquet",
                2,
                1500m,
                0m,
                null,
                null,
                0m,
                3000m,
                0m,
                3000m);
            db.PosSaleSyncOrderLines.Add(buggyOrderLine);

            var ex = await Assert.ThrowsAsync<DbUpdateException>(() => db.SaveChangesAsync());
            Assert.Contains("FOREIGN KEY", ex.InnerException?.Message ?? ex.Message, StringComparison.OrdinalIgnoreCase);
        }
    }

    [Fact]
    public async Task FinishedGoodsBatchSale_WithInsufficientStock_ThrowsInvalidOperationException()
    {
        await using var db = CreateDb();
        var finishedBatch = new FinishedGoodsBatch(
            _companyId,
            Guid.NewGuid(),
            "Small Bouquet",
            "FGB-SM-1",
            "890123457",
            quantityProduced: 1,
            expectedExpiry: DateTime.UtcNow.AddDays(7),
            locationId: Guid.NewGuid(),
            locationName: "Main Store",
            totalCost: 200m);
        db.FinishedGoodsBatches.Add(finishedBatch);
        await db.SaveChangesAsync();

        var request = new PosSaleSyncRequest
        {
            ClientSyncId = "insufficient-fg-sync",
            LocalOrderId = 702,
            Order = new PosSaleOrderSnapshot
            {
                OrderNo = "POS-FG-2",
                GrandTotalPaise = 60000,
                SubtotalPaise = 60000,
                CustomerPhone = "9988776655"
            },
            Lines = new List<PosSaleLineSnapshot>
            {
                new()
                {
                    Id = 1,
                    CloudProductId = finishedBatch.Id,
                    Description = "Small Bouquet",
                    Qty = 2, // Requested 2 when only 1 is available
                    UnitPricePaise = 30000,
                    LineSubtotalPaise = 60000,
                    LineTotalPaise = 60000,
                    Source = "product"
                }
            },
            InventoryTransactions = new List<PosSaleInventoryTransactionSnapshot>
            {
                new()
                {
                    Id = 1,
                    CloudProductId = finishedBatch.Id,
                    Qty = 2,
                    CreatedAt = DateTime.UtcNow
                }
            },
            Payments = new List<PosSalePaymentSnapshot>
            {
                new() { Id = 1, Method = "Cash", AmountPaise = 60000 }
            }
        };

        var ex = await Assert.ThrowsAsync<InvalidOperationException>(
            () => Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "insufficient-fg-hash"));

        Assert.Contains("Insufficient stock", ex.Message);
        var unchangedBatch = await db.FinishedGoodsBatches.SingleAsync(b => b.Id == finishedBatch.Id);
        Assert.Equal(1, unchangedBatch.QuantityAvailable); // Still 1, no partial deduction
    }

    [Fact]
    public async Task FinishedGoodsBatchSale_WithBothLineAndInventoryTransaction_DeductsBatchQuantityOnlyOnce()
    {
        await using var db = CreateDb();
        var finishedBatch = new FinishedGoodsBatch(
            _companyId,
            Guid.NewGuid(),
            "Orchid Bouquet",
            "FGB-ORCHID-1",
            "890123458",
            quantityProduced: 10,
            expectedExpiry: DateTime.UtcNow.AddDays(7),
            locationId: Guid.NewGuid(),
            locationName: "Main Store",
            totalCost: 1500m);
        db.FinishedGoodsBatches.Add(finishedBatch);
        await db.SaveChangesAsync();

        var request = new PosSaleSyncRequest
        {
            ClientSyncId = "single-deduction-fg-sync",
            LocalOrderId = 703,
            Order = new PosSaleOrderSnapshot
            {
                OrderNo = "POS-FG-3",
                GrandTotalPaise = 150000,
                SubtotalPaise = 150000,
                CustomerPhone = "9988776655"
            },
            Lines = new List<PosSaleLineSnapshot>
            {
                new()
                {
                    Id = 1,
                    CloudProductId = finishedBatch.Id,
                    Description = "Orchid Bouquet",
                    Qty = 3,
                    UnitPricePaise = 50000,
                    LineSubtotalPaise = 150000,
                    LineTotalPaise = 150000,
                    Source = "product"
                }
            },
            InventoryTransactions = new List<PosSaleInventoryTransactionSnapshot>
            {
                new()
                {
                    Id = 1,
                    CloudProductId = finishedBatch.Id,
                    Qty = 3,
                    CreatedAt = DateTime.UtcNow
                }
            },
            Payments = new List<PosSalePaymentSnapshot>
            {
                new() { Id = 1, Method = "Cash", AmountPaise = 150000 }
            }
        };

        var response = await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "single-deduct-hash");
        Assert.Equal("completed", response.SyncStatus);

        var updatedBatch = await db.FinishedGoodsBatches.SingleAsync(b => b.Id == finishedBatch.Id);
        Assert.Equal(7, updatedBatch.QuantityAvailable); // Deducted 3 exactly once, NOT 6!
    }

    [Fact]
    public async Task EventSale_WithFinishedBouquet_WhenAvailableStockIsLowerThanRequested_SucceedsWithoutDeductingBatchStock()
    {
        await using var db = CreateDb();
        var finishedBatch = new FinishedGoodsBatch(
            _companyId,
            Guid.NewGuid(),
            "20 red roses basket",
            "FGB-ROSE-20",
            "890123499",
            quantityProduced: 1,
            expectedExpiry: DateTime.UtcNow.AddDays(7),
            locationId: Guid.NewGuid(),
            locationName: "Main Store",
            totalCost: 500m);
        db.FinishedGoodsBatches.Add(finishedBatch);
        await db.SaveChangesAsync();

        var request = new PosSaleSyncRequest
        {
            ClientSyncId = "event-sale-low-stock-sync",
            LocalOrderId = 801,
            Order = new PosSaleOrderSnapshot
            {
                OrderNo = "EVT-2026-001",
                CustomerName = "Event Organizer",
                CustomerPhone = "9876543210",
                Source = "walkIn",
                Channel = "retail",
                FulfilmentType = "event_sale",
                SubtotalPaise = 200000,
                GrandTotalPaise = 200000,
                ConfirmedAt = DateTime.UtcNow
            },
            Lines = new List<PosSaleLineSnapshot>
            {
                new()
                {
                    Id = 1,
                    CloudProductId = finishedBatch.Id,
                    Description = "20 red roses basket",
                    Qty = 2, // Requested 2 when available is only 1
                    UnitPricePaise = 100000,
                    LineSubtotalPaise = 200000,
                    LineTotalPaise = 200000,
                    Source = "product"
                }
            },
            InventoryTransactions = new List<PosSaleInventoryTransactionSnapshot>(), // Flutter sends empty for event_sale
            Payments = new List<PosSalePaymentSnapshot>
            {
                new() { Id = 1, Method = "Cash", AmountPaise = 200000 }
            }
        };

        var response = await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "event-sale-low-stock-hash");
        Assert.Equal("completed", response.SyncStatus);

        var batchInDb = await db.FinishedGoodsBatches.SingleAsync(b => b.Id == finishedBatch.Id);
        Assert.Equal(1, batchInDb.QuantityAvailable); // Untouched physical stock

        var order = await db.Orders.Include(o => o.Items).SingleAsync(o => o.Id == response.CloudOrderId);
        Assert.Equal(2000m, order.TotalAmount);
        Assert.Single(order.Items);
        Assert.Equal("20 red roses basket", order.Items.Single().ProductName);
        Assert.Equal(2, order.Items.Single().Quantity);
    }

    [Fact]
    public async Task EventSale_WithFinishedBouquet_WhenAvailableStockIsSufficient_SucceedsWithoutDeductingBatchStock()
    {
        await using var db = CreateDb();
        var finishedBatch = new FinishedGoodsBatch(
            _companyId,
            Guid.NewGuid(),
            "20 red roses basket",
            "FGB-ROSE-20-B",
            "890123498",
            quantityProduced: 10,
            expectedExpiry: DateTime.UtcNow.AddDays(7),
            locationId: Guid.NewGuid(),
            locationName: "Main Store",
            totalCost: 5000m);
        db.FinishedGoodsBatches.Add(finishedBatch);
        await db.SaveChangesAsync();

        var request = new PosSaleSyncRequest
        {
            ClientSyncId = "event-sale-sufficient-stock-sync",
            LocalOrderId = 802,
            Order = new PosSaleOrderSnapshot
            {
                OrderNo = "EVT-2026-002",
                CustomerName = "Event Organizer",
                CustomerPhone = "9876543210",
                Source = "walkIn",
                Channel = "retail",
                FulfilmentType = "event_sale",
                SubtotalPaise = 300000,
                GrandTotalPaise = 300000,
                ConfirmedAt = DateTime.UtcNow
            },
            Lines = new List<PosSaleLineSnapshot>
            {
                new()
                {
                    Id = 1,
                    CloudProductId = finishedBatch.Id,
                    Description = "20 red roses basket",
                    Qty = 3,
                    UnitPricePaise = 100000,
                    LineSubtotalPaise = 300000,
                    LineTotalPaise = 300000,
                    Source = "product"
                }
            },
            InventoryTransactions = new List<PosSaleInventoryTransactionSnapshot>(),
            Payments = new List<PosSalePaymentSnapshot>
            {
                new() { Id = 1, Method = "Cash", AmountPaise = 300000 }
            }
        };

        var response = await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "event-sale-suff-stock-hash");
        Assert.Equal("completed", response.SyncStatus);

        var batchInDb = await db.FinishedGoodsBatches.SingleAsync(b => b.Id == finishedBatch.Id);
        Assert.Equal(10, batchInDb.QuantityAvailable); // Untouched physical stock
    }

    [Fact]
    public async Task EventSale_WithCatalogProduct_CreatesNoInventoryLedgerMovementAndDoesNotDeductStock()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db); // StockQuantity = 10, TrackInventory = true
        await db.SaveChangesAsync();

        var request = new PosSaleSyncRequest
        {
            ClientSyncId = "event-sale-catalog-prod-sync",
            LocalOrderId = 803,
            Order = new PosSaleOrderSnapshot
            {
                OrderNo = "EVT-2026-003",
                CustomerName = "Event Organizer",
                CustomerPhone = "9876543210",
                Source = "walkIn",
                Channel = "retail",
                FulfilmentType = "event_sale",
                SubtotalPaise = 2997,
                GrandTotalPaise = 2997,
                ConfirmedAt = DateTime.UtcNow
            },
            Lines = new List<PosSaleLineSnapshot>
            {
                new()
                {
                    Id = 1,
                    LocalProductId = 101,
                    CloudProductId = product.Id,
                    Description = product.Name,
                    Qty = 3,
                    UnitPricePaise = 999,
                    LineSubtotalPaise = 2997,
                    LineTotalPaise = 2997,
                    Source = "product"
                }
            },
            InventoryTransactions = new List<PosSaleInventoryTransactionSnapshot>(), // Flutter sends empty for event_sale
            Payments = new List<PosSalePaymentSnapshot>
            {
                new() { Id = 1, Method = "Cash", AmountPaise = 2997 }
            }
        };

        var response = await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "event-sale-cat-hash");
        Assert.Equal("completed", response.SyncStatus);

        var productInDb = await db.Products.SingleAsync(p => p.Id == product.Id);
        Assert.Equal(10, productInDb.StockQuantity); // Stock not deducted
        Assert.Empty(db.InventoryLedgers); // No ledger movement
    }

    [Fact]
    public async Task TakeAway_WithFinishedBouquet_WhenAvailableStockIsLowerThanRequested_ThrowsInvalidOperationException()
    {
        await using var db = CreateDb();
        var finishedBatch = new FinishedGoodsBatch(
            _companyId,
            Guid.NewGuid(),
            "20 red roses basket",
            "FGB-ROSE-20-TA",
            "890123497",
            quantityProduced: 1,
            expectedExpiry: DateTime.UtcNow.AddDays(7),
            locationId: Guid.NewGuid(),
            locationName: "Main Store",
            totalCost: 500m);
        db.FinishedGoodsBatches.Add(finishedBatch);
        await db.SaveChangesAsync();

        var request = new PosSaleSyncRequest
        {
            ClientSyncId = "take-away-low-stock-sync",
            LocalOrderId = 804,
            Order = new PosSaleOrderSnapshot
            {
                OrderNo = "POS-TA-001",
                CustomerName = "Walk-in Customer",
                CustomerPhone = "9876543210",
                Source = "walkIn",
                Channel = "retail",
                FulfilmentType = "take_away",
                SubtotalPaise = 200000,
                GrandTotalPaise = 200000,
                ConfirmedAt = DateTime.UtcNow
            },
            Lines = new List<PosSaleLineSnapshot>
            {
                new()
                {
                    Id = 1,
                    CloudProductId = finishedBatch.Id,
                    Description = "20 red roses basket",
                    Qty = 2, // Requested 2 when available is 1
                    UnitPricePaise = 100000,
                    LineSubtotalPaise = 200000,
                    LineTotalPaise = 200000,
                    Source = "product"
                }
            },
            InventoryTransactions = new List<PosSaleInventoryTransactionSnapshot>
            {
                new()
                {
                    Id = 1,
                    CloudProductId = finishedBatch.Id,
                    Qty = 2,
                    CreatedAt = DateTime.UtcNow
                }
            },
            Payments = new List<PosSalePaymentSnapshot>
            {
                new() { Id = 1, Method = "Cash", AmountPaise = 200000 }
            }
        };

        var ex = await Assert.ThrowsAsync<InvalidOperationException>(
            () => Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "take-away-low-stock-hash"));

        Assert.Contains("Insufficient stock for finished bouquet", ex.Message);
        var batchInDb = await db.FinishedGoodsBatches.SingleAsync(b => b.Id == finishedBatch.Id);
        Assert.Equal(1, batchInDb.QuantityAvailable); // Still 1
    }

    [Fact]
    public async Task EventSale_PosSaleSync_CreatesOrderWithEventSaleFulfilmentType_AndCanBeFilteredInWorkspace()
    {
        await using var db = CreateDb();
        var product = SeedProduct(db);
        await db.SaveChangesAsync();

        var request = Request(product);
        request.Order.OrderNo = "POS-EVENT-999";
        request.Order.FulfilmentType = "event_sale";
        request.Order.DeliveryAddress = "Grand Ballroom, Hotel Taj"; // Event venue
        request.InventoryTransactions = new List<PosSaleInventoryTransactionSnapshot>(); // Event sale sends empty inventory transactions

        var syncResponse = await Service(db).SyncAsync(_companyId, _mobileUserId, _identityUserId, "device-1", request, "event-999-hash");
        Assert.Equal("completed", syncResponse.SyncStatus);

        // 1. Check workspace read without filter
        var controller = OrdersController(db);
        var workspaceResult = await controller.Workspace(new MobileOrderWorkspaceRequest { PageSize = 20 }, CancellationToken.None);
        var workspaceResponse = Assert.IsType<MobileOrderWorkspaceResponse>(Assert.IsType<OkObjectResult>(workspaceResult).Value);
        var eventItem = Assert.Single(workspaceResponse.Items, i => i.OrderNumber == "POS-EVENT-999");
        Assert.Equal("event_sale", eventItem.FulfilmentType);

        // 2. Check detail read
        var detailResult = await controller.GetById(syncResponse.CloudOrderId, CancellationToken.None);
        var detail = Assert.IsType<MobileOrderDetailDto>(Assert.IsType<OkObjectResult>(detailResult).Value);
        Assert.Equal("event_sale", detail.FulfilmentType);

        // 3. Check workspace filter by event_sale returns this order
        var filterResult = await controller.Workspace(new MobileOrderWorkspaceRequest { FulfilmentType = "event_sale" }, CancellationToken.None);
        var filterResponse = Assert.IsType<MobileOrderWorkspaceResponse>(Assert.IsType<OkObjectResult>(filterResult).Value);
        var filteredEvent = Assert.Single(filterResponse.Items);
        Assert.Equal("POS-EVENT-999", filteredEvent.OrderNumber);
        Assert.Equal("event_sale", filteredEvent.FulfilmentType);

        // 4. Check workspace filter by delivery does NOT return event sale
        var deliveryFilterResult = await controller.Workspace(new MobileOrderWorkspaceRequest { FulfilmentType = "delivery" }, CancellationToken.None);
        var deliveryFilterResponse = Assert.IsType<MobileOrderWorkspaceResponse>(Assert.IsType<OkObjectResult>(deliveryFilterResult).Value);
        Assert.DoesNotContain(deliveryFilterResponse.Items, i => i.OrderNumber == "POS-EVENT-999");
    }

    private MobileOrdersController OrdersController(SumpoojDbContext db) =>
        new(db, new TestTenantContext(_companyId));

    private static PosSaleLineSnapshot DesignLine(
        int id,
        string description,
        int unitPricePaise = 300000,
        int subtotalPaise = 254237,
        int gstPaise = 45763,
        int gstPercent = 18,
        string designRef = "data:image/jpeg;base64,abc123") => new()
    {
        Id = id,
        ProductId = null,
        LocalProductId = null,
        CloudProductId = null,
        Description = description,
        Qty = 1,
        UnitPricePaise = unitPricePaise,
        GstPercent = gstPercent,
        DiscountPaise = 0,
        LineSubtotalPaise = subtotalPaise,
        LineGstPaise = gstPaise,
        LineTotalPaise = unitPricePaise,
        Source = "design",
        DesignRef = designRef
    };

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

