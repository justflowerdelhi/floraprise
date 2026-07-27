using Floraprise.License.Api.Data;
using Floraprise.License.Api.Entities;
using Microsoft.EntityFrameworkCore;

namespace Floraprise.License.Api.Repositories;

public sealed class CustomerRepository : ICustomerRepository
{
    private readonly LicenseDbContext _dbContext;

    public CustomerRepository(LicenseDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public Task<Customer?> GetByIdAsync(Guid id, CancellationToken cancellationToken)
    {
        return _dbContext.Customers
            .Include(customer => customer.License)
            .FirstOrDefaultAsync(customer => customer.Id == id, cancellationToken);
    }

    public Task<Customer?> GetByMobileAsync(string mobile, CancellationToken cancellationToken)
    {
        return _dbContext.Customers
            .Include(customer => customer.License)
            .FirstOrDefaultAsync(customer => customer.Mobile == mobile, cancellationToken);
    }

    public async Task AddAsync(Customer customer, CancellationToken cancellationToken)
    {
        await _dbContext.Customers.AddAsync(customer, cancellationToken);
    }
}