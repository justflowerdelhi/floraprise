using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Analytics;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.UseCases;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/analytics")]
[Authorize(Policy = PolicyNames.CompanyOnly)]
public class AnalyticsController : ControllerBase
{
    private readonly ProfitDashboardService _profitService;
    private readonly ITenantContext _tenant;

    public AnalyticsController(ProfitDashboardService profitService, ITenantContext tenant)
    {
        _profitService = profitService;
        _tenant = tenant;
    }

    /// <summary>
    /// Get profit dashboard data
    /// </summary>
    [HttpGet("profit-dashboard")]
    [Authorize(Policy = PolicyNames.CompanyAdmin)]
    public async Task<ActionResult<ProfitDashboardDto>> GetProfitDashboard([FromQuery] ProfitDashboardRequest request)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var dashboard = await _profitService.GetDashboardAsync(companyId, request);
        return Ok(dashboard);
    }

    /// <summary>
    /// Get profit summary for a date range
    /// </summary>
    [HttpGet("profit-summary")]
    [Authorize(Policy = PolicyNames.CompanyAdmin)]
    public async Task<ActionResult<ExecutiveSummaryDto>> GetProfitSummary(
        [FromQuery] DateTime? fromDate,
        [FromQuery] DateTime? toDate)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var request = new ProfitDashboardRequest
        {
            FromDate = fromDate,
            ToDate = toDate
        };
        var dashboard = await _profitService.GetDashboardAsync(companyId, request);
        return Ok(dashboard.Summary);
    }

    /// <summary>
    /// Get channel-wise profit breakdown
    /// </summary>
    [HttpGet("profit-by-channel")]
    [Authorize(Policy = PolicyNames.CompanyAdmin)]
    public async Task<ActionResult<List<ChannelProfitDto>>> GetProfitByChannel(
        [FromQuery] DateTime? fromDate,
        [FromQuery] DateTime? toDate)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var request = new ProfitDashboardRequest
        {
            FromDate = fromDate,
            ToDate = toDate
        };
        var dashboard = await _profitService.GetDashboardAsync(companyId, request);
        return Ok(dashboard.ChannelProfit);
    }

    /// <summary>
    /// Get product profit analysis
    /// </summary>
    [HttpGet("product-profit")]
    [Authorize(Policy = PolicyNames.CompanyAdmin)]
    public async Task<ActionResult<List<ProductProfitDto>>> GetProductProfit(
        [FromQuery] DateTime? fromDate,
        [FromQuery] DateTime? toDate)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var request = new ProfitDashboardRequest
        {
            FromDate = fromDate,
            ToDate = toDate
        };
        var dashboard = await _profitService.GetDashboardAsync(companyId, request);
        return Ok(dashboard.ProductProfit);
    }

    /// <summary>
    /// Get platform commission analysis
    /// </summary>
    [HttpGet("platform-commission")]
    [Authorize(Policy = PolicyNames.CompanyAdmin)]
    public async Task<ActionResult<List<PlatformCommissionDto>>> GetPlatformCommission(
        [FromQuery] DateTime? fromDate,
        [FromQuery] DateTime? toDate)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var request = new ProfitDashboardRequest
        {
            FromDate = fromDate,
            ToDate = toDate
        };
        var dashboard = await _profitService.GetDashboardAsync(companyId, request);
        return Ok(dashboard.PlatformCommission);
    }
}
