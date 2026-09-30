using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.EntityFrameworkCore.Storage;
using Sumpooj.API.Controllers;
using Sumpooj.API.Controllers.Mobile;
using Sumpooj.API.Services.Mobile;
using Sumpooj.Application.DayClose;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Mobile;
using Sumpooj.Application.UseCases;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;
using Sumpooj.Infrastructure.Repositories;
using Xunit;

namespace Floraprise.Mobile.Tests;

public sealed class DayCloseAndReportingTests : IDisposable
{
    private readonly Guid _companyId = Guid.NewGuid();
    private readonly Guid _locationId = Guid.NewGuid();
    private readonly Guid _userId = Guid.NewGuid();
    private readonly string _databaseName = $"DayCloseReporting_{Guid.NewGuid():N}";
    private readonly InMemoryDatabaseRoot _databaseRoot = new();

    public void Dispose()
    {
    }

    private SumpoojDbContext CreateDb()
    {
        var options = new DbContextOptionsBuilder<SumpoojDbContext>()
            .UseInMemoryDatabase(_databaseName, _databaseRoot)
            .ConfigureWarnings(w => w.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options;
        var db = new SumpoojDbContext(options, new TestTenantContext { CompanyId = _companyId });
        db.Database.EnsureCreated();
        return db;
    }

    private sealed class TestTenantContext : ITenantContext
    {
        public Guid? CompanyId { get; set; }
        public bool IsPlatformUser { get; set; }
        public string? Region { get; set; }
    }

    private DayCloseService CreateDayCloseService(SumpoojDbContext db)
    {
        var dayCloseRepo = new DayCloseRepository(db);
        var orderRepo = new OrderRepository(db);
        var paymentRepo = new PaymentRepository(db);
        var locationRepo = new LocationRepository(db);
        return new DayCloseService(dayCloseRepo, orderRepo, paymentRepo, locationRepo, dayCloseRepo);
    }

    private MobileDashboardController CreateDashboardController(SumpoojDbContext db)
    {
        var tenant = new TestTenantContext { CompanyId = _companyId };
        var controller = new MobileDashboardController(db, tenant);
        controller.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext
            {
                User = new ClaimsPrincipal(new ClaimsIdentity(new[]
                {
                    new Claim("company_id", _companyId.ToString()),
                    new Claim(ClaimTypes.NameIdentifier, _userId.ToString())
                }))
            }
        };
        return controller;
    }

    private Location SeedLocation(SumpoojDbContext db)
    {
        var loc = new Location(_companyId, "Main Branch", "MB01", LocationType.Store, "123 Street");
        typeof(Location).GetProperty("Id")?.SetValue(loc, _locationId);
        loc.SetAsDefault();
        db.Locations.Add(loc);
        return loc;
    }

    private Customer SeedCustomer(SumpoojDbContext db, string phone = "9876543210", string name = "Test Customer")
    {
        var customer = new Customer(_companyId, name, "test@example.com", phone);
        db.Customers.Add(customer);
        return customer;
    }

    private static (DateTime utcStart, DateTime utcEnd) GetUtcRangeForIstDate(DateTime businessDate)
    {
        if (TimeZoneInfo.TryFindSystemTimeZoneById("Asia/Kolkata", out var tz) ||
            TimeZoneInfo.TryFindSystemTimeZoneById("India Standard Time", out tz))
        {
            var istMidnight = new DateTime(businessDate.Year, businessDate.Month, businessDate.Day, 0, 0, 0, DateTimeKind.Unspecified);
            var istEnd = istMidnight.AddDays(1);
            return (TimeZoneInfo.ConvertTimeToUtc(istMidnight, tz), TimeZoneInfo.ConvertTimeToUtc(istEnd, tz));
        }
        var dayStart = DateTime.SpecifyKind(businessDate.Date, DateTimeKind.Utc);
        return (dayStart, dayStart.AddDays(1));
    }

    private Order CreateTestOrder(SumpoojDbContext db, Customer customer, DateTime orderDateUtc, decimal totalAmount, PaymentStatus paymentStatus, string orderNumber = "ORD-TEST")
    {
        var order = new Order(_companyId, customer.Id, orderDateUtc.AddDays(1), "123 Street", "110001", "Recipient", "9876543210");
        order.LocationId = _locationId;
        order.SetImportedOrderNumber(orderNumber);
        order.SetOrderDate(orderDateUtc);
        order.AddItem(Guid.NewGuid(), "Flowers", 1, totalAmount);
        if (paymentStatus == PaymentStatus.Paid) order.MarkPaid();
        else if (paymentStatus == PaymentStatus.PartiallyPaid) order.MarkPartiallyPaid(totalAmount);
        else if (paymentStatus == PaymentStatus.Credit) order.MarkCredit();
        db.Orders.Add(order);
        return order;
    }

    private Payment CreateTestPayment(SumpoojDbContext db, Guid orderId, PaymentMethod method, decimal amount, DateTime paymentTimeUtc, string txnId = "TXN-1", PaymentType paymentType = PaymentType.SaleTender)
    {
        var payment = new Payment(_companyId, orderId, method, amount);
        typeof(Payment).GetProperty("LocationId")?.SetValue(payment, _locationId);
        typeof(Payment).GetProperty("CreatedAtUtc")?.SetValue(payment, paymentTimeUtc);
        payment.SetPaymentType(paymentType);
        payment.Approve(txnId, "AUTH-1");
        db.Payments.Add(payment);
        return payment;
    }

    [Fact]
    public async Task Test1_FullCashSale_DayCloseAndDashboard_CorrectlyReflected()
    {
        await using var db = CreateDb();
        SeedLocation(db);
        var customer = SeedCustomer(db);
        var date = new DateTime(2026, 9, 20);
        var (dayStart, _) = GetUtcRangeForIstDate(date);
        var saleTime = dayStart.AddHours(4); // 4 hours into IST day

        // Order: ₹1,000, Cash: ₹1,000
        var order = CreateTestOrder(db, customer, saleTime, 1000m, PaymentStatus.Paid, "ORD-001");
        CreateTestPayment(db, order.Id, PaymentMethod.Cash, 1000m, saleTime, "TXN-1");

        await db.SaveChangesAsync();

        var service = CreateDayCloseService(db);
        var summaryObj = await service.GetSummaryAsync(_companyId, _locationId, date);

        var totalSales = (decimal)summaryObj.GetType().GetProperty("totalSales")!.GetValue(summaryObj)!;
        var cashSales = (decimal)summaryObj.GetType().GetProperty("cashSales")!.GetValue(summaryObj)!;
        var upiSales = (decimal)summaryObj.GetType().GetProperty("upiSales")!.GetValue(summaryObj)!;
        var creditSales = (decimal)summaryObj.GetType().GetProperty("creditSales")!.GetValue(summaryObj)!;
        var expectedCash = (decimal)summaryObj.GetType().GetProperty("expectedCash")!.GetValue(summaryObj)!;

        Assert.Equal(1000m, totalSales);
        Assert.Equal(1000m, cashSales);
        Assert.Equal(0m, upiSales);
        Assert.Equal(0m, creditSales);
        Assert.Equal(1000m, expectedCash);

        // Dashboard
        var controller = CreateDashboardController(db);
        var result = await controller.GetSummary(date, date, CancellationToken.None) as OkObjectResult;
        var dash = Assert.IsType<MobileDashboardSummaryDto>(result!.Value);

        Assert.Equal(100000, dash.TotalSalesPaise);
        Assert.Equal(100000, dash.CashPaise);
        Assert.Equal(0, dash.UpiPaise);
        Assert.Equal(0, dash.CreditPaise);
    }

    [Fact]
    public async Task Test2_FullUpiSale_DayCloseAndDashboard_ReflectsUpiWithoutCash()
    {
        await using var db = CreateDb();
        SeedLocation(db);
        var customer = SeedCustomer(db);
        var date = new DateTime(2026, 9, 20);
        var (dayStart, _) = GetUtcRangeForIstDate(date);
        var saleTime = dayStart.AddHours(4);

        // Order: ₹1,000, UPI: ₹1,000
        var order = CreateTestOrder(db, customer, saleTime, 1000m, PaymentStatus.Paid, "ORD-002");
        CreateTestPayment(db, order.Id, PaymentMethod.Upi, 1000m, saleTime, "TXN-UPI");

        await db.SaveChangesAsync();

        var service = CreateDayCloseService(db);
        var summaryObj = await service.GetSummaryAsync(_companyId, _locationId, date);

        var totalSales = (decimal)summaryObj.GetType().GetProperty("totalSales")!.GetValue(summaryObj)!;
        var cashSales = (decimal)summaryObj.GetType().GetProperty("cashSales")!.GetValue(summaryObj)!;
        var upiSales = (decimal)summaryObj.GetType().GetProperty("upiSales")!.GetValue(summaryObj)!;
        var creditSales = (decimal)summaryObj.GetType().GetProperty("creditSales")!.GetValue(summaryObj)!;
        var expectedCash = (decimal)summaryObj.GetType().GetProperty("expectedCash")!.GetValue(summaryObj)!;

        Assert.Equal(1000m, totalSales);
        Assert.Equal(0m, cashSales);
        Assert.Equal(1000m, upiSales);
        Assert.Equal(0m, creditSales);
        Assert.Equal(0m, expectedCash);

        // Dashboard
        var controller = CreateDashboardController(db);
        var result = await controller.GetSummary(date, date, CancellationToken.None) as OkObjectResult;
        var dash = Assert.IsType<MobileDashboardSummaryDto>(result!.Value);

        Assert.Equal(100000, dash.TotalSalesPaise);
        Assert.Equal(0, dash.CashPaise);
        Assert.Equal(100000, dash.UpiPaise);
        Assert.Equal(0, dash.CreditPaise);
    }

    [Fact]
    public async Task Test3_SplitCashCredit_Sale1000_Cash600_Credit400()
    {
        await using var db = CreateDb();
        SeedLocation(db);
        var customer = SeedCustomer(db);
        var date = new DateTime(2026, 9, 20);
        var (dayStart, _) = GetUtcRangeForIstDate(date);
        var saleTime = dayStart.AddHours(5);

        // Order: ₹1,000, Cash: ₹600, Credit: ₹400
        var order = CreateTestOrder(db, customer, saleTime, 1000m, PaymentStatus.PartiallyPaid, "ORD-003");
        CreateTestPayment(db, order.Id, PaymentMethod.Cash, 600m, saleTime, "TXN-CASH-600");

        await db.SaveChangesAsync();

        var service = CreateDayCloseService(db);
        var summaryObj = await service.GetSummaryAsync(_companyId, _locationId, date);

        var totalSales = (decimal)summaryObj.GetType().GetProperty("totalSales")!.GetValue(summaryObj)!;
        var cashSales = (decimal)summaryObj.GetType().GetProperty("cashSales")!.GetValue(summaryObj)!;
        var upiSales = (decimal)summaryObj.GetType().GetProperty("upiSales")!.GetValue(summaryObj)!;
        var creditSales = (decimal)summaryObj.GetType().GetProperty("creditSales")!.GetValue(summaryObj)!;
        var expectedCash = (decimal)summaryObj.GetType().GetProperty("expectedCash")!.GetValue(summaryObj)!;

        Assert.Equal(1000m, totalSales);
        Assert.Equal(600m, cashSales);
        Assert.Equal(0m, upiSales);
        Assert.Equal(400m, creditSales);
        Assert.Equal(600m, expectedCash);

        // Gross Sales identity check
        Assert.Equal(totalSales, cashSales + upiSales + creditSales);

        // Dashboard check
        var controller = CreateDashboardController(db);
        var result = await controller.GetSummary(date, date, CancellationToken.None) as OkObjectResult;
        var dash = Assert.IsType<MobileDashboardSummaryDto>(result!.Value);

        Assert.Equal(100000, dash.TotalSalesPaise);
        Assert.Equal(60000, dash.CashPaise);
        Assert.Equal(0, dash.UpiPaise);
        Assert.Equal(40000, dash.CreditPaise);
    }

    [Fact]
    public async Task Test4_SplitUpiCredit_Sale1000_Upi600_Credit400()
    {
        await using var db = CreateDb();
        SeedLocation(db);
        var customer = SeedCustomer(db);
        var date = new DateTime(2026, 9, 20);
        var (dayStart, _) = GetUtcRangeForIstDate(date);
        var saleTime = dayStart.AddHours(6);

        // Order: ₹1,000, UPI: ₹600, Credit: ₹400
        var order = CreateTestOrder(db, customer, saleTime, 1000m, PaymentStatus.PartiallyPaid, "ORD-004");
        CreateTestPayment(db, order.Id, PaymentMethod.Upi, 600m, saleTime, "TXN-UPI-600");

        await db.SaveChangesAsync();

        var service = CreateDayCloseService(db);
        var summaryObj = await service.GetSummaryAsync(_companyId, _locationId, date);

        var totalSales = (decimal)summaryObj.GetType().GetProperty("totalSales")!.GetValue(summaryObj)!;
        var cashSales = (decimal)summaryObj.GetType().GetProperty("cashSales")!.GetValue(summaryObj)!;
        var upiSales = (decimal)summaryObj.GetType().GetProperty("upiSales")!.GetValue(summaryObj)!;
        var creditSales = (decimal)summaryObj.GetType().GetProperty("creditSales")!.GetValue(summaryObj)!;
        var expectedCash = (decimal)summaryObj.GetType().GetProperty("expectedCash")!.GetValue(summaryObj)!;

        Assert.Equal(1000m, totalSales);
        Assert.Equal(0m, cashSales);
        Assert.Equal(600m, upiSales);
        Assert.Equal(400m, creditSales);
        Assert.Equal(0m, expectedCash);

        // Dashboard check
        var controller = CreateDashboardController(db);
        var result = await controller.GetSummary(date, date, CancellationToken.None) as OkObjectResult;
        var dash = Assert.IsType<MobileDashboardSummaryDto>(result!.Value);

        Assert.Equal(100000, dash.TotalSalesPaise);
        Assert.Equal(0, dash.CashPaise);
        Assert.Equal(60000, dash.UpiPaise);
        Assert.Equal(40000, dash.CreditPaise);
    }

    [Fact]
    public async Task Test5_MultiTenderSplit_Sale1000_Cash400_Upi300_Credit300()
    {
        await using var db = CreateDb();
        SeedLocation(db);
        var customer = SeedCustomer(db);
        var date = new DateTime(2026, 9, 20);
        var (dayStart, _) = GetUtcRangeForIstDate(date);
        var saleTime = dayStart.AddHours(7);

        // Order: ₹1,000, Cash: ₹400, UPI: ₹300, Credit: ₹300
        var order = CreateTestOrder(db, customer, saleTime, 1000m, PaymentStatus.PartiallyPaid, "ORD-005");
        CreateTestPayment(db, order.Id, PaymentMethod.Cash, 400m, saleTime, "TXN-MULTI-CASH");
        CreateTestPayment(db, order.Id, PaymentMethod.Upi, 300m, saleTime, "TXN-MULTI-UPI");

        await db.SaveChangesAsync();

        var service = CreateDayCloseService(db);
        var summaryObj = await service.GetSummaryAsync(_companyId, _locationId, date);

        var totalSales = (decimal)summaryObj.GetType().GetProperty("totalSales")!.GetValue(summaryObj)!;
        var cashSales = (decimal)summaryObj.GetType().GetProperty("cashSales")!.GetValue(summaryObj)!;
        var upiSales = (decimal)summaryObj.GetType().GetProperty("upiSales")!.GetValue(summaryObj)!;
        var creditSales = (decimal)summaryObj.GetType().GetProperty("creditSales")!.GetValue(summaryObj)!;
        var expectedCash = (decimal)summaryObj.GetType().GetProperty("expectedCash")!.GetValue(summaryObj)!;

        Assert.Equal(1000m, totalSales);
        Assert.Equal(400m, cashSales);
        Assert.Equal(300m, upiSales);
        Assert.Equal(300m, creditSales);
        Assert.Equal(400m, expectedCash);

        // Dashboard check
        var controller = CreateDashboardController(db);
        var result = await controller.GetSummary(date, date, CancellationToken.None) as OkObjectResult;
        var dash = Assert.IsType<MobileDashboardSummaryDto>(result!.Value);

        Assert.Equal(100000, dash.TotalSalesPaise);
        Assert.Equal(40000, dash.CashPaise);
        Assert.Equal(30000, dash.UpiPaise);
        Assert.Equal(30000, dash.CreditPaise);
    }

    [Fact]
    public async Task Test6_HistoricalCreditCollection_Day1Sale_Day2CashCollection()
    {
        await using var db = CreateDb();
        SeedLocation(db);
        var customer = SeedCustomer(db);

        var day1 = new DateTime(2026, 9, 20);
        var (day1Start, _) = GetUtcRangeForIstDate(day1);
        var day1Time = day1Start.AddHours(5);

        var day2 = new DateTime(2026, 9, 21);
        var (day2Start, _) = GetUtcRangeForIstDate(day2);
        var day2Time = day2Start.AddHours(5);

        // Day 1: Order ₹1,000, Cash ₹600, Credit ₹400
        var order = CreateTestOrder(db, customer, day1Time, 1000m, PaymentStatus.PartiallyPaid, "ORD-DAY1");
        CreateTestPayment(db, order.Id, PaymentMethod.Cash, 600m, day1Time, "TXN-DAY1-CASH", PaymentType.SaleTender);

        // Day 2: Customer pays ₹400 cash against the Day 1 order
        CreateTestPayment(db, order.Id, PaymentMethod.Cash, 400m, day2Time, "TXN-DAY2-COLLECTION", PaymentType.CreditCollection);

        await db.SaveChangesAsync();

        var service = CreateDayCloseService(db);

        // --- Verify Day 1 Day Close ---
        var day1Summary = await service.GetSummaryAsync(_companyId, _locationId, day1);
        var d1Sales = (decimal)day1Summary.GetType().GetProperty("totalSales")!.GetValue(day1Summary)!;
        var d1CashSales = (decimal)day1Summary.GetType().GetProperty("cashSales")!.GetValue(day1Summary)!;
        var d1CreditSales = (decimal)day1Summary.GetType().GetProperty("creditSales")!.GetValue(day1Summary)!;
        var d1CashCollections = (decimal)day1Summary.GetType().GetProperty("cashCollections")!.GetValue(day1Summary)!;
        var d1ExpectedCash = (decimal)day1Summary.GetType().GetProperty("expectedCash")!.GetValue(day1Summary)!;

        Assert.Equal(1000m, d1Sales);
        Assert.Equal(600m, d1CashSales);
        Assert.Equal(400m, d1CreditSales);
        Assert.Equal(0m, d1CashCollections);
        Assert.Equal(600m, d1ExpectedCash);

        // --- Verify Day 2 Day Close ---
        // Day 2 has 0 new orders, but ₹400 cash collection from Day 1 order
        var day2Summary = await service.GetSummaryAsync(_companyId, _locationId, day2);
        var d2Sales = (decimal)day2Summary.GetType().GetProperty("totalSales")!.GetValue(day2Summary)!;
        var d2CashSales = (decimal)day2Summary.GetType().GetProperty("cashSales")!.GetValue(day2Summary)!;
        var d2CreditSales = (decimal)day2Summary.GetType().GetProperty("creditSales")!.GetValue(day2Summary)!;
        var d2CashCollections = (decimal)day2Summary.GetType().GetProperty("cashCollections")!.GetValue(day2Summary)!;
        var d2ExpectedCash = (decimal)day2Summary.GetType().GetProperty("expectedCash")!.GetValue(day2Summary)!;

        Assert.Equal(0m, d2Sales); // Collection does NOT increase today's Gross Sales
        Assert.Equal(0m, d2CashSales);
        Assert.Equal(0m, d2CreditSales);
        Assert.Equal(400m, d2CashCollections);
        Assert.Equal(400m, d2ExpectedCash); // Expected cash includes today's cash collections

        // Dashboard for Day 2 only: 0 sales
        var controller = CreateDashboardController(db);
        var d2Result = await controller.GetSummary(day2, day2, CancellationToken.None) as OkObjectResult;
        var d2Dash = Assert.IsType<MobileDashboardSummaryDto>(d2Result!.Value);
        Assert.Equal(0, d2Dash.TotalSalesPaise);
        Assert.Equal(0, d2Dash.CreditPaise);
    }

    [Fact]
    public async Task Test7_HistoricalCreditCollection_Day3UpiCollection()
    {
        await using var db = CreateDb();
        SeedLocation(db);
        var customer = SeedCustomer(db);

        var day1 = new DateTime(2026, 9, 20);
        var (day1Start, _) = GetUtcRangeForIstDate(day1);
        var day1Time = day1Start.AddHours(5);

        var day3 = new DateTime(2026, 9, 22);
        var (day3Start, _) = GetUtcRangeForIstDate(day3);
        var day3Time = day3Start.AddHours(5);

        // Day 1: Order ₹1,000, 100% Credit
        var order = CreateTestOrder(db, customer, day1Time, 1000m, PaymentStatus.Credit, "ORD-CREDIT-ONLY");

        // Day 3: Customer pays ₹1,000 via UPI
        CreateTestPayment(db, order.Id, PaymentMethod.Upi, 1000m, day3Time, "TXN-DAY3-UPI", PaymentType.CreditCollection);

        await db.SaveChangesAsync();

        var service = CreateDayCloseService(db);

        // Day 3 Day Close
        var day3Summary = await service.GetSummaryAsync(_companyId, _locationId, day3);
        var d3Sales = (decimal)day3Summary.GetType().GetProperty("totalSales")!.GetValue(day3Summary)!;
        var d3CashSales = (decimal)day3Summary.GetType().GetProperty("cashSales")!.GetValue(day3Summary)!;
        var d3UpiCollections = (decimal)day3Summary.GetType().GetProperty("upiCollections")!.GetValue(day3Summary)!;
        var d3ExpectedCash = (decimal)day3Summary.GetType().GetProperty("expectedCash")!.GetValue(day3Summary)!;

        Assert.Equal(0m, d3Sales);
        Assert.Equal(0m, d3CashSales);
        Assert.Equal(1000m, d3UpiCollections);
        Assert.Equal(0m, d3ExpectedCash); // UPI collection does not affect cash drawer
    }

    [Fact]
    public async Task Test8_CancelledOrder_ExcludedFromSalesAndCreditCreated()
    {
        await using var db = CreateDb();
        SeedLocation(db);
        var customer = SeedCustomer(db);
        var date = new DateTime(2026, 9, 20);
        var (dayStart, _) = GetUtcRangeForIstDate(date);
        var saleTime = dayStart.AddHours(5);

        // Cancelled order of ₹1,000
        var cancelledOrder = CreateTestOrder(db, customer, saleTime, 1000m, PaymentStatus.Credit, "ORD-CANCELLED");
        cancelledOrder.Cancel("Customer changed mind");

        await db.SaveChangesAsync();

        var service = CreateDayCloseService(db);
        var summaryObj = await service.GetSummaryAsync(_companyId, _locationId, date);

        var totalOrders = (int)summaryObj.GetType().GetProperty("totalOrders")!.GetValue(summaryObj)!;
        var totalSales = (decimal)summaryObj.GetType().GetProperty("totalSales")!.GetValue(summaryObj)!;
        var creditSales = (decimal)summaryObj.GetType().GetProperty("creditSales")!.GetValue(summaryObj)!;

        Assert.Equal(0, totalOrders);
        Assert.Equal(0m, totalSales);
        Assert.Equal(0m, creditSales);

        // Dashboard check
        var controller = CreateDashboardController(db);
        var result = await controller.GetSummary(date, date, CancellationToken.None) as OkObjectResult;
        var dash = Assert.IsType<MobileDashboardSummaryDto>(result!.Value);

        Assert.Equal(0, dash.OrderCount);
        Assert.Equal(0, dash.TotalSalesPaise);
        Assert.Equal(0, dash.CreditPaise);
    }

    [Fact]
    public async Task Test9_MidnightIstBoundary_CorrectlySegmentsDays()
    {
        await using var db = CreateDb();
        SeedLocation(db);
        var customer = SeedCustomer(db);

        var day1 = new DateTime(2026, 9, 20);
        var (day1Start, day1End) = GetUtcRangeForIstDate(day1);

        // Sale 1: 23:59:00 IST on Day 1 (1 minute before Day 1 end)
        var sale1Time = day1End.AddMinutes(-1);
        var order1 = CreateTestOrder(db, customer, sale1Time, 500m, PaymentStatus.Paid, "ORD-LATE-NIGHT");
        CreateTestPayment(db, order1.Id, PaymentMethod.Cash, 500m, sale1Time, "TXN-LATE");

        // Sale 2: 00:01:00 IST on Day 2 (1 minute after Day 2 start)
        var sale2Time = day1End.AddMinutes(1);
        var day2 = new DateTime(2026, 9, 21);
        var order2 = CreateTestOrder(db, customer, sale2Time, 700m, PaymentStatus.Paid, "ORD-EARLY-MORN");
        CreateTestPayment(db, order2.Id, PaymentMethod.Cash, 700m, sale2Time, "TXN-EARLY");

        await db.SaveChangesAsync();

        var service = CreateDayCloseService(db);

        // Day 1 Day Close: Only Order 1 (₹500)
        var d1Summary = await service.GetSummaryAsync(_companyId, _locationId, day1);
        var d1Sales = (decimal)d1Summary.GetType().GetProperty("totalSales")!.GetValue(d1Summary)!;
        var d1Orders = (int)d1Summary.GetType().GetProperty("totalOrders")!.GetValue(d1Summary)!;
        Assert.Equal(1, d1Orders);
        Assert.Equal(500m, d1Sales);

        // Day 2 Day Close: Only Order 2 (₹700)
        var d2Summary = await service.GetSummaryAsync(_companyId, _locationId, day2);
        var d2Sales = (decimal)d2Summary.GetType().GetProperty("totalSales")!.GetValue(d2Summary)!;
        var d2Orders = (int)d2Summary.GetType().GetProperty("totalOrders")!.GetValue(d2Summary)!;
        Assert.Equal(1, d2Orders);
        Assert.Equal(700m, d2Sales);
    }

    [Fact]
    public async Task Test10_OldCreditCollection_Plus_TodayNewSale_DrawerAccumulation()
    {
        await using var db = CreateDb();
        SeedLocation(db);
        var customer = SeedCustomer(db);

        var day1 = new DateTime(2026, 9, 20);
        var (day1Start, _) = GetUtcRangeForIstDate(day1);
        var day1Time = day1Start.AddHours(4);

        var day2 = new DateTime(2026, 9, 21);
        var (day2Start, _) = GetUtcRangeForIstDate(day2);
        var day2Time = day2Start.AddHours(4);

        // Day 1: Old Order ₹500 on Credit
        var oldOrder = CreateTestOrder(db, customer, day1Time, 500m, PaymentStatus.Credit, "ORD-OLD");

        // Day 2: New Order ₹1,000 Cash
        var newOrder = CreateTestOrder(db, customer, day2Time, 1000m, PaymentStatus.Paid, "ORD-NEW");
        CreateTestPayment(db, newOrder.Id, PaymentMethod.Cash, 1000m, day2Time, "TXN-NEW-CASH");

        // Day 2: Cash collection of ₹500 against old order
        CreateTestPayment(db, oldOrder.Id, PaymentMethod.Cash, 500m, day2Time, "TXN-COLLECTION-500", PaymentType.CreditCollection);

        await db.SaveChangesAsync();

        var service = CreateDayCloseService(db);
        var day2Summary = await service.GetSummaryAsync(_companyId, _locationId, day2);

        var d2Sales = (decimal)day2Summary.GetType().GetProperty("totalSales")!.GetValue(day2Summary)!;
        var d2CashSales = (decimal)day2Summary.GetType().GetProperty("cashSales")!.GetValue(day2Summary)!;
        var d2Collections = (decimal)day2Summary.GetType().GetProperty("cashCollections")!.GetValue(day2Summary)!;
        var d2ExpectedCash = (decimal)day2Summary.GetType().GetProperty("expectedCash")!.GetValue(day2Summary)!;

        Assert.Equal(1000m, d2Sales); // Only today's sale
        Assert.Equal(1000m, d2CashSales);
        Assert.Equal(500m, d2Collections); // Old credit collection
        Assert.Equal(1500m, d2ExpectedCash); // Expected cash = 1000 cash sale + 500 cash collection
    }

    [Fact]
    public async Task Test11_MandatorySameDayCollection_CreditCollection_DoesNotMutate_GrossSales_Or_CreditCreated()
    {
        await using var db = CreateDb();
        SeedLocation(db);
        var customer = SeedCustomer(db);

        var date = new DateTime(2026, 9, 20);
        var (dayStart, _) = GetUtcRangeForIstDate(date);
        var morningTime = dayStart.AddHours(4); // 10:00 AM IST
        var afternoonTime = dayStart.AddHours(10); // 4:00 PM IST

        // 10:00 AM: Order ₹1,000 with ₹600 cash tender (PaymentType.SaleTender)
        var order = CreateTestOrder(db, customer, morningTime, 1000m, PaymentStatus.PartiallyPaid, "ORD-SAMEDAY");
        CreateTestPayment(db, order.Id, PaymentMethod.Cash, 600m, morningTime, "TXN-MORNING-CASH", PaymentType.SaleTender);

        // 4:00 PM: Customer makes a credit collection payment of ₹200 cash (PaymentType.CreditCollection)
        CreateTestPayment(db, order.Id, PaymentMethod.Cash, 200m, afternoonTime, "TXN-AFTERNOON-COLLECTION", PaymentType.CreditCollection);

        await db.SaveChangesAsync();

        var service = CreateDayCloseService(db);
        var summaryObj = await service.GetSummaryAsync(_companyId, _locationId, date);

        var totalSales = (decimal)summaryObj.GetType().GetProperty("totalSales")!.GetValue(summaryObj)!;
        var cashSales = (decimal)summaryObj.GetType().GetProperty("cashSales")!.GetValue(summaryObj)!;
        var creditSales = (decimal)summaryObj.GetType().GetProperty("creditSales")!.GetValue(summaryObj)!;
        var cashCollections = (decimal)summaryObj.GetType().GetProperty("cashCollections")!.GetValue(summaryObj)!;
        var expectedCash = (decimal)summaryObj.GetType().GetProperty("expectedCash")!.GetValue(summaryObj)!;

        // Invariants:
        // 1. Gross sales must remain ₹1,000 (NOT ₹1,200)
        Assert.Equal(1000m, totalSales);
        // 2. Cash sales tender must remain ₹600 (NOT ₹800)
        Assert.Equal(600m, cashSales);
        // 3. Credit created must remain ₹400 (NOT ₹200)
        Assert.Equal(400m, creditSales);
        // 4. Cash collections must be ₹200
        Assert.Equal(200m, cashCollections);
        // 5. Drawer expected cash must be ₹800 (₹600 cash sale + ₹200 cash collection)
        Assert.Equal(800m, expectedCash);
        // 6. Identity: Gross Sales == Cash Sales + Credit Created
        Assert.Equal(totalSales, cashSales + creditSales);

        // Dashboard Verification:
        var controller = CreateDashboardController(db);
        var result = await controller.GetSummary(date, date, CancellationToken.None) as OkObjectResult;
        var dash = Assert.IsType<MobileDashboardSummaryDto>(result!.Value);

        Assert.Equal(100000, dash.TotalSalesPaise);
        Assert.Equal(60000, dash.CashPaise);
        Assert.Equal(40000, dash.CreditPaise);
    }
}
