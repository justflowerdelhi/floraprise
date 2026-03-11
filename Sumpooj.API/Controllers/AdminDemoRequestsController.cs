using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;

namespace Sumpooj.API.Controllers;

/// <summary>
/// Platform Super Admin endpoints for managing demo requests.
/// </summary>
[ApiController]
[Route("api/admin/demo-requests")]
[Authorize(Policy = "PlatformOnly")]
public class AdminDemoRequestsController : ControllerBase
{
    private readonly IDemoRequestRepository _repo;

    public AdminDemoRequestsController(IDemoRequestRepository repo)
    {
        _repo = repo;
    }

    /// <summary>
    /// List all demo requests. Platform Super Admin only.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var items = await _repo.GetAllAsync();
        var result = items.Select(d => new DemoRequestListDto
        {
            Id = d.Id,
            FullName = d.FullName,
            BusinessEmail = d.BusinessEmail,
            BusinessType = d.BusinessType,
            CurrentSoftware = d.CurrentSoftware,
            Notes = d.Notes,
            Status = d.Status.ToString(),
            Comments = d.Comments,
            CreatedAt = d.CreatedAtUtc.ToString("o"),
            UpdatedAt = d.UpdatedAtUtc?.ToString("o"),
        }).ToList();

        return Ok(result);
    }

    /// <summary>
    /// Get a single demo request by ID.
    /// </summary>
    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var d = await _repo.GetByIdAsync(id);
        if (d == null) return NotFound();

        return Ok(new DemoRequestListDto
        {
            Id = d.Id,
            FullName = d.FullName,
            BusinessEmail = d.BusinessEmail,
            BusinessType = d.BusinessType,
            CurrentSoftware = d.CurrentSoftware,
            Notes = d.Notes,
            Status = d.Status.ToString(),
            Comments = d.Comments,
            CreatedAt = d.CreatedAtUtc.ToString("o"),
            UpdatedAt = d.UpdatedAtUtc?.ToString("o"),
        });
    }

    /// <summary>
    /// Update the status of a demo request (e.g. NewLead → Contacted → Qualified → Converted).
    /// </summary>
    [HttpPatch("{id:guid}/status")]
    public async Task<IActionResult> UpdateStatus(Guid id, [FromBody] UpdateDemoRequestStatusRequest request)
    {
        var demo = await _repo.GetByIdAsync(id);
        if (demo == null) return NotFound();

        if (!Enum.TryParse<LeadStatus>(request.Status, true, out var status))
            return BadRequest(new { message = $"Invalid status: {request.Status}. Valid values: NewLead, Contacted, Qualified, Converted" });

        demo.UpdateStatus(status, request.Comments);
        await _repo.UpdateAsync(demo);

        return Ok(new { id = demo.Id, status = demo.Status.ToString(), comments = demo.Comments });
    }
}

public class DemoRequestListDto
{
    public Guid Id { get; set; }
    public string FullName { get; set; } = default!;
    public string BusinessEmail { get; set; } = default!;
    public string? BusinessType { get; set; }
    public string? CurrentSoftware { get; set; }
    public string? Notes { get; set; }
    public string Status { get; set; } = default!;
    public string? Comments { get; set; }
    public string CreatedAt { get; set; } = default!;
    public string? UpdatedAt { get; set; }
}

public class UpdateDemoRequestStatusRequest
{
    public string Status { get; set; } = default!;
    public string? Comments { get; set; }
}
