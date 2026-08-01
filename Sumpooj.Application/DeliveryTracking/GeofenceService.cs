using Sumpooj.Application.DeliveryTracking.DTOs;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.DeliveryTracking;

public class GeofenceService
{
    private readonly IDriverLocationRepository _locationRepository;
    private readonly IDeliveryRepository _deliveryRepository;
    private readonly DeliveryNotificationService _notificationService;

    public GeofenceService(
        IDriverLocationRepository locationRepository,
        IDeliveryRepository deliveryRepository,
        DeliveryNotificationService notificationService)
    {
        _locationRepository = locationRepository;
        _deliveryRepository = deliveryRepository;
        _notificationService = notificationService;
    }

    public async Task CheckGeofenceAfterLocationUpload(Guid deliveryId)
    {
        var delivery = await _deliveryRepository.GetByIdAsync(deliveryId);
        if (delivery == null) return;

        // Only check for active deliveries
        if (delivery.Status != DeliveryStatus.OutForDelivery && 
            delivery.Status != DeliveryStatus.PickedUp)
            return;

        var latestLocation = await _locationRepository.GetLatestLocationAsync(
            delivery.DeliveryPersonId ?? Guid.Empty,
            deliveryId
        );

        if (latestLocation == null) return;

        // Get destination coordinates
        var destLat = delivery.DeliveryAddressLatitude ?? 0;
        var destLng = delivery.DeliveryAddressLongitude ?? 0;

        if (destLat == 0 || destLng == 0) return;

        // Calculate distance to destination
        var distanceMeters = SmartETACalculator.CalculateDistance(
            latestLocation.Latitude,
            latestLocation.Longitude,
            destLat,
            destLng
        ) * 1000; // Convert km to meters

        // Get geofence radius from settings (default 200m for arrived, 150m for "I'm Outside")
        var arrivedRadius = 200.0;
        var outsideRadius = 150.0;

        // Check if driver is within "I'm Outside" radius
        if (distanceMeters <= outsideRadius && delivery.Status == DeliveryStatus.OutForDelivery)
        {
            await TriggerImOutsideNotification(delivery, latestLocation);
        }

        // Check if driver is within arrived radius
        if (distanceMeters <= arrivedRadius && delivery.Status == DeliveryStatus.OutForDelivery)
        {
            await TriggerArrivedNotification(delivery, latestLocation);
        }
    }

    private async Task TriggerImOutsideNotification(Delivery delivery, DriverLocation location)
    {
        // Update status to ArrivedNearby
        delivery.MarkArrivedNearby();
        await _deliveryRepository.UpdateAsync(delivery);

        // Send notification to customer
        await _notificationService.SendNotificationAsync(new NotificationRequest
        {
            DeliveryId = delivery.Id,
            Type = NotificationType.ArrivedNearby,
            CustomerPhone = delivery.CustomerPhone,
            CustomerEmail = delivery.CustomerEmail,
            AdditionalData = new Dictionary<string, object>
            {
                { "message", "Your driver is outside! They will be at your location shortly." },
                { "driverId", delivery.DeliveryPersonId }
            }
        });
    }

    private async Task TriggerArrivedNotification(Delivery delivery, DriverLocation location)
    {
        // This is handled by the "I'm Outside" notification above
        // The status is already updated to ArrivedNearby
    }
}
