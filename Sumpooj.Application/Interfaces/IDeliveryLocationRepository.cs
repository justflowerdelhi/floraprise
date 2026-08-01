using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IDeliveryLocationRepository
{
    Task<DeliveryLocation?> GetByIdAsync(Guid id);
    Task<List<DeliveryLocation>> GetByDeliveryIdAsync(Guid deliveryId);
    Task<List<DeliveryLocation>> GetByRouteIdAsync(Guid routeId);
    Task<List<DeliveryLocation>> GetByDriverIdAsync(Guid driverId, DateTime? fromDate = null);
    Task<DeliveryLocation?> GetLatestLocationAsync(Guid deliveryId);
    Task<DeliveryLocation?> GetLatestDriverLocationAsync(Guid driverId);
    Task AddAsync(DeliveryLocation location);
    Task UpdateAsync(DeliveryLocation location);
    Task DeleteAsync(Guid id);
    Task<List<DeliveryLocation>> GetRecentLocationsAsync(Guid deliveryId, int count = 10);
}
