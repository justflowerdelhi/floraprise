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
    private readonly IProductRepository _productRepository;

    public InventoryController(InventoryService service, IProductRepository productRepository)
    {
        _service = service;
        _productRepository = productRepository;
    }

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

    private Guid GetCurrentUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return Guid.TryParse(userIdClaim, out var userId) ? userId : Guid.Empty;
    }
}
