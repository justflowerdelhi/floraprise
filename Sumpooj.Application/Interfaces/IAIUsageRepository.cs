using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IAIUsageRepository
{
    Task AddAsync(AIUsageRecord record);

    /// <summary>Count calls for a specific user today (UTC).</summary>
    Task<int> GetDailyCountByUserAsync(Guid userId, string feature);

    /// <summary>Count calls for a company this calendar month (UTC).</summary>
    Task<int> GetMonthlyCountByCompanyAsync(Guid companyId, string feature);
}
