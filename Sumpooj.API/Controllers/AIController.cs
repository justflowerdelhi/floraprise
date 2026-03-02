using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.AI;
using Sumpooj.Application.Interfaces;
using System.Security.Claims;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/ai")]
[Authorize(Policy = "CompanyOnly")]
public class AIController : ControllerBase
{
    private readonly GiftCardAIService _giftCardAI;
    private readonly ITenantContext _tenantContext;

    public AIController(GiftCardAIService giftCardAI, ITenantContext tenantContext)
    {
        _giftCardAI = giftCardAI;
        _tenantContext = tenantContext;
    }

    private Guid CompanyId => _tenantContext.CompanyId
        ?? throw new UnauthorizedAccessException("Company context required");

    private Guid UserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)
        ?? throw new UnauthorizedAccessException("User not found"));

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
}
