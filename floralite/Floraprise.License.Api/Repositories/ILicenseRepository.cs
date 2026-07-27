namespace Floraprise.License.Api.Repositories;

public interface ILicenseRepository
{
    Task<Entities.License?> GetByCustomerIdAsync(
        Guid customerId,
        CancellationToken cancellationToken);

    Task AddAsync(Entities.License license, CancellationToken cancellationToken);
}