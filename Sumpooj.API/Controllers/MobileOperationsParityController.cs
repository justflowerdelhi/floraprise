using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.API.Controllers;

public record SaveMorningPurchaseItemRequest(Guid ProductId, int Quantity, string Unit, string? Supplier, string Priority, string? Remarks);
public record SetPurchasedRequest(bool Purchased);
public record SaveAssociateRequest(string BusinessName, string? ContactPerson, string Phone, string? Whatsapp,
    string? Email, string City, string? State, string Pincode, string? Address, string? GstNumber,
    string? Website, string? Notes, List<string> Types, bool IsActive);

[ApiController]
[Route("api/morning-purchase-list")]
[Authorize(Policy = "CompanyOnly")]
public class MorningPurchaseListController : ControllerBase
{
    private readonly SumpoojDbContext _db;
    private readonly ITenantContext _tenant;
    public MorningPurchaseListController(SumpoojDbContext db, ITenantContext tenant) { _db = db; _tenant = tenant; }
    private Guid CompanyId => _tenant.CompanyId ?? throw new UnauthorizedAccessException("Company context required");

    [HttpGet]
    public async Task<IActionResult> List([FromQuery] DateTime date, [FromQuery] bool? purchased)
    {
        var day = date.ToUniversalTime().Date;
        var query = _db.MorningPurchaseListItems.Where(i => i.CompanyId == CompanyId && i.ListDate == day && i.DeletedAtUtc == null);
        if (purchased.HasValue) query = query.Where(i => i.Purchased == purchased.Value);
        return Ok(await query.OrderBy(i => i.Purchased).ThenByDescending(i => i.Priority).ThenBy(i => i.ProductName).ToListAsync());
    }

    [HttpGet("history")]
    public async Task<IActionResult> History([FromQuery] DateTime from, [FromQuery] DateTime to) =>
        Ok(await _db.MorningPurchaseListItems.Where(i => i.CompanyId == CompanyId && i.ListDate >= from.ToUniversalTime().Date &&
            i.ListDate <= to.ToUniversalTime().Date && i.DeletedAtUtc == null).OrderByDescending(i => i.ListDate).ToListAsync());

    [HttpPost]
    public async Task<IActionResult> AddOrUpdate([FromQuery] DateTime date, [FromBody] SaveMorningPurchaseItemRequest request)
    {
        var product = await _db.Products.FirstOrDefaultAsync(p => p.CompanyId == CompanyId && p.Id == request.ProductId && p.IsActive);
        if (product == null) return BadRequest(new { message = "Product was not found." });
        var day = date.ToUniversalTime().Date;
        var item = await _db.MorningPurchaseListItems.FirstOrDefaultAsync(i => i.CompanyId == CompanyId && i.ListDate == day && i.ProductId == request.ProductId);
        try
        {
            if (item == null)
            {
                item = new MorningPurchaseListItem(CompanyId, day, product.Id, product.Name, product.Category.ToString(),
                    request.Quantity, request.Unit, request.Supplier, request.Priority, request.Remarks);
                _db.MorningPurchaseListItems.Add(item);
            }
            else item.Update(product.Name, product.Category.ToString(), request.Quantity, request.Unit, request.Supplier, request.Priority, request.Remarks);
            await _db.SaveChangesAsync();
            return Ok(item);
        }
        catch (InvalidOperationException ex) { return BadRequest(new { message = ex.Message }); }
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] SaveMorningPurchaseItemRequest request)
    {
        var item = await _db.MorningPurchaseListItems.FirstOrDefaultAsync(i => i.CompanyId == CompanyId && i.Id == id && i.DeletedAtUtc == null);
        if (item == null) return NotFound();
        try { item.Update(item.ProductName, item.Category, request.Quantity, request.Unit, request.Supplier, request.Priority, request.Remarks); }
        catch (InvalidOperationException ex) { return BadRequest(new { message = ex.Message }); }
        await _db.SaveChangesAsync(); return Ok(item);
    }

    [HttpPut("{id:guid}/purchased")]
    public async Task<IActionResult> SetPurchased(Guid id, [FromBody] SetPurchasedRequest request)
    {
        var item = await _db.MorningPurchaseListItems.FirstOrDefaultAsync(i => i.CompanyId == CompanyId && i.Id == id && i.DeletedAtUtc == null);
        if (item == null) return NotFound();
        item.SetPurchased(request.Purchased); await _db.SaveChangesAsync(); return NoContent();
    }

    [HttpPut("{id:guid}/inventory-updated")]
    public async Task<IActionResult> MarkInventoryUpdated(Guid id)
    {
        var item = await _db.MorningPurchaseListItems.FirstOrDefaultAsync(i => i.CompanyId == CompanyId && i.Id == id && i.DeletedAtUtc == null);
        if (item == null) return NotFound();
        item.MarkInventoryUpdated(); await _db.SaveChangesAsync(); return NoContent();
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var item = await _db.MorningPurchaseListItems.FirstOrDefaultAsync(i => i.CompanyId == CompanyId && i.Id == id);
        if (item == null) return NotFound(); item.Delete(); await _db.SaveChangesAsync(); return NoContent();
    }
}

[ApiController]
[Route("api/associates")]
[Authorize(Policy = "CompanyOnly")]
public class AssociatesController : ControllerBase
{
    private readonly SumpoojDbContext _db;
    private readonly ITenantContext _tenant;
    public AssociatesController(SumpoojDbContext db, ITenantContext tenant) { _db = db; _tenant = tenant; }
    private Guid CompanyId => _tenant.CompanyId ?? throw new UnauthorizedAccessException("Company context required");

    [HttpGet]
    public async Task<IActionResult> List([FromQuery] string? query, [FromQuery] bool includeInactive = false)
    {
        var rows = _db.Associates.Where(a => a.CompanyId == CompanyId && a.DeletedAtUtc == null);
        if (!includeInactive) rows = rows.Where(a => a.IsActive);
        if (!string.IsNullOrWhiteSpace(query))
        {
            var q = query.Trim().ToLower();
            rows = rows.Where(a => a.BusinessName.ToLower().Contains(q) || a.ContactPerson!.ToLower().Contains(q) ||
                a.Phone.Contains(q) || a.Whatsapp!.Contains(q) || a.Email!.ToLower().Contains(q) || a.City.ToLower().Contains(q));
        }
        return Ok(await rows.OrderBy(a => a.BusinessName).ToListAsync());
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> Get(Guid id)
    {
        var row = await _db.Associates.FirstOrDefaultAsync(a => a.CompanyId == CompanyId && a.Id == id && a.DeletedAtUtc == null);
        return row == null ? NotFound() : Ok(row);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] SaveAssociateRequest request)
    {
        var sequence = await _db.Associates.CountAsync(a => a.CompanyId == CompanyId) + 1;
        var row = new Associate(CompanyId, $"ASSOC-{sequence:D4}", request.BusinessName, request.Phone);
        try { Apply(row, request); }
        catch (InvalidOperationException ex) { return BadRequest(new { message = ex.Message }); }
        _db.Associates.Add(row); await _db.SaveChangesAsync(); return CreatedAtAction(nameof(Get), new { id = row.Id }, row);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] SaveAssociateRequest request)
    {
        var row = await _db.Associates.FirstOrDefaultAsync(a => a.CompanyId == CompanyId && a.Id == id && a.DeletedAtUtc == null);
        if (row == null) return NotFound();
        try { Apply(row, request); }
        catch (InvalidOperationException ex) { return BadRequest(new { message = ex.Message }); }
        await _db.SaveChangesAsync(); return Ok(row);
    }

    [HttpPut("{id:guid}/deactivate")] public Task<IActionResult> Deactivate(Guid id) => SetActive(id, false);
    [HttpPut("{id:guid}/reactivate")] public Task<IActionResult> Reactivate(Guid id) => SetActive(id, true);
    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var row = await _db.Associates.FirstOrDefaultAsync(a => a.CompanyId == CompanyId && a.Id == id);
        if (row == null) return NotFound(); row.Delete(); await _db.SaveChangesAsync(); return NoContent();
    }

    private async Task<IActionResult> SetActive(Guid id, bool active)
    {
        var row = await _db.Associates.FirstOrDefaultAsync(a => a.CompanyId == CompanyId && a.Id == id && a.DeletedAtUtc == null);
        if (row == null) return NotFound(); if (active) row.Reactivate(); else row.Deactivate();
        await _db.SaveChangesAsync(); return NoContent();
    }

    private static void Apply(Associate row, SaveAssociateRequest r) => row.Update(r.BusinessName, r.ContactPerson, r.Phone,
        r.Whatsapp, r.Email, r.City, r.State, r.Pincode, r.Address, r.GstNumber, r.Website, r.Notes, r.Types, r.IsActive);
}