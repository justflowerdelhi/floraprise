using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Common;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Proposals;
using Sumpooj.Application.UseCases;
using System.Security.Claims;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/proposals")]
[Authorize(Policy = PolicyNames.CompanyOnly)]
public class ProposalsController : ControllerBase
{
    private readonly ProposalService _service;
    private readonly ITenantContext _tenant;

    public ProposalsController(ProposalService service, ITenantContext tenant)
    {
        _service = service;
        _tenant = tenant;
    }

    /// <summary>
    /// Search proposals
    /// </summary>
    [HttpGet("search")]
    public async Task<ActionResult<PagedResult<ProposalDto>>> Search([FromQuery] ProposalSearchRequest request)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var result = await _service.SearchAsync(companyId, request);
        return Ok(result);
    }

    /// <summary>
    /// Get proposal by ID
    /// </summary>
    [HttpGet("{id:guid}")]
    public async Task<ActionResult<ProposalDto>> GetById(Guid id)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var proposal = await _service.GetByIdAsync(companyId, id);
        return proposal == null ? NotFound() : Ok(proposal);
    }

    /// <summary>
    /// Get proposals for an event
    /// </summary>
    [HttpGet("by-event/{eventId:guid}")]
    public async Task<ActionResult<List<ProposalDto>>> GetByEvent(Guid eventId)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var proposals = await _service.GetByEventAsync(companyId, eventId);
        return Ok(proposals);
    }

    /// <summary>
    /// Create a new proposal
    /// </summary>
    [HttpPost]
    public async Task<ActionResult<ProposalDto>> Create([FromBody] CreateProposalRequest request)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var proposal = await _service.CreateAsync(companyId, userId, request);
        return CreatedAtAction(nameof(GetById), new { id = proposal.Id }, proposal);
    }

    /// <summary>
    /// Update a proposal
    /// </summary>
    [HttpPut("{id:guid}")]
    public async Task<ActionResult<ProposalDto>> Update(Guid id, [FromBody] UpdateProposalRequest request)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var proposal = await _service.UpdateAsync(companyId, id, request);
        return proposal == null ? NotFound() : Ok(proposal);
    }

    /// <summary>
    /// Send proposal to client
    /// </summary>
    [HttpPost("{id:guid}/send")]
    public async Task<ActionResult<ProposalDto>> Send(Guid id)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var proposal = await _service.SendAsync(companyId, id);
        return proposal == null ? NotFound() : Ok(proposal);
    }

    /// <summary>
    /// Mark proposal as viewed (called when client opens)
    /// </summary>
    [HttpPost("{id:guid}/mark-viewed")]
    [AllowAnonymous] // Can be called from public link
    public async Task<ActionResult<ProposalDto>> MarkViewed(Guid id, [FromQuery] Guid companyId)
    {
        var proposal = await _service.MarkViewedAsync(companyId, id);
        return proposal == null ? NotFound() : Ok(proposal);
    }

    /// <summary>
    /// Accept proposal (client action)
    /// </summary>
    [HttpPost("{id:guid}/accept")]
    public async Task<ActionResult<ProposalDto>> Accept(Guid id, [FromBody] AcceptProposalRequest? request)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var proposal = await _service.AcceptAsync(companyId, id, request?.Feedback);
        return proposal == null ? NotFound() : Ok(proposal);
    }

    /// <summary>
    /// Decline proposal (client action)
    /// </summary>
    [HttpPost("{id:guid}/decline")]
    public async Task<ActionResult<ProposalDto>> Decline(Guid id, [FromBody] DeclineProposalRequest request)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var proposal = await _service.DeclineAsync(companyId, id, request.Reason, request.Feedback);
        return proposal == null ? NotFound() : Ok(proposal);
    }

    /// <summary>
    /// Request revision (client action)
    /// </summary>
    [HttpPost("{id:guid}/request-revision")]
    public async Task<ActionResult<ProposalDto>> RequestRevision(Guid id, [FromBody] RevisionRequest request)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var proposal = await _service.RequestRevisionAsync(companyId, id, request.Feedback);
        return proposal == null ? NotFound() : Ok(proposal);
    }

    /// <summary>
    /// Create a new revision of a proposal
    /// </summary>
    [HttpPost("{id:guid}/create-revision")]
    public async Task<ActionResult<ProposalDto>> CreateRevision(Guid id)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var proposal = await _service.CreateRevisionAsync(companyId, id);
        return proposal == null ? NotFound() : Ok(proposal);
    }
}

// Request DTOs
public record AcceptProposalRequest(string? Feedback);
public record DeclineProposalRequest(string Reason, string? Feedback);
public record RevisionRequest(string Feedback);
