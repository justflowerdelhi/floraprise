using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Production;
using Sumpooj.Application.UseCases;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/production")]
[Authorize(Policy = PolicyNames.CompanyOnly)]
public class ProductionController : ControllerBase
{
    private readonly ProductionService _service;
    private readonly ITenantContext _tenant;

    public ProductionController(ProductionService service, ITenantContext tenant)
    {
        _service = service;
        _tenant = tenant;
    }

    private Guid CompanyId =>
        _tenant.CompanyId ?? throw new UnauthorizedAccessException("Company context required");

    // ─── Recipes ────────────────────────────────────────────

    [HttpGet("recipes")]
    public async Task<ActionResult<List<FloralRecipeDto>>> GetRecipes()
        => Ok(await _service.GetRecipesAsync(CompanyId));

    [HttpGet("recipes/{id:guid}")]
    public async Task<ActionResult<FloralRecipeDto>> GetRecipe(Guid id)
    {
        var recipe = await _service.GetRecipeByIdAsync(CompanyId, id);
        return recipe == null ? NotFound() : Ok(recipe);
    }

    [HttpPost("recipes")]
    public async Task<ActionResult<FloralRecipeDto>> CreateRecipe([FromBody] CreateRecipeRequest request)
    {
        var recipe = await _service.CreateRecipeAsync(CompanyId, request);
        return CreatedAtAction(nameof(GetRecipe), new { id = recipe.Id }, recipe);
    }

    [HttpPut("recipes/{id:guid}")]
    public async Task<ActionResult<FloralRecipeDto>> UpdateRecipe(Guid id, [FromBody] UpdateRecipeRequest request)
    {
        var recipe = await _service.UpdateRecipeAsync(CompanyId, id, request);
        return recipe == null ? NotFound() : Ok(recipe);
    }

    [HttpDelete("recipes/{id:guid}")]
    public async Task<ActionResult> DeleteRecipe(Guid id)
    {
        var success = await _service.DeleteRecipeAsync(CompanyId, id);
        return success ? NoContent() : NotFound();
    }

    // ─── Finished Goods ─────────────────────────────────────

    [HttpGet("finished-goods")]
    public async Task<ActionResult<List<FinishedGoodsBatchDto>>> GetFinishedBatches()
        => Ok(await _service.GetFinishedBatchesAsync(CompanyId));

    [HttpGet("finished-goods/{id:guid}")]
    public async Task<ActionResult<FinishedGoodsBatchDto>> GetFinishedBatch(Guid id)
    {
        var batch = await _service.GetFinishedBatchByIdAsync(CompanyId, id);
        return batch == null ? NotFound() : Ok(batch);
    }

    [HttpPost("finished-goods/{id:guid}/deduct")]
    public async Task<IActionResult> DeductFromBatch(Guid id, [FromBody] DeductBatchRequest request)
    {
        await _service.DeductFromBatchAsync(CompanyId, id, request.Quantity);
        return NoContent();
    }

    // ─── Production Runs ────────────────────────────────────

    [HttpPost("runs")]
    public async Task<ActionResult<ProductionRunResult>> CreateRun([FromBody] ProductionRunRequest request)
    {
        var result = await _service.CreateProductionRunAsync(CompanyId, request);
        return Ok(result);
    }

    // ─── On-Demand Assembly ─────────────────────────────────

    [HttpPost("on-demand")]
    public async Task<ActionResult<OnDemandAssemblyResult>> OnDemand([FromBody] OnDemandAssemblyRequest request)
    {
        var result = await _service.CreateOnDemandAssemblyAsync(CompanyId, request);
        return Ok(result);
    }

    // ─── Custom Bouquet ─────────────────────────────────────

    [HttpPost("custom/sell")]
    public ActionResult CustomSell([FromBody] CustomBouquetRequest _)
        => Ok(new { success = true });

    [HttpPost("custom/save-recipe")]
    public async Task<ActionResult<FloralRecipeDto>> SaveCustomRecipe([FromBody] CustomBouquetSaveRequest request)
    {
        var recipe = await _service.SaveCustomBouquetAsRecipeAsync(CompanyId, request);
        return Ok(recipe);
    }

    // ─── Maintenance ────────────────────────────────────────

    [HttpGet("maintenance")]
    public async Task<ActionResult<List<MaintenanceLogDto>>> GetMaintenanceLogs()
        => Ok(await _service.GetMaintenanceLogsAsync(CompanyId));

    [HttpPost("maintenance")]
    public async Task<ActionResult<MaintenanceLogDto>> CreateMaintenance([FromBody] MaintenanceRequest request)
    {
        var log = await _service.CreateMaintenanceAsync(CompanyId, request);
        return Ok(log);
    }

    // ─── Wastage ────────────────────────────────────────────

    [HttpGet("wastage")]
    public async Task<ActionResult<List<WastageLogDto>>> GetWastageLogs()
        => Ok(await _service.GetWastageLogsAsync(CompanyId));

    [HttpPost("wastage")]
    public async Task<ActionResult<WastageLogDto>> CreateWastage([FromBody] CreateWastageRequest request)
    {
        var log = await _service.CreateWastageAsync(CompanyId, request);
        return Ok(log);
    }

    // ─── Inventory Products (for production screen) ─────────

    [HttpGet("inventory-products")]
    public async Task<ActionResult<List<InventoryProductDto>>> GetInventoryProducts([FromQuery] Guid locationId)
        => Ok(await _service.GetInventoryProductsAsync(CompanyId, locationId));
}
