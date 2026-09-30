using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Common;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/crm/enquiries")]
[Authorize(Policy = PolicyNames.CompanyOnly)]
public class CrmEnquiriesController : ControllerBase
{
    private readonly SumpoojDbContext _db;
    private readonly ITenantContext _tenantContext;

    public CrmEnquiriesController(SumpoojDbContext db, ITenantContext tenantContext)
    {
        _db = db;
        _tenantContext = tenantContext;
    }

    private Guid CompanyId => _tenantContext.CompanyId
        ?? throw new UnauthorizedAccessException("Company context required");

    [HttpGet]
    public async Task<IActionResult> ListEnquiries(
        [FromQuery] string? query = null,
        [FromQuery] string? status = null,
        [FromQuery] DateTime? fromEventDate = null,
        [FromQuery] DateTime? toEventDate = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50)
    {
        var p = page <= 0 ? 1 : page;
        var ps = pageSize <= 0 ? 50 : Math.Min(pageSize, 200);

        var baseQuery = _db.CrmEnquiries
            .AsNoTracking()
            .Where(e => e.CompanyId == CompanyId && e.DeletedAtUtc == null);

        if (!string.IsNullOrWhiteSpace(status) && status.Trim().ToLowerInvariant() != "all")
        {
            var normalizedStatus = status.Trim().ToLowerInvariant();
            baseQuery = baseQuery.Where(e => e.Status == normalizedStatus);
        }

        if (fromEventDate.HasValue)
        {
            var fromUtc = fromEventDate.Value.ToUniversalTime().Date;
            baseQuery = baseQuery.Where(e => e.EventDate >= fromUtc);
        }

        if (toEventDate.HasValue)
        {
            var toUtc = toEventDate.Value.ToUniversalTime().Date.AddDays(1).AddTicks(-1);
            baseQuery = baseQuery.Where(e => e.EventDate <= toUtc);
        }

        var totalCount = await baseQuery.CountAsync();

        var enquiries = await baseQuery
            .OrderByDescending(e => e.CreatedAtUtc)
            .Skip((p - 1) * ps)
            .Take(ps)
            .ToListAsync();

        var customerIds = enquiries.Select(e => e.CustomerId).Distinct().ToList();
        var customers = await _db.Customers
            .AsNoTracking()
            .Where(c => c.CompanyId == CompanyId && customerIds.Contains(c.Id))
            .ToDictionaryAsync(c => c.Id);

        var items = new List<CrmEnquiryDto>();
        var searchLower = query?.Trim().ToLowerInvariant();

        foreach (var e in enquiries)
        {
            customers.TryGetValue(e.CustomerId, out var customer);
            var custName = customer?.Name ?? "Customer";
            var custPhone = customer?.Phone ?? string.Empty;

            if (!string.IsNullOrWhiteSpace(searchLower))
            {
                var match = custName.ToLowerInvariant().Contains(searchLower) ||
                            custPhone.ToLowerInvariant().Contains(searchLower) ||
                            e.Requirement.ToLowerInvariant().Contains(searchLower) ||
                            e.Category.ToLowerInvariant().Contains(searchLower) ||
                            (e.Location != null && e.Location.ToLowerInvariant().Contains(searchLower));

                if (!match) continue;
            }

            items.Add(ToDto(e, custName, custPhone));
        }

        return Ok(new PagedResult<CrmEnquiryDto>(items, totalCount, p, ps));
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetEnquiry(Guid id)
    {
        var enquiry = await _db.CrmEnquiries
            .AsNoTracking()
            .FirstOrDefaultAsync(e => e.Id == id && e.CompanyId == CompanyId && e.DeletedAtUtc == null);

        if (enquiry == null) return NotFound();

        var customer = await _db.Customers
            .AsNoTracking()
            .FirstOrDefaultAsync(c => c.Id == enquiry.CustomerId && c.CompanyId == CompanyId);

        return Ok(ToDto(enquiry, customer?.Name ?? "Customer", customer?.Phone ?? string.Empty));
    }

    [HttpPost]
    public async Task<IActionResult> CreateEnquiry([FromBody] CreateCrmEnquiryRequest request)
    {
        if (request == null) return BadRequest("Request body is required.");
        if (string.IsNullOrWhiteSpace(request.ClientSyncId)) return BadRequest("ClientSyncId is required.");
        if (string.IsNullOrWhiteSpace(request.Requirement)) return BadRequest("Requirement is required.");

        // Idempotency: return existing if ClientSyncId already processed for this company
        var existing = await _db.CrmEnquiries
            .FirstOrDefaultAsync(e => e.CompanyId == CompanyId && e.ClientSyncId == request.ClientSyncId && e.DeletedAtUtc == null);

        if (existing != null)
        {
            var existingCust = await _db.Customers
                .AsNoTracking()
                .FirstOrDefaultAsync(c => c.Id == existing.CustomerId && c.CompanyId == CompanyId);

            return Ok(ToDto(existing, existingCust?.Name ?? "Customer", existingCust?.Phone ?? string.Empty));
        }

        // Customer resolution / creation
        Customer? customer = null;
        if (request.CustomerId.HasValue && request.CustomerId.Value != Guid.Empty)
        {
            customer = await _db.Customers
                .FirstOrDefaultAsync(c => c.Id == request.CustomerId.Value && c.CompanyId == CompanyId);
        }

        if (customer == null && !string.IsNullOrWhiteSpace(request.CustomerPhone))
        {
            var normalizedPhone = NormalizePhone(request.CustomerPhone);
            customer = await _db.Customers
                .FirstOrDefaultAsync(c => c.CompanyId == CompanyId && c.Phone == normalizedPhone);

            if (customer == null)
            {
                var custName = string.IsNullOrWhiteSpace(request.CustomerName) ? "Customer" : request.CustomerName.Trim();
                customer = new Customer(CompanyId, custName, null, normalizedPhone);
                _db.Customers.Add(customer);
                await _db.SaveChangesAsync();
            }
        }

        if (customer == null)
        {
            return BadRequest("A valid Customer ID or Customer Phone is required to link the enquiry.");
        }

        var enquiry = new CrmEnquiry(
            CompanyId,
            customer.Id,
            request.ClientSyncId,
            request.Category ?? "Flowers",
            request.Requirement,
            request.EventDate,
            request.BudgetAmount,
            request.Location,
            request.Notes,
            request.NextAction,
            request.NextFollowUpAtUtc);

        _db.CrmEnquiries.Add(enquiry);
        await _db.SaveChangesAsync();

        return CreatedAtAction(
            nameof(GetEnquiry),
            new { id = enquiry.Id },
            ToDto(enquiry, customer.Name, customer.Phone ?? string.Empty));
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> UpdateEnquiry(Guid id, [FromBody] UpdateCrmEnquiryRequest request)
    {
        if (request == null) return BadRequest("Request body is required.");
        if (string.IsNullOrWhiteSpace(request.Requirement)) return BadRequest("Requirement is required.");

        var enquiry = await _db.CrmEnquiries
            .FirstOrDefaultAsync(e => e.Id == id && e.CompanyId == CompanyId && e.DeletedAtUtc == null);

        if (enquiry == null) return NotFound();

        enquiry.Update(
            request.Category ?? "Flowers",
            request.Requirement,
            request.EventDate,
            request.BudgetAmount,
            request.Location,
            request.Notes,
            request.NextAction,
            request.NextFollowUpAtUtc);

        if (!string.IsNullOrWhiteSpace(request.Status))
        {
            var normalizedStatus = request.Status.Trim().ToLowerInvariant();
            if (!CrmEnquiry.ValidStatuses.Contains(normalizedStatus))
            {
                return BadRequest($"Invalid status '{request.Status}'. Allowed statuses: new, follow_up, quote_sent, won, lost.");
            }

            enquiry.SetStatus(
                normalizedStatus,
                request.NextAction,
                request.QuoteOrderId,
                request.ConvertedOrderId,
                request.LostReason);
        }

        await _db.SaveChangesAsync();

        var customer = await _db.Customers
            .AsNoTracking()
            .FirstOrDefaultAsync(c => c.Id == enquiry.CustomerId && c.CompanyId == CompanyId);

        return Ok(ToDto(enquiry, customer?.Name ?? "Customer", customer?.Phone ?? string.Empty));
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> DeleteEnquiry(Guid id)
    {
        var enquiry = await _db.CrmEnquiries
            .FirstOrDefaultAsync(e => e.Id == id && e.CompanyId == CompanyId && e.DeletedAtUtc == null);

        if (enquiry == null) return NotFound();

        enquiry.Delete();
        await _db.SaveChangesAsync();

        return NoContent();
    }

    private static CrmEnquiryDto ToDto(CrmEnquiry e, string customerName, string customerPhone)
    {
        return new CrmEnquiryDto(
            e.Id,
            e.ClientSyncId,
            e.CustomerId,
            customerName,
            customerPhone,
            e.Category,
            e.Requirement,
            e.EventDate,
            e.BudgetAmount,
            e.Location,
            e.Notes,
            e.Status,
            e.NextAction,
            e.NextFollowUpAtUtc,
            e.LinkedTaskId,
            e.QuoteOrderId,
            e.ConvertedOrderId,
            e.LostReason,
            e.CreatedAtUtc,
            e.UpdatedAtUtc);
    }

    private static string NormalizePhone(string raw)
    {
        var digits = new string(raw.Where(char.IsDigit).ToArray());
        return digits.Length >= 10 ? digits[^10..] : digits;
    }
}

public record CrmEnquiryDto(
    Guid Id,
    string ClientSyncId,
    Guid CustomerId,
    string CustomerName,
    string CustomerPhone,
    string Category,
    string Requirement,
    DateTime? EventDate,
    decimal? BudgetAmount,
    string? Location,
    string? Notes,
    string Status,
    string NextAction,
    DateTime? NextFollowUpAtUtc,
    Guid? LinkedTaskId,
    Guid? QuoteOrderId,
    Guid? ConvertedOrderId,
    string? LostReason,
    DateTime CreatedAtUtc,
    DateTime? UpdatedAtUtc);

public record CreateCrmEnquiryRequest(
    string ClientSyncId,
    Guid? CustomerId,
    string? CustomerPhone,
    string? CustomerName,
    string? Category,
    string Requirement,
    DateTime? EventDate,
    decimal? BudgetAmount,
    string? Location,
    string? Notes,
    string? NextAction,
    DateTime? NextFollowUpAtUtc);

public record UpdateCrmEnquiryRequest(
    string? Category,
    string Requirement,
    DateTime? EventDate,
    decimal? BudgetAmount,
    string? Location,
    string? Notes,
    string? NextAction,
    DateTime? NextFollowUpAtUtc,
    string? Status,
    string? LostReason,
    Guid? QuoteOrderId,
    Guid? ConvertedOrderId);
