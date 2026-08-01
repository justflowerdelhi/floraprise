using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Sumpooj.Application.DeliveryTracking;
using Sumpooj.Application.DeliveryTracking.DTOs;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.API.Hubs;
using System.Security.Claims;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/delivery")]
[Authorize]
public class DriverLocationController : ControllerBase
{
    private readonly DriverJourneyService _journeyService;
    private readonly IDeliveryRepository _deliveryRepository;
    private readonly ETAUpdateService _etaUpdateService;
    private readonly GeofenceService _geofenceService;
    private readonly IHubContext<DeliveryTrackingHub> _hubContext;

    public DriverLocationController(
        DriverJourneyService journeyService,
        IDeliveryRepository deliveryRepository,
        ETAUpdateService etaUpdateService,
        GeofenceService geofenceService,
        IHubContext<DeliveryTrackingHub> hubContext)
    {
        _journeyService = journeyService;
        _deliveryRepository = deliveryRepository;
        _etaUpdateService = etaUpdateService;
        _geofenceService = geofenceService;
        _hubContext = hubContext;
    }

    /// <summary>
    /// Upload driver GPS location
    /// </summary>
    [HttpPost("location")]
    public async Task<IActionResult> UploadLocation([FromBody] UploadLocationRequest request)
    {
        var driverId = GetCurrentDriverId();
        if (driverId == null)
            return Unauthorized("Driver not authenticated");

        // Validate coordinates
        if (request.Latitude < -90 || request.Latitude > 90)
            return BadRequest("Invalid latitude");
        if (request.Longitude < -180 || request.Longitude > 180)
            return BadRequest("Invalid longitude");

        // Validate that driver is assigned to this delivery
        var delivery = await _deliveryRepository.GetByIdAsync(request.DeliveryId);
        if (delivery == null)
            return NotFound("Delivery not found");

        if (delivery.DeliveryPersonId != driverId)
            return Forbid("Driver not assigned to this delivery");

        // Validate delivery is in active state
        if (delivery.Status != DeliveryStatus.OutForDelivery && 
            delivery.Status != DeliveryStatus.PickedUp &&
            delivery.Status != DeliveryStatus.Accepted)
            return BadRequest("Delivery is not in active state");

        await _journeyService.UploadLocationAsync(driverId.Value, request);
        
        // Update ETA after location upload
        await _etaUpdateService.UpdateETAAfterLocationUpload(request.DeliveryId);
        
        // Check geofence for "I'm Outside" notification
        await _geofenceService.CheckGeofenceAfterLocationUpload(request.DeliveryId);
        
        // Broadcast location update via SignalR
        await DeliveryTrackingHub.BroadcastLocationUpdate(_hubContext, request.DeliveryId, new
        {
            latitude = request.Latitude,
            longitude = request.Longitude,
            accuracy = request.Accuracy,
            speed = request.Speed,
            heading = request.Heading,
            timestamp = DateTime.UtcNow
        });
        
        return Ok();
    }

    /// <summary>
    /// Upload multiple GPS locations (batch for offline sync)
    /// </summary>
    [HttpPost("location/batch")]
    public async Task<IActionResult> UploadLocationsBatch([FromBody] List<UploadLocationRequest> requests)
    {
        var driverId = GetCurrentDriverId();
        if (driverId == null)
            return Unauthorized("Driver not authenticated");

        if (requests == null || !requests.Any())
            return BadRequest("No locations provided");

        // Validate all deliveries belong to this driver
        foreach (var request in requests)
        {
            var delivery = await _deliveryRepository.GetByIdAsync(request.DeliveryId);
            if (delivery == null || delivery.DeliveryPersonId != driverId)
                return BadRequest($"Invalid delivery: {request.DeliveryId}");
        }

        await _journeyService.UploadLocationsBatchAsync(driverId.Value, requests);
        return Ok();
    }

    /// <summary>
    /// Get latest location for a delivery
    /// </summary>
    [HttpGet("{deliveryId}/live")]
    [AllowAnonymous]
    public async Task<IActionResult> GetLiveTracking(Guid deliveryId)
    {
        var delivery = await _deliveryRepository.GetByIdAsync(deliveryId);
        if (delivery == null)
            return NotFound("Delivery not found");

        var location = await _journeyService.GetLatestLocationAsync(
            delivery.DeliveryPersonId ?? Guid.Empty, 
            deliveryId);

        var response = new DeliveryLiveTrackingResponse
        {
            DeliveryId = delivery.Id,
            OrderNumber = delivery.SalesOrderId.ToString(),
            Status = delivery.Status.ToString(),
            CurrentLocation = location,
            LastUpdated = location?.RecordedAt ?? DateTime.UtcNow
        };

        return Ok(response);
    }

    /// <summary>
    /// Get latest location for a driver
    /// </summary>
    [HttpGet("driver/{driverId}/location")]
    [Authorize(Roles = "Admin,Manager")]
    public async Task<IActionResult> GetDriverLocation(Guid driverId)
    {
        var location = await _journeyService.GetLatestDriverLocationAsync(driverId);
        return Ok(location);
    }

    private Guid? GetCurrentDriverId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (Guid.TryParse(userIdClaim, out var userId))
        {
            return userId;
        }
        return null;
    }
}
