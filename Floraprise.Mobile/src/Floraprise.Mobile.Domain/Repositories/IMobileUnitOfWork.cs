namespace Floraprise.Mobile.Domain.Repositories;

public interface IMobileUnitOfWork
{
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
