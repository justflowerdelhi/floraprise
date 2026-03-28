using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.AI;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Production;
using Sumpooj.Application.UseCases;
using System.Security.Claims;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/ai")]
[Authorize(Policy = "CompanyOnly")]
public class AIController : ControllerBase
{
    private readonly ILogger<AIController> _logger;
    private readonly IWebHostEnvironment _environment;
    private readonly GiftCardAIService _giftCardAI;
    private readonly BouquetAIService _bouquetAI;
    private readonly ProductionService _productionService;
    private readonly ITenantContext _tenantContext;

    public AIController(
        ILogger<AIController> logger,
        IWebHostEnvironment environment,
        GiftCardAIService giftCardAI,
        BouquetAIService bouquetAI,
        ProductionService productionService,
        ITenantContext tenantContext)
    {
        _logger = logger;
        _environment = environment;
        _giftCardAI = giftCardAI;
        _bouquetAI = bouquetAI;
        _productionService = productionService;
        _tenantContext = tenantContext;
    }

    private Guid CompanyId => _tenantContext.CompanyId
        ?? throw new UnauthorizedAccessException("Company context required");

    private Guid UserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)
        ?? throw new UnauthorizedAccessException("User not found"));

    // ─── Gift Card AI ───────────────────────────────────────

    /// <summary>
    /// Generate an AI gift card background image (DALL-E 3).
    /// Subject to daily per-user and monthly per-company limits.
    /// </summary>
    [HttpPost("giftcard/background")]
    public async Task<IActionResult> GenerateGiftCardBackground([FromBody] GiftCardBackgroundRequest request)
    {
        try
        {
            var result = await _giftCardAI.GenerateBackgroundAsync(CompanyId, UserId, request);
            return Ok(result);
        }
        catch (AIUsageLimitException ex)
        {
            return StatusCode(429, new { error = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return StatusCode(503, new { error = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Gift card generation failed for user {UserId} in company {CompanyId}", UserId, CompanyId);
            return StatusCode(500, new
            {
                error = _environment.IsDevelopment()
                    ? ex.Message
                    : "Gift card generation failed. Please try again later."
            });
        }
    }

    /// <summary>
    /// Get current AI usage quota for the authenticated user/company.
    /// </summary>
    [HttpGet("giftcard/usage")]
    public async Task<IActionResult> GetGiftCardUsage()
    {
        var usage = await _giftCardAI.GetUsageAsync(CompanyId, UserId);
        return Ok(usage);
    }

    // ─── Bouquet Scanner AI ─────────────────────────────────

    /// <summary>
    /// Analyze a bouquet photo using GPT-4o-mini vision.
    /// Returns detected flowers, stem counts, style, shape, and height.
    /// Replaces the separate Python AI service.
    /// </summary>
    [HttpPost("analyze-bouquet")]
    public async Task<IActionResult> AnalyzeBouquet(IFormFile file)
    {
        if (file == null || file.Length == 0)
            return BadRequest(new { message = "Image file is required" });

        try
        {
            using var ms = new MemoryStream();
            await file.CopyToAsync(ms);
            var imageBytes = ms.ToArray();

            var result = await _bouquetAI.AnalyzeAsync(
                CompanyId, UserId, imageBytes, file.ContentType);

            return Ok(result);
        }
        catch (AIUsageLimitException ex)
        {
            return StatusCode(429, new { error = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return StatusCode(503, new { error = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Bouquet analysis failed for user {UserId} in company {CompanyId}", UserId, CompanyId);
            return StatusCode(500, new
            {
                error = _environment.IsDevelopment()
                    ? ex.Message
                    : "Bouquet analysis failed. Please try again later."
            });
        }
    }

    /// <summary>
    /// Save a bouquet recipe from AI scan results.
    /// Persists to the FloralRecipes table (same as production recipes).
    /// </summary>
    [HttpPost("bouquet-recipes")]
    public async Task<IActionResult> SaveBouquetRecipe([FromBody] SaveBouquetRecipeRequest request)
    {
        var createRequest = new CreateRecipeRequest
        {
            Name = request.Name,
            Category = "Bouquets",
            SellingPrice = 0,
            Components = request.Components.Select(c => new RecipeComponentDto
            {
                ProductName = $"{c.Color} {c.Flower}".Trim(),
                QuantityRequired = c.Stems,
                UnitCost = 0,
            }).ToList(),
            IsActive = true,
        };

        var recipe = await _productionService.CreateRecipeAsync(CompanyId, createRequest);
        return Ok(new { status = "saved", recipe });
    }

    /// <summary>
    /// Get bouquet recipes saved from AI scans.
    /// </summary>
    [HttpGet("bouquet-recipes")]
    public async Task<IActionResult> GetBouquetRecipes()
    {
        var recipes = await _productionService.GetRecipesAsync(CompanyId);
        var bouquetRecipes = recipes.Where(r =>
            string.Equals(r.Category, "Bouquets", StringComparison.OrdinalIgnoreCase)).ToList();

        return Ok(new { recipes = bouquetRecipes });
    }
}
