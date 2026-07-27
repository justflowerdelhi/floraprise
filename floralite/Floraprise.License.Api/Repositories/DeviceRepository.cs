using Floraprise.License.Api.Data;
using Floraprise.License.Api.Entities;
using Microsoft.EntityFrameworkCore;

namespace Floraprise.License.Api.Repositories;

public sealed class DeviceRepository : IDeviceRepository
{
    private readonly LicenseDbContext _dbContext;

    public DeviceRepository(LicenseDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public Task<Device?> GetAsync(
        Guid customerId,
        string deviceId,
        CancellationToken cancellationToken)
    {
        return _dbContext.Devices.FirstOrDefaultAsync(
            device => device.CustomerId == customerId && device.DeviceId == deviceId,
            cancellationToken);
    }

    public async Task AddAsync(Device device, CancellationToken cancellationToken)
    {
        await _dbContext.Devices.AddAsync(device, cancellationToken);
    }
}