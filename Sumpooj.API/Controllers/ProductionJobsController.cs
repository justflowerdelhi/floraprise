using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Production;
using Sumpooj.Application.UseCases;
using Sumpooj.Domain.Entities;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/production-jobs")]
[Authorize(Policy = PolicyNames.CompanyOnly)]
public class ProductionJobsController : ControllerBase
{
    private readonly ProductionService _service;
    private readonly ITenantContext _tenant;

    public ProductionJobsController(ProductionService service, ITenantContext tenant)
    {
        _service = service;
        _tenant = tenant;
    }

    private Guid CompanyId =>
        _tenant.CompanyId ?? throw new UnauthorizedAccessException("Company context required");

    /// <summary>
    /// GET /api/production-jobs?status=Pending
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<List<ProductionJobDto>>> Get([FromQuery] string? status = null)
    {
        ProductionStatus? parsed = null;
        if (!string.IsNullOrWhiteSpace(status) && Enum.TryParse<ProductionStatus>(status, true, out var s))
            parsed = s;

        var jobs = await _service.GetJobsAsync(CompanyId, parsed);
        return Ok(jobs);
    }

    /// <summary>
    /// GET /api/production-jobs/{id}
    /// </summary>
    [HttpGet("{id:guid}")]
    public async Task<ActionResult<ProductionJobDto>> GetById(Guid id)
    {
        var job = await _service.GetJobByIdAsync(CompanyId, id);
        return job == null ? NotFound() : Ok(job);
    }

    /// <summary>
    /// POST /api/production-jobs
    /// </summary>
    [HttpPost]
    public async Task<ActionResult<ProductionJobDto>> Create([FromBody] CreateProductionJobRequest request)
    {
        var job = await _service.CreateJobAsync(CompanyId, request);
        return CreatedAtAction(nameof(GetById), new { id = job.JobId }, job);
    }

    /// <summary>
    /// POST /api/production-jobs/{id}/start
    /// </summary>
    [HttpPost("{id:guid}/start")]
    public async Task<ActionResult> Start(Guid id)
    {
        var success = await _service.StartJobAsync(CompanyId, id);
        return success ? Ok() : NotFound();
    }

    /// <summary>
    /// POST /api/production-jobs/{id}/complete
    /// </summary>
    [HttpPost("{id:guid}/complete")]
    public async Task<ActionResult> Complete(Guid id)
    {
        var success = await _service.CompleteJobAsync(CompanyId, id);
        return success ? Ok() : NotFound();
    }
}
