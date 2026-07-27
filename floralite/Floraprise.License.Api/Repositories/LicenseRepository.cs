using Floraprise.License.Api.Data;
using Microsoft.EntityFrameworkCore;

namespace Floraprise.License.Api.Repositories;

public sealed class LicenseRepository : ILicenseRepository
{
    private readonly LicenseDbContext _dbContext;

    public LicenseRepository(LicenseDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public Task<Entities.License?> GetByCustomerIdAsync(
        Guid customerId,
        CancellationToken cancellationToken)
    {
        return _dbContext.Licenses.FirstOrDefaultAsync(
            license => license.CustomerId == customerId,
            cancellationToken);
    }

    public async Task AddAsync(Entities.License license, CancellationToken cancellationToken)
    {
        await _dbContext.Licenses.AddAsync(license, cancellationToken);
    }
}