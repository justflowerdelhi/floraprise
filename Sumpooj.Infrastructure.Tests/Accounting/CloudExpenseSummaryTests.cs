using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.API.Controllers;
using Sumpooj.Application.Accounting;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;
using Xunit;

namespace Sumpooj.Infrastructure.Tests.Accounting;

/// <summary>
/// Cloud Expense Report summary endpoint tests covering IST business-date
/// logic, payment-mode totals, and company isolation.
/// </summary>
public class CloudExpenseSummaryTests
{
    [Fact]
    public async Task ExpenseSummary_ForToday_ReturnsTodayOnlyExpenses()
    {
        var companyId = Guid.NewGuid();
        var today = GetServerLocalBusinessDate();
        var yesterday = today.AddDays(-1);
        await using var db = CreateDb(companyId);

        AddExpense(db, companyId, 100m, ExpensePaymentMode.Cash, ConvertBusinessDateToUtcTime(today));
        AddExpense(db, companyId, 50m, ExpensePaymentMode.Cash, ConvertBusinessDateToUtcTime(yesterday));
        await db.SaveChangesAsync();

        var controller = new MobileFinanceController(db, new TenantContext(companyId));
        var result = await controller.GetExpenseSummary(today, null, null);

        var dto = Assert.IsType<ExpenseSummaryDto>(Assert.IsType<OkObjectResult>(result).Value);
        Assert.Equal(1, dto.ExpenseCount);
        Assert.Equal(100m, dto.TotalAmount);
    }

    [Fact]
    public async Task ExpenseSummary_ForPreviousDate_ReturnsHistoricalExpenses()
    {
        var companyId = Guid.NewGuid();
        var today = GetServerLocalBusinessDate();
        var threeDaysAgo = today.AddDays(-3);
        await using var db = CreateDb(companyId);

        AddExpense(db, companyId, 75m, ExpensePaymentMode.Upi, ConvertBusinessDateToUtcTime(threeDaysAgo));
        AddExpense(db, companyId, 200m, ExpensePaymentMode.Cash, ConvertBusinessDateToUtcTime(today));
        await db.SaveChangesAsync();

        var controller = new MobileFinanceController(db, new TenantContext(companyId));
        var result = await controller.GetExpenseSummary(threeDaysAgo, null, null);

        var dto = Assert.IsType<ExpenseSummaryDto>(Assert.IsType<OkObjectResult>(result).Value);
        Assert.Equal(1, dto.ExpenseCount);
        Assert.Equal(75m, dto.TotalAmount);
    }

    [Fact]
    public async Task ExpenseSummary_WhenRangeIsProvided_IncludesAllDaysInRange()
    {
        var companyId = Guid.NewGuid();
        var baseDate = GetServerLocalBusinessDate();
        var day1 = baseDate.AddDays(-4);
        var day2 = baseDate.AddDays(-3);
        var dayOutside = baseDate.AddDays(-5);
        await using var db = CreateDb(companyId);

        AddExpense(db, companyId, 10m, ExpensePaymentMode.Cash, ConvertBusinessDateToUtcTime(day1));
        AddExpense(db, companyId, 20m, ExpensePaymentMode.Cash, ConvertBusinessDateToUtcTime(day2));
        AddExpense(db, companyId, 90m, ExpensePaymentMode.Cash, ConvertBusinessDateToUtcTime(dayOutside));
        await db.SaveChangesAsync();

        var controller = new MobileFinanceController(db, new TenantContext(companyId));
        var result = await controller.GetExpenseSummary(null, day1, day2);

        var dto = Assert.IsType<ExpenseSummaryDto>(Assert.IsType<OkObjectResult>(result).Value);
        Assert.Equal(2, dto.ExpenseCount);
        Assert.Equal(30m, dto.TotalAmount);
    }

    [Fact]
    public async Task ExpenseSummary_UsesIstBusinessDateBoundary_ForUtcTimesNearMidnight()
    {
        var companyId = Guid.NewGuid();
        var businessDate = GetServerLocalBusinessDate();
        await using var db = CreateDb(companyId);

        // 00:00 UTC = 05:30 IST same business day; 18:29 UTC = 23:59 IST same business day.
        AddExpense(db, companyId, 15m, ExpensePaymentMode.Cash, businessDate.Date.Add(new TimeSpan(0, 0, 0)));
        AddExpense(db, companyId, 25m, ExpensePaymentMode.Cash, businessDate.Date.Add(new TimeSpan(18, 29, 0)));
        await db.SaveChangesAsync();

        var controller = new MobileFinanceController(db, new TenantContext(companyId));
        var result = await controller.GetExpenseSummary(businessDate, null, null);

        var dto = Assert.IsType<ExpenseSummaryDto>(Assert.IsType<OkObjectResult>(result).Value);
        Assert.Equal(2, dto.ExpenseCount);
        Assert.Equal(40m, dto.TotalAmount);
    }

    [Fact]
    public async Task ExpenseSummary_CalculatesPaymentModeTotalsCorrectly()
    {
        var companyId = Guid.NewGuid();
        var today = GetServerLocalBusinessDate();
        await using var db = CreateDb(companyId);

        AddExpense(db, companyId, 100m, ExpensePaymentMode.Cash, ConvertBusinessDateToUtcTime(today));
        AddExpense(db, companyId, 50m, ExpensePaymentMode.Upi, ConvertBusinessDateToUtcTime(today));
        AddExpense(db, companyId, 25m, ExpensePaymentMode.Card, ConvertBusinessDateToUtcTime(today));
        await db.SaveChangesAsync();

        var controller = new MobileFinanceController(db, new TenantContext(companyId));
        var result = await controller.GetExpenseSummary(today, null, null);

        var dto = Assert.IsType<ExpenseSummaryDto>(Assert.IsType<OkObjectResult>(result).Value);
        Assert.Equal(3, dto.ExpenseCount);
        Assert.Equal(175m, dto.TotalAmount);
        Assert.Equal(100m, dto.CashAmount);
        Assert.Equal(50m, dto.UpiAmount);
        Assert.Equal(25m, dto.CardAmount);
    }

    [Fact]
    public async Task ExpenseSummary_ExcludesInactiveExpenses()
    {
        var companyId = Guid.NewGuid();
        var today = GetServerLocalBusinessDate();
        await using var db = CreateDb(companyId);

        var active = AddExpense(db, companyId, 30m, ExpensePaymentMode.Cash, ConvertBusinessDateToUtcTime(today));
        var inactive = AddExpense(db, companyId, 70m, ExpensePaymentMode.Cash, ConvertBusinessDateToUtcTime(today));
        inactive.Disable();
        await db.SaveChangesAsync();

        var controller = new MobileFinanceController(db, new TenantContext(companyId));
        var result = await controller.GetExpenseSummary(today, null, null);

        var dto = Assert.IsType<ExpenseSummaryDto>(Assert.IsType<OkObjectResult>(result).Value);
        Assert.Equal(1, dto.ExpenseCount);
        Assert.Equal(30m, dto.TotalAmount);
    }

    [Fact]
    public async Task ExpenseSummary_RespectsCompanyIsolation()
    {
        var companyId = Guid.NewGuid();
        var otherCompanyId = Guid.NewGuid();
        var today = GetServerLocalBusinessDate();
        await using var db = CreateDb(companyId);

        AddExpense(db, companyId, 40m, ExpensePaymentMode.Cash, ConvertBusinessDateToUtcTime(today));
        AddExpense(db, otherCompanyId, 999m, ExpensePaymentMode.Cash, ConvertBusinessDateToUtcTime(today));
        await db.SaveChangesAsync();

        var controller = new MobileFinanceController(db, new TenantContext(companyId));
        var result = await controller.GetExpenseSummary(today, null, null);

        var dto = Assert.IsType<ExpenseSummaryDto>(Assert.IsType<OkObjectResult>(result).Value);
        Assert.Equal(1, dto.ExpenseCount);
        Assert.Equal(40m, dto.TotalAmount);
    }

    private static Expense AddExpense(SumpoojDbContext db, Guid companyId, decimal amount, ExpensePaymentMode mode, DateTime expenseDateUtc)
    {
        var expense = new Expense(companyId, "Supplies", amount, null, expenseDateUtc);
        expense.SetPaymentMode(mode);
        db.Expenses.Add(expense);
        return expense;
    }

    private static DateTime GetServerLocalBusinessDate()
    {
        if (TimeZoneInfo.TryFindSystemTimeZoneById("Asia/Kolkata", out var tz) ||
            TimeZoneInfo.TryFindSystemTimeZoneById("India Standard Time", out tz))
        {
            var localNow = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, tz);
            return DateTime.SpecifyKind(localNow.Date, DateTimeKind.Utc);
        }
        return DateTime.SpecifyKind(DateTime.Now.Date, DateTimeKind.Utc);
    }

    private static DateTime ConvertBusinessDateToUtcTime(DateTime businessDate)
    {
        if (TimeZoneInfo.TryFindSystemTimeZoneById("Asia/Kolkata", out var tz) ||
            TimeZoneInfo.TryFindSystemTimeZoneById("India Standard Time", out tz))
        {
            var istMidday = new DateTime(businessDate.Year, businessDate.Month, businessDate.Day, 12, 0, 0);
            return TimeZoneInfo.ConvertTimeToUtc(istMidday, tz);
        }
        return businessDate;
    }

    private static SumpoojDbContext CreateDb(Guid companyId)
    {
        var options = new DbContextOptionsBuilder<SumpoojDbContext>()
            .UseInMemoryDatabase($"CloudExpenseSummary_{Guid.NewGuid():N}")
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
