using Sumpooj.Application.Audit;
using Sumpooj.Application.Common;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IAuditLogRepository
{
    Task AddAsync(AuditLog auditLog);
    Task<AuditLog?> GetByIdAsync(Guid companyId, Guid id);
    Task<PagedResult<AuditLogDto>> SearchAsync(Guid companyId, AuditLogSearchRequest request);
    Task<List<AuditLogDto>> GetByEntityAsync(Guid companyId, string entityType, Guid entityId);
    Task<List<AuditLogDto>> GetByUserAsync(Guid companyId, Guid userId, int limit = 100);
    Task<List<AuditLogDto>> GetRecentAsync(Guid companyId, int limit = 100);
    Task<AuditLogSummaryDto> GetSummaryAsync(Guid companyId, DateTime date);
    Task<List<UserActivityDto>> GetUserActivityAsync(Guid companyId, DateTime fromDate, DateTime toDate);
}
