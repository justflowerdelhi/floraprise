using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.API.Controllers;
using Sumpooj.Application.Accounting;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;
using Xunit;

namespace Sumpooj.Infrastructure.Tests.Accounting;

public class CloudRemainingReportsTests
{
    [Fact]
    public async Task RewardsSummary_ReproducesTotalsRankingAndCompanyIsolation()
    {
        var companyId = Guid.NewGuid();
        var otherCompanyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        var first = AddCustomer(db, companyId, "First", 20, 30, 10);
        var second = AddCustomer(db, companyId, "Second", 20, 25, 5);
        var inactive = AddCustomer(db, companyId, "Inactive", 500, 500, 500);
        inactive.MarkInactive();
        var other = AddCustomer(db, otherCompanyId, "Other", 999, 999, 999);
        AddRewardOrder(db, companyId, first, 5, 2, 12.50m);
        AddRewardOrder(db, companyId, second, 0, 0, 99m);
        var inactiveOrder = AddRewardOrder(db, companyId, first, 100, 100, 700m);
        inactiveOrder.Deactivate();
        AddRewardOrder(db, otherCompanyId, other, 50, 10, 500m);
        await db.SaveChangesAsync();

        var result = await new MobileFinanceController(db, new TenantContext(companyId))
            .GetRewardsSummary();

        var dto = Assert.IsType<RewardsReportDto>(Assert.IsType<OkObjectResult>(result).Value);
        Assert.Equal(40, dto.CurrentPoints);
        Assert.Equal(55, dto.LifetimePoints);
        Assert.Equal(15, dto.RedeemedPoints);
        Assert.Equal(1, dto.RewardOrders);
        Assert.Equal(12.50m, dto.DiscountAmount);
        Assert.Equal(new[] { "First", "Second" }, dto.Customers.Select(customer => customer.CustomerName));
    }

    [Fact]
    public async Task TopProducts_FiltersInclusiveIstRangeAndRanksByLineRevenue()
    {
        var companyId = Guid.NewGuid();
        var date = BusinessDate();
        await using var db = CreateDb(companyId);
        var customer = AddCustomer(db, companyId, "Customer", 0, 0, 0);
        var rose = AddProduct(db, companyId, "Rose");
        var lily = AddProduct(db, companyId, "Lily");
        var utcStart = BusinessDateToUtc(date);
        AddOrder(db, companyId, customer, utcStart, (rose, 2, 50m), (lily, 1, 80m));
        AddOrder(db, companyId, customer, utcStart.AddDays(1).AddTicks(-1), (lily, 1, 40m));
        AddOrder(db, companyId, customer, utcStart.AddTicks(-1), (rose, 10, 100m));
        await db.SaveChangesAsync();

        var result = await new MobileFinanceController(db, new TenantContext(companyId))
            .GetTopProducts(date, null, null);

        var rows = Assert.IsType<List<TopProductDto>>(Assert.IsType<OkObjectResult>(result).Value);
        Assert.Equal(new[] { "Lily", "Rose" }, rows.Select(row => row.ProductName));
        Assert.Equal(2, rows[0].QuantitySold);
        Assert.Equal(120m, rows[0].TotalRevenue);
        Assert.Equal(2, rows[1].QuantitySold);
        Assert.Equal(100m, rows[1].TotalRevenue);
    }

    [Fact]
    public async Task TopProducts_SupportsMultiDayRangeLimitAndCompanyIsolation()
    {
        var companyId = Guid.NewGuid();
        var otherCompanyId = Guid.NewGuid();
        var from = BusinessDate().AddDays(-1);
        var to = BusinessDate();
        await using var db = CreateDb(companyId);
        var customer = AddCustomer(db, companyId, "Customer", 0, 0, 0);
        var otherCustomer = AddCustomer(db, otherCompanyId, "Other", 0, 0, 0);
        var rose = AddProduct(db, companyId, "Rose");
        var lily = AddProduct(db, companyId, "Lily");
        var otherProduct = AddProduct(db, otherCompanyId, "Other Product");
        AddOrder(db, companyId, customer, BusinessDateToUtc(from, 12), (rose, 1, 30m));
        AddOrder(db, companyId, customer, BusinessDateToUtc(to, 12), (lily, 1, 20m));
        AddOrder(db, otherCompanyId, otherCustomer, BusinessDateToUtc(to, 12), (otherProduct, 1, 999m));
        await db.SaveChangesAsync();

        var result = await new MobileFinanceController(db, new TenantContext(companyId))
            .GetTopProducts(null, from, to, 1);

        var row = Assert.Single(Assert.IsType<List<TopProductDto>>(Assert.IsType<OkObjectResult>(result).Value));
        Assert.Equal("Rose", row.ProductName);
        Assert.Equal(30m, row.TotalRevenue);
    }

    private static Customer AddCustomer(
        SumpoojDbContext db,
        Guid companyId,
        string name,
        int currentPoints,
        int lifetimePoints,
        int redeemedPoints)
    {
        var customer = new Customer(companyId, name, null, $"9{Guid.NewGuid():N}"[..10]);
        customer.UpdateMobileCrm(null, null, null, null, null, 0, null, 0m,
            currentPoints, lifetimePoints, redeemedPoints, null);
        db.Customers.Add(customer);
        return customer;
    }

    private static Product AddProduct(SumpoojDbContext db, Guid companyId, string name)
    {
        var product = new Product(companyId, name, $"SKU-{Guid.NewGuid():N}", ProductType.Bouquet,
            ProductCategory.MixedFlowers, 0m, 0m, null);
        db.Products.Add(product);
        return product;
    }

    private static Order AddRewardOrder(
        SumpoojDbContext db,
        Guid companyId,
        Customer customer,
        int earned,
        int redeemed,
        decimal discount)
    {
        var order = new Order(companyId, customer.Id, DateTime.UtcNow.AddDays(1), null, null, null, null);
        order.SetRewardPoints(earned, redeemed);
        order.SetPosFinancialDetails(0m, discount);
        db.Orders.Add(order);
        return order;
    }

    private static void AddOrder(
        SumpoojDbContext db,
        Guid companyId,
        Customer customer,
        DateTime createdAtUtc,
        params (Product product, int quantity, decimal unitPrice)[] items)
    {
        var order = new Order(companyId, customer.Id, createdAtUtc.AddDays(1), null, null, null, null);
        foreach (var item in items)
        {
            order.AddItem(item.product.Id, item.product.Name, item.quantity, item.unitPrice);
        }
        order.SetCreatedAtUtc(createdAtUtc);
        db.Orders.Add(order);
    }

    private static DateTime BusinessDate() =>
        DateTime.SpecifyKind(new DateTime(2026, 9, 10), DateTimeKind.Utc);

    private static DateTime BusinessDateToUtc(DateTime date, int hour = 0)
    {
        if (TimeZoneInfo.TryFindSystemTimeZoneById("Asia/Kolkata", out var tz) ||
            TimeZoneInfo.TryFindSystemTimeZoneById("India Standard Time", out tz))
        {
            return TimeZoneInfo.ConvertTimeToUtc(new DateTime(date.Year, date.Month, date.Day, hour, 0, 0), tz);
        }
        return DateTime.SpecifyKind(new DateTime(date.Year, date.Month, date.Day, hour, 0, 0), DateTimeKind.Utc);
    }

    private static SumpoojDbContext CreateDb(Guid companyId)
    {
        var options = new DbContextOptionsBuilder<SumpoojDbContext>()
            .UseInMemoryDatabase($"CloudRemainingReports_{Guid.NewGuid():N}")
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