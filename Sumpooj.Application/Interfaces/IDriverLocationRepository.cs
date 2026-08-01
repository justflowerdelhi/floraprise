using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IDriverLocationRepository
{
    Task<DriverLocation?> GetLatestLocationAsync(Guid driverId, Guid deliveryId);
    Task<DriverLocation?> GetLatestLocationByDriverAsync(Guid driverId);
    Task<IEnumerable<DriverLocation>> GetLocationsByDeliveryAsync(Guid deliveryId, int limit = 100);
    Task<IEnumerable<DriverLocation>> GetLocationsByDriverAsync(Guid driverId, DateTime since);
    Task AddLocationAsync(DriverLocation location);
    Task AddRangeAsync(IEnumerable<DriverLocation> locations);
    Task CleanupOldLocationsAsync(int retentionDays);
}
