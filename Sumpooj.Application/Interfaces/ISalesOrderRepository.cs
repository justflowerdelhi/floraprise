using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface ISalesOrderRepository
{
    Task<SalesOrder?> GetByIdAsync(Guid id);
    Task<IReadOnlyList<SalesOrder>> GetAllAsync();
    Task AddAsync(SalesOrder order);
    Task UpdateAsync(SalesOrder order);
}
