using System.Security.Claims;
using System.Text.Json;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
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
