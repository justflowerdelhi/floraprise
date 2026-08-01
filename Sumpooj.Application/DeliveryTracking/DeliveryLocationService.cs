using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.DeliveryTracking;

public class DeliveryLocationService : IDeliveryLocationService
{
    private readonly IDeliveryLocationRepository _locationRepo;

    public DeliveryLocationService(IDeliveryLocationRepository locationRepo)
    {
        _locationRepo = locationRepo;
    }

    public async Task<DeliveryLocation> RecordLocationAsync(Guid deliveryId, double latitude, double longitude, double speedKph, Guid? routeId = null, Guid? driverId = null)
    {
        var location = new DeliveryLocation(deliveryId, latitude, longitude, speedKph);
        
        if (routeId.HasValue || driverId.HasValue)
        {
            location.SetRouteContext(routeId, driverId);
        }

        await _locationRepo.AddAsync(location);
        return location;
    }

    public async Task<DeliveryLocation?> GetLatestLocationAsync(Guid deliveryId)
    {
        return await _locationRepo.GetLatestLocationAsync(deliveryId);
    }

    public async Task<DeliveryLocation?> GetLatestDriverLocationAsync(Guid driverId)
    {
        return await _locationRepo.GetLatestDriverLocationAsync(driverId);
    }

    public async Task<List<DeliveryLocation>> GetDeliveryRouteAsync(Guid deliveryId)
    {
        return await _locationRepo.GetByDeliveryIdAsync(deliveryId);
    }

    public async Task<List<DeliveryLocation>> GetDriverHistoryAsync(Guid driverId, DateTime? fromDate = null)
    {
        return await _locationRepo.GetByDriverIdAsync(driverId, fromDate);
    }
}
