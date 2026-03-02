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

    [HttpGet("profit-by-category")]
    [Authorize(Policy = PolicyNames.CompanyAdmin)]
    public async Task<IActionResult> GetProfitByCategory(
        [FromQuery] DateTime? fromDate, [FromQuery] DateTime? toDate)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var dashboard = await _profitService.GetDashboardAsync(companyId, new ProfitDashboardRequest { FromDate = fromDate, ToDate = toDate });
        return Ok(dashboard.ProductProfit?.GroupBy(p => p.Category ?? "Other")
            .Select(g => new { category = g.Key, revenue = g.Sum(p => p.GrossRevenue), profit = g.Sum(p => p.NetProfit) })
            .ToList() ?? []);
    }

    [HttpGet("top-products")]
    [Authorize(Policy = PolicyNames.CompanyAdmin)]
    public async Task<IActionResult> GetTopProducts(
        [FromQuery] DateTime? fromDate, [FromQuery] DateTime? toDate, [FromQuery] int limit = 10)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var dashboard = await _profitService.GetDashboardAsync(companyId, new ProfitDashboardRequest { FromDate = fromDate, ToDate = toDate });
        return Ok(dashboard.ProductProfit?.OrderByDescending(p => p.GrossRevenue).Take(limit).ToList() ?? []);
    }

    [HttpGet("low-margin-products")]
    [Authorize(Policy = PolicyNames.CompanyAdmin)]
    public async Task<IActionResult> GetLowMarginProducts(
        [FromQuery] DateTime? fromDate, [FromQuery] DateTime? toDate, [FromQuery] int limit = 10)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var dashboard = await _profitService.GetDashboardAsync(companyId, new ProfitDashboardRequest { FromDate = fromDate, ToDate = toDate });
        return Ok(dashboard.ProductProfit?.OrderBy(p => p.EffectiveMarginPercent).Take(limit).ToList() ?? []);
    }

    [HttpGet("profit-by-source")]
    [Authorize(Policy = PolicyNames.CompanyAdmin)]
    public async Task<IActionResult> GetProfitBySource(
        [FromQuery] DateTime? fromDate, [FromQuery] DateTime? toDate)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var dashboard = await _profitService.GetDashboardAsync(companyId, new ProfitDashboardRequest { FromDate = fromDate, ToDate = toDate });
        return Ok(dashboard.ChannelProfit ?? []);
    }

    [HttpGet("daily-profit")]
    [Authorize(Policy = PolicyNames.CompanyAdmin)]
    public async Task<IActionResult> GetDailyProfit(
        [FromQuery] DateTime? fromDate, [FromQuery] DateTime? toDate)
    {
        return Ok(new List<object>());
    }

    [HttpGet("wire-order-profit")]
    [Authorize(Policy = PolicyNames.CompanyAdmin)]
    public async Task<IActionResult> GetWireOrderProfit(
        [FromQuery] DateTime? fromDate, [FromQuery] DateTime? toDate)
    {
        return Ok(new List<object>());
    }

    [HttpGet("event-profit")]
    [Authorize(Policy = PolicyNames.CompanyAdmin)]
    public async Task<IActionResult> GetEventProfit(
        [FromQuery] DateTime? fromDate, [FromQuery] DateTime? toDate)
    {
        return Ok(new List<object>());
    }
}
