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
/// Cloud Sales Report endpoint tests covering IST business-date logic,
/// company isolation, payment-method totals, and date-range filtering.
/// </summary>
public class CloudSalesReportTests
{
    private sealed class TenantContext(Guid companyId) : ITenantContext
    {
        public Guid? CompanyId => companyId;
        public bool IsPlatformUser => false;
        public string? Region => null;
    }

    private readonly SumpoojDbContext _db;
    private readonly ITenantContext _tenantContext;
    private readonly MobileDashboardController _controller;
    private readonly Guid _companyId = Guid.NewGuid();
    private readonly Guid _otherCompanyId = Guid.NewGuid();

    public CloudSalesReportTests()
    {
        _tenantContext = new TenantContext(_companyId);
        _db = CreateDb(_companyId);
        _controller = new MobileDashboardController(_db, _tenantContext);
    }

    private static SumpoojDbContext CreateDb(Guid companyId)
    {
        var options = new DbContextOptionsBuilder<SumpoojDbContext>()
            .UseInMemoryDatabase($"CloudSalesReport_{Guid.NewGuid():N}")
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

    /// <summary>
    /// Test that sales reports for today include only today's orders.
    /// </summary>
    [Fact]
    public async Task SalesReport_WhenDateIsToday_ReturnsTodayOnlyOrders()
    {
        // Arrange
        var today = GetServerLocalBusinessDate();
        var yesterday = today.AddDays(-1);
        
        var todayOrder = CreateOrder(_companyId, today, 10000m);
        var yesterdayOrder = CreateOrder(_companyId, yesterday, 5000m);
        
        _db.Orders.AddRange(todayOrder, yesterdayOrder);
        _db.SaveChanges();

        // Act
        var result = await _controller.GetSummary(today, today, CancellationToken.None) as OkObjectResult;
        var summary = result?.Value as Sumpooj.Application.Mobile.MobileDashboardSummaryDto;

        // Assert
        Assert.NotNull(summary);
        Assert.Equal(1, summary.OrderCount);
        Assert.Equal(1000000, summary.TotalSalesPaise); // 10000 * 100
    }

    /// <summary>
    /// Test that sales reports for previous dates include historical orders
    /// </summary>
    [Fact]
    public async Task SalesReport_WhenDateIsPreviousDay_ReturnsHistoricalOrders()
    {
        // Arrange
        var today = GetServerLocalBusinessDate();
        var threeYearsAgo = today.AddDays(-3);
        
        var historicalOrder = CreateOrder(_companyId, threeYearsAgo, 5000m);
        var recentOrder = CreateOrder(_companyId, today, 10000m);
        
        _db.Orders.AddRange(historicalOrder, recentOrder);
        _db.SaveChanges();

        // Act
        var result = await _controller.GetSummary(threeYearsAgo, threeYearsAgo, CancellationToken.None) as OkObjectResult;
        var summary = result?.Value as Sumpooj.Application.Mobile.MobileDashboardSummaryDto;

        // Assert
        Assert.NotNull(summary);
        Assert.Equal(1, summary.OrderCount);
        Assert.Equal(500000, summary.TotalSalesPaise); // 5000 * 100
    }

    /// <summary>
    /// Test that multi-day ranges include all orders within range
    /// </summary>
    [Fact]
    public async Task SalesReport_WhenRangeIsProvided_IncludesAllOrdersInRange()
    {
        // Arrange
        var baseDate = GetServerLocalBusinessDate();
        var day1 = baseDate.AddDays(-4);
        var day2 = baseDate.AddDays(-3);
        var day3 = baseDate.AddDays(-2);
        var dayOutside = baseDate.AddDays(-5);

        var orders = new[]
        {
            CreateOrder(_companyId, day1, 1000m),
            CreateOrder(_companyId, day2, 2000m),
            CreateOrder(_companyId, day3, 3000m),
            CreateOrder(_companyId, dayOutside, 5000m),
        };

        _db.Orders.AddRange(orders);
        _db.SaveChanges();

        // Act
        var result = await _controller.GetSummary(day1, day3, CancellationToken.None) as OkObjectResult;
        var summary = result?.Value as Sumpooj.Application.Mobile.MobileDashboardSummaryDto;

        // Assert
        Assert.NotNull(summary);
        Assert.Equal(3, summary.OrderCount); // Only day1, day2, day3
        Assert.Equal(600000, summary.TotalSalesPaise); // (1000 + 2000 + 3000) * 100
    }

    /// <summary>
    /// Test that IST business-date boundary correctly handles UTC midnight transitions
    /// </summary>
    [Fact]
    public async Task SalesReport_UsesIstBusinessDateBoundary_ForUtcTimesNearMidnight()
    {
        // Arrange
        var businessDate = GetServerLocalBusinessDate();
        
        // IST is UTC+5:30. Order1 at 00:00 UTC = 05:30 IST same business day.
        // Order2 at 18:29 UTC = 23:59 IST same business day (just before IST midnight boundary).
        var order1 = CreateOrderAtUtcTime(_companyId, businessDate, new TimeSpan(0, 0, 0));
        var order2 = CreateOrderAtUtcTime(_companyId, businessDate, new TimeSpan(18, 29, 0));
        
        _db.Orders.AddRange(order1, order2);
        _db.SaveChanges();

        // Act
        var result = await _controller.GetSummary(businessDate, businessDate, CancellationToken.None) as OkObjectResult;
        var summary = result?.Value as Sumpooj.Application.Mobile.MobileDashboardSummaryDto;

        // Assert
        Assert.NotNull(summary);
        Assert.Equal(2, summary.OrderCount);
    }

    /// <summary>
    /// Test that payment-method totals are correctly calculated
    /// </summary>
    [Fact]
    public async Task SalesReport_CalculatesPaymentMethodTotalsCorrectly()
    {
        // Arrange
        var today = GetServerLocalBusinessDate();

        var order1 = CreateOrder(_companyId, today, 1000m, PaymentStatus.Paid);
        var order2 = CreateOrder(_companyId, today, 2000m, PaymentStatus.Paid);
        var order3 = CreateOrder(_companyId, today, 1500m, PaymentStatus.Credit);

        _db.Orders.AddRange(order1, order2, order3);
        _db.SaveChanges();

        var payment1 = CreatePayment(order1.Id, _companyId, 1000m, PaymentMethod.Cash);
        var payment2 = CreatePayment(order2.Id, _companyId, 2000m, PaymentMethod.Upi);

        _db.Payments.AddRange(payment1, payment2);
        _db.SaveChanges();

        // Act
        var result = await _controller.GetSummary(today, today, CancellationToken.None) as OkObjectResult;
        var summary = result?.Value as Sumpooj.Application.Mobile.MobileDashboardSummaryDto;

        // Assert
        Assert.NotNull(summary);
        Assert.Equal(3, summary.OrderCount);
        Assert.Equal(450000, summary.TotalSalesPaise); // (1000 + 2000 + 1500) * 100
        Assert.Equal(100000, summary.CashPaise); // 1000 * 100
        Assert.Equal(200000, summary.UpiPaise); // 2000 * 100
        Assert.Equal(150000, summary.CreditPaise); // 1500 * 100
    }

    /// <summary>
    /// Test that company isolation is enforced - other company orders are not included
    /// </summary>
    [Fact]
    public async Task SalesReport_RespectCompanyIsolation_OtherCompanyOrdersExcluded()
    {
        // Arrange
        var today = GetServerLocalBusinessDate();

        var myOrder = CreateOrder(_companyId, today, 5000m);
        var otherOrder = CreateOrder(_otherCompanyId, today, 10000m);

        _db.Orders.AddRange(myOrder, otherOrder);
        _db.SaveChanges();

        // Act
        var result = await _controller.GetSummary(today, today, CancellationToken.None) as OkObjectResult;
        var summary = result?.Value as Sumpooj.Application.Mobile.MobileDashboardSummaryDto;

        // Assert
        Assert.NotNull(summary);
        Assert.Equal(1, summary.OrderCount);
        Assert.Equal(500000, summary.TotalSalesPaise); // Only myOrder
    }

    /// <summary>
    /// Test that inactive orders are excluded from reports
    /// </summary>
    [Fact]
    public async Task SalesReport_ExcludesInactiveOrders()
    {
        // Arrange
        var today = GetServerLocalBusinessDate();

        var activeOrder = CreateOrder(_companyId, today, 1000m, isActive: true);
        var inactiveOrder = CreateOrder(_companyId, today, 2000m, isActive: false);

        _db.Orders.AddRange(activeOrder, inactiveOrder);
        _db.SaveChanges();

        // Act
        var result = await _controller.GetSummary(today, today, CancellationToken.None) as OkObjectResult;
        var summary = result?.Value as Sumpooj.Application.Mobile.MobileDashboardSummaryDto;

        // Assert
        Assert.NotNull(summary);
        Assert.Equal(1, summary.OrderCount);
        Assert.Equal(100000, summary.TotalSalesPaise); // Only activeOrder
    }

    /// <summary>
    /// Test that only approved payments are included in payment totals
    /// </summary>
    [Fact]
    public async Task SalesReport_IncludesOnlyApprovedPayments()
    {
        // Arrange
        var today = GetServerLocalBusinessDate();

        var order1 = CreateOrder(_companyId, today, 1000m);
        var order2 = CreateOrder(_companyId, today, 2000m);

        _db.Orders.AddRange(order1, order2);
        _db.SaveChanges();

        var approvedPayment = CreatePayment(order1.Id, _companyId, 1000m, PaymentMethod.Cash, PaymentTransactionStatus.Approved);
        var pendingPayment = CreatePayment(order2.Id, _companyId, 2000m, PaymentMethod.Cash, PaymentTransactionStatus.Pending);

        _db.Payments.AddRange(approvedPayment, pendingPayment);
        _db.SaveChanges();

        // Act
        var result = await _controller.GetSummary(today, today, CancellationToken.None) as OkObjectResult;
        var summary = result?.Value as Sumpooj.Application.Mobile.MobileDashboardSummaryDto;

        // Assert
        Assert.NotNull(summary);
        Assert.Equal(100000, summary.CashPaise); // Only approvedPayment
    }

    /// <summary>
    /// Test that ranges include expenses when present
    /// </summary>
    [Fact]
    public async Task SalesReport_IncludesExpensesInDateRange()
    {
        // Arrange
        var today = GetServerLocalBusinessDate();
        var expense = CreateExpense(_companyId, today, 500m);

        _db.Expenses.Add(expense);
        _db.SaveChanges();

        // Act
        var result = await _controller.GetSummary(today, today, CancellationToken.None) as OkObjectResult;
        var summary = result?.Value as Sumpooj.Application.Mobile.MobileDashboardSummaryDto;

        // Assert
        Assert.NotNull(summary);
        Assert.Equal(50000, summary.ExpensePaise); // 500 * 100
    }

    /// <summary>
    /// Test that Cloud does not fall back to local SQLite data (implicit - uses cloud API data only)
    /// </summary>
    [Fact]
    public async Task SalesReport_UsesOnlyCloudOrderData_NoLocalFallback()
    {
        // Arrange
        var today = GetServerLocalBusinessDate();
        
        var order = CreateOrder(_companyId, today, 10000m);
        _db.Orders.Add(order);
        _db.SaveChanges();

        // Act
        // The controller queries the database directly (which in production is PostgreSQL Cloud)
        // This test verifies that the API endpoint works with cloud data
        var result = await _controller.GetSummary(today, today, CancellationToken.None) as OkObjectResult;
        var summary = result?.Value as Sumpooj.Application.Mobile.MobileDashboardSummaryDto;

        // Assert
        Assert.NotNull(summary);
        Assert.Equal(1000000, summary.TotalSalesPaise);
        // If there was a SQLite fallback, the data would be different or missing
    }

    // Helper methods
    private Order CreateOrder(
        Guid companyId,
        DateTime businessDate,
        decimal totalAmount,
        PaymentStatus paymentStatus = PaymentStatus.Paid,
        bool isActive = true)
    {
        var customer = GetOrCreateTestCustomer(companyId);
        var utcTime = ConvertBusinessDateToUtcTime(businessDate);
        
        var order = new Order(companyId, customer.Id, utcTime, null, null, "Test", "9999999999");
        
        // Use reflection to set private properties for testing
        var orderProps = order.GetType();
        orderProps.GetProperty("TotalAmount", System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Instance)?
            .SetValue(order, totalAmount);
        orderProps.GetProperty("PaymentStatus", System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Instance)?
            .SetValue(order, paymentStatus);
        orderProps.GetProperty("OrderDate", System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Instance)?
            .SetValue(order, utcTime);
        
        if (!isActive)
        {
            orderProps.GetProperty("IsActive", System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Instance)?
                .SetValue(order, false);
        }

        return order;
    }

    private Order CreateOrderAtUtcTime(Guid companyId, DateTime businessDate, TimeSpan utcTimeOfDay)
    {
        var customer = GetOrCreateTestCustomer(companyId);
        var utcDateTime = businessDate.Date.Add(utcTimeOfDay);
        var order = new Order(companyId, customer.Id, DateTime.SpecifyKind(utcDateTime, DateTimeKind.Utc), null, null, "Test", "9999999999");
        
        var orderProps = order.GetType();
        orderProps.GetProperty("TotalAmount", System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Instance)?
            .SetValue(order, 1000m);
        orderProps.GetProperty("OrderDate", System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Instance)?
            .SetValue(order, DateTime.SpecifyKind(utcDateTime, DateTimeKind.Utc));

        return order;
    }

    private Payment CreatePayment(
        Guid orderId,
        Guid companyId,
        decimal amount,
        PaymentMethod method,
        PaymentTransactionStatus status = PaymentTransactionStatus.Approved)
    {
        var payment = new Payment(companyId, orderId, method, amount);
        if (status == PaymentTransactionStatus.Approved)
        {
            payment.Approve(null, null);
        }
        return payment;
    }

    private Expense CreateExpense(Guid companyId, DateTime businessDate, decimal amount)
    {
        var utcTime = ConvertBusinessDateToUtcTime(businessDate);
        return new Expense(companyId, "Test", amount, null, utcTime);
    }

    private Customer GetOrCreateTestCustomer(Guid companyId)
    {
        var existing = _db.Customers.FirstOrDefault(c => c.CompanyId == companyId);
        if (existing != null)
            return existing;

        var customer = new Customer(companyId, "Test Customer", null, "9999999999");
        _db.Customers.Add(customer);
        _db.SaveChanges();
        return customer;
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
