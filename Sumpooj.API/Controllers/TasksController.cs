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
    private readonly ILogger<TasksController> _logger;
    private readonly IWebHostEnvironment _environment;
    private readonly TaskService _taskService;
    private readonly ITenantContext _tenantContext;

    public TasksController(
        ILogger<TasksController> logger,
        IWebHostEnvironment environment,
        TaskService taskService,
        ITenantContext tenantContext)
    {
        _logger = logger;
        _environment = environment;
        _taskService = taskService;
        _tenantContext = tenantContext;
    }

    private Guid CompanyId => _tenantContext.CompanyId 
        ?? throw new UnauthorizedAccessException("Company context required");

    private static string GetInnermostMessage(Exception ex)
    {
        var current = ex;
        while (current.InnerException != null)
        {
            current = current.InnerException;
        }

        return current.Message;
    }

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
        try
        {
            var id = await _taskService.CreateAsync(CompanyId, request);
            return CreatedAtAction(nameof(GetById), new { id }, new { id });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { error = ex.Message });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to create task for company {CompanyId}. Title={Title}", CompanyId, request.Title);
            return StatusCode(500, new
            {
                error = _environment.IsDevelopment()
                    ? GetInnermostMessage(ex)
                    : "Failed to create task. Please try again later."
            });
        }
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateTaskRequest request)
    {
        try
        {
            await _taskService.UpdateAsync(CompanyId, id, request);
            return NoContent();
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { error = ex.Message });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to update task {TaskId} for company {CompanyId}", id, CompanyId);
            return StatusCode(500, new
            {
                error = _environment.IsDevelopment()
                    ? GetInnermostMessage(ex)
                    : "Failed to update task. Please try again later."
            });
        }
    }

    [HttpPost("{id:guid}/start")]
    public async Task<IActionResult> Start(Guid id)
    {
        try
        {
            await _taskService.StartAsync(CompanyId, id);
            return NoContent();
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { error = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to start task {TaskId} for company {CompanyId}", id, CompanyId);
            return StatusCode(500, new
            {
                error = _environment.IsDevelopment()
                    ? GetInnermostMessage(ex)
                    : "Failed to start task. Please try again later."
            });
        }
    }

    [HttpPost("{id:guid}/complete")]
    public async Task<IActionResult> Complete(Guid id)
    {
        try
        {
            await _taskService.CompleteAsync(CompanyId, id);
            return NoContent();
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { error = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to complete task {TaskId} for company {CompanyId}", id, CompanyId);
            return StatusCode(500, new
            {
                error = _environment.IsDevelopment()
                    ? GetInnermostMessage(ex)
                    : "Failed to complete task. Please try again later."
            });
        }
    }

    [HttpPost("{id:guid}/reopen")]
    public async Task<IActionResult> Reopen(Guid id)
    {
        try
        {
            await _taskService.ReopenAsync(CompanyId, id);
            return NoContent();
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { error = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to reopen task {TaskId} for company {CompanyId}", id, CompanyId);
            return StatusCode(500, new
            {
                error = _environment.IsDevelopment()
                    ? GetInnermostMessage(ex)
                    : "Failed to reopen task. Please try again later."
            });
        }
    }
}
