using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Shifts;
using Sumpooj.Application.UseCases;
using System.Security.Claims;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/shifts")]
[Authorize(Policy = "CompanyOnly")]
public class ShiftController : ControllerBase
{
    private readonly ShiftService _shiftService;
    private readonly ITenantContext _tenantContext;

    public ShiftController(ShiftService shiftService, ITenantContext tenantContext)
    {
        _shiftService = shiftService;
        _tenantContext = tenantContext;
    }

    private Guid CompanyId => _tenantContext.CompanyId
        ?? throw new UnauthorizedAccessException("Company context required");

    private Guid UserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)
        ?? throw new UnauthorizedAccessException("User not found"));

    private string UserName => User.FindFirstValue(ClaimTypes.Name)
        ?? User.FindFirstValue("name")
        ?? "Unknown";

    /// <summary>
    /// Get the currently-open shift for a location.
    /// Returns 204 if no active shift.
    /// </summary>
    [HttpGet("active")]
    public async Task<IActionResult> GetActive([FromQuery] Guid locationId)
    {
        var shift = await _shiftService.GetActiveShiftAsync(CompanyId, locationId);
        return shift == null ? NoContent() : Ok(shift);
    }

    /// <summary>
    /// Get a specific shift by ID.
    /// </summary>
    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var shift = await _shiftService.GetByIdAsync(CompanyId, id);
        return shift == null ? NotFound() : Ok(shift);
    }

    /// <summary>
    /// Get shift history for a location.
    /// </summary>
    [HttpGet("history")]
    public async Task<IActionResult> GetHistory([FromQuery] Guid locationId, [FromQuery] int count = 20)
    {
        var history = await _shiftService.GetHistoryAsync(CompanyId, locationId, count);
        return Ok(history);
    }

    /// <summary>
    /// Open a new shift at a location.
    /// </summary>
    [HttpPost("open")]
    [Authorize(Policy = "StaffAccess")]
    public async Task<IActionResult> Open([FromBody] OpenShiftRequest request)
    {
        var id = await _shiftService.OpenAsync(CompanyId, request, UserId, UserName);
        return CreatedAtAction(nameof(GetById), new { id }, new { id });
    }

    /// <summary>
    /// Close an active shift (Manager or Admin only).
    /// </summary>
    [HttpPost("{id:guid}/close")]
    [Authorize(Policy = "StaffAccess")]
    public async Task<IActionResult> Close(Guid id, [FromBody] CloseShiftRequest request)
    {
        await _shiftService.CloseAsync(CompanyId, id, request, UserId, UserName);
        return Ok(new { message = "Shift closed successfully" });
    }
}
