using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.API.Controllers.Mobile;
using Sumpooj.API.Services.Mobile;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Mobile;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;
using Xunit;

namespace Sumpooj.Infrastructure.Tests.Mobile;

/// <summary>
/// Cloud Profit/Margin endpoint tests covering IST business-date logic,
/// revenue/COGS/margin calculation, discounts, and company isolation.
/// </summary>
public class CloudProfitMarginTests
{
    private sealed class TenantContext(Guid companyId) : ITenantContext
    {
        public Guid? CompanyId => companyId;
        public bool IsPlatformUser => false;
        public string? Region => null;
    }

    private readonly SumpoojDbContext _db;
    private readonly MobileDashboardController _controller;
    private readonly Guid _companyId = Guid.NewGuid();
    private readonly Guid _otherCompanyId = Guid.NewGuid();

    public CloudProfitMarginTests()
    {
        _db = CreateDb(_companyId);
        _controller = new MobileDashboardController(_db, new TenantContext(_companyId));
    }

    private static SumpoojDbContext CreateDb(Guid companyId)
    {
        var options = new DbContextOptionsBuilder<SumpoojDbContext>()
            .UseInMemoryDatabase($"CloudProfitMargin_{Guid.NewGuid():N}")
            .Options;
        return new SumpoojDbContext(options, new TenantContext(companyId));
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

    [Fact]
    public async Task ProfitMargin_WhenDateIsToday_CalculatesFromTodayOrdersOnly()
    {
        var today = GetServerLocalBusinessDate();
        var yesterday = today.AddDays(-1);

        var product = await SeedProductAsync(100m);
        await SeedOrderAsync(today, product.Id, quantity: 2, unitPrice: 250m);
        await SeedOrderAsync(yesterday, product.Id, quantity: 1, unitPrice: 500m);

        var result = await _controller.GetProfitMargin(today, today, CancellationToken.None) as OkObjectResult;
        var dto = result?.Value as MobileProfitMarginDto;

        Assert.NotNull(dto);
        Assert.Equal(1, dto.OrderCount);
        Assert.Equal(50000, dto.GrossSalesPaise); // 2 * 250 = 500
    }

    [Fact]
    public async Task ProfitMargin_WhenDateIsPreviousDay_ReturnsHistoricalCalculation()
    {
        var today = GetServerLocalBusinessDate();
        var threeDaysAgo = today.AddDays(-3);

        var product = await SeedProductAsync(100m);
        await SeedOrderAsync(threeDaysAgo, product.Id, quantity: 1, unitPrice: 400m);

        var result = await _controller.GetProfitMargin(threeDaysAgo, threeDaysAgo, CancellationToken.None) as OkObjectResult;
        var dto = result?.Value as MobileProfitMarginDto;

        Assert.NotNull(dto);
        Assert.Equal(1, dto.OrderCount);
        Assert.Equal(40000, dto.GrossSalesPaise);
    }

    [Fact]
    public async Task ProfitMargin_WhenRangeIsProvided_IncludesAllOrdersInRange()
    {
        var baseDate = GetServerLocalBusinessDate();
        var day1 = baseDate.AddDays(-4);
        var day2 = baseDate.AddDays(-3);
        var dayOutside = baseDate.AddDays(-5);

        var product = await SeedProductAsync(100m);
        await SeedOrderAsync(day1, product.Id, quantity: 1, unitPrice: 100m);
        await SeedOrderAsync(day2, product.Id, quantity: 1, unitPrice: 200m);
        await SeedOrderAsync(dayOutside, product.Id, quantity: 1, unitPrice: 900m);

        var result = await _controller.GetProfitMargin(day1, day2, CancellationToken.None) as OkObjectResult;
        var dto = result?.Value as MobileProfitMarginDto;

        Assert.NotNull(dto);
        Assert.Equal(2, dto.OrderCount);
        Assert.Equal(30000, dto.GrossSalesPaise); // (100 + 200) * 100
    }

    [Fact]
    public async Task ProfitMargin_UsesIstBusinessDateBoundary_ForUtcTimesNearMidnight()
    {
        var businessDate = GetServerLocalBusinessDate();
        var product = await SeedProductAsync(50m);

        // 00:00 UTC = 05:30 IST same business day; 18:29 UTC = 23:59 IST same business day.
        await SeedOrderAtUtcTimeAsync(businessDate, new TimeSpan(0, 0, 0), product.Id, quantity: 1, unitPrice: 100m);
        await SeedOrderAtUtcTimeAsync(businessDate, new TimeSpan(18, 29, 0), product.Id, quantity: 1, unitPrice: 100m);

        var result = await _controller.GetProfitMargin(businessDate, businessDate, CancellationToken.None) as OkObjectResult;
        var dto = result?.Value as MobileProfitMarginDto;

        Assert.NotNull(dto);
        Assert.Equal(2, dto.OrderCount);
    }

    [Fact]
    public async Task ProfitMargin_CalculatesCogsFromCurrentProductCost()
    {
        var today = GetServerLocalBusinessDate();
        var product = await SeedProductAsync(costPrice: 60m);

        await SeedOrderAsync(today, product.Id, quantity: 3, unitPrice: 100m);

        var result = await _controller.GetProfitMargin(today, today, CancellationToken.None) as OkObjectResult;
        var dto = result?.Value as MobileProfitMarginDto;

        Assert.NotNull(dto);
        Assert.Equal(30000, dto.GrossSalesPaise); // 3 * 100
        Assert.Equal(18000, dto.CogsPaise); // 3 * 60
        Assert.True(dto.CogsIsEstimate);
        Assert.False(string.IsNullOrWhiteSpace(dto.CogsLimitationNote));
    }

    [Fact]
    public async Task ProfitMargin_CalculatesGrossProfitAndMarginPercent()
    {
        var today = GetServerLocalBusinessDate();
        var product = await SeedProductAsync(costPrice: 40m);

        await SeedOrderAsync(today, product.Id, quantity: 10, unitPrice: 100m); // revenue 1000, cogs 400

        var result = await _controller.GetProfitMargin(today, today, CancellationToken.None) as OkObjectResult;
        var dto = result?.Value as MobileProfitMarginDto;

        Assert.NotNull(dto);
        Assert.Equal(100000, dto.NetRevenuePaise); // 1000 * 100
        Assert.Equal(40000, dto.CogsPaise); // 400 * 100
        Assert.Equal(60000, dto.GrossProfitPaise); // 600 * 100
        Assert.Equal(60m, dto.MarginPercent); // 600/1000 * 100
    }

    [Fact]
    public async Task ProfitMargin_AppliesDiscountsToNetRevenue()
    {
        var today = GetServerLocalBusinessDate();
        var product = await SeedProductAsync(costPrice: 50m);

        await SeedOrderAsync(today, product.Id, quantity: 5, unitPrice: 100m, discountAmount: 100m); // gross 500, discount 100 -> net 400

        var result = await _controller.GetProfitMargin(today, today, CancellationToken.None) as OkObjectResult;
        var dto = result?.Value as MobileProfitMarginDto;

        Assert.NotNull(dto);
        Assert.Equal(50000, dto.GrossSalesPaise); // 500
        Assert.Equal(10000, dto.DiscountsPaise); // 100
        Assert.Equal(40000, dto.NetRevenuePaise); // 400
    }

    [Fact]
    public async Task ProfitMargin_RespectsCompanyIsolation()
    {
        var today = GetServerLocalBusinessDate();
        var myProduct = await SeedProductAsync(costPrice: 20m, companyId: _companyId);
        var otherProduct = await SeedProductAsync(costPrice: 20m, companyId: _otherCompanyId);

        await SeedOrderAsync(today, myProduct.Id, quantity: 1, unitPrice: 100m, companyId: _companyId);
        await SeedOrderAsync(today, otherProduct.Id, quantity: 1, unitPrice: 500m, companyId: _otherCompanyId);

        var result = await _controller.GetProfitMargin(today, today, CancellationToken.None) as OkObjectResult;
        var dto = result?.Value as MobileProfitMarginDto;

        Assert.NotNull(dto);
        Assert.Equal(1, dto.OrderCount);
        Assert.Equal(10000, dto.GrossSalesPaise); // Only my order
    }

    [Fact]
    public async Task ProfitMargin_UsesOnlyCloudData_NoLocalFallback()
    {
        var today = GetServerLocalBusinessDate();
        var product = await SeedProductAsync(costPrice: 30m);
        await SeedOrderAsync(today, product.Id, quantity: 2, unitPrice: 100m);

        var result = await _controller.GetProfitMargin(today, today, CancellationToken.None) as OkObjectResult;
        var dto = result?.Value as MobileProfitMarginDto;

        Assert.NotNull(dto);
        Assert.Equal(20000, dto.GrossSalesPaise);
        Assert.Equal(6000, dto.CogsPaise);
    }

    // Helpers
    private async Task<Product> SeedProductAsync(decimal costPrice, Guid? companyId = null)
    {
        var product = new Product(
            companyId ?? _companyId,
            "Test Rose",
            $"SKU-{Guid.NewGuid():N}",
            ProductType.SingleFlower,
            ProductCategory.Roses,
            retailPrice: costPrice + 50m,
            costPrice: costPrice,
            description: null);
        _db.Products.Add(product);
        await _db.SaveChangesAsync();
        return product;
    }

    private async Task<Customer> GetOrCreateCustomerAsync(Guid companyId)
    {
        var existing = _db.Customers.FirstOrDefault(c => c.CompanyId == companyId);
        if (existing != null) return existing;

        var customer = new Customer(companyId, "Test Customer", null, "9999999999");
        _db.Customers.Add(customer);
        await _db.SaveChangesAsync();
        return customer;
    }

    private async Task<Order> SeedOrderAsync(
        DateTime businessDate,
        Guid productId,
        int quantity,
        decimal unitPrice,
        decimal discountAmount = 0m,
        Guid? companyId = null)
    {
        var cid = companyId ?? _companyId;
        var customer = await GetOrCreateCustomerAsync(cid);
        var utcTime = ConvertBusinessDateToUtcTime(businessDate);

        var order = new Order(cid, customer.Id, utcTime, null, null, "Test", "9999999999");
        order.AddItem(productId, "Test Rose", quantity, unitPrice);
        if (discountAmount > 0m)
        {
            order.ApplyDiscount(discountAmount);
        }

        typeof(Order).GetProperty("OrderDate")!.SetValue(order, utcTime);

        _db.Orders.Add(order);
        await _db.SaveChangesAsync();
        return order;
    }

    private async Task<Order> SeedOrderAtUtcTimeAsync(
        DateTime businessDate,
        TimeSpan utcTimeOfDay,
        Guid productId,
        int quantity,
        decimal unitPrice)
    {
        var customer = await GetOrCreateCustomerAsync(_companyId);
        var utcDateTime = DateTime.SpecifyKind(businessDate.Date.Add(utcTimeOfDay), DateTimeKind.Utc);

        var order = new Order(_companyId, customer.Id, utcDateTime, null, null, "Test", "9999999999");
        order.AddItem(productId, "Test Rose", quantity, unitPrice);

        typeof(Order).GetProperty("OrderDate")!.SetValue(order, utcDateTime);

        _db.Orders.Add(order);
        await _db.SaveChangesAsync();
        return order;
    }

    private DateTime ConvertBusinessDateToUtcTime(DateTime businessDate)
    {
        if (TimeZoneInfo.TryFindSystemTimeZoneById("Asia/Kolkata", out var tz) ||
            TimeZoneInfo.TryFindSystemTimeZoneById("India Standard Time", out tz))
        {
            var istMidnight = new DateTime(businessDate.Year, businessDate.Month, businessDate.Day, 12, 0, 0);
            return TimeZoneInfo.ConvertTimeToUtc(istMidnight, tz);
        }
        return businessDate;
    }
}
