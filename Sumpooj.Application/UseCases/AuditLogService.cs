using System.Text.Json;
using Sumpooj.Application.Audit;
using Sumpooj.Application.Common;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.UseCases;

public class AuditLogService
{
    private readonly IAuditLogRepository _auditLogRepository;

    public AuditLogService(IAuditLogRepository auditLogRepository)
    {
        _auditLogRepository = auditLogRepository;
    }

    public async Task<AuditLogDto?> GetByIdAsync(Guid companyId, Guid id)
    {
        var log = await _auditLogRepository.GetByIdAsync(companyId, id);
        return log == null ? null : MapToDto(log);
    }

    public async Task<PagedResult<AuditLogDto>> SearchAsync(Guid companyId, AuditLogSearchRequest request)
    {
        return await _auditLogRepository.SearchAsync(companyId, request);
    }

    public async Task<List<AuditLogDto>> GetByEntityAsync(Guid companyId, string entityType, Guid entityId)
    {
        return await _auditLogRepository.GetByEntityAsync(companyId, entityType, entityId);
    }

    public async Task<List<AuditLogDto>> GetByUserAsync(Guid companyId, Guid userId, int limit = 100)
    {
        return await _auditLogRepository.GetByUserAsync(companyId, userId, limit);
    }

    public async Task<List<AuditLogDto>> GetRecentAsync(Guid companyId, int limit = 100)
    {
        return await _auditLogRepository.GetRecentAsync(companyId, limit);
    }

    public async Task<AuditLogSummaryDto> GetSummaryAsync(Guid companyId, DateTime date)
    {
        return await _auditLogRepository.GetSummaryAsync(companyId, date);
    }

    public async Task<List<UserActivityDto>> GetUserActivityAsync(Guid companyId, DateTime fromDate, DateTime toDate)
    {
        return await _auditLogRepository.GetUserActivityAsync(companyId, fromDate, toDate);
    }

    /// <summary>
    /// Log an audit event
    /// </summary>
    public async Task LogAsync(
        Guid companyId,
        Guid? userId,
        string? userName,
        string? userRole,
        string action,
        string entityType,
        Guid? entityId,
        string? entityName,
        object? oldValue = null,
        object? newValue = null,
        string? description = null,
        string? ipAddress = null,
        string? userAgent = null,
        string? requestPath = null,
        string? httpMethod = null,
        bool isSuccess = true,
        string? errorMessage = null)
    {
        var auditLog = new AuditLog(
            companyId,
            userId,
            userName,
            action,
            entityType,
            entityId,
            entityName);

        auditLog.SetUserRole(userRole);
        
        if (oldValue != null)
        {
            auditLog.SetOldValues(SerializeValue(oldValue));
        }
        
        if (newValue != null)
        {
            auditLog.SetNewValues(SerializeValue(newValue));
        }

        auditLog.SetDescription(description);
        auditLog.SetRequestInfo(ipAddress, userAgent, requestPath, httpMethod);

        if (!isSuccess)
        {
            auditLog.MarkFailed(errorMessage ?? "Unknown error");
        }

        await _auditLogRepository.AddAsync(auditLog);
    }

    /// <summary>
    /// Log a create action
    /// </summary>
    public Task LogCreateAsync(
        Guid companyId, Guid? userId, string? userName, string? userRole,
        string entityType, Guid entityId, string? entityName, object? newValue = null,
        string? ipAddress = null, string? requestPath = null)
    {
        return LogAsync(companyId, userId, userName, userRole,
            AuditActions.Create, entityType, entityId, entityName,
            null, newValue, $"Created {entityType}: {entityName}",
            ipAddress, null, requestPath, "POST");
    }

    /// <summary>
    /// Log an update action
    /// </summary>
    public Task LogUpdateAsync(
        Guid companyId, Guid? userId, string? userName, string? userRole,
        string entityType, Guid entityId, string? entityName,
        object? oldValue = null, object? newValue = null,
        string? ipAddress = null, string? requestPath = null)
    {
        return LogAsync(companyId, userId, userName, userRole,
            AuditActions.Update, entityType, entityId, entityName,
            oldValue, newValue, $"Updated {entityType}: {entityName}",
            ipAddress, null, requestPath, "PUT");
    }

    /// <summary>
    /// Log a delete action
    /// </summary>
    public Task LogDeleteAsync(
        Guid companyId, Guid? userId, string? userName, string? userRole,
        string entityType, Guid entityId, string? entityName,
        string? ipAddress = null, string? requestPath = null)
    {
        return LogAsync(companyId, userId, userName, userRole,
            AuditActions.Delete, entityType, entityId, entityName,
            null, null, $"Deleted {entityType}: {entityName}",
            ipAddress, null, requestPath, "DELETE");
    }

    private static string? SerializeValue(object? value)
    {
        if (value == null) return null;
        
        try
        {
            return JsonSerializer.Serialize(value, new JsonSerializerOptions
            {
                WriteIndented = false,
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase
            });
        }
        catch
        {
            return value.ToString();
        }
    }

    private static AuditLogDto MapToDto(AuditLog log) => new()
    {
        Id = log.Id,
        UserId = log.UserId,
        UserName = log.UserName,
        UserRole = log.UserRole,
        Action = log.Action,
        EntityType = log.EntityType,
        EntityId = log.EntityId,
        EntityName = log.EntityName,
        OldValues = log.OldValues,
        NewValues = log.NewValues,
        Description = log.Description,
        IpAddress = log.IpAddress,
        RequestPath = log.RequestPath,
        HttpMethod = log.HttpMethod,
        Timestamp = log.Timestamp,
        DurationMs = log.DurationMs,
        IsSuccess = log.IsSuccess,
        ErrorMessage = log.ErrorMessage
    };
}
