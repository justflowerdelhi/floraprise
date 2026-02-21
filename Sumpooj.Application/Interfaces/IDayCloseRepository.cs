using Sumpooj.Application.DayClose;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IDayCloseRepository
{
    Task<Domain.Entities.DayClose?> GetByIdAsync(Guid companyId, Guid id);
    Task<Domain.Entities.DayClose?> GetByDateAsync(Guid companyId, Guid locationId, DateTime date);
    Task<bool> IsDayClosedAsync(Guid companyId, Guid locationId, DateTime date);
    Task<List<DayCloseDto>> GetHistoryAsync(Guid companyId, Guid locationId, int days = 30);
    Task AddAsync(Domain.Entities.DayClose dayClose);
    Task UpdateAsync(Domain.Entities.DayClose dayClose);
}
