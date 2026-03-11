using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Customers;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.UseCases;
using Sumpooj.Infrastructure.Persistence;


namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/customers")]
[Authorize(Policy = PolicyNames.CompanyOnly)]
public class CustomersController : ControllerBase
{
    private readonly CustomerService _service;
    private readonly SumpoojDbContext _db;
    private readonly ITenantContext _tenantContext;

    public CustomersController(CustomerService service, SumpoojDbContext db, ITenantContext tenantContext)
    {
        _service = service;
        _db = db;
        _tenantContext = tenantContext;
    }

    private Guid CompanyId => _tenantContext.CompanyId
        ?? throw new UnauthorizedAccessException("Company context required");

    [HttpGet("search")]
    public async Task<IActionResult> Search([FromQuery] CustomerSearchRequest request)
    {
        var result = await _service.SearchAsync(request);
        return Ok(result);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> Get(Guid id)
    {
        var customer = await _service.GetAsync(id);
        return customer == null ? NotFound() : Ok(customer);
    }

    [HttpPost]
    public async Task<IActionResult> Create(CreateCustomerRequest request)
    {
        var id = await _service.CreateAsync(request);
        return CreatedAtAction(nameof(Get), new { id }, null);
    }

    [HttpPut("{id:guid}/contact")]
    public async Task<IActionResult> UpdateContact(
        Guid id,
        UpdateCustomerRequest request)
    {
        await _service.UpdateContactAsync(id, request);
        return NoContent();
    }

    [HttpPut("{id:guid}/card-message")]
    public async Task<IActionResult> UpdateCardMessage(
        Guid id,
        [FromBody] string? message)
    {
        await _service.UpdateCardMessageAsync(id, message);
        return NoContent();
    }

    [HttpPut("{id:guid}/notes")]
    public async Task<IActionResult> UpdateNotes(
        Guid id,
        [FromBody] string? notes)
    {
        await _service.UpdateNotesAsync(id, notes);
        return NoContent();
    }

    [HttpPut("{id:guid}/deactivate")]
    public async Task<IActionResult> Deactivate(Guid id)
    {
        await _service.DeactivateAsync(id);
        return NoContent();
    }

    [HttpPut("{id:guid}/reactivate")]
    public async Task<IActionResult> Reactivate(Guid id)
    {
        await _service.ReactivateAsync(id);
        return NoContent();
    }

    /// <summary>
    /// Lookup a customer by phone number.
    /// Used by phone-order screen for quick customer identification.
    /// </summary>
    [HttpGet("by-phone")]
    public async Task<IActionResult> GetByPhone([FromQuery] string phone)
    {
        if (string.IsNullOrWhiteSpace(phone))
            return BadRequest(new { message = "Phone number is required" });

        var cid = CompanyId;
        var customer = await _db.Customers
            .Where(c => c.CompanyId == cid && c.IsActive && c.Phone != null && c.Phone.Contains(phone))
            .Select(c => new
            {
                c.Id,
                c.Name,
                c.Email,
                c.Phone,
                c.Notes,
            })
            .FirstOrDefaultAsync();

        if (customer == null)
            return Ok((object?)null);

        // Also fetch recent orders for this customer
        var recentOrders = await _db.Orders
            .Where(o => o.CompanyId == cid && o.CustomerId == customer.Id)
            .OrderByDescending(o => o.OrderDate)
            .Take(5)
            .Select(o => new
            {
                o.Id,
                o.OrderNumber,
                description = o.InternalNotes ?? "",
                amount = o.TotalAmount,
                o.OrderDate,
            })
            .ToListAsync();

        return Ok(new
        {
            customer.Id,
            customer.Name,
            customer.Email,
            customer.Phone,
            orders = recentOrders,
        });
    }
}
