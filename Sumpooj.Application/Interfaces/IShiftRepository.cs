using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IShiftRepository
{
    Task<Shift?> GetByIdAsync(Guid companyId, Guid id);
    Task<Shift?> GetActiveShiftAsync(Guid companyId, Guid locationId);
    Task<List<Shift>> GetHistoryAsync(Guid companyId, Guid locationId, int count = 20);
    Task AddAsync(Shift shift);
    Task UpdateAsync(Shift shift);
}
