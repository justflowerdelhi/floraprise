using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface ISupplierRepository
{
    Task<Supplier?> GetByIdAsync(Guid id);
    Task AddAsync(Supplier supplier);
    Task UpdateAsync(Supplier supplier);

    Task<(List<Supplier> Items, int TotalCount)> SearchAsync(
        string? query,
        bool? isActive,
        int page,
        int pageSize);

    Task<List<Supplier>> GetAllActiveAsync();
}
