using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IDeliveryLocationService
{
    Task<DeliveryLocation> RecordLocationAsync(Guid deliveryId, double latitude, double longitude, double speedKph, Guid? routeId = null, Guid? driverId = null);
    Task<DeliveryLocation?> GetLatestLocationAsync(Guid deliveryId);
    Task<DeliveryLocation?> GetLatestDriverLocationAsync(Guid driverId);
    Task<List<DeliveryLocation>> GetDeliveryRouteAsync(Guid deliveryId);
    Task<List<DeliveryLocation>> GetDriverHistoryAsync(Guid driverId, DateTime? fromDate = null);
}
