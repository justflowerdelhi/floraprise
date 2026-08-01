using Sumpooj.Application.DeliveryTracking.DTOs;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.DeliveryTracking;

public class DriverJourneyService
{
    private readonly IDriverLocationRepository _locationRepository;
    private readonly SmartETACalculator _etaCalculator;

    public DriverJourneyService(
        IDriverLocationRepository locationRepository,
        SmartETACalculator etaCalculator)
    {
        _locationRepository = locationRepository;
        _etaCalculator = etaCalculator;
    }

    public async Task UploadLocationAsync(Guid driverId, UploadLocationRequest request)
    {
        // Validate coordinates
        if (request.Latitude < -90 || request.Latitude > 90)
            throw new ArgumentException("Invalid latitude", nameof(request.Latitude));
        if (request.Longitude < -180 || request.Longitude > 180)
            throw new ArgumentException("Invalid longitude", nameof(request.Longitude));

        var location = new DriverLocation(
            driverId,
            request.DeliveryId,
            request.Latitude,
            request.Longitude,
            request.Accuracy,
            request.Speed,
            request.Heading,
            request.Altitude,
            request.BatteryLevel
        );

        await _locationRepository.AddLocationAsync(location);
    }

    public async Task UploadLocationsBatchAsync(Guid driverId, List<UploadLocationRequest> requests)
    {
        var locations = requests.Select(r => new DriverLocation(
            driverId,
            r.DeliveryId,
            r.Latitude,
            r.Longitude,
            r.Accuracy,
            r.Speed,
            r.Heading,
            r.Altitude,
            r.BatteryLevel
        )).ToList();

        await _locationRepository.AddRangeAsync(locations);
    }

    public async Task<DriverLocationDto?> GetLatestLocationAsync(Guid driverId, Guid deliveryId)
    {
        var location = await _locationRepository.GetLatestLocationAsync(driverId, deliveryId);
        return MapToDto(location);
    }

    public async Task<DriverLocationDto?> GetLatestDriverLocationAsync(Guid driverId)
    {
        var location = await _locationRepository.GetLatestLocationByDriverAsync(driverId);
        return MapToDto(location);
    }

    public async Task CleanupOldLocationsAsync(int retentionDays)
    {
        await _locationRepository.CleanupOldLocationsAsync(retentionDays);
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
