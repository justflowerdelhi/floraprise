using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Audit;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.UseCases;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/audit-logs")]
[Authorize(Policy = "CompanyAdmin")]
public class AuditLogsController : ControllerBase
{
    private readonly AuditLogService _auditLogService;
    private readonly ITenantContext _tenantContext;

    public AuditLogsController(AuditLogService auditLogService, ITenantContext tenantContext)
    {
        _auditLogService = auditLogService;
        _tenantContext = tenantContext;
    }

    private Guid CompanyId => _tenantContext.CompanyId 
        ?? throw new UnauthorizedAccessException("Company context required");

    /// <summary>
    /// Search audit logs with filters
    /// </summary>
    [HttpGet("search")]
    public async Task<IActionResult> Search([FromQuery] AuditLogSearchRequest request)
    {
        var result = await _auditLogService.SearchAsync(CompanyId, request);
        return Ok(result);
    }

    /// <summary>
    /// Get recent audit logs
    /// </summary>
    [HttpGet("recent")]
    public async Task<IActionResult> GetRecent([FromQuery] int limit = 100)
    {
        var logs = await _auditLogService.GetRecentAsync(CompanyId, limit);
        return Ok(logs);
    }

    /// <summary>
    /// Get audit log by ID
    /// </summary>
    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var log = await _auditLogService.GetByIdAsync(CompanyId, id);
        return log == null ? NotFound() : Ok(log);
    }

    /// <summary>
    /// Get audit history for a specific entity
    /// </summary>
    [HttpGet("entity/{entityType}/{entityId:guid}")]
    public async Task<IActionResult> GetByEntity(string entityType, Guid entityId)
    {
        var logs = await _auditLogService.GetByEntityAsync(CompanyId, entityType, entityId);
        return Ok(logs);
    }

    /// <summary>
    /// Get audit history for a specific user
    /// </summary>
    [HttpGet("user/{userId:guid}")]
    public async Task<IActionResult> GetByUser(Guid userId, [FromQuery] int limit = 100)
    {
        var logs = await _auditLogService.GetByUserAsync(CompanyId, userId, limit);
        return Ok(logs);
    }

    /// <summary>
    /// Get daily summary of audit logs
    /// </summary>
    [HttpGet("summary")]
    public async Task<IActionResult> GetSummary([FromQuery] DateTime? date = null)
    {
        var targetDate = date ?? DateTime.UtcNow;
        var summary = await _auditLogService.GetSummaryAsync(CompanyId, targetDate);
        return Ok(summary);
    }

    /// <summary>
    /// Get user activity report
    /// </summary>
    [HttpGet("user-activity")]
    public async Task<IActionResult> GetUserActivity(
        [FromQuery] DateTime? fromDate = null, 
        [FromQuery] DateTime? toDate = null)
    {
        var from = fromDate ?? DateTime.UtcNow.AddDays(-30);
        var to = toDate ?? DateTime.UtcNow;
        var activity = await _auditLogService.GetUserActivityAsync(CompanyId, from, to);
        return Ok(activity);
    }
}
