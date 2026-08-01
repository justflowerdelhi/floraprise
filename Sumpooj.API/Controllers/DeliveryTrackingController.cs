using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.DeliveryTracking;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;

namespace Sumpooj.API.Controllers;

[Route("api/delivery/tracking")]
[ApiController]
[Authorize(Policy = "CompanyOnly")]
public class DeliveryTrackingController : ControllerBase
{
    private readonly IDeliveryLocationService _locationService;
    private readonly IDeliveryTimelineService _timelineService;
    private readonly IDeliveryProofService _proofService;
    private readonly IDeliveryTrackingService _trackingService;
    private readonly ISignalRBroadcastService _signalRBroadcastService;
    private readonly ITenantContext _tenantContext;

    public DeliveryTrackingController(
        IDeliveryLocationService locationService,
        IDeliveryTimelineService timelineService,
        IDeliveryProofService proofService,
        IDeliveryTrackingService trackingService,
        ISignalRBroadcastService signalRBroadcastService,
        ITenantContext tenantContext)
    {
        _locationService = locationService;
        _timelineService = timelineService;
        _proofService = proofService;
        _trackingService = trackingService;
        _signalRBroadcastService = signalRBroadcastService;
        _tenantContext = tenantContext;
    }

    private Guid CompanyId => _tenantContext.CompanyId
        ?? throw new UnauthorizedAccessException("Company context required");

    /// <summary>
    /// Record GPS location update for a delivery
    /// </summary>
    [HttpPost("location")]
    public async Task<IActionResult> RecordLocation([FromBody] RecordLocationRequest request)
    {
        try
        {
            var location = await _locationService.RecordLocationAsync(
                request.DeliveryId,
                request.Latitude,
                request.Longitude,
                request.SpeedKph,
                request.RouteId,
                request.DriverId);

            // Broadcast real-time update
            await _signalRBroadcastService.BroadcastLocationUpdateAsync(
                request.DeliveryId,
                request.Latitude,
                request.Longitude,
                request.SpeedKph);

            return Ok(new { locationId = location.Id, timestamp = location.RecordedAt, deliveryId = request.DeliveryId });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    /// <summary>
    /// Record heartbeat for a delivery (used to keep connection alive)
    /// </summary>
    [HttpPost("heartbeat")]
    public async Task<IActionResult> RecordHeartbeat([FromBody] HeartbeatRequest request)
    {
        try
        {
            await _trackingService.RecordHeartbeatAsync(request.DeliveryId, request.DriverId);

            // Broadcast heartbeat
            await _signalRBroadcastService.BroadcastHeartbeatAsync(request.DeliveryId, request.DriverId);

            return Ok(new { timestamp = DateTime.UtcNow, deliveryId = request.DeliveryId, driverId = request.DriverId });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    /// <summary>
    /// Upload delivery proof (photo, recipient name, note)
    /// </summary>
    [HttpPost("proof")]
    public async Task<IActionResult> UploadProof([FromBody] UploadProofRequest request)
    {
        try
        {
            var proof = await _proofService.UploadProofAsync(
                request.DeliveryId,
                request.PhotoUrl,
                request.RecipientName,
                request.Note,
                request.UserId,
                request.UserName);

            // Broadcast proof update
            await _signalRBroadcastService.BroadcastProofUpdateAsync(
                request.DeliveryId,
                request.PhotoUrl,
                request.RecipientName);

            // Add timeline event
            await _timelineService.AddTimelineEventAsync(
                request.DeliveryId,
                "ProofUploaded",
                request.Note,
                request.UserId,
                request.UserName);

            return Ok(new { proofId = proof.Id, timestamp = proof.RecordedAt, deliveryId = request.DeliveryId });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    /// <summary>
    /// Get tracking information for a specific order
    /// </summary>
    [HttpGet("order/{orderId}")]
    public async Task<IActionResult> GetTrackingByOrder(Guid orderId)
    {
        try
        {
            var tracking = await _trackingService.GetTrackingByOrderIdAsync(orderId);
            return Ok(tracking);
        }
        catch (KeyNotFoundException)
        {
            return NotFound(new { error = "Delivery not found" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    /// <summary>
    /// Get tracking information for a specific delivery by delivery ID
    /// </summary>
    [HttpGet("by-delivery/{deliveryId}")]
    public async Task<IActionResult> GetTrackingByDelivery(Guid deliveryId)
    {
        try
        {
            var tracking = await _trackingService.GetTrackingByDeliveryIdAsync(deliveryId);
            
            return Ok(new
            {
                assignmentId = tracking.AssignmentId,
                deliveryId = tracking.AssignmentId,
                orderId = tracking.OrderId,
                orderNumber = tracking.OrderId.ToString(),
                customerName = tracking.Driver?.Name ?? "Unknown",
                customerPhone = tracking.Driver?.Phone ?? "",
                deliveryAddress = "Delivery Address",
                timeSlot = "Time Slot",
                assignedDriver = tracking.Driver?.Name ?? "Unassigned",
                driverPhone = tracking.Driver?.Phone ?? "",
                eta = tracking.Eta?.ToString("o") ?? null,
                status = tracking.Status,
                timeline = tracking.Timeline.Select(t => new
                {
                    status = t.Status,
                    note = t.Note,
                    timestamp = t.RecordedAt,
                    changedBy = ""
                }),
                route = tracking.Route.Select(l => new
                {
                    latitude = l.Latitude,
                    longitude = l.Longitude,
                    speedKph = l.SpeedKph,
                    timestamp = l.RecordedAt
                }),
                proof = tracking.Proof != null ? new
                {
                    photoUrl = tracking.Proof.PhotoUrl,
                    recipientName = tracking.Proof.RecipientName,
                    note = tracking.Proof.Note,
                    timestamp = tracking.Proof.RecordedAt,
                    signature = ""
                } : null
            });
        }
        catch (KeyNotFoundException)
        {
            return NotFound(new { error = "Delivery not found" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    /// <summary>
    /// Get tracking information for a specific driver
    /// </summary>
    [HttpGet("driver/{driverId}")]
    public async Task<IActionResult> GetTrackingByDriver(Guid driverId)
    {
        try
        {
            var location = await _locationService.GetLatestDriverLocationAsync(driverId);
            return Ok(new
            {
                driverId,
                location = location != null ? new
                {
                    latitude = location.Latitude,
                    longitude = location.Longitude,
                    speedKph = location.SpeedKph,
                    timestamp = location.RecordedAt
                } : null,
                timestamp = DateTime.UtcNow
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    /// <summary>
    /// Get tracking history for a specific delivery
    /// </summary>
    [HttpGet("history/{deliveryId}")]
    public async Task<IActionResult> GetTrackingHistory(Guid deliveryId)
    {
        try
        {
            var locations = await _locationService.GetDeliveryRouteAsync(deliveryId);
            var timeline = await _timelineService.GetDeliveryTimelineAsync(deliveryId);
            var proof = await _proofService.GetDeliveryProofAsync(deliveryId);

            return Ok(new
            {
                deliveryId,
                locations = locations.Select(l => new
                {
                    latitude = l.Latitude,
                    longitude = l.Longitude,
                    speedKph = l.SpeedKph,
                    timestamp = l.RecordedAt
                }),
                timeline = timeline.Select(t => new
                {
                    status = t.Status,
                    note = t.Note,
                    timestamp = t.RecordedAt,
                    changedBy = t.ChangedByUserName
                }),
                proof = proof != null ? new
                {
                    photoUrl = proof.PhotoUrl,
                    recipientName = proof.RecipientName,
                    note = proof.Note,
                    timestamp = proof.RecordedAt,
                    uploadedBy = proof.UploadedByUserName
                } : null
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    /// <summary>
    /// Get active deliveries for the company
    /// </summary>
    [HttpGet("active")]
    public async Task<IActionResult> GetActiveDeliveries()
    {
        try
        {
            var deliveries = await _trackingService.GetActiveDeliveriesAsync();
            return Ok(new { items = deliveries });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    /// <summary>
    /// Get deliveries by status
    /// </summary>
    [HttpGet("status/{status}")]
    public async Task<IActionResult> GetDeliveriesByStatus(string status)
    {
        try
        {
            var deliveries = await _trackingService.GetDeliveriesByStatusAsync(status);
            return Ok(new { items = deliveries });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }
}

// Request DTOs
public class RecordLocationRequest
{
    public Guid DeliveryId { get; set; }
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public double SpeedKph { get; set; }
    public Guid? RouteId { get; set; }
    public Guid? DriverId { get; set; }
}

public class HeartbeatRequest
{
    public Guid DeliveryId { get; set; }
    public Guid? DriverId { get; set; }
}

public class UploadProofRequest
{
    public Guid DeliveryId { get; set; }
    public string PhotoUrl { get; set; } = string.Empty;
    public string? RecipientName { get; set; }
    public string? Note { get; set; }
    public Guid? UserId { get; set; }
    public string? UserName { get; set; }
}
