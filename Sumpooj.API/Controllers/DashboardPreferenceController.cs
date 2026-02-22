using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Dashboard;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.UseCases;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/dashboard-preference")]
[Authorize(Policy = "CompanyOnly")]
public class DashboardPreferenceController : ControllerBase
{
    private readonly DashboardPreferenceService _service;
    private readonly ITenantContext _tenantContext;

    public DashboardPreferenceController(
        DashboardPreferenceService service,
        ITenantContext tenantContext)
    {
        _service = service;
        _tenantContext = tenantContext;
    }

    private Guid CompanyId => _tenantContext.CompanyId
        ?? throw new UnauthorizedAccessException("Company context required");

    private Guid UserId => Guid.Parse(
        User.FindFirstValue(ClaimTypes.NameIdentifier)
        ?? throw new UnauthorizedAccessException("User identity required"));

    /// <summary>
    /// GET /api/dashboard-preference
    /// Returns the current user's module visibility/order, or defaults if none saved.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> Get()
    {
        var result = await _service.GetAsync(CompanyId, UserId);
        return Ok(result);
    }

    /// <summary>
    /// POST /api/dashboard-preference
    /// Creates or updates the current user's module visibility/order.
    /// </summary>
    [HttpPost]
    public async Task<IActionResult> Save([FromBody] SaveDashboardPreferenceRequest request)
    {
        var result = await _service.SaveAsync(CompanyId, UserId, request);
        return Ok(result);
    }
}
