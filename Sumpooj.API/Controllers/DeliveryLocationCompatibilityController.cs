using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.DeliveryTracking;
using Sumpooj.Application.Interfaces;

namespace Sumpooj.API.Controllers;

[Route("api/delivery/location")]
[ApiController]
[Authorize(Policy = "CompanyOnly")]
public sealed class DeliveryLocationCompatibilityController : ControllerBase
{
    private readonly IDeliveryLocationService _locationService;
    private readonly ISignalRBroadcastService _signalRBroadcastService;

    public DeliveryLocationCompatibilityController(
        IDeliveryLocationService locationService,
        ISignalRBroadcastService signalRBroadcastService)
    {
        _locationService = locationService;
        _signalRBroadcastService = signalRBroadcastService;
    }

    [HttpPost]
    public async Task<IActionResult> RecordLocation([FromBody] LegacyLocationRequest request)
    {
        try
        {
            var location = await _locationService.RecordLocationAsync(
                request.DeliveryId,
                request.Latitude,
                request.Longitude,
                request.SpeedKph ?? request.Speed ?? 0,
                request.RouteId,
                request.DriverId);

            await _signalRBroadcastService.BroadcastLocationUpdateAsync(
                request.DeliveryId,
                request.Latitude,
                request.Longitude,
                request.SpeedKph ?? request.Speed ?? 0);

            return Ok(new { locationId = location.Id, timestamp = location.RecordedAt });
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
                var location = await _locationService.RecordLocationAsync(
                    request.DeliveryId,
                    request.Latitude,
                    request.Longitude,
                    request.SpeedKph ?? request.Speed ?? 0,
                    request.RouteId,
                    request.DriverId);

                items.Add(new { locationId = location.Id, timestamp = location.RecordedAt });
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
}
