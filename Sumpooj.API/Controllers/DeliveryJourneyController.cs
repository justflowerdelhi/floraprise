using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Sumpooj.Application.DeliveryTracking.DTOs;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.API.Hubs;
using System.Security.Claims;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/delivery/journey")]
[Authorize]
public class DeliveryJourneyController : ControllerBase
{
    private readonly IDeliveryRepository _deliveryRepository;
    private readonly IHubContext<DeliveryTrackingHub> _hubContext;

    public DeliveryJourneyController(
        IDeliveryRepository deliveryRepository,
        IHubContext<DeliveryTrackingHub> hubContext)
    {
        _deliveryRepository = deliveryRepository;
        _hubContext = hubContext;
    }

    /// <summary>
    /// Driver accepts delivery assignment
    /// </summary>
    [HttpPost("accept")]
    public async Task<IActionResult> AcceptDelivery([FromBody] StartDeliveryRequest request)
    {
        var driverId = GetCurrentDriverId();
        if (driverId == null)
            return Unauthorized("Driver not authenticated");

        var delivery = await _deliveryRepository.GetByIdAsync(request.DeliveryId);
        if (delivery == null)
            return NotFound("Delivery not found");

        if (delivery.Status != DeliveryStatus.Assigned)
            return BadRequest("Delivery is not in assigned state");

        if (delivery.DeliveryPersonId != driverId)
            return Forbid("Driver not assigned to this delivery");

        delivery.MarkAccepted(driverId.Value);
        await _deliveryRepository.UpdateAsync(delivery);

        // Notify via SignalR
        await DeliveryTrackingHub.BroadcastStatusChange(_hubContext, delivery.Id, "Accepted", new { DriverId = driverId });

        return Ok(new { Status = "Accepted" });
    }

    /// <summary>
    /// Start delivery journey (GPS tracking begins)
    /// </summary>
    [HttpPost("start")]
    public async Task<IActionResult> StartJourney([FromBody] StartDeliveryRequest request)
    {
        var driverId = GetCurrentDriverId();
        if (driverId == null)
            return Unauthorized("Driver not authenticated");

        var delivery = await _deliveryRepository.GetByIdAsync(request.DeliveryId);
        if (delivery == null)
            return NotFound("Delivery not found");

        if (delivery.Status != DeliveryStatus.Accepted && delivery.Status != DeliveryStatus.PickedUp)
            return BadRequest("Delivery must be accepted first");

        if (delivery.DeliveryPersonId != driverId)
            return Forbid("Driver not assigned to this delivery");

        delivery.MarkPickedUp();
        await _deliveryRepository.UpdateAsync(delivery);

        // Notify via SignalR
        await DeliveryTrackingHub.BroadcastStatusChange(_hubContext, delivery.Id, "PickedUp", new { DriverId = driverId, Timestamp = DateTime.UtcNow });

        return Ok(new { Status = "PickedUp" });
    }

    /// <summary>
    /// Mark as out for delivery (en route)
    /// </summary>
    [HttpPost("enroute")]
    public async Task<IActionResult> MarkEnRoute([FromBody] StartDeliveryRequest request)
    {
        var driverId = GetCurrentDriverId();
        if (driverId == null)
            return Unauthorized("Driver not authenticated");

        var delivery = await _deliveryRepository.GetByIdAsync(request.DeliveryId);
        if (delivery == null)
            return NotFound("Delivery not found");

        if (delivery.Status != DeliveryStatus.PickedUp)
            return BadRequest("Delivery must be picked up first");

        if (delivery.DeliveryPersonId != driverId)
            return Forbid("Driver not assigned to this delivery");

        delivery.MarkOutForDelivery();
        await _deliveryRepository.UpdateAsync(delivery);

        // Notify via SignalR
        await DeliveryTrackingHub.BroadcastStatusChange(_hubContext, delivery.Id, "OutForDelivery", new { DriverId = driverId, Timestamp = DateTime.UtcNow });

        return Ok(new { Status = "OutForDelivery" });
    }

    /// <summary>
    /// Mark as arrived nearby (within geofence)
    /// </summary>
    [HttpPost("arrived")]
    public async Task<IActionResult> MarkArrived([FromBody] StartDeliveryRequest request)
    {
        var driverId = GetCurrentDriverId();
        if (driverId == null)
            return Unauthorized("Driver not authenticated");

        var delivery = await _deliveryRepository.GetByIdAsync(request.DeliveryId);
        if (delivery == null)
            return NotFound("Delivery not found");

        if (delivery.Status != DeliveryStatus.OutForDelivery)
            return BadRequest("Delivery must be out for delivery first");

        if (delivery.DeliveryPersonId != driverId)
            return Forbid("Driver not assigned to this delivery");

        delivery.MarkArrivedNearby();
        await _deliveryRepository.UpdateAsync(delivery);

        // Notify via SignalR
        await DeliveryTrackingHub.BroadcastStatusChange(_hubContext, delivery.Id, "ArrivedNearby", new { DriverId = driverId, Timestamp = DateTime.UtcNow });

        return Ok(new { Status = "ArrivedNearby" });
    }

    /// <summary>
    /// Complete delivery with proof
    /// </summary>
    [HttpPost("complete")]
    public async Task<IActionResult> CompleteDelivery([FromBody] CompleteDeliveryRequest request)
    {
        var driverId = GetCurrentDriverId();
        if (driverId == null)
            return Unauthorized("Driver not authenticated");

        var delivery = await _deliveryRepository.GetByIdAsync(request.DeliveryId);
        if (delivery == null)
            return NotFound("Delivery not found");

        if (delivery.Status != DeliveryStatus.ArrivedNearby && delivery.Status != DeliveryStatus.OutForDelivery)
            return BadRequest("Delivery must be out for delivery first");

        if (delivery.DeliveryPersonId != driverId)
            return Forbid("Driver not assigned to this delivery");

        // TODO: Validate OTP if required
        // TODO: Store proof (photo, signature, notes, GPS coordinates)

        delivery.MarkDelivered();
        await _deliveryRepository.UpdateAsync(delivery);

        // Notify via SignalR
        await DeliveryTrackingHub.BroadcastStatusChange(_hubContext, delivery.Id, "Delivered", new
        {
            DriverId = driverId,
            Timestamp = DateTime.UtcNow,
            Proof = new
            {
                PhotoUrl = request.PhotoUrl,
                Notes = request.Notes,
                CompletionLatitude = request.CompletionLatitude,
                CompletionLongitude = request.CompletionLongitude
            }
        });

        return Ok(new { Status = "Delivered" });
    }

    /// <summary>
    /// Mark delivery as failed
    /// </summary>
    [HttpPost("failed")]
    public async Task<IActionResult> MarkFailed([FromBody] StartDeliveryRequest request)
    {
        var driverId = GetCurrentDriverId();
        if (driverId == null)
            return Unauthorized("Driver not authenticated");

        var delivery = await _deliveryRepository.GetByIdAsync(request.DeliveryId);
        if (delivery == null)
            return NotFound("Delivery not found");

        if (delivery.Status != DeliveryStatus.OutForDelivery && delivery.Status != DeliveryStatus.ArrivedNearby)
            return BadRequest("Delivery must be out for delivery first");

        if (delivery.DeliveryPersonId != driverId)
            return Forbid("Driver not assigned to this delivery");

        delivery.MarkFailed();
        await _deliveryRepository.UpdateAsync(delivery);

        // Notify via SignalR
        await DeliveryTrackingHub.BroadcastStatusChange(_hubContext, delivery.Id, "Failed", new { DriverId = driverId, Timestamp = DateTime.UtcNow });

        return Ok(new { Status = "Failed" });
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
