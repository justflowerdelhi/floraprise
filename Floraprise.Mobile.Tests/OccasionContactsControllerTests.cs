using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.EntityFrameworkCore.Storage;
using Sumpooj.API.Controllers;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;
using Xunit;

namespace Floraprise.Mobile.Tests;

public sealed class OccasionContactsControllerTests
{
    private readonly Guid _companyId = Guid.NewGuid();
    private readonly Guid _otherCompanyId = Guid.NewGuid();
    private readonly string _databaseName = $"OccasionContactsTest_{Guid.NewGuid():N}";
    private readonly InMemoryDatabaseRoot _databaseRoot = new();

    private SumpoojDbContext CreateDb(Guid? companyId = null)
    {
        var options = new DbContextOptionsBuilder<SumpoojDbContext>()
            .UseInMemoryDatabase(_databaseName, _databaseRoot)
            .ConfigureWarnings(w => w.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options;

        return new SumpoojDbContext(options, new TestTenantContext(companyId ?? _companyId));
    }

    private OccasionContactsController Controller(SumpoojDbContext db, Guid? companyId = null) =>
        new(db, new TestTenantContext(companyId ?? _companyId));

    private Customer CreateCustomer(SumpoojDbContext db, Guid companyId, string name, string phone)
    {
        var customer = new Customer(companyId, name, "customer@example.com", phone);
        db.Customers.Add(customer);
        return customer;
    }

    private OccasionContact CreateContact(
        SumpoojDbContext db,
        Guid companyId,
        Guid customerId,
        string recipientName,
        string relationship,
        string occasion,
        DateTime occasionDate,
        string phone = "9988776655")
    {
        var contact = new OccasionContact(companyId, customerId);
        contact.Update(recipientName, relationship, occasion, occasionDate, phone, "Flowers Inc", "Notes", true, "Manual");
        db.OccasionContacts.Add(contact);
        return contact;
    }

    [Fact]
    public async Task List_ReturnsOk200_WithExpectedData()
    {
        await using var db = CreateDb();
        var customer = CreateCustomer(db, _companyId, "Alice Smith", "9876543210");
        CreateContact(db, _companyId, customer.Id, "Bob Smith", "Brother", "Birthday", new DateTime(2026, 10, 15, 0, 0, 0, DateTimeKind.Utc));
        await db.SaveChangesAsync();

        var result = await Controller(db).List(null, null, null, null, null);
        var list = AssertOk<List<OccasionContactResponse>>(result);

        Assert.Single(list);
        Assert.Equal("Bob Smith", list[0].Contact.RecipientName);
        Assert.Equal("Alice Smith", list[0].CustomerName);
        Assert.Equal("9876543210", list[0].CustomerPhone);
    }

    [Fact]
    public async Task List_OrdersByOccasionDateThenRecipientName()
    {
        await using var db = CreateDb();
        var customer = CreateCustomer(db, _companyId, "Customer One", "9876543210");
        CreateContact(db, _companyId, customer.Id, "Zara", "Friend", "Birthday", new DateTime(2026, 12, 1, 0, 0, 0, DateTimeKind.Utc));
        CreateContact(db, _companyId, customer.Id, "Abby", "Sister", "Birthday", new DateTime(2026, 10, 1, 0, 0, 0, DateTimeKind.Utc));
        CreateContact(db, _companyId, customer.Id, "Aaron", "Brother", "Anniversary", new DateTime(2026, 10, 1, 0, 0, 0, DateTimeKind.Utc));
        await db.SaveChangesAsync();

        var result = await Controller(db).List(null, null, null, null, null);
        var list = AssertOk<List<OccasionContactResponse>>(result);

        Assert.Equal(3, list.Count);
        // Aaron & Abby both on Oct 1, Aaron comes first alphabetically
        Assert.Equal("Aaron", list[0].Contact.RecipientName);
        Assert.Equal("Abby", list[1].Contact.RecipientName);
        Assert.Equal("Zara", list[2].Contact.RecipientName);
    }

    [Fact]
    public async Task List_FiltersByCustomerId()
    {
        await using var db = CreateDb();
        var customer1 = CreateCustomer(db, _companyId, "Customer 1", "1111111111");
        var customer2 = CreateCustomer(db, _companyId, "Customer 2", "2222222222");
        CreateContact(db, _companyId, customer1.Id, "Contact 1", "Friend", "Birthday", DateTime.UtcNow);
        CreateContact(db, _companyId, customer2.Id, "Contact 2", "Friend", "Birthday", DateTime.UtcNow);
        await db.SaveChangesAsync();

        var result = await Controller(db).List(customer1.Id, null, null, null, null);
        var list = AssertOk<List<OccasionContactResponse>>(result);

        var single = Assert.Single(list);
        Assert.Equal("Contact 1", single.Contact.RecipientName);
    }

    [Fact]
    public async Task List_FiltersByDateRange()
    {
        await using var db = CreateDb();
        var customer = CreateCustomer(db, _companyId, "Customer", "1111111111");
        CreateContact(db, _companyId, customer.Id, "Too Early", "Friend", "Birthday", new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc));
        CreateContact(db, _companyId, customer.Id, "In Range 1", "Friend", "Birthday", new DateTime(2026, 5, 10, 0, 0, 0, DateTimeKind.Utc));
        CreateContact(db, _companyId, customer.Id, "In Range 2", "Friend", "Birthday", new DateTime(2026, 5, 20, 0, 0, 0, DateTimeKind.Utc));
        CreateContact(db, _companyId, customer.Id, "Too Late", "Friend", "Birthday", new DateTime(2026, 9, 1, 0, 0, 0, DateTimeKind.Utc));
        await db.SaveChangesAsync();

        var from = new DateTime(2026, 5, 1, 0, 0, 0, DateTimeKind.Utc);
        var to = new DateTime(2026, 5, 31, 0, 0, 0, DateTimeKind.Utc);
        var result = await Controller(db).List(null, from, to, null, null);
        var list = AssertOk<List<OccasionContactResponse>>(result);

        Assert.Equal(2, list.Count);
        Assert.Contains(list, x => x.Contact.RecipientName == "In Range 1");
        Assert.Contains(list, x => x.Contact.RecipientName == "In Range 2");
    }

    [Fact]
    public async Task List_FiltersByOccasion()
    {
        await using var db = CreateDb();
        var customer = CreateCustomer(db, _companyId, "Customer", "1111111111");
        CreateContact(db, _companyId, customer.Id, "Birthday Contact", "Friend", "Birthday", DateTime.UtcNow);
        CreateContact(db, _companyId, customer.Id, "Anniversary Contact", "Spouse", "Anniversary", DateTime.UtcNow);
        await db.SaveChangesAsync();

        var result = await Controller(db).List(null, null, null, "anniversary", null);
        var list = AssertOk<List<OccasionContactResponse>>(result);

        var single = Assert.Single(list);
        Assert.Equal("Anniversary Contact", single.Contact.RecipientName);
    }

    [Fact]
    public async Task List_FiltersByQueryText()
    {
        await using var db = CreateDb();
        var customer = CreateCustomer(db, _companyId, "Customer", "1111111111");
        CreateContact(db, _companyId, customer.Id, "Special Name", "Colleague", "Event", DateTime.UtcNow, phone: "1234567890");
        CreateContact(db, _companyId, customer.Id, "Other Name", "Partner", "Event", DateTime.UtcNow, phone: "9876543210");
        await db.SaveChangesAsync();

        // Search by recipient name
        var resultName = await Controller(db).List(null, null, null, null, "special");
        var listName = AssertOk<List<OccasionContactResponse>>(resultName);
        Assert.Single(listName);
        Assert.Equal("Special Name", listName[0].Contact.RecipientName);

        // Search by phone
        var resultPhone = await Controller(db).List(null, null, null, null, "123456");
        var listPhone = AssertOk<List<OccasionContactResponse>>(resultPhone);
        Assert.Single(listPhone);
        Assert.Equal("Special Name", listPhone[0].Contact.RecipientName);

        // Search by relationship
        var resultRel = await Controller(db).List(null, null, null, null, "colleague");
        var listRel = AssertOk<List<OccasionContactResponse>>(resultRel);
        Assert.Single(listRel);
        Assert.Equal("Special Name", listRel[0].Contact.RecipientName);
    }

    [Fact]
    public async Task List_ExcludesDeletedContacts()
    {
        await using var db = CreateDb();
        var customer = CreateCustomer(db, _companyId, "Customer", "1111111111");
        var active = CreateContact(db, _companyId, customer.Id, "Active Contact", "Friend", "Birthday", DateTime.UtcNow);
        var deleted = CreateContact(db, _companyId, customer.Id, "Deleted Contact", "Friend", "Birthday", DateTime.UtcNow);
        deleted.Delete();
        await db.SaveChangesAsync();

        var result = await Controller(db).List(null, null, null, null, null);
        var list = AssertOk<List<OccasionContactResponse>>(result);

        var single = Assert.Single(list);
        Assert.Equal("Active Contact", single.Contact.RecipientName);
    }

    [Fact]
    public async Task List_EnforcesTenantIsolation()
    {
        await using var dbA = CreateDb(_companyId);
        var customerA = CreateCustomer(dbA, _companyId, "Customer A", "1111111111");
        CreateContact(dbA, _companyId, customerA.Id, "Tenant A Contact", "Friend", "Birthday", DateTime.UtcNow);
        await dbA.SaveChangesAsync();

        await using var dbB = CreateDb(_otherCompanyId);
        var customerB = CreateCustomer(dbB, _otherCompanyId, "Customer B", "2222222222");
        CreateContact(dbB, _otherCompanyId, customerB.Id, "Tenant B Contact", "Friend", "Birthday", DateTime.UtcNow);
        await dbB.SaveChangesAsync();

        // Controller for Tenant A
        var resultA = await Controller(dbA, _companyId).List(null, null, null, null, null);
        var listA = AssertOk<List<OccasionContactResponse>>(resultA);
        Assert.Single(listA);
        Assert.Equal("Tenant A Contact", listA[0].Contact.RecipientName);

        // Controller for Tenant B
        var resultB = await Controller(dbB, _otherCompanyId).List(null, null, null, null, null);
        var listB = AssertOk<List<OccasionContactResponse>>(resultB);
        Assert.Single(listB);
        Assert.Equal("Tenant B Contact", listB[0].Contact.RecipientName);
    }

    [Fact]
    public async Task List_WhenEmpty_ReturnsOkEmptyList()
    {
        await using var db = CreateDb();
        var result = await Controller(db).List(null, null, null, null, null);
        var list = AssertOk<List<OccasionContactResponse>>(result);
        Assert.Empty(list);
    }

    [Fact]
    public void Regression_ProductionQueryPattern_FailsUnderRelationalProvider_WhileFixedQuerySucceeds()
    {
        // Configure SumpoojDbContext with Npgsql provider (without connecting) to inspect query compilation
        var npgsqlOptions = new DbContextOptionsBuilder<SumpoojDbContext>()
            .UseNpgsql("Host=localhost;Database=dummy_test;Username=test;Password=test")
            .Options;

        using var db = new SumpoojDbContext(npgsqlOptions, new TestTenantContext(_companyId));

        var rows = db.OccasionContacts.Where(x => x.CompanyId == _companyId && x.DeletedAtUtc == null);

        // 1. REPRODUCE OLD PRODUCTION PATTERN:
        // Ordering AFTER projecting into new OccasionContactResponse(contact, customer.Name, customer.Phone)
        var oldPatternQuery = (
            from contact in rows
            join customer in db.Customers on contact.CustomerId equals customer.Id
            select new OccasionContactResponse(contact, customer.Name, customer.Phone)
        ).OrderBy(x => x.Contact.OccasionDate).ThenBy(x => x.Contact.RecipientName);

        // Under Npgsql relational query compilation, the old pattern CANNOT be translated to SQL!
        var ex = Assert.Throws<InvalidOperationException>(() => oldPatternQuery.ToQueryString());
        Assert.Contains("could not be translated", ex.Message, StringComparison.OrdinalIgnoreCase);

        // 2. VERIFY NEW FIXED QUERY PATTERN:
        // Ordering BEFORE DTO projection on actual entity properties
        var fixedQuery =
            from contact in rows
            join customer in db.Customers on contact.CustomerId equals customer.Id
            orderby contact.OccasionDate, contact.RecipientName
            select new OccasionContactResponse(contact, customer.Name, customer.Phone);

        // Under Npgsql relational query compilation, the fixed query translates cleanly to SQL!
        var sql = fixedQuery.ToQueryString();
        Assert.NotNull(sql);
        Assert.Contains("ORDER BY", sql, StringComparison.OrdinalIgnoreCase);
        Assert.Contains("OccasionDate", sql, StringComparison.OrdinalIgnoreCase);
        Assert.Contains("RecipientName", sql, StringComparison.OrdinalIgnoreCase);
    }

    private static T AssertOk<T>(IActionResult result)
    {
        var ok = Assert.IsType<OkObjectResult>(result);
        return Assert.IsType<T>(ok.Value);
    }

    private sealed class TestTenantContext : ITenantContext
    {
        public TestTenantContext(Guid companyId) => CompanyId = companyId;
        public Guid? CompanyId { get; }
        public string? Region => null;
        public bool IsPlatformUser => false;
    }
}
