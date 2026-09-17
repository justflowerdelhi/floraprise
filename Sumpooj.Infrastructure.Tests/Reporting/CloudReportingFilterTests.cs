using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.API.Controllers;
using Sumpooj.Application.Accounting;
using Sumpooj.Application.Common;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Production;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;
using Sumpooj.Infrastructure.Repositories;

namespace Sumpooj.Infrastructure.Tests.Reporting;

public class CloudReportingFilterTests
{
    private sealed class TenantContext(Guid companyId) : ITenantContext
    {
        public Guid? CompanyId => companyId;
        public bool IsPlatformUser => false;
        public string? Region => null;
    }

    // ─── Accounting date filters ────────────────────────────

    [Fact]
    public async Task ProfitLossHonoursDateRangeAndKeepsLifetimeBehaviourWhenOmitted()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var income = new Account(companyId, "4000", "Sales", "Income");
        var expense = new Account(companyId, "6000", "Rent Expense", "Expense");
        db.AddRange(income, expense);
        db.AddRange(
            Journal(companyId, new DateTime(2026, 1, 10, 0, 0, 0, DateTimeKind.Utc), credit: 1000m, accountId: income.Id),
            Journal(companyId, new DateTime(2026, 3, 10, 0, 0, 0, DateTimeKind.Utc), credit: 500m, accountId: income.Id),
            Journal(companyId, new DateTime(2026, 3, 10, 0, 0, 0, DateTimeKind.Utc), debit: 200m, accountId: expense.Id));
        await db.SaveChangesAsync();
        var controller = CreateAccountingController(db, companyId);

        var all = Unwrap<ProfitLossDto>(await controller.GetProfitLoss(null, null));
        Assert.Equal(1500m, all.Revenue);
        Assert.Equal(200m, all.Expenses);
        Assert.Equal(1300m, all.NetProfit);

        var march = Unwrap<ProfitLossDto>(await controller.GetProfitLoss(
            new DateTime(2026, 3, 1, 0, 0, 0, DateTimeKind.Utc),
            new DateTime(2026, 3, 31, 0, 0, 0, DateTimeKind.Utc)));
        Assert.Equal(500m, march.Revenue);
        Assert.Equal(200m, march.Expenses);
        Assert.Equal(300m, march.NetProfit);
    }

    [Fact]
    public async Task JournalAndLedgerHonourDateRangeAndLedgerCarriesOpeningBalance()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var account = new Account(companyId, "1000", "Cash", "Asset");
        db.Add(account);
        db.AddRange(
            Journal(companyId, new DateTime(2026, 1, 5, 0, 0, 0, DateTimeKind.Utc), debit: 300m, accountId: account.Id),
            Journal(companyId, new DateTime(2026, 2, 5, 0, 0, 0, DateTimeKind.Utc), debit: 100m, accountId: account.Id),
            Journal(companyId, new DateTime(2026, 2, 6, 0, 0, 0, DateTimeKind.Utc), credit: 50m, accountId: account.Id));
        await db.SaveChangesAsync();
        var controller = CreateAccountingController(db, companyId);

        var allJournal = Unwrap<List<JournalEntryDto>>(await controller.GetJournalEntries(null, null));
        Assert.Equal(3, allJournal.Count);

        var februaryJournal = Unwrap<List<JournalEntryDto>>(await controller.GetJournalEntries(
            new DateTime(2026, 2, 1, 0, 0, 0, DateTimeKind.Utc),
            new DateTime(2026, 2, 28, 0, 0, 0, DateTimeKind.Utc)));
        Assert.Equal(2, februaryJournal.Count);

        var februaryLedger = Unwrap<List<LedgerEntryDto>>(await controller.GetLedger(
            account.Id,
            new DateTime(2026, 2, 1, 0, 0, 0, DateTimeKind.Utc),
            new DateTime(2026, 2, 28, 0, 0, 0, DateTimeKind.Utc)));
        Assert.Equal(2, februaryLedger.Count);
        Assert.Equal(400m, februaryLedger[0].Balance);
        Assert.Equal(350m, februaryLedger[1].Balance);
    }

    [Fact]
    public async Task TaxSummaryHonoursDateRange()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var order = SeedOrder(db, companyId, subTotalUnitPrice: 100m, taxAmount: 18m);
        await db.SaveChangesAsync();
        var controller = CreateAccountingController(db, companyId);

        var today = order.OrderDate.Date;
        var included = Unwrap<List<TaxSummaryDto>>(await controller.GetTaxSummary(today, today));
        Assert.Equal(18m, included.Single().TaxAmount);

        var excluded = Unwrap<List<TaxSummaryDto>>(await controller.GetTaxSummary(today.AddDays(1), today.AddDays(2)));
        Assert.Equal(0m, excluded.Single().TaxAmount);
        Assert.Equal(0m, excluded.Single().Rate);
    }

    [Fact]
    public async Task DashboardReturnsRewardPointTotals()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var first = SeedOrder(db, companyId, subTotalUnitPrice: 100m, taxAmount: 0m);
        first.SetRewardPoints(30, 10);
        var second = SeedOrder(db, companyId, subTotalUnitPrice: 50m, taxAmount: 0m);
        second.SetRewardPoints(12, 5);
        await db.SaveChangesAsync();
        var controller = CreateAccountingController(db, companyId);

        var dashboard = Unwrap<AccountingDashboardDto>(await controller.GetDashboard());
        Assert.Equal(42, dashboard.RewardPointsEarned);
        Assert.Equal(15, dashboard.RewardPointsRedeemed);
    }

    // ─── Wastage filters ────────────────────────────────────

    [Fact]
    public async Task WastageLogsFilterByDateProductCategoryAndReason()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var rose = new Product(companyId, "Rose", "ROSE", ProductType.SingleFlower, ProductCategory.Roses, 10m, 5m, null);
        var lily = new Product(companyId, "Lily", "LILY", ProductType.SingleFlower, ProductCategory.Lilies, 10m, 5m, null);
        db.AddRange(rose, lily);

        var oldRose = new ProductionWastageLog(companyId, rose.Id, "Rose", 2, WastageReason.Spoiled, null, null);
        var newRose = new ProductionWastageLog(companyId, rose.Id, "Rose", 3, WastageReason.Damaged, null, null);
        var newLily = new ProductionWastageLog(companyId, lily.Id, "Lily", 4, WastageReason.Spoiled, null, null);
        db.AddRange(oldRose, newRose, newLily);
        await db.SaveChangesAsync();

        // CreatedAtUtc is assigned by the base entity, so age one row explicitly.
        db.Entry(oldRose).Property(nameof(BaseEntity.CreatedAtUtc)).CurrentValue = DateTime.UtcNow.AddDays(-30);
        await db.SaveChangesAsync();
        db.ChangeTracker.Clear();

        var repo = new ProductionWastageLogRepository(db);

        Assert.Equal(3, (await repo.GetAllAsync(companyId)).Count);
        Assert.Equal(3, (await repo.GetAllAsync(companyId, new WastageLogFilter())).Count);

        var recent = await repo.GetAllAsync(companyId, new WastageLogFilter { From = DateTime.UtcNow.AddDays(-1) });
        Assert.Equal(2, recent.Count);

        var roseOnly = await repo.GetAllAsync(companyId, new WastageLogFilter { ProductId = rose.Id });
        Assert.Equal(2, roseOnly.Count);

        var lilyCategory = await repo.GetAllAsync(companyId, new WastageLogFilter { Category = ProductCategory.Lilies });
        Assert.Equal(lily.Id, Assert.Single(lilyCategory).ProductId);

        var damaged = await repo.GetAllAsync(companyId, new WastageLogFilter { Reason = WastageReason.Damaged });
        Assert.Equal(3, Assert.Single(damaged).Quantity);

        var combined = await repo.GetAllAsync(companyId, new WastageLogFilter
        {
            From = DateTime.UtcNow.AddDays(-1),
            ProductId = rose.Id,
            Reason = WastageReason.Damaged,
        });
        Assert.Single(combined);
    }

    // ─── CRM lifetime value sorting ─────────────────────────

    [Fact]
    public async Task CustomersSortByLifetimeValueBeforePaging()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var small = new Customer(companyId, "Small Spender", null, "9000000001");
        var big = new Customer(companyId, "Big Spender", null, "9000000002");
        var none = new Customer(companyId, "No Orders", null, "9000000003");
        db.AddRange(small, big, none);
        SeedOrder(db, companyId, subTotalUnitPrice: 100m, taxAmount: 0m, customerId: small.Id);
        SeedOrder(db, companyId, subTotalUnitPrice: 900m, taxAmount: 0m, customerId: big.Id);
        await db.SaveChangesAsync();

        var controller = new CrmController(db, new TenantContext(companyId));

        var sorted = Unwrap<PagedResult<CrmCustomerDto>>(
            await controller.GetCustomers(new CrmCustomerListRequest(null, null, 1, 1, "lifetimeValue")));
        Assert.Equal(3, sorted.TotalCount);
        Assert.Equal("Big Spender", Assert.Single(sorted.Items).Name);

        var secondPage = Unwrap<PagedResult<CrmCustomerDto>>(
            await controller.GetCustomers(new CrmCustomerListRequest(null, null, 2, 1, "lifetimeValue")));
        Assert.Equal("Small Spender", Assert.Single(secondPage.Items).Name);

        var defaultOrder = Unwrap<PagedResult<CrmCustomerDto>>(
            await controller.GetCustomers(new CrmCustomerListRequest(null, null, 1, 10)));
        Assert.Equal(3, defaultOrder.Items.Count);
    }

    // ─── Low stock / reorder company scoping ────────────────

    [Fact]
    public async Task LowStockAndReorderQueriesAreCompanyScoped()
    {
        var companyId = Guid.NewGuid();
        var otherCompanyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);

        var mine = new Product(companyId, "Mine", "MINE", ProductType.SingleFlower, ProductCategory.Roses, 10m, 5m, null);
        mine.SetMinimumStockLevel(5);
        mine.SetInventorySettings(true, false, 5);
        var theirs = new Product(otherCompanyId, "Theirs", "THEIRS", ProductType.SingleFlower, ProductCategory.Roses, 10m, 5m, null);
        theirs.SetMinimumStockLevel(5);
        theirs.SetInventorySettings(true, false, 5);
        db.AddRange(mine, theirs);
        await db.SaveChangesAsync();
        db.ChangeTracker.Clear();

        var repo = new ProductRepository(db);

        var lowStock = await repo.GetLowStockProductsAsync(companyId);
        Assert.Equal("Mine", Assert.Single(lowStock).Name);

        var reorder = await repo.GetProductsNeedingReorderAsync(companyId);
        Assert.Equal("Mine", Assert.Single(reorder).Name);

        Assert.Empty(await repo.GetLowStockProductsAsync(Guid.NewGuid()));
        Assert.Empty(await repo.GetProductsNeedingReorderAsync(Guid.NewGuid()));
    }

    // ─── Helpers ────────────────────────────────────────────

    private static JournalEntry Journal(
        Guid companyId,
        DateTime date,
        Guid accountId,
        decimal debit = 0m,
        decimal credit = 0m) =>
        new(companyId, date, "REF", "TEST", "Test entry", debit, credit, accountId);

    private static Order SeedOrder(
        SumpoojDbContext db,
        Guid companyId,
        decimal subTotalUnitPrice,
        decimal taxAmount,
        Guid? customerId = null)
    {
        var order = new Order(companyId, customerId ?? Guid.NewGuid(), DateTime.UtcNow, null, null, null, null);
        order.AddItem(Guid.NewGuid(), "Item", 1, subTotalUnitPrice);
        order.SetTaxAmount(taxAmount);
        db.Add(order);
        return order;
    }

    private static AccountingController CreateAccountingController(SumpoojDbContext db, Guid companyId) =>
        new(db, new TenantContext(companyId), null!);

    private static T Unwrap<T>(IActionResult result) =>
        (T)Assert.IsType<OkObjectResult>(result).Value!;

    private static T Unwrap<T>(ActionResult<T> result) =>
        (T)Assert.IsType<OkObjectResult>(result.Result).Value!;

    private static SumpoojDbContext CreateDb(Guid companyId)
    {
        var options = new DbContextOptionsBuilder<SumpoojDbContext>()
            .UseInMemoryDatabase($"CloudReporting_{Guid.NewGuid():N}")
            .Options;
        return new SumpoojDbContext(options, new TenantContext(companyId));
    }
}
