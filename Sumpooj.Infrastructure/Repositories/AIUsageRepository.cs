using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class AIUsageRepository : IAIUsageRepository
{
    private readonly SumpoojDbContext _db;

    public AIUsageRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public async Task AddAsync(AIUsageRecord record)
    {
        _db.AIUsageRecords.Add(record);
        await _db.SaveChangesAsync();
    }

    public async Task<int> GetDailyCountByUserAsync(Guid userId, string feature)
    {
        var todayUtc = DateTime.UtcNow.Date;
        return await _db.AIUsageRecords
            .CountAsync(r => r.UserId == userId
                          && r.Feature == feature
                          && r.CreatedAtUtc >= todayUtc);
    }

    public async Task<int> GetMonthlyCountByCompanyAsync(Guid companyId, string feature)
    {
        var firstOfMonth = new DateTime(DateTime.UtcNow.Year, DateTime.UtcNow.Month, 1, 0, 0, 0, DateTimeKind.Utc);
        return await _db.AIUsageRecords
            .CountAsync(r => r.CompanyId == companyId
                          && r.Feature == feature
                          && r.CreatedAtUtc >= firstOfMonth);
    }
}
