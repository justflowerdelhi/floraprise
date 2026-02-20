using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Tasks;
using Sumpooj.Application.UseCases;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = "CompanyOnly")]
public class TasksController : ControllerBase
{
    private readonly TaskService _taskService;
    private readonly ITenantContext _tenantContext;

    public TasksController(TaskService taskService, ITenantContext tenantContext)
    {
        _taskService = taskService;
        _tenantContext = tenantContext;
    }

    private Guid CompanyId => _tenantContext.CompanyId 
        ?? throw new UnauthorizedAccessException("Company context required");

    [HttpGet("search")]
    public async Task<IActionResult> Search([FromQuery] TaskSearchRequest request)
    {
        var result = await _taskService.SearchAsync(CompanyId, request);
        return Ok(result);
    }

    [HttpGet("pending")]
    public async Task<IActionResult> GetPending([FromQuery] Guid? locationId = null)
    {
        var tasks = await _taskService.GetPendingTasksAsync(CompanyId, locationId);
        return Ok(tasks);
    }

    [HttpGet("by-staff/{staffId:guid}")]
    public async Task<IActionResult> GetByStaffId(Guid staffId)
    {
        var tasks = await _taskService.GetByStaffIdAsync(CompanyId, staffId);
        return Ok(tasks);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var task = await _taskService.GetByIdAsync(CompanyId, id);
        return task == null ? NotFound() : Ok(task);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateTaskRequest request)
    {
        var id = await _taskService.CreateAsync(CompanyId, request);
        return CreatedAtAction(nameof(GetById), new { id }, new { id });
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateTaskRequest request)
    {
        await _taskService.UpdateAsync(CompanyId, id, request);
        return NoContent();
    }

    [HttpPost("{id:guid}/start")]
    public async Task<IActionResult> Start(Guid id)
    {
        await _taskService.StartAsync(CompanyId, id);
        return NoContent();
    }

    [HttpPost("{id:guid}/complete")]
    public async Task<IActionResult> Complete(Guid id)
    {
        await _taskService.CompleteAsync(CompanyId, id);
        return NoContent();
    }

    [HttpPost("{id:guid}/reopen")]
    public async Task<IActionResult> Reopen(Guid id)
    {
        await _taskService.ReopenAsync(CompanyId, id);
        return NoContent();
    }
}
