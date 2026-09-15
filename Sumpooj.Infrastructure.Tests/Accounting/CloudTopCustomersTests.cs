using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.API.Controllers;
using Sumpooj.Application.Accounting;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;
using Xunit;

namespace Sumpooj.Infrastructure.Tests.Accounting;

public class CloudTopCustomersTests
{
    [Fact]
    public async Task TopCustomers_SupportsTodayPreviousDateAndMultiDayRanges()
    {
        var companyId = Guid.NewGuid();
        var today = GetBusinessDate();
        var previous = today.AddDays(-1);
        await using var db = CreateDb(companyId);
        var customer = AddCustomer(db, companyId, "Range Customer");
        AddOrder(db, companyId, customer, 100m, ConvertBusinessDateToUtcTime(today));
        AddOrder(db, companyId, customer, 40m, ConvertBusinessDateToUtcTime(previous));
        await db.SaveChangesAsync();
        var controller = new MobileFinanceController(db, new TenantContext(companyId));

        var todayRows = GetRows(await controller.GetTopCustomers(today, null, null));
        var previousRows = GetRows(await controller.GetTopCustomers(previous, null, null));
        var rangeRows = GetRows(await controller.GetTopCustomers(null, previous, today));

        Assert.Equal(100m, Assert.Single(todayRows).TotalAmount);
        Assert.Equal(40m, Assert.Single(previousRows).TotalAmount);
        Assert.Equal(140m, Assert.Single(rangeRows).TotalAmount);
        Assert.Equal(2, rangeRows[0].OrderCount);
    }

    [Fact]
    public async Task TopCustomers_UsesInclusiveIstBusinessDateBoundaries()
    {
        var companyId = Guid.NewGuid();
        var businessDate = GetBusinessDate();
        await using var db = CreateDb(companyId);
        var customer = AddCustomer(db, companyId, "Boundary Customer");
        var utcStart = ConvertBusinessDateToUtcTime(businessDate, 0, 0, 0);
        AddOrder(db, companyId, customer, 10m, utcStart);
        AddOrder(db, companyId, customer, 20m, utcStart.AddDays(1).AddTicks(-1));
        AddOrder(db, companyId, customer, 90m, utcStart.AddTicks(-1));
        await db.SaveChangesAsync();

        var rows = GetRows(await new MobileFinanceController(db, new TenantContext(companyId))
            .GetTopCustomers(businessDate, null, null));

        var row = Assert.Single(rows);
        Assert.Equal(30m, row.TotalAmount);
        Assert.Equal(2, row.OrderCount);
    }

    [Fact]
    public async Task TopCustomers_RanksBySpendThenCountThenName_AndHonorsLimit()
    {
        var companyId = Guid.NewGuid();
        var date = GetBusinessDate();
        await using var db = CreateDb(companyId);
        var alpha = AddCustomer(db, companyId, "alpha");
        var beta = AddCustomer(db, companyId, "Beta");
        var gamma = AddCustomer(db, companyId, "Gamma");
        AddOrder(db, companyId, alpha, 50m, ConvertBusinessDateToUtcTime(date));
        AddOrder(db, companyId, alpha, 50m, ConvertBusinessDateToUtcTime(date));
        AddOrder(db, companyId, beta, 100m, ConvertBusinessDateToUtcTime(date));
        AddOrder(db, companyId, gamma, 100m, ConvertBusinessDateToUtcTime(date));
        await db.SaveChangesAsync();

        var rows = GetRows(await new MobileFinanceController(db, new TenantContext(companyId))
            .GetTopCustomers(date, null, null, 2));

        Assert.Equal(new[] { "alpha", "Beta" }, rows.Select(row => row.CustomerName));
        Assert.Equal(2, rows[0].OrderCount);
        Assert.Equal(1, rows[1].OrderCount);
    }

    [Fact]
    public async Task TopCustomers_ExcludesInactiveAndInvalidRecords_AndOtherCompanies()
    {
        var companyId = Guid.NewGuid();
        var otherCompanyId = Guid.NewGuid();
        var date = GetBusinessDate();
        await using var db = CreateDb(companyId);
        var valid = AddCustomer(db, companyId, "Valid");
        var inactiveCustomer = AddCustomer(db, companyId, "Inactive Customer");
        inactiveCustomer.MarkInactive();
        var otherCustomer = AddCustomer(db, otherCompanyId, "Other Company");
        AddOrder(db, companyId, valid, 25m, ConvertBusinessDateToUtcTime(date));
        AddOrder(db, companyId, valid, 50m, ConvertBusinessDateToUtcTime(date), OrderStatus.Pending);
        AddOrder(db, companyId, valid, 60m, ConvertBusinessDateToUtcTime(date), deactivate: true);
        AddOrder(db, companyId, inactiveCustomer, 70m, ConvertBusinessDateToUtcTime(date));
        AddOrder(db, otherCompanyId, otherCustomer, 999m, ConvertBusinessDateToUtcTime(date));
        await db.SaveChangesAsync();

        var rows = GetRows(await new MobileFinanceController(db, new TenantContext(companyId))
            .GetTopCustomers(date, null, null));

        var row = Assert.Single(rows);
        Assert.Equal("Valid", row.CustomerName);
        Assert.Equal(25m, row.TotalAmount);
        Assert.Equal(1, row.OrderCount);
    }

    private static List<TopCustomerDto> GetRows(IActionResult result) =>
        Assert.IsType<List<TopCustomerDto>>(Assert.IsType<OkObjectResult>(result).Value);

    private static Customer AddCustomer(SumpoojDbContext db, Guid companyId, string name)
    {
        var customer = new Customer(companyId, name, null, $"9{Guid.NewGuid():N}"[..10]);
        db.Customers.Add(customer);
        return customer;
    }

    private static Order AddOrder(
        SumpoojDbContext db,
        Guid companyId,
        Customer customer,
        decimal total,
        DateTime createdAtUtc,
        OrderStatus status = OrderStatus.Confirmed,
        bool deactivate = false)
    {
        var order = new Order(companyId, customer.Id, createdAtUtc.AddDays(1), null, null, null, null);
        order.SetImportedPosFinancials(total, 0m, 0m, total, 0m, 0m, 0, 0);
        order.SetCreatedAtUtc(createdAtUtc);
        if (status != OrderStatus.Pending)
        {
            order.Confirm();
        }
        if (status == OrderStatus.Processing)
        {
            order.StartProcessing(Guid.NewGuid());
        }
        if (deactivate)
        {
            order.Deactivate();
        }
        db.Orders.Add(order);
        return order;
    }

    private static DateTime GetBusinessDate() =>
        DateTime.SpecifyKind(new DateTime(2026, 9, 10), DateTimeKind.Utc);

    private static DateTime ConvertBusinessDateToUtcTime(DateTime businessDate, int hour = 12, int minute = 0, int second = 0)
    {
        if (TimeZoneInfo.TryFindSystemTimeZoneById("Asia/Kolkata", out var tz) ||
            TimeZoneInfo.TryFindSystemTimeZoneById("India Standard Time", out tz))
        {
            var istTime = new DateTime(businessDate.Year, businessDate.Month, businessDate.Day, hour, minute, second);
            return TimeZoneInfo.ConvertTimeToUtc(istTime, tz);
        }
        return DateTime.SpecifyKind(new DateTime(businessDate.Year, businessDate.Month, businessDate.Day, hour, minute, second), DateTimeKind.Utc);
    }

    private static SumpoojDbContext CreateDb(Guid companyId)
    {
        var options = new DbContextOptionsBuilder<SumpoojDbContext>()
            .UseInMemoryDatabase($"CloudTopCustomers_{Guid.NewGuid():N}")
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