using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface ILocationRepository
{
    Task<Location?> GetByIdAsync(Guid id);
    Task<Location?> GetByIdAsync(Guid companyId, Guid id);
    Task AddAsync(Location location);
    Task UpdateAsync(Location location);
    Task<List<Location>> GetAllAsync();
    Task<List<Location>> GetActiveLocationsAsync();
    Task<Location?> GetDefaultLocationAsync();
}
