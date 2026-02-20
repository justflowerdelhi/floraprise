using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Audit;
using Sumpooj.Application.Common;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class AuditLogRepository : IAuditLogRepository
{
    private readonly SumpoojDbContext _db;

    public AuditLogRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public async Task AddAsync(AuditLog auditLog)
    {
        await _db.AuditLogs.AddAsync(auditLog);
        await _db.SaveChangesAsync();
    }

    public async Task<AuditLog?> GetByIdAsync(Guid companyId, Guid id)
    {
        return await _db.AuditLogs
            .FirstOrDefaultAsync(a => a.CompanyId == companyId && a.Id == id);
    }

    public async Task<PagedResult<AuditLogDto>> SearchAsync(Guid companyId, AuditLogSearchRequest request)
    {
        var query = _db.AuditLogs.Where(a => a.CompanyId == companyId);

        if (request.UserId.HasValue)
        {
            query = query.Where(a => a.UserId == request.UserId.Value);
        }

        if (!string.IsNullOrWhiteSpace(request.UserName))
        {
            var name = request.UserName.ToLower();
            query = query.Where(a => a.UserName != null && a.UserName.ToLower().Contains(name));
        }

        if (!string.IsNullOrWhiteSpace(request.Action))
        {
            query = query.Where(a => a.Action == request.Action);
        }

        if (!string.IsNullOrWhiteSpace(request.EntityType))
        {
            query = query.Where(a => a.EntityType == request.EntityType);
        }

        if (request.EntityId.HasValue)
        {
            query = query.Where(a => a.EntityId == request.EntityId.Value);
        }

        if (request.FromDate.HasValue)
        {
            query = query.Where(a => a.Timestamp >= request.FromDate.Value);
        }

        if (request.ToDate.HasValue)
        {
            query = query.Where(a => a.Timestamp <= request.ToDate.Value);
        }

        if (request.IsSuccess.HasValue)
        {
            query = query.Where(a => a.IsSuccess == request.IsSuccess.Value);
        }

        var total = await query.CountAsync();

        var items = await query
            .OrderByDescending(a => a.Timestamp)
            .Skip((request.Page - 1) * request.PageSize)
            .Take(request.PageSize)
            .Select(a => new AuditLogDto
            {
                Id = a.Id,
                UserId = a.UserId,
                UserName = a.UserName,
                UserRole = a.UserRole,
                Action = a.Action,
                EntityType = a.EntityType,
                EntityId = a.EntityId,
                EntityName = a.EntityName,
                OldValues = a.OldValues,
                NewValues = a.NewValues,
                Description = a.Description,
                IpAddress = a.IpAddress,
                RequestPath = a.RequestPath,
                HttpMethod = a.HttpMethod,
                Timestamp = a.Timestamp,
                DurationMs = a.DurationMs,
                IsSuccess = a.IsSuccess,
                ErrorMessage = a.ErrorMessage
            })
            .ToListAsync();

        return new PagedResult<AuditLogDto>(items, total, request.Page, request.PageSize);
    }

    public async Task<List<AuditLogDto>> GetByEntityAsync(Guid companyId, string entityType, Guid entityId)
    {
        return await _db.AuditLogs
            .Where(a => a.CompanyId == companyId && a.EntityType == entityType && a.EntityId == entityId)
            .OrderByDescending(a => a.Timestamp)
            .Select(a => new AuditLogDto
            {
                Id = a.Id,
                UserId = a.UserId,
                UserName = a.UserName,
                UserRole = a.UserRole,
                Action = a.Action,
                EntityType = a.EntityType,
                EntityId = a.EntityId,
                EntityName = a.EntityName,
                OldValues = a.OldValues,
                NewValues = a.NewValues,
                Description = a.Description,
                IpAddress = a.IpAddress,
                RequestPath = a.RequestPath,
                HttpMethod = a.HttpMethod,
                Timestamp = a.Timestamp,
                DurationMs = a.DurationMs,
                IsSuccess = a.IsSuccess,
                ErrorMessage = a.ErrorMessage
            })
            .ToListAsync();
    }

    public async Task<List<AuditLogDto>> GetByUserAsync(Guid companyId, Guid userId, int limit = 100)
    {
        return await _db.AuditLogs
            .Where(a => a.CompanyId == companyId && a.UserId == userId)
            .OrderByDescending(a => a.Timestamp)
            .Take(limit)
            .Select(a => new AuditLogDto
            {
                Id = a.Id,
                UserId = a.UserId,
                UserName = a.UserName,
                UserRole = a.UserRole,
                Action = a.Action,
                EntityType = a.EntityType,
                EntityId = a.EntityId,
                EntityName = a.EntityName,
                Description = a.Description,
                Timestamp = a.Timestamp,
                IsSuccess = a.IsSuccess
            })
            .ToListAsync();
    }

    public async Task<List<AuditLogDto>> GetRecentAsync(Guid companyId, int limit = 100)
    {
        return await _db.AuditLogs
            .Where(a => a.CompanyId == companyId)
            .OrderByDescending(a => a.Timestamp)
            .Take(limit)
            .Select(a => new AuditLogDto
            {
                Id = a.Id,
                UserId = a.UserId,
                UserName = a.UserName,
                UserRole = a.UserRole,
                Action = a.Action,
                EntityType = a.EntityType,
                EntityId = a.EntityId,
                EntityName = a.EntityName,
                Description = a.Description,
                Timestamp = a.Timestamp,
                IsSuccess = a.IsSuccess
            })
            .ToListAsync();
    }

    public async Task<AuditLogSummaryDto> GetSummaryAsync(Guid companyId, DateTime date)
    {
        var startOfDay = date.Date;
        var endOfDay = startOfDay.AddDays(1);

        var logs = await _db.AuditLogs
            .Where(a => a.CompanyId == companyId && a.Timestamp >= startOfDay && a.Timestamp < endOfDay)
            .ToListAsync();

        var actionBreakdown = logs
            .GroupBy(a => a.Action)
            .ToDictionary(g => g.Key, g => g.Count());

        var entityBreakdown = logs
            .GroupBy(a => a.EntityType)
            .ToDictionary(g => g.Key, g => g.Count());

        var topUsers = logs
            .Where(a => a.UserId.HasValue)
            .GroupBy(a => new { a.UserId, a.UserName })
            .Select(g => new UserActivityDto
            {
                UserId = g.Key.UserId,
                UserName = g.Key.UserName,
                ActionCount = g.Count(),
                LastActivity = g.Max(a => a.Timestamp)
            })
            .OrderByDescending(u => u.ActionCount)
            .Take(10)
            .ToList();

        return new AuditLogSummaryDto
        {
            Date = date.Date,
            TotalActions = logs.Count,
            SuccessfulActions = logs.Count(a => a.IsSuccess),
            FailedActions = logs.Count(a => !a.IsSuccess),
            ActionBreakdown = actionBreakdown,
            EntityBreakdown = entityBreakdown,
            TopUsers = topUsers
        };
    }

    public async Task<List<UserActivityDto>> GetUserActivityAsync(Guid companyId, DateTime fromDate, DateTime toDate)
    {
        return await _db.AuditLogs
            .Where(a => a.CompanyId == companyId && 
                       a.UserId.HasValue && 
                       a.Timestamp >= fromDate && 
                       a.Timestamp <= toDate)
            .GroupBy(a => new { a.UserId, a.UserName })
            .Select(g => new UserActivityDto
            {
                UserId = g.Key.UserId,
                UserName = g.Key.UserName,
                ActionCount = g.Count(),
                LastActivity = g.Max(a => a.Timestamp)
            })
            .OrderByDescending(u => u.ActionCount)
            .ToListAsync();
    }
}
