using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.API.Controllers;

public record CreateReadyBouquetRequest(Guid FinishedProductId, Guid? RecipeId, Guid? ProductionId, int InitialQuantity,
    DateTime ProducedAt, int ShelfLifeDays, int RefreshAfterDays, DateTime ExpiryAt, string? Location, string? Note);
public record RefreshReadyBouquetRequest(string ActionType, Guid ProductId, int Quantity, bool ReturnToInventory, string? Reason, string? Note);
public record ExpireReadyBouquetRequest(int Quantity, string Reason, string? Note);

[ApiController, Route("api/ready-bouquets"), Authorize(Policy = "CompanyOnly")]
public class ReadyBouquetsController : ControllerBase
{
    private readonly SumpoojDbContext _db; private readonly ITenantContext _tenant;
    public ReadyBouquetsController(SumpoojDbContext db, ITenantContext tenant) { _db = db; _tenant = tenant; }
    private Guid CompanyId => _tenant.CompanyId ?? throw new UnauthorizedAccessException("Company context required");

    [HttpGet]
    public async Task<IActionResult> List([FromQuery] bool attentionOnly = false)
    {
        var rows = await _db.ReadyBouquetRecords.Where(x => x.CompanyId == CompanyId).OrderBy(x => x.ExpiryAt).ToListAsync();
        var result = rows.Select(x => new { batch = x, computedStatus = x.ComputeStatus(DateTime.UtcNow) });
        return Ok(attentionOnly ? result.Where(x => x.computedStatus != "fresh") : result);
    }
    [HttpGet("{id:guid}")]
    public async Task<IActionResult> Get(Guid id)
    {
        var row = await _db.ReadyBouquetRecords.FirstOrDefaultAsync(x => x.CompanyId == CompanyId && x.Id == id);
        return row == null ? NotFound() : Ok(new { batch = row, computedStatus = row.ComputeStatus(DateTime.UtcNow) });
    }
    [HttpGet("{id:guid}/history")]
    public async Task<IActionResult> History(Guid id) => Ok(await (
        from refresh in _db.ReadyBouquetRefreshEvents
        join product in _db.Products on refresh.ProductId equals product.Id
        where refresh.CompanyId == CompanyId && refresh.BatchId == id
        orderby refresh.CreatedAtUtc descending
        select new { refresh, productName = product.Name }).ToListAsync());

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateReadyBouquetRequest r)
    {
        if (r.InitialQuantity <= 0 || r.ShelfLifeDays < 0 || r.RefreshAfterDays < 0) return BadRequest(new { message = "Quantities and intervals are invalid." });
        if (!await _db.Products.AnyAsync(x => x.CompanyId == CompanyId && x.Id == r.FinishedProductId && x.IsActive)) return BadRequest(new { message = "Finished product was not found." });
        var row = new ReadyBouquetRecord(CompanyId, r.FinishedProductId, r.RecipeId, r.ProductionId, r.InitialQuantity, r.ProducedAt,
            r.ShelfLifeDays, r.RefreshAfterDays, r.ExpiryAt, r.Location, r.Note);
        _db.ReadyBouquetRecords.Add(row); await _db.SaveChangesAsync(); return CreatedAtAction(nameof(Get), new { id = row.Id }, row);
    }

    [HttpPost("{id:guid}/refresh")]
    public async Task<IActionResult> Refresh(Guid id, [FromBody] RefreshReadyBouquetRequest r)
    {
        if (r.ActionType is not ("replace" or "add" or "remove") || r.Quantity <= 0) return BadRequest(new { message = "Invalid refresh action or quantity." });
        await using var transaction = await _db.Database.BeginTransactionAsync();
        var batch = await _db.ReadyBouquetRecords.FirstOrDefaultAsync(x => x.CompanyId == CompanyId && x.Id == id);
        var product = await _db.Products.FirstOrDefaultAsync(x => x.CompanyId == CompanyId && x.Id == r.ProductId && x.IsActive);
        if (batch == null || product == null) return NotFound();
        var stockDelta = r.ActionType == "remove" && r.ReturnToInventory ? r.Quantity : -r.Quantity;
        if (stockDelta < 0 && product.StockQuantity < -stockDelta) return BadRequest(new { message = "Insufficient component inventory." });
        product.AdjustStock(stockDelta);
        _db.InventoryLedgers.Add(new InventoryLedger(CompanyId, product.Id, id.ToString(), "READY_BOUQUET_REFRESH", stockDelta, product.StockQuantity, r.Reason ?? r.ActionType));
        var waste = r.ActionType == "replace" || (r.ActionType == "remove" && !r.ReturnToInventory) ? r.Quantity : 0;
        _db.ReadyBouquetRefreshEvents.Add(new ReadyBouquetRefreshEvent(CompanyId, id, r.ActionType, product.Id, r.Quantity, waste, r.Reason, r.Note));
        batch.Refresh(); await _db.SaveChangesAsync(); await transaction.CommitAsync(); return Ok(new { batch, computedStatus = batch.ComputeStatus(DateTime.UtcNow) });
    }

    [HttpPost("{id:guid}/expire")]
    public async Task<IActionResult> Expire(Guid id, [FromBody] ExpireReadyBouquetRequest r)
    {
        await using var transaction = await _db.Database.BeginTransactionAsync();
        var batch = await _db.ReadyBouquetRecords.FirstOrDefaultAsync(x => x.CompanyId == CompanyId && x.Id == id);
        if (batch == null) return NotFound();
        var product = await _db.Products.FirstOrDefaultAsync(x => x.CompanyId == CompanyId && x.Id == batch.FinishedProductId);
        if (product == null) return BadRequest(new { message = "Finished product was not found." });
        try { batch.Expire(r.Quantity); }
        catch (InvalidOperationException ex) { return BadRequest(new { message = ex.Message }); }
        product.AdjustStock(-r.Quantity);
        _db.InventoryLedgers.Add(new InventoryLedger(CompanyId, product.Id, id.ToString(), "EXPIRED_BOUQUET", -r.Quantity, product.StockQuantity, r.Reason));
        _db.StockMovements.Add(new StockMovement(CompanyId, product.Id, StockMovementType.Expired, -r.Quantity, r.Reason));
        await _db.SaveChangesAsync(); await transaction.CommitAsync(); return Ok(new { batch, computedStatus = batch.ComputeStatus(DateTime.UtcNow) });
    }
}