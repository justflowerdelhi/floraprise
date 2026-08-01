using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.DeliveryTracking;
using Sumpooj.Application.DeliveryTracking.DTOs;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;

namespace Sumpooj.API.Controllers.Mobile;

[Route("api/v1/mobile/delivery")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme, Policy = PolicyNames.CompanyOnly)]
public sealed class MobileDeliveryController : MobileApiControllerBase
{
    private readonly IDeliveryTrackingService _trackingService;
    private readonly IDeliveryRepository _deliveryRepository;
    private readonly DriverJourneyService _journeyService;

    public MobileDeliveryController(
        IDeliveryTrackingService trackingService,
        IDeliveryRepository deliveryRepository,
        DriverJourneyService journeyService,
        ITenantContext tenantContext)
        : base(tenantContext)
    {
        _trackingService = trackingService;
        _deliveryRepository = deliveryRepository;
        _journeyService = journeyService;
    }

    [HttpGet("workspace")]
    public async Task<IActionResult> Workspace([FromQuery] string? status, CancellationToken cancellationToken)
    {
        try
        {
            var normalizedStatus = (status ?? "active").Trim().ToLowerInvariant();

            var items = normalizedStatus switch
            {
                "active" => await GetCombinedWorkspaceAsync(
                    DeliveryStatus.Assigned,
                    DeliveryStatus.Accepted,
                    DeliveryStatus.PickedUp,
                    DeliveryStatus.OutForDelivery,
                    DeliveryStatus.ArrivedNearby),
                "completed" => await GetCombinedWorkspaceAsync(
                    DeliveryStatus.Delivered,
                    DeliveryStatus.SettlementCompleted),
                "cancelled" => await GetCombinedWorkspaceAsync(
                    DeliveryStatus.Cancelled,
                    DeliveryStatus.Failed,
                    DeliveryStatus.Returned),
                _ => await _trackingService.GetDeliveriesByStatusAsync(status ?? string.Empty)
            };

            return Ok(new { items });
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    [HttpGet("workspace/active")]
    public async Task<IActionResult> Active(CancellationToken cancellationToken)
    {
        try
        {
            var items = await GetCombinedWorkspaceAsync(
                DeliveryStatus.Assigned,
                DeliveryStatus.Accepted,
                DeliveryStatus.PickedUp,
                DeliveryStatus.OutForDelivery,
                DeliveryStatus.ArrivedNearby);

            return Ok(new { items });
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    [HttpGet("orders/{orderId}/tracking")]
    public async Task<IActionResult> TrackingByOrder(string orderId, CancellationToken cancellationToken)
    {
        try
        {
            if (!Guid.TryParse(orderId, out var parsedOrderId))
                throw new ArgumentException("Order tracking requires a valid order identifier.", nameof(orderId));

            var snapshot = await _trackingService.GetTrackingByOrderIdAsync(parsedOrderId);
            return Ok(new
            {
                assignmentId = snapshot.AssignmentId,
                orderId = snapshot.OrderId,
                trackingId = snapshot.TrackingId,
                trackingLink = snapshot.TrackingLink,
                status = snapshot.Status,
                eta = snapshot.Eta,
                driver = snapshot.Driver,
                route = snapshot.Route,
                timeline = snapshot.Timeline,
                proof = snapshot.Proof,
                lastLocation = snapshot.LastLocation
            });
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    [HttpGet("assignments/{assignmentId}/tracking")]
    public async Task<IActionResult> TrackingByAssignment(string assignmentId, CancellationToken cancellationToken)
    {
        try
        {
            if (!Guid.TryParse(assignmentId, out var parsedAssignmentId))
                throw new ArgumentException("Assignment tracking requires a valid assignment identifier.", nameof(assignmentId));

            var snapshot = await _trackingService.GetTrackingByDeliveryIdAsync(parsedAssignmentId);
            return Ok(new
            {
                assignmentId = snapshot.AssignmentId,
                orderId = snapshot.OrderId,
                trackingId = snapshot.TrackingId,
                trackingLink = snapshot.TrackingLink,
                status = snapshot.Status,
                eta = snapshot.Eta,
                driver = snapshot.Driver,
                route = snapshot.Route,
                timeline = snapshot.Timeline,
                proof = snapshot.Proof,
                lastLocation = snapshot.LastLocation
            });
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    [HttpPost("assignments/{assignmentId}/status")]
    public async Task<IActionResult> UpdateAssignmentStatus(
        string assignmentId,
        [FromBody] MobileDeliveryStatusUpdateRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var delivery = await LoadCompanyDeliveryAsync(assignmentId);
            var action = (request.Action ?? string.Empty).Trim().ToLowerInvariant();
            var driverId = delivery.DeliveryPersonId ?? GetMobileUserId();

            switch (action)
            {
                case "accept":
                    delivery.MarkAccepted(driverId);
                    break;
                case "reject":
                    delivery.Cancel();
                    break;
                case "start":
                    if (delivery.Status == DeliveryStatus.Assigned)
                        delivery.MarkAccepted(driverId);
                    if (delivery.Status == DeliveryStatus.Accepted)
                        delivery.MarkPickedUp();
                    if (delivery.Status == DeliveryStatus.PickedUp)
                        delivery.MarkOutForDelivery();
                    if (delivery.Status != DeliveryStatus.OutForDelivery)
                        throw new InvalidOperationException("Delivery cannot be started from the current status.");
                    break;
                case "complete":
                    if (delivery.Status == DeliveryStatus.OutForDelivery)
                        delivery.MarkArrivedNearby();
                    delivery.MarkDelivered();
                    break;
                case "cancel":
                    delivery.Cancel();
                    break;
                default:
                    throw new ArgumentException("Action must be accept, reject, start, complete, or cancel.", nameof(request.Action));
            }

            await _deliveryRepository.UpdateAsync(delivery);
            return Ok(new { success = true, status = delivery.Status.ToString() });
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    [HttpPost("assignments/{assignmentId}/location")]
    public async Task<IActionResult> UploadAssignmentLocation(
        string assignmentId,
        [FromBody] MobileDeliveryLocationRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var delivery = await LoadCompanyDeliveryAsync(assignmentId);
            if (delivery.Status != DeliveryStatus.OutForDelivery &&
                delivery.Status != DeliveryStatus.ArrivedNearby)
            {
                throw new InvalidOperationException("GPS tracking starts only after delivery has started.");
            }

            var driverId = delivery.DeliveryPersonId ?? GetMobileUserId();
            await _journeyService.UploadLocationAsync(driverId, new UploadLocationRequest
            {
                DeliveryId = delivery.Id,
                Latitude = request.Latitude,
                Longitude = request.Longitude,
                Accuracy = request.Accuracy,
                Speed = request.Speed,
                Heading = request.Heading,
                RecordedAt = request.RecordedAt ?? DateTime.UtcNow
            });

            return Ok(new { success = true });
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    private async Task<Delivery> LoadCompanyDeliveryAsync(string assignmentId)
    {
        if (!Guid.TryParse(assignmentId, out var parsedAssignmentId))
            throw new ArgumentException("Assignment requires a valid delivery identifier.", nameof(assignmentId));

        var delivery = await _deliveryRepository.GetByIdAsync(parsedAssignmentId)
            ?? throw new KeyNotFoundException("Delivery not found.");
        if (delivery.CompanyId != GetCompanyId())
            throw new KeyNotFoundException("Delivery not found.");

        return delivery;
    }

    private async Task<List<DeliveryWorkspaceRecord>> GetCombinedWorkspaceAsync(params DeliveryStatus[] statuses)
    {
        var items = new List<DeliveryWorkspaceRecord>();
        foreach (var status in statuses)
        {
            var slice = await _trackingService.GetDeliveriesByStatusAsync(status.ToString());
            items.AddRange(slice);
        }

        return items
            .OrderByDescending(x => x.UpdatedAt)
            .ToList();
    }
}

public sealed class MobileDeliveryStatusUpdateRequest
{
    public string Action { get; set; } = string.Empty;
    public string? Notes { get; set; }
}

public sealed class MobileDeliveryLocationRequest
{
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public double? Accuracy { get; set; }
    public double? Speed { get; set; }
    public double? Heading { get; set; }
    public DateTime? RecordedAt { get; set; }
}