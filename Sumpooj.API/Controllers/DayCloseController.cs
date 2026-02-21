using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.DayClose;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.UseCases;
using System.Security.Claims;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/day-close")]
[Authorize(Policy = "CompanyOnly")]
public class DayCloseController : ControllerBase
{
    private readonly DayCloseService _dayCloseService;
    private readonly ITenantContext _tenantContext;

    public DayCloseController(DayCloseService dayCloseService, ITenantContext tenantContext)
    {
        _dayCloseService = dayCloseService;
        _tenantContext = tenantContext;
    }

    private Guid CompanyId => _tenantContext.CompanyId 
        ?? throw new UnauthorizedAccessException("Company context required");

    private Guid UserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier) 
        ?? throw new UnauthorizedAccessException("User not found"));

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var dayClose = await _dayCloseService.GetByIdAsync(CompanyId, id);
        return dayClose == null ? NotFound() : Ok(dayClose);
    }

    [HttpGet("summary")]
    public async Task<IActionResult> GetSummary([FromQuery] Guid locationId, [FromQuery] DateTime date)
    {
        var summary = await _dayCloseService.GetSummaryAsync(CompanyId, locationId, date);
        return Ok(summary);
    }

    [HttpGet("is-closed")]
    public async Task<IActionResult> IsClosed([FromQuery] Guid locationId, [FromQuery] DateTime date)
    {
        var isClosed = await _dayCloseService.IsDayClosedAsync(CompanyId, locationId, date);
        return Ok(new { isClosed });
    }

    [HttpGet("history")]
    public async Task<IActionResult> GetHistory([FromQuery] Guid locationId, [FromQuery] int days = 30)
    {
        var history = await _dayCloseService.GetHistoryAsync(CompanyId, locationId, days);
        return Ok(history);
    }

    [HttpPost]
    [Authorize(Policy = "StaffAccess")]
    public async Task<IActionResult> Close([FromBody] CloseDayRequest request)
    {
        var id = await _dayCloseService.CloseAsync(CompanyId, request, UserId);
        return CreatedAtAction(nameof(GetById), new { id }, new { id });
    }
}
