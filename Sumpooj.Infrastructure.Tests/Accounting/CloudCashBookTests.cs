using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.API.Controllers;
using Sumpooj.Application.Accounting;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;
using Sumpooj.Infrastructure.Repositories;
using Xunit;

namespace Sumpooj.Infrastructure.Tests.Accounting;

public class CloudCashBookTests
{
    [Theory]
    [InlineData("Cash", 1)]
    [InlineData("Upi", 0)]
    [InlineData("Card", 0)]
    public async Task CreateExpense_WritesCashBookOutflowOnlyForCash(string paymentMode, int expectedEntries)
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var controller = new AccountingController(db, new TenantContext(companyId), null!);

        var result = await controller.CreateExpense(new CreateExpenseRequest
        {
            Category = "Supplies",
            Amount = 125m,
            PaymentMode = paymentMode,
            ExpenseDate = "2026-09-08T00:00:00Z"
        });

        Assert.IsType<OkObjectResult>(result);
        Assert.Equal(expectedEntries, await db.CashBookEntries.CountAsync());
        Assert.Equal(Enum.Parse<ExpensePaymentMode>(paymentMode), (await db.Expenses.SingleAsync()).PaymentMode);
        if (expectedEntries == 1)
        {
            var entry = await db.CashBookEntries.SingleAsync();
            Assert.Equal(CashBookTransactionType.CashExpense, entry.TransactionType);
            Assert.Equal(125m, entry.CashOut);
            Assert.Equal(0m, entry.CashIn);
        }
    }

    [Fact]
    public async Task CashDrawerSummary_IsCompanyScopedAndUsesCashSalesAndExpenses()
    {
        var companyId = Guid.NewGuid();
        var otherCompanyId = Guid.NewGuid();
        var date = new DateTime(2026, 9, 8, 0, 0, 0, DateTimeKind.Utc);
        await using var db = CreateDb(companyId);
        db.OpeningCashEntries.Add(new OpeningCash(companyId, date, 100m));
        db.CashBookEntries.AddRange(
            new CashBookEntry(companyId, date, CashBookTransactionType.CashSale, "Sale", 500m, 500m, 0m, 600m),
            new CashBookEntry(companyId, date, CashBookTransactionType.CashExpense, "Expense", 50m, 0m, 50m, 550m),
            new CashBookEntry(otherCompanyId, date, CashBookTransactionType.CashSale, "Other company", 999m, 999m, 0m, 999m));
        await db.SaveChangesAsync();

        var summary = await new DayCloseRepository(db).GetSummaryAsync(companyId, date);

        Assert.Equal(100m, summary.OpeningCash);
        Assert.Equal(500m, summary.CashSales);
        Assert.Equal(50m, summary.CashExpenses);
        Assert.Equal(550m, summary.OpeningCash + summary.CashSales - summary.CashExpenses);
    }

    [Fact]
    public async Task CashBookRead_ReturnsOnlyTheAuthenticatedCompanyEntries()
    {
        var companyId = Guid.NewGuid();
        var otherCompanyId = Guid.NewGuid();
        var date = new DateTime(2026, 9, 8, 0, 0, 0, DateTimeKind.Utc);
        await using var db = CreateDb(companyId);
        db.CashBookEntries.AddRange(
            new CashBookEntry(companyId, date, CashBookTransactionType.CashSale, "Own sale", 200m, 200m, 0m, 200m),
            new CashBookEntry(otherCompanyId, date, CashBookTransactionType.CashSale, "Other sale", 300m, 300m, 0m, 300m));
        await db.SaveChangesAsync();
        var controller = new MobileFinanceController(db, new TenantContext(companyId));

        var result = await controller.GetCashBook(date, null, null, null);

        var ok = Assert.IsType<OkObjectResult>(result);
        var entries = Assert.IsAssignableFrom<IEnumerable<CashBookEntryDto>>(ok.Value);
        Assert.Equal("Own sale", Assert.Single(entries).Description);
    }

    private static SumpoojDbContext CreateDb(Guid companyId)
    {
        var options = new DbContextOptionsBuilder<SumpoojDbContext>()
            .UseInMemoryDatabase($"CloudCashBook_{Guid.NewGuid():N}")
            .Options;
        return new SumpoojDbContext(options, new TenantContext(companyId));
    }

    private sealed class TenantContext(Guid companyId) : ITenantContext
    {
        public Guid? CompanyId => companyId;
        public bool IsPlatformUser => false;
        public string? Region => null;
    }
}