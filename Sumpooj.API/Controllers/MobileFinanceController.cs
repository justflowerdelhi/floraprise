using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Accounting;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/accounting")]
[Authorize(Policy = "CompanyOnly")]
public class MobileFinanceController : ControllerBase
{
    private readonly SumpoojDbContext _db;
    private readonly ITenantContext _tenant;

    public MobileFinanceController(SumpoojDbContext db, ITenantContext tenant)
    {
        _db = db;
        _tenant = tenant;
    }

    private Guid CompanyId => _tenant.CompanyId
        ?? throw new UnauthorizedAccessException("Company context required");

    [HttpGet("expense-categories")]
    public async Task<IActionResult> GetCategories([FromQuery] string? group, [FromQuery] bool includeInactive = false)
    {
        var query = _db.ExpenseCategories.Where(c => c.CompanyId == CompanyId);
        if (!includeInactive) query = query.Where(c => c.IsActive);
        if (!string.IsNullOrWhiteSpace(group)) query = query.Where(c => c.GroupName == group);
        return Ok((await query.OrderBy(c => c.GroupName).ThenBy(c => c.Name).ToListAsync()).Select(ToDto));
    }

    [HttpGet("expense-categories/{id:guid}")]
    public async Task<IActionResult> GetCategory(Guid id)
    {
        var category = await _db.ExpenseCategories.FirstOrDefaultAsync(c => c.CompanyId == CompanyId && c.Id == id);
        return category == null ? NotFound() : Ok(ToDto(category));
    }

    [HttpPost("expense-categories")]
    public async Task<IActionResult> CreateCategory([FromBody] SaveExpenseCategoryRequest request)
    {
        var normalized = request.Name.Trim().ToLower();
        if (await _db.ExpenseCategories.AnyAsync(c => c.CompanyId == CompanyId && c.Name.ToLower() == normalized))
            return Conflict(new { message = "Expense category already exists." });
        try
        {
            var category = new ExpenseCategory(CompanyId, request.Name, request.Emoji, request.GroupName);
            _db.ExpenseCategories.Add(category);
            await _db.SaveChangesAsync();
            return CreatedAtAction(nameof(GetCategory), new { id = category.Id }, ToDto(category));
        }
        catch (InvalidOperationException ex) { return BadRequest(new { message = ex.Message }); }
    }

    [HttpPut("expense-categories/{id:guid}")]
    public async Task<IActionResult> UpdateCategory(Guid id, [FromBody] SaveExpenseCategoryRequest request)
    {
        var category = await _db.ExpenseCategories.FirstOrDefaultAsync(c => c.CompanyId == CompanyId && c.Id == id);
        if (category == null) return NotFound();
        try { category.Update(request.Name, request.Emoji, request.GroupName); }
        catch (InvalidOperationException ex) { return BadRequest(new { message = ex.Message }); }
        await _db.SaveChangesAsync();
        return Ok(ToDto(category));
    }

    [HttpPut("expense-categories/{id:guid}/deactivate")]
    public Task<IActionResult> DeactivateCategory(Guid id) => SetCategoryActive(id, false);

    [HttpPut("expense-categories/{id:guid}/reactivate")]
    public Task<IActionResult> ReactivateCategory(Guid id) => SetCategoryActive(id, true);

    [HttpGet("opening-cash")]
    public async Task<IActionResult> GetOpeningCash([FromQuery] DateTime date)
    {
        var day = date.ToUniversalTime().Date;
        var entry = await _db.OpeningCashEntries.FirstOrDefaultAsync(o => o.CompanyId == CompanyId && o.Date == day);
        return entry == null ? NotFound() : Ok(ToDto(entry));
    }

    [HttpPost("opening-cash")]
    public async Task<IActionResult> CreateOpeningCash([FromBody] SaveOpeningCashRequest request)
    {
        var day = request.Date.ToUniversalTime().Date;
        if (await _db.OpeningCashEntries.AnyAsync(o => o.CompanyId == CompanyId && o.Date == day))
            return Conflict(new { message = "Opening cash already exists for this date." });
        try
        {
            var entry = new OpeningCash(CompanyId, day, request.Amount);
            _db.OpeningCashEntries.Add(entry);
            await _db.SaveChangesAsync();
            return Ok(ToDto(entry));
        }
        catch (InvalidOperationException ex) { return BadRequest(new { message = ex.Message }); }
    }

    [HttpPut("opening-cash/{id:guid}")]
    public async Task<IActionResult> UpdateOpeningCash(Guid id, [FromBody] SaveOpeningCashRequest request)
    {
        var entry = await _db.OpeningCashEntries.FirstOrDefaultAsync(o => o.CompanyId == CompanyId && o.Id == id);
        if (entry == null) return NotFound();
        if (await _db.CashBookEntries.AnyAsync(e => e.CompanyId == CompanyId && e.Date == entry.Date))
            return Conflict(new { message = "Opening cash cannot be changed after cash transactions exist." });
        try { entry.SetAmount(request.Amount); }
        catch (InvalidOperationException ex) { return BadRequest(new { message = ex.Message }); }
        await _db.SaveChangesAsync();
        return Ok(ToDto(entry));
    }

    [HttpGet("cash-book")]
    public async Task<IActionResult> GetCashBook([FromQuery] DateTime? date, [FromQuery] DateTime? from,
        [FromQuery] DateTime? to, [FromQuery] string? query)
    {
        var entries = _db.CashBookEntries.Where(e => e.CompanyId == CompanyId);
        if (date.HasValue) entries = entries.Where(e => e.Date == date.Value.ToUniversalTime().Date);
        if (from.HasValue) entries = entries.Where(e => e.Date >= from.Value.ToUniversalTime().Date);
        if (to.HasValue) entries = entries.Where(e => e.Date <= to.Value.ToUniversalTime().Date);
        if (!string.IsNullOrWhiteSpace(query)) entries = entries.Where(e => e.Description.ToLower().Contains(query.Trim().ToLower()));
        return Ok((await entries.OrderBy(e => e.CreatedAtUtc).ToListAsync()).Select(ToDto));
    }

    [HttpGet("cash-book/balance")]
    public async Task<IActionResult> GetCashBookBalance([FromQuery] DateTime date)
    {
        var day = date.ToUniversalTime().Date;
        var balance = await _db.CashBookEntries.Where(e => e.CompanyId == CompanyId && e.Date == day)
            .OrderByDescending(e => e.CreatedAtUtc).Select(e => (decimal?)e.RunningBalance).FirstOrDefaultAsync() ?? 0;
        return Ok(new { balance });
    }

    [HttpPost("cash-book")]
    public async Task<IActionResult> CreateCashBookEntry([FromBody] CreateCashBookEntryRequest request)
    {
        if (!Enum.TryParse<CashBookTransactionType>(request.TransactionType, true, out var type))
            return BadRequest(new { message = "Invalid cash-book transaction type." });
        var day = request.Date.ToUniversalTime().Date;
        var current = await _db.CashBookEntries.Where(e => e.CompanyId == CompanyId && e.Date == day)
            .OrderByDescending(e => e.CreatedAtUtc).Select(e => (decimal?)e.RunningBalance).FirstOrDefaultAsync() ?? 0;
        try
        {
            var entry = new CashBookEntry(CompanyId, day, type, request.Description, request.Amount,
                request.CashIn, request.CashOut, current + request.CashIn - request.CashOut);
            _db.CashBookEntries.Add(entry);
            await _db.SaveChangesAsync();
            return Ok(ToDto(entry));
        }
        catch (InvalidOperationException ex) { return BadRequest(new { message = ex.Message }); }
    }

    [HttpDelete("cash-book/{id:guid}")]
    public async Task<IActionResult> DeleteCashBookEntry(Guid id)
    {
        var entry = await _db.CashBookEntries.FirstOrDefaultAsync(e => e.CompanyId == CompanyId && e.Id == id);
        if (entry == null) return NotFound();
        _db.CashBookEntries.Remove(entry);
        await _db.SaveChangesAsync();
        return NoContent();
    }

    private async Task<IActionResult> SetCategoryActive(Guid id, bool active)
    {
        var category = await _db.ExpenseCategories.FirstOrDefaultAsync(c => c.CompanyId == CompanyId && c.Id == id);
        if (category == null) return NotFound();
        if (active) category.Reactivate(); else category.Deactivate();
        await _db.SaveChangesAsync();
        return NoContent();
    }

    private static ExpenseCategoryDto ToDto(ExpenseCategory category) => new()
    {
        Id = category.Id, Name = category.Name, Emoji = category.Emoji, GroupName = category.GroupName,
        Active = category.IsActive, CreatedAtUtc = category.CreatedAtUtc, UpdatedAtUtc = category.UpdatedAtUtc
    };

    private static OpeningCashDto ToDto(OpeningCash entry) => new()
    {
        Id = entry.Id, Date = entry.Date.ToString("yyyy-MM-dd"), Amount = entry.Amount,
        CreatedAtUtc = entry.CreatedAtUtc, UpdatedAtUtc = entry.UpdatedAtUtc
    };

    private static CashBookEntryDto ToDto(CashBookEntry entry) => new()
    {
        Id = entry.Id, Date = entry.Date.ToString("yyyy-MM-dd"), TransactionType = entry.TransactionType.ToString(),
        Description = entry.Description, Amount = entry.Amount, CashIn = entry.CashIn, CashOut = entry.CashOut,
        RunningBalance = entry.RunningBalance, CreatedAtUtc = entry.CreatedAtUtc
    };
}