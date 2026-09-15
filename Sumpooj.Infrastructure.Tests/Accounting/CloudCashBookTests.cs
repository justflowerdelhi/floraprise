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
    [Fact]
    public async Task CashBookRead_WhenDateIsPreviousBusinessDate_ReturnsHistoricalEntries()
    {
        var companyId = Guid.NewGuid();
        var previous = new DateTime(2026, 9, 7, 0, 0, 0, DateTimeKind.Utc);
        var today = previous.AddDays(1);
        await using var db = CreateDb(companyId);
        db.CashBookEntries.AddRange(
            new CashBookEntry(companyId, previous, CashBookTransactionType.CashSale, "Previous sale", 200m, 200m, 0m, 200m),
            new CashBookEntry(companyId, today, CashBookTransactionType.CashSale, "Today sale", 300m, 300m, 0m, 300m));
        await db.SaveChangesAsync();

        var controller = new MobileFinanceController(db, new TenantContext(companyId));
        var result = await controller.GetCashBook(previous, null, null, null);

        var ok = Assert.IsType<OkObjectResult>(result);
        var entries = Assert.IsAssignableFrom<IEnumerable<CashBookEntryDto>>(ok.Value).ToList();
        Assert.Equal("Previous sale", entries.Single().Description);
    }

    [Fact]
    public async Task CashBookRead_WhenRangeIsProvided_IncludesAllDaysInRange()
    {
        var companyId = Guid.NewGuid();
        var start = new DateTime(2026, 9, 7, 0, 0, 0, DateTimeKind.Utc);
        var mid = start.AddDays(1);
        var end = start.AddDays(2);
        await using var db = CreateDb(companyId);
        db.CashBookEntries.AddRange(
            new CashBookEntry(companyId, start, CashBookTransactionType.CashSale, "Day 1", 100m, 100m, 0m, 100m),
            new CashBookEntry(companyId, mid, CashBookTransactionType.CashExpense, "Day 2", 40m, 0m, 40m, 60m),
            new CashBookEntry(companyId, end, CashBookTransactionType.CashSale, "Day 3", 120m, 120m, 0m, 180m));
        await db.SaveChangesAsync();

        var controller = new MobileFinanceController(db, new TenantContext(companyId));
        var result = await controller.GetCashBook(null, start, end, null);

        var ok = Assert.IsType<OkObjectResult>(result);
        var entries = Assert.IsAssignableFrom<IEnumerable<CashBookEntryDto>>(ok.Value).ToList();
        Assert.Equal(3, entries.Count);
        Assert.Equal(new[] { "Day 1", "Day 2", "Day 3" }, entries.Select(e => e.Description).ToArray());
    }

    [Fact]
    public async Task CashBookRead_UsesIstBusinessDateBoundary_ForUtcTimesNearMidnight()
    {
        var companyId = Guid.NewGuid();
        var expectedBusinessDate = new DateTime(2026, 9, 8, 0, 0, 0, DateTimeKind.Utc);
        var utcRequest = new DateTime(2026, 9, 7, 18, 30, 0, DateTimeKind.Utc);
        await using var db = CreateDb(companyId);
        db.CashBookEntries.Add(new CashBookEntry(companyId, expectedBusinessDate, CashBookTransactionType.CashSale, "IST business date", 250m, 250m, 0m, 250m));
        await db.SaveChangesAsync();

        var controller = new MobileFinanceController(db, new TenantContext(companyId));
        var result = await controller.GetCashBook(utcRequest, null, null, null);

        var ok = Assert.IsType<OkObjectResult>(result);
        var entries = Assert.IsAssignableFrom<IEnumerable<CashBookEntryDto>>(ok.Value).ToList();
        Assert.Equal("IST business date", entries.Single().Description);
    }

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

    [Fact]
    public async Task CashPaymentCollectedLater_CreatesCashBookEntryAtomicallyWithPayment()
    {
        var companyId = Guid.NewGuid();
        var date = new DateTime(2026, 9, 9, 0, 0, 0, DateTimeKind.Utc);
        await using var db = CreateDb(companyId);

        var customer = new Customer(companyId, "Customer 1", "cust@test.com", "9876543210");
        db.Customers.Add(customer);
        var order = new Order(companyId, customer.Id, date, "Address", "110001", "Recipient", "9876543210");
        order.SetImportedOrderNumber("ORD-101");
        db.Orders.Add(order);
        await db.SaveChangesAsync();

        var paymentRepo = new PaymentRepository(db);
        var payment = new Payment(companyId, order.Id, PaymentMethod.Cash, 450m);
        payment.Approve(null, null);

        await paymentRepo.AddAsync(payment, date);

        var paymentInDb = await db.Payments.SingleAsync(p => p.Id == payment.Id);
        Assert.Equal(PaymentTransactionStatus.Approved, paymentInDb.Status);

        var cashEntry = await db.CashBookEntries.SingleAsync(e => e.CompanyId == companyId);
        Assert.Equal(CashBookTransactionType.CashSale, cashEntry.TransactionType);
        Assert.Equal(450m, cashEntry.Amount);
        Assert.Equal(450m, cashEntry.CashIn);
        Assert.Equal(date.Date, cashEntry.Date);
        Assert.Contains("ORD-101", cashEntry.Description);
    }

    [Theory]
    [InlineData(PaymentMethod.Card)]
    [InlineData(PaymentMethod.Upi)]
    public async Task UpiAndCardPayments_DoNotCreateCashBookEntry(PaymentMethod method)
    {
        var companyId = Guid.NewGuid();
        var date = new DateTime(2026, 9, 9, 0, 0, 0, DateTimeKind.Utc);
        await using var db = CreateDb(companyId);

        var customer = new Customer(companyId, "Customer 1", "cust@test.com", "9876543210");
        db.Customers.Add(customer);
        var order = new Order(companyId, customer.Id, date, "Address", "110001", "Recipient", "9876543210");
        order.SetImportedOrderNumber("ORD-102");
        db.Orders.Add(order);
        await db.SaveChangesAsync();

        var paymentRepo = new PaymentRepository(db);
        var payment = new Payment(companyId, order.Id, method, 500m);
        payment.Approve(null, null);

        await paymentRepo.AddAsync(payment, date);

        Assert.Single(db.Payments);
        Assert.Empty(db.CashBookEntries);
    }

    [Fact]
    public async Task DayClose_IncludesAllCashPayments_PosSalesAndLaterCollections()
    {
        var companyId = Guid.NewGuid();
        var date = new DateTime(2026, 9, 9, 0, 0, 0, DateTimeKind.Utc);
        await using var db = CreateDb(companyId);

        db.OpeningCashEntries.Add(new OpeningCash(companyId, date, 200m));

        // 1. POS cash sale entry
        db.CashBookEntries.Add(new CashBookEntry(
            companyId, date, CashBookTransactionType.CashSale, "POS cash sale POS-001", 300m, 300m, 0m, 500m));

        // 2. Later cash collection via Payment
        var customer = new Customer(companyId, "Customer 1", null, "9876543210");
        db.Customers.Add(customer);
        var order = new Order(companyId, customer.Id, date, "Address", "110001", "Recipient", "9876543210");
        order.SetImportedOrderNumber("ORD-COLLECT");
        db.Orders.Add(order);
        await db.SaveChangesAsync();

        var paymentRepo = new PaymentRepository(db);
        var payment = new Payment(companyId, order.Id, PaymentMethod.Cash, 250m);
        payment.Approve(null, null);
        await paymentRepo.AddAsync(payment, date);

        // 3. Expense
        db.CashBookEntries.Add(new CashBookEntry(
            companyId, date, CashBookTransactionType.CashExpense, "Supplies", 50m, 0m, 50m, 700m));
        await db.SaveChangesAsync();

        var summary = await new DayCloseRepository(db).GetSummaryAsync(companyId, date);

        Assert.Equal(200m, summary.OpeningCash);
        Assert.Equal(550m, summary.CashSales); // 300 POS + 250 collected later
        Assert.Equal(50m, summary.CashExpenses);
        Assert.Equal(700m, summary.OpeningCash + summary.CashSales + summary.CashReceived - summary.CashExpenses - summary.CashPaid);
    }

    [Fact]
    public async Task IdempotentRetry_DoesNotDuplicateCashBookEntry()
    {
        var companyId = Guid.NewGuid();
        var date = new DateTime(2026, 9, 9, 0, 0, 0, DateTimeKind.Utc);
        await using var db = CreateDb(companyId);

        var customer = new Customer(companyId, "Customer 1", null, "9876543210");
        db.Customers.Add(customer);
        var order = new Order(companyId, customer.Id, date, "Address", "110001", "Recipient", "9876543210");
        order.SetImportedOrderNumber("ORD-RETRY");
        db.Orders.Add(order);
        await db.SaveChangesAsync();

        var paymentRepo = new PaymentRepository(db);
        var payment = new Payment(companyId, order.Id, PaymentMethod.Cash, 100m);
        payment.Approve(null, null);

        await paymentRepo.AddAsync(payment, date);
        Assert.Single(db.CashBookEntries);

        // Retry / update
        await paymentRepo.UpdateAsync(payment, date);
        Assert.Single(db.CashBookEntries);
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