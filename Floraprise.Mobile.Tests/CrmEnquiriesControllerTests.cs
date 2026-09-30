using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.EntityFrameworkCore.Storage;
using Sumpooj.API.Controllers;
using Sumpooj.Application.Common;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;
using Xunit;

namespace Floraprise.Mobile.Tests;

public sealed class CrmEnquiriesControllerTests
{
    private readonly Guid _companyId = Guid.NewGuid();
    private readonly Guid _otherCompanyId = Guid.NewGuid();
    private readonly string _databaseName = $"CrmEnquiriesTest_{Guid.NewGuid():N}";
    private readonly InMemoryDatabaseRoot _databaseRoot = new();

    private SumpoojDbContext CreateDb(Guid? companyId = null)
    {
        var options = new DbContextOptionsBuilder<SumpoojDbContext>()
            .UseInMemoryDatabase(_databaseName, _databaseRoot)
            .ConfigureWarnings(w => w.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options;

        return new SumpoojDbContext(options, new TestTenantContext(companyId ?? _companyId));
    }

    private CrmEnquiriesController Controller(SumpoojDbContext db, Guid? companyId = null) =>
        new(db, new TestTenantContext(companyId ?? _companyId));

    private Customer CreateCustomer(SumpoojDbContext db, Guid companyId, string name, string phone)
    {
        var customer = new Customer(companyId, name, "customer@example.com", phone);
        db.Customers.Add(customer);
        return customer;
    }

    [Fact]
    public async Task CreateEnquiry_LinksToExistingCustomer_WhenFoundByPhone()
    {
        await using var db = CreateDb();
        var customer = CreateCustomer(db, _companyId, "Priya Sharma", "9876543210");
        await db.SaveChangesAsync();

        var controller = Controller(db);
        var request = new CreateCrmEnquiryRequest(
            ClientSyncId: Guid.NewGuid().ToString(),
            CustomerId: null,
            CustomerPhone: "+91 9876543210",
            CustomerName: "Priya Sharma",
            Category: "Wedding",
            Requirement: "50 Red Roses for stage decoration",
            EventDate: DateTime.UtcNow.AddDays(14),
            BudgetAmount: 5000.00m,
            Location: "Taj Hotel, Mumbai",
            Notes: "Pastel theme",
            NextAction: "Call on Friday",
            NextFollowUpAtUtc: DateTime.UtcNow.AddDays(2));

        var result = await controller.CreateEnquiry(request);
        var createdResult = Assert.IsType<CreatedAtActionResult>(result);
        var dto = Assert.IsType<CrmEnquiryDto>(createdResult.Value);

        Assert.Equal(customer.Id, dto.CustomerId);
        Assert.Equal("Priya Sharma", dto.CustomerName);
        Assert.Equal("9876543210", dto.CustomerPhone);
        Assert.Equal(5000.00m, dto.BudgetAmount);
        Assert.Equal("Wedding", dto.Category);
        Assert.Equal("new", dto.Status);
    }

    [Fact]
    public async Task CreateEnquiry_AutoCreatesCustomer_WhenCustomerDoesNotExist()
    {
        await using var db = CreateDb();
        var controller = Controller(db);
        var request = new CreateCrmEnquiryRequest(
            ClientSyncId: Guid.NewGuid().ToString(),
            CustomerId: null,
            CustomerPhone: "9123456780",
            CustomerName: "Rahul Verma",
            Category: "Birthday",
            Requirement: "Carnation bouquet with balloons",
            EventDate: DateTime.UtcNow.AddDays(3),
            BudgetAmount: 1500.50m,
            Location: "Indiranagar",
            Notes: null,
            NextAction: "Send catalog",
            NextFollowUpAtUtc: null);

        var result = await controller.CreateEnquiry(request);
        var createdResult = Assert.IsType<CreatedAtActionResult>(result);
        var dto = Assert.IsType<CrmEnquiryDto>(createdResult.Value);

        Assert.NotEqual(Guid.Empty, dto.CustomerId);
        Assert.Equal("Rahul Verma", dto.CustomerName);
        Assert.Equal("9123456780", dto.CustomerPhone);
        Assert.Equal(1500.50m, dto.BudgetAmount);

        // Verify customer was created in DB
        var savedCustomer = await db.Customers.FirstOrDefaultAsync(c => c.Id == dto.CustomerId && c.CompanyId == _companyId);
        Assert.NotNull(savedCustomer);
        Assert.Equal("Rahul Verma", savedCustomer.Name);
        Assert.Equal("9123456780", savedCustomer.Phone);
    }

    [Fact]
    public async Task CreateEnquiry_IsIdempotent_OnCompanyAndClientSyncId()
    {
        await using var db = CreateDb();
        var controller = Controller(db);
        var syncId = Guid.NewGuid().ToString();

        var request1 = new CreateCrmEnquiryRequest(
            ClientSyncId: syncId,
            CustomerId: null,
            CustomerPhone: "9876500001",
            CustomerName: "Aarav",
            Category: "Corporate",
            Requirement: "Office lobby floral setup",
            EventDate: null,
            BudgetAmount: 8000.00m,
            Location: "Tech Park",
            Notes: null,
            NextAction: "Visit site",
            NextFollowUpAtUtc: null);

        var result1 = await controller.CreateEnquiry(request1);
        var created1 = Assert.IsType<CreatedAtActionResult>(result1);
        var dto1 = Assert.IsType<CrmEnquiryDto>(created1.Value);

        // Re-post same ClientSyncId
        var result2 = await controller.CreateEnquiry(request1);
        var okResult2 = Assert.IsType<OkObjectResult>(result2);
        var dto2 = Assert.IsType<CrmEnquiryDto>(okResult2.Value);

        Assert.Equal(dto1.Id, dto2.Id);
        Assert.Equal(dto1.ClientSyncId, dto2.ClientSyncId);

        // Verify only 1 enquiry exists in DB
        var count = await db.CrmEnquiries.CountAsync(e => e.CompanyId == _companyId && e.ClientSyncId == syncId);
        Assert.Equal(1, count);
    }

    [Fact]
    public async Task ListEnquiries_EnforcesTenantIsolation()
    {
        await using var db = CreateDb();

        // Company 1 enquiry
        var cust1 = CreateCustomer(db, _companyId, "Company 1 Customer", "9000000001");
        var enquiry1 = new CrmEnquiry(_companyId, cust1.Id, Guid.NewGuid().ToString(), "Flowers", "Roses for C1", null, 1000m, null, null, null, null);
        db.CrmEnquiries.Add(enquiry1);

        // Company 2 enquiry
        var cust2 = CreateCustomer(db, _otherCompanyId, "Company 2 Customer", "9000000002");
        var enquiry2 = new CrmEnquiry(_otherCompanyId, cust2.Id, Guid.NewGuid().ToString(), "Flowers", "Lilies for C2", null, 2000m, null, null, null, null);
        db.CrmEnquiries.Add(enquiry2);

        await db.SaveChangesAsync();

        // Query with Company 1
        var controller1 = Controller(db, _companyId);
        var result1 = await controller1.ListEnquiries();
        var okResult1 = Assert.IsType<OkObjectResult>(result1);
        var paged1 = Assert.IsType<PagedResult<CrmEnquiryDto>>(okResult1.Value);

        Assert.Single(paged1.Items);
        Assert.Equal("Roses for C1", paged1.Items[0].Requirement);

        // Query with Company 2
        var controller2 = Controller(db, _otherCompanyId);
        var result2 = await controller2.ListEnquiries();
        var okResult2 = Assert.IsType<OkObjectResult>(result2);
        var paged2 = Assert.IsType<PagedResult<CrmEnquiryDto>>(okResult2.Value);

        Assert.Single(paged2.Items);
        Assert.Equal("Lilies for C2", paged2.Items[0].Requirement);
    }

    [Fact]
    public async Task UpdateEnquiry_UpdatesFieldsAndStatus()
    {
        await using var db = CreateDb();
        var cust = CreateCustomer(db, _companyId, "Sunita Rao", "9871122334");
        var enquiry = new CrmEnquiry(_companyId, cust.Id, Guid.NewGuid().ToString(), "Wedding", "Mandap flowers", null, 12000m, "Grand Palace", null, "Initial quote", null);
        db.CrmEnquiries.Add(enquiry);
        await db.SaveChangesAsync();

        var controller = Controller(db);
        var updateRequest = new UpdateCrmEnquiryRequest(
            Category: "Wedding Decor",
            Requirement: "Mandap flowers with exotic orchids",
            EventDate: DateTime.UtcNow.AddDays(30),
            BudgetAmount: 15000.00m,
            Location: "Grand Palace - Hall A",
            Notes: "Client requested white and purple theme",
            NextAction: "Confirm quote details",
            NextFollowUpAtUtc: DateTime.UtcNow.AddDays(5),
            Status: "follow_up",
            LostReason: null,
            QuoteOrderId: null,
            ConvertedOrderId: null);

        var updateResult = await controller.UpdateEnquiry(enquiry.Id, updateRequest);
        var okResult = Assert.IsType<OkObjectResult>(updateResult);
        var dto = Assert.IsType<CrmEnquiryDto>(okResult.Value);

        Assert.Equal("Wedding Decor", dto.Category);
        Assert.Equal("Mandap flowers with exotic orchids", dto.Requirement);
        Assert.Equal(15000.00m, dto.BudgetAmount);
        Assert.Equal("follow_up", dto.Status);
    }

    [Theory]
    [InlineData("new")]
    [InlineData("follow_up")]
    [InlineData("quote_sent")]
    [InlineData("won")]
    [InlineData("lost")]
    public async Task UpdateEnquiry_AcceptsAllApprovedStatuses(string status)
    {
        await using var db = CreateDb();
        var cust = CreateCustomer(db, _companyId, "Status Test Cust", "9876543210");
        var enquiry = new CrmEnquiry(_companyId, cust.Id, Guid.NewGuid().ToString(), "General", "Requirement", null, null, null, null, null, null);
        db.CrmEnquiries.Add(enquiry);
        await db.SaveChangesAsync();

        var controller = Controller(db);
        var updateRequest = new UpdateCrmEnquiryRequest(
            Category: "General",
            Requirement: "Requirement",
            EventDate: null,
            BudgetAmount: null,
            Location: null,
            Notes: null,
            NextAction: null,
            NextFollowUpAtUtc: null,
            Status: status,
            LostReason: status == "lost" ? "Customer cancelled" : null,
            QuoteOrderId: null,
            ConvertedOrderId: null);

        var updateResult = await controller.UpdateEnquiry(enquiry.Id, updateRequest);
        var okResult = Assert.IsType<OkObjectResult>(updateResult);
        var dto = Assert.IsType<CrmEnquiryDto>(okResult.Value);
        Assert.Equal(status, dto.Status);
    }

    [Theory]
    [InlineData("in_discussion")]
    [InlineData("quoted")]
    [InlineData("cancelled")]
    [InlineData("invalid_status")]
    public async Task UpdateEnquiry_RejectsInvalidOrRemovedStatuses(string invalidStatus)
    {
        await using var db = CreateDb();
        var cust = CreateCustomer(db, _companyId, "Status Reject Cust", "9876543210");
        var enquiry = new CrmEnquiry(_companyId, cust.Id, Guid.NewGuid().ToString(), "General", "Requirement", null, null, null, null, null, null);
        db.CrmEnquiries.Add(enquiry);
        await db.SaveChangesAsync();

        var controller = Controller(db);
        var updateRequest = new UpdateCrmEnquiryRequest(
            Category: "General",
            Requirement: "Requirement",
            EventDate: null,
            BudgetAmount: null,
            Location: null,
            Notes: null,
            NextAction: null,
            NextFollowUpAtUtc: null,
            Status: invalidStatus,
            LostReason: null,
            QuoteOrderId: null,
            ConvertedOrderId: null);

        var updateResult = await controller.UpdateEnquiry(enquiry.Id, updateRequest);
        var badRequest = Assert.IsType<BadRequestObjectResult>(updateResult);
        Assert.Contains("Invalid status", badRequest.Value?.ToString());
    }

    [Fact]
    public async Task DeleteEnquiry_SoftDeletesRecord()
    {
        await using var db = CreateDb();
        var cust = CreateCustomer(db, _companyId, "Test Cust", "9998887776");
        var enquiry = new CrmEnquiry(_companyId, cust.Id, Guid.NewGuid().ToString(), "General", "Test requirement", null, null, null, null, null, null);
        db.CrmEnquiries.Add(enquiry);
        await db.SaveChangesAsync();

        var controller = Controller(db);
        var deleteResult = await controller.DeleteEnquiry(enquiry.Id);
        Assert.IsType<NoContentResult>(deleteResult);

        // Verify soft-deleted
        var inDb = await db.CrmEnquiries.FirstOrDefaultAsync(e => e.Id == enquiry.Id);
        Assert.NotNull(inDb);
        Assert.NotNull(inDb.DeletedAtUtc);

        // Verify excluded from list
        var listResult = await controller.ListEnquiries();
        var okList = Assert.IsType<OkObjectResult>(listResult);
        var paged = Assert.IsType<PagedResult<CrmEnquiryDto>>(okList.Value);
        Assert.Empty(paged.Items);
    }

    private sealed class TestTenantContext : ITenantContext
    {
        public TestTenantContext(Guid companyId) => CompanyId = companyId;
        public Guid? CompanyId { get; }
        public string? Region => null;
        public bool IsPlatformUser => false;
    }
}
