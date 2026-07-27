using Floraprise.License.Api.Entities;

namespace Floraprise.License.Api.Repositories;

public interface ICustomerRepository
{
    Task<Customer?> GetByIdAsync(Guid id, CancellationToken cancellationToken);
    Task<Customer?> GetByMobileAsync(string mobile, CancellationToken cancellationToken);
    Task AddAsync(Customer customer, CancellationToken cancellationToken);
}