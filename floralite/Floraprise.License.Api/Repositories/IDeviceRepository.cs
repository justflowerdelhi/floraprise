using Floraprise.License.Api.Entities;

namespace Floraprise.License.Api.Repositories;

public interface IDeviceRepository
{
    Task<Device?> GetAsync(Guid customerId, string deviceId, CancellationToken cancellationToken);
    Task AddAsync(Device device, CancellationToken cancellationToken);
}