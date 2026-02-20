using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Staff;
using Sumpooj.Application.UseCases;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = "CompanyOnly")]
public class StaffController : ControllerBase
{
    private readonly StaffService _staffService;
    private readonly ITenantContext _tenantContext;

    public StaffController(StaffService staffService, ITenantContext tenantContext)
    {
        _staffService = staffService;
        _tenantContext = tenantContext;
    }

    private Guid CompanyId => _tenantContext.CompanyId 
        ?? throw new UnauthorizedAccessException("Company context required");

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var staff = await _staffService.GetAllActiveAsync(CompanyId);
        return Ok(staff);
    }

    [HttpGet("search")]
    public async Task<IActionResult> Search([FromQuery] StaffSearchRequest request)
    {
        var result = await _staffService.SearchAsync(CompanyId, request);
        return Ok(result);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var staff = await _staffService.GetByIdAsync(CompanyId, id);
        return staff == null ? NotFound() : Ok(staff);
    }

    [HttpGet("by-role/{role}")]
    public async Task<IActionResult> GetByRole(string role)
    {
        var staff = await _staffService.GetByRoleAsync(CompanyId, role);
        return Ok(staff);
    }

    [HttpPost]
    [Authorize(Policy = "CompanyAdmin")]
    public async Task<IActionResult> Create([FromBody] CreateStaffRequest request)
    {
        var id = await _staffService.CreateAsync(CompanyId, request);
        return CreatedAtAction(nameof(GetById), new { id }, new { id });
    }

    [HttpPut("{id:guid}")]
    [Authorize(Policy = "CompanyAdmin")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateStaffRequest request)
    {
        await _staffService.UpdateAsync(CompanyId, id, request);
        return NoContent();
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Policy = "CompanyAdmin")]
    public async Task<IActionResult> Deactivate(Guid id)
    {
        await _staffService.DeactivateAsync(CompanyId, id);
        return NoContent();
    }
}
