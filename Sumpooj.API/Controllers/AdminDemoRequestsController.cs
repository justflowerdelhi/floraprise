using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Companies;
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
    private readonly ICompanyService _companyService;

    public AdminDemoRequestsController(IDemoRequestRepository repo, ICompanyService companyService)
    {
        _repo = repo;
        _companyService = companyService;
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

    /// <summary>
    /// Onboard a demo request as a new company.
    /// Creates the company and marks the demo request as Converted.
    /// </summary>
    [HttpPost("{id:guid}/onboard")]
    public async Task<IActionResult> Onboard(Guid id)
    {
        var demo = await _repo.GetByIdAsync(id);
        if (demo == null) return NotFound();

        if (demo.Status == LeadStatus.Converted)
            return BadRequest(new { message = "This demo request has already been converted." });

        // Create company from demo request info
        var companyId = await _companyService.CreateAsync(new CreateCompanyRequest
        {
            Name = demo.FullName,
            Region = "IN",
            Email = demo.BusinessEmail,
            ShortDescription = demo.BusinessType,
            TimeZone = "Asia/Kolkata",
            CurrencyCode = "INR",
        });

        // Mark as Converted
        demo.UpdateStatus(LeadStatus.Converted, $"Onboarded as company {companyId}");
        await _repo.UpdateAsync(demo);

        return Ok(new { companyId, message = $"Company created and demo request marked as Converted." });
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
