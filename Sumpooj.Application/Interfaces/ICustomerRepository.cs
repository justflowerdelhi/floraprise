using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface ICustomerRepository
{
    Task<Customer?> GetByIdAsync(Guid id);
    Task AddAsync(Customer customer);
    Task UpdateAsync(Customer customer);

    Task<(List<Customer> Items, int TotalCount)> SearchAsync(
        string? query,
        int page,
        int pageSize);
}
