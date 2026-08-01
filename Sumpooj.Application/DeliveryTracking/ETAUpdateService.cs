using Sumpooj.Application.DeliveryTracking.DTOs;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.DeliveryTracking;

public class ETAUpdateService
{
    private readonly SmartETACalculator _etaCalculator;
    private readonly IDriverLocationRepository _locationRepository;
    private readonly IDeliveryRepository _deliveryRepository;

    public ETAUpdateService(
        SmartETACalculator etaCalculator,
        IDriverLocationRepository locationRepository,
        IDeliveryRepository deliveryRepository)
    {
        _etaCalculator = etaCalculator;
        _locationRepository = locationRepository;
        _deliveryRepository = deliveryRepository;
    }

    public async Task UpdateETAAfterLocationUpload(Guid deliveryId)
    {
        var delivery = await _deliveryRepository.GetByIdAsync(deliveryId);
        if (delivery == null) return;

        var latestLocation = await _locationRepository.GetLatestLocationAsync(
            delivery.DeliveryPersonId ?? Guid.Empty,
            deliveryId
        );

        if (latestLocation == null) return;

        // Calculate remaining distance to destination
        var destinationLat = delivery.DeliveryAddressLatitude ?? 0;
        var destinationLng = delivery.DeliveryAddressLongitude ?? 0;

        if (destinationLat == 0 || destinationLng == 0) return;

        var distanceKm = SmartETACalculator.CalculateDistance(
            latestLocation.Latitude,
            latestLocation.Longitude,
            destinationLat,
            destinationLng
        );

        // Calculate ETA based on current speed
        var currentSpeed = latestLocation.Speed ?? 0; // m/s
        var averageSpeedKmh = currentSpeed > 0 ? currentSpeed * 3.6 : 20; // Default to 20 km/h if stationary

        var timeToDestinationHours = distanceKm / averageSpeedKmh;
        var etaMinutes = timeToDestinationHours * 60;

        // Apply traffic factor (could be dynamic based on time of day)
        var trafficFactor = 1.2; // 20% buffer for traffic
        etaMinutes *= trafficFactor;

        var estimatedArrival = DateTime.UtcNow.AddMinutes(etaMinutes);

        // Update delivery with new ETA
        // This would be stored in the delivery entity or a separate tracking table
        // For now, we'll return the calculated values
    }

    public async Task<DeliveryLiveTrackingResponse> GetLiveTrackingWithETA(Guid deliveryId)
    {
        var delivery = await _deliveryRepository.GetByIdAsync(deliveryId);
        if (delivery == null) return null;

        var latestLocation = await _locationRepository.GetLatestLocationAsync(
            delivery.DeliveryPersonId ?? Guid.Empty,
            deliveryId
        );

        var response = new DeliveryLiveTrackingResponse
        {
            DeliveryId = delivery.Id,
            OrderNumber = delivery.SalesOrderId.ToString(),
            Status = delivery.Status.ToString(),
            CurrentLocation = MapToDto(latestLocation),
            LastUpdated = latestLocation?.RecordedAt ?? DateTime.UtcNow
        };

        // Calculate ETA if location is available
        if (latestLocation != null && delivery.DeliveryAddressLatitude.HasValue)
        {
            var distanceKm = SmartETACalculator.CalculateDistance(
                latestLocation.Latitude,
                latestLocation.Longitude,
                delivery.DeliveryAddressLatitude.Value,
                delivery.DeliveryAddressLongitude.Value
            );

            var currentSpeed = latestLocation.Speed ?? 0;
            var averageSpeedKmh = currentSpeed > 0 ? currentSpeed * 3.6 : 20;
            var timeToDestinationHours = distanceKm / averageSpeedKmh;
            var etaMinutes = timeToDestinationHours * 60 * 1.2; // Traffic factor

            response.EstimatedArrival = DateTime.UtcNow.AddMinutes(etaMinutes);
            response.RemainingDistanceKm = distanceKm;
        }

        return response;
    }

    private static DriverLocationDto? MapToDto(DriverLocation? location)
    {
        if (location == null) return null;

        return new DriverLocationDto
        {
            Id = location.Id,
            DriverId = location.DriverId,
            DeliveryId = location.DeliveryId,
            Latitude = location.Latitude,
            Longitude = location.Longitude,
            Accuracy = location.Accuracy,
            Speed = location.Speed,
            Heading = location.Heading,
            Altitude = location.Altitude,
            BatteryLevel = location.BatteryLevel,
            RecordedAt = location.RecordedAt
        };
    }
}
