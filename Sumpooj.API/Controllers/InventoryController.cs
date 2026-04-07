using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Inventory;
using Sumpooj.Application.UseCases;
using System.Security.Claims;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/inventory")]
[Authorize(Policy = PolicyNames.CompanyOnly)]
public class InventoryController : ControllerBase
{
    private readonly InventoryService _service;
    private readonly StockReceiveService _receiveService;
    private readonly IProductRepository _productRepository;
    private readonly IInventoryLedgerRepository _repo;
    private readonly ITenantContext _tenant;

    public InventoryController(
        InventoryService service,
        StockReceiveService receiveService,
        IProductRepository productRepository,
        IInventoryLedgerRepository repo,
        ITenantContext tenant)
    {
        _service = service;
        _receiveService = receiveService;
        _productRepository = productRepository;
        _repo = repo;
        _tenant = tenant;
    }

    private Guid CompanyId => _tenant.CompanyId!.Value;

    #region Batches

    [HttpGet("batches")]
    public async Task<IActionResult> SearchBatches([FromQuery] BatchSearchRequest request)
    {
        var result = await _service.SearchBatchesAsync(request);
        return Ok(result);
    }

    [HttpGet("batches/{id:guid}")]
    public async Task<IActionResult> GetBatch(Guid id)
    {
        var batch = await _service.GetBatchAsync(id);
        return batch == null ? NotFound() : Ok(batch);
    }

    [HttpGet("batches/by-product/{productId:guid}")]
    public async Task<IActionResult> GetBatchesByProduct(Guid productId)
    {
        var batches = await _service.GetBatchesByProductAsync(productId);
        return Ok(batches);
    }

    [HttpPost("batches")]
    public async Task<IActionResult> CreateBatch([FromBody] CreateBatchRequest request)
    {
        var id = await _service.CreateBatchAsync(request);
        return CreatedAtAction(nameof(GetBatch), new { id }, new { id });
    }

    [HttpGet("expiry-alerts")]
    public async Task<IActionResult> GetExpiryAlerts(
        [FromQuery] int criticalDays = 2,
        [FromQuery] int warningDays = 5,
        [FromQuery] int upcomingDays = 14)
    {
        var alerts = await _service.GetExpiryAlertsAsync(criticalDays, warningDays, upcomingDays);
        return Ok(alerts);
    }

    [HttpGet("summary")]
    public async Task<IActionResult> GetSummary()
    {
        var summary = await _service.GetInventorySummaryAsync();
        return Ok(summary);
    }

    [HttpGet("batch-summary")]
    public async Task<IActionResult> GetBatchSummary()
    {
        var projections = await _service.GetBatchSummaryAsync();
        return Ok(projections);
    }

    #endregion

    #region Adjustments

    [HttpGet("adjustments")]
    public async Task<IActionResult> SearchAdjustments([FromQuery] AdjustmentSearchRequest request)
    {
        var result = await _service.SearchAdjustmentsAsync(request);
        return Ok(result);
    }

    [HttpGet("adjustments/recent")]
    public async Task<IActionResult> GetRecentAdjustments([FromQuery] int count = 10)
    {
        var adjustments = await _service.GetRecentAdjustmentsAsync(count);
        return Ok(adjustments);
    }

    [HttpPost("adjustments")]
    public async Task<IActionResult> CreateAdjustment([FromBody] CreateAdjustmentRequest request)
    {
        var userId = GetCurrentUserId();
        var id = await _service.CreateAdjustmentAsync(request, userId);
        return CreatedAtAction(nameof(SearchAdjustments), new { id }, new { id });
    }

    #endregion

    [HttpGet("ledger/{productId}")]
    public async Task<IActionResult> GetLedger(Guid productId)
    {
        var data = await _repo.GetByProductAsync(CompanyId, productId);
        return Ok(data);
    }

    [HttpGet("available-flowers")]
    public async Task<IActionResult> GetAvailableFlowers()
    {
        var tenantContext = HttpContext.RequestServices.GetRequiredService<ITenantContext>();
        var companyId = tenantContext.CompanyId
            ?? throw new UnauthorizedAccessException("Company context required");

        var products = await _productRepository.GetAllAsync(companyId);
        var available = products
            .Where(p => p.IsActive && p.StockQuantity > 0)
            .Select(p => new
            {
                productId = p.Id.ToString(),
                productName = p.Name,
                availableUnits = p.StockQuantity,
                unitPrice = p.RetailPrice,
                consumptionUnit = p.UnitOfMeasure.ToString().ToLower()
            })
            .ToList();

        return Ok(available);
    }

    /// <summary>
    /// Returns all active products as inventory items for production/custom bouquet builder.
    /// Frontend calls GET /api/inventory/products.
    /// </summary>
    [HttpGet("products")]
    public async Task<IActionResult> GetProducts()
    {
        var products = await _productRepository.GetAllAsync(CompanyId);
        var result = products
            .Where(p => p.IsActive)
            .Select(p => new
            {
                id = p.Id,
                name = p.Name,
                productType = p.ProductType.ToString(),
                quantityAvailable = p.StockQuantity,
                unitCost = p.CostPrice,
            })
            .ToList();

        return Ok(result);
    }

    [HttpGet("daily-report")]
    public async Task<IActionResult> GetDailyReport([FromQuery] DateTime date)
    {
        var result = await _service.GetDailyInventoryReportAsync(date);
        return Ok(result);
    }

    [HttpGet("reconciliation")]
    public async Task<IActionResult> GetReconciliation([FromQuery] bool mismatchesOnly = true)
    {
        var result = await _service.GetStockReconciliationAsync(mismatchesOnly);
        return Ok(result);
    }

    [HttpPost("reconciliation/apply")]
    public async Task<IActionResult> ApplyReconciliationFix([FromBody] ReconciliationApplyRequest request)
    {
        try
        {
            var userId = GetCurrentUserId();
            var result = await _service.ApplyReconciliationFixAsync(request, userId);
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    // ─── Quick Receive ──────────────────────────────────────────────────

    [HttpPost("quick-receive")]
    public async Task<IActionResult> QuickReceive([FromBody] QuickReceiveRequest request)
    {
        try
        {
            var result = await _receiveService.QuickReceiveAsync(request);
            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    // ─── Direct Stock Add ───────────────────────────────────────────────

    [HttpPost("direct-add")]
    public async Task<IActionResult> DirectAdd([FromBody] DirectAddRequest request)
    {
        try
        {
            var result = await _receiveService.DirectAddAsync(request);
            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    private Guid GetCurrentUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return Guid.TryParse(userIdClaim, out var userId) ? userId : Guid.Empty;
    }
}
