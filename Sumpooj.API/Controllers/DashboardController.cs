using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.UseCases;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = "CompanyOnly")]
public class DashboardController : ControllerBase
{
    private readonly DashboardService _dashboardService;
    private readonly ITenantContext _tenantContext;

    public DashboardController(DashboardService dashboardService, ITenantContext tenantContext)
    {
        _dashboardService = dashboardService;
        _tenantContext = tenantContext;
    }

    private Guid CompanyId => _tenantContext.CompanyId 
        ?? throw new UnauthorizedAccessException("Company context required");

    [HttpGet]
    public async Task<IActionResult> GetDashboard([FromQuery] string role, [FromQuery] Guid? locationId = null)
    {
        var result = await _dashboardService.GetDashboardAsync(CompanyId, role, locationId);
        return Ok(result);
    }
}
