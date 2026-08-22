using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.DeliveryTracking;
using Sumpooj.Application.DeliveryTracking.DTOs;
using Sumpooj.Application.Interfaces;

namespace Sumpooj.API.Controllers;

[Route("api/delivery/location")]
[ApiController]
[Authorize(Policy = "CompanyOnly")]
public sealed class DeliveryLocationCompatibilityController : ControllerBase
{
    private readonly DriverJourneyService _journeyService;
    private readonly IDeliveryRepository _deliveryRepository;
    private readonly ISignalRBroadcastService _signalRBroadcastService;

    public DeliveryLocationCompatibilityController(
        DriverJourneyService journeyService,
        IDeliveryRepository deliveryRepository,
        ISignalRBroadcastService signalRBroadcastService)
    {
        _journeyService = journeyService;
        _deliveryRepository = deliveryRepository;
        _signalRBroadcastService = signalRBroadcastService;
    }

    [HttpPost]
    public async Task<IActionResult> RecordLocation([FromBody] LegacyLocationRequest request)
    {
        try
        {
            var delivery = await _deliveryRepository.GetByIdAsync(request.DeliveryId);
            if (delivery == null)
                return NotFound(new { error = "Delivery not found" });

            var driverId = request.DriverId ?? delivery.DeliveryPersonId;
            if (!driverId.HasValue)
                return BadRequest(new { error = "DriverId is required for location updates" });

            var speedMs = request.Speed
                ?? (request.SpeedKph.HasValue ? request.SpeedKph.Value / 3.6d : (double?)null);

            await _journeyService.UploadLocationAsync(driverId.Value, new UploadLocationRequest
            {
                DeliveryId = request.DeliveryId,
                Latitude = request.Latitude,
                Longitude = request.Longitude,
                Speed = speedMs,
                RecordedAt = request.RecordedAt ?? DateTime.UtcNow
            });

            await _signalRBroadcastService.BroadcastLocationUpdateAsync(
                request.DeliveryId,
                request.Latitude,
                request.Longitude,
                request.SpeedKph ?? request.Speed ?? 0);

            return Ok(new { success = true, deliveryId = request.DeliveryId, timestamp = DateTime.UtcNow });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpPost("batch")]
    public async Task<IActionResult> RecordLocationBatch([FromBody] List<LegacyLocationRequest> requests)
    {
        try
        {
            var items = new List<object>();
            foreach (var request in requests)
            {
                var delivery = await _deliveryRepository.GetByIdAsync(request.DeliveryId);
                if (delivery == null)
                    continue;

                var driverId = request.DriverId ?? delivery.DeliveryPersonId;
                if (!driverId.HasValue)
                    continue;

                var speedMs = request.Speed
                    ?? (request.SpeedKph.HasValue ? request.SpeedKph.Value / 3.6d : (double?)null);

                await _journeyService.UploadLocationAsync(driverId.Value, new UploadLocationRequest
                {
                    DeliveryId = request.DeliveryId,
                    Latitude = request.Latitude,
                    Longitude = request.Longitude,
                    Speed = speedMs,
                    RecordedAt = request.RecordedAt ?? DateTime.UtcNow
                });

                items.Add(new { success = true, deliveryId = request.DeliveryId, timestamp = DateTime.UtcNow });
            }

            return Ok(new { items });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }
}

public sealed class LegacyLocationRequest
{
    public Guid DeliveryId { get; set; }
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public double? SpeedKph { get; set; }
    public double? Speed { get; set; }
    public Guid? RouteId { get; set; }
    public Guid? DriverId { get; set; }
    public DateTime? RecordedAt { get; set; }
}
