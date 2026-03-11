using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IDemoRequestRepository
{
    Task AddAsync(DemoRequest request);
    Task<List<DemoRequest>> GetAllAsync();
    Task<DemoRequest?> GetByIdAsync(Guid id);
    Task UpdateAsync(DemoRequest request);
}
