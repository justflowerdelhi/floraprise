using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.DeliveryTracking;
using Sumpooj.Application.DeliveryTracking.DTOs;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.API.Controllers.Mobile;

[Route("api/v1/mobile/delivery")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme, Policy = PolicyNames.CompanyOnly)]
public sealed class MobileDeliveryController : MobileApiControllerBase
{
    private readonly IDeliveryTrackingService _trackingService;
    private readonly IDeliveryRepository _deliveryRepository;
    private readonly DriverJourneyService _journeyService;
    private readonly SumpoojDbContext _db;

    public MobileDeliveryController(
        IDeliveryTrackingService trackingService,
        IDeliveryRepository deliveryRepository,
        DriverJourneyService journeyService,
        SumpoojDbContext db,
        ITenantContext tenantContext)
        : base(tenantContext)
    {
        _trackingService = trackingService;
        _deliveryRepository = deliveryRepository;
        _journeyService = journeyService;
        _db = db;
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

    [HttpPost("sync-assignment")]
    public async Task<IActionResult> SyncAssignment(
        [FromBody] MobileDeliveryAssignmentSyncRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var companyId = GetCompanyId();
            var orderNumber = request.OrderNumber?.Trim();
            if (string.IsNullOrWhiteSpace(orderNumber))
                throw new ArgumentException("Order number is required.", nameof(request.OrderNumber));

            var order = await _db.Orders
                .FirstOrDefaultAsync(x => x.CompanyId == companyId && x.OrderNumber == orderNumber, cancellationToken);

            if (order == null)
            {
                var customerName = string.IsNullOrWhiteSpace(request.CustomerName)
                    ? string.IsNullOrWhiteSpace(request.RecipientName) ? "POS Customer" : request.RecipientName.Trim()
                    : request.CustomerName.Trim();
                var customerPhone = string.IsNullOrWhiteSpace(request.CustomerPhone)
                    ? request.RecipientPhone?.Trim()
                    : request.CustomerPhone.Trim();

                var customer = await _db.Customers
                    .FirstOrDefaultAsync(x => x.CompanyId == companyId && x.Phone == customerPhone, cancellationToken);
                if (customer == null)
                {
                    customer = new Customer(companyId, customerName, null, customerPhone);
                    _db.Customers.Add(customer);
                    await _db.SaveChangesAsync(cancellationToken);
                }

                order = new Order(
                    companyId,
                    customer.Id,
                    request.DeliveryDate ?? DateTime.UtcNow,
                    string.IsNullOrWhiteSpace(request.DeliveryAddress) ? "Address not specified" : request.DeliveryAddress.Trim(),
                    request.DeliveryPincode,
                    request.RecipientName,
                    request.RecipientPhone);
                order.SetImportedOrderNumber(orderNumber);
                if (!string.IsNullOrWhiteSpace(request.DeliverySlot))
                    order.SetTimeSlot(request.DeliverySlot.Trim());
                _db.Orders.Add(order);
                try
                {
                    await _db.SaveChangesAsync(cancellationToken);
                }
                catch (DbUpdateException ex) when (IsDuplicateOrderNumber(ex))
                {
                    _db.Entry(order).State = EntityState.Detached;
                    order = await _db.Orders
                        .FirstOrDefaultAsync(x => x.CompanyId == companyId && x.OrderNumber == orderNumber, cancellationToken)
                        ?? throw new InvalidOperationException("Order already exists but could not be reloaded.");
                }
            }

            var delivery = await _db.Deliveries
                .FirstOrDefaultAsync(x => x.CompanyId == companyId && x.SalesOrderId == order.Id, cancellationToken);

            if (delivery == null)
            {
                // Create Delivery without driver - driver can be assigned below.
                delivery = new Delivery(
                    companyId,
                    order.Id,
                    request.DeliveryDate ?? order.DeliveryDate,
                    string.IsNullOrWhiteSpace(request.DeliverySlot) ? "Anytime" : request.DeliverySlot.Trim(),
                    string.IsNullOrWhiteSpace(request.DeliveryAddress) ? order.DeliveryAddress ?? "Address not specified" : request.DeliveryAddress.Trim());
                _db.Deliveries.Add(delivery);

                if (!string.IsNullOrWhiteSpace(request.DeliveryPincode))
                    delivery.SetPostalCode(request.DeliveryPincode.Trim());
                delivery.SetCustomerContact(request.RecipientPhone ?? request.CustomerPhone, null);

                await _db.SaveChangesAsync(cancellationToken);
            }

            // If driver information is supplied, assign the driver to both
            // the Order and the Delivery. This must also run when the Delivery
            // record already existed.
            if (!string.IsNullOrWhiteSpace(request.DriverPhone) || !string.IsNullOrWhiteSpace(request.DriverName))
            {
                var driverPhone = request.DriverPhone?.Trim();
                var driverName = string.IsNullOrWhiteSpace(request.DriverName)
                    ? driverPhone ?? "Delivery Driver"
                    : request.DriverName.Trim();
                var driver = await _db.Staff
                    .FirstOrDefaultAsync(x => x.CompanyId == companyId && x.Phone == driverPhone, cancellationToken);
                if (driver == null)
                {
                    driver = new Staff(companyId, driverName, StaffRole.Driver, null, driverPhone, null);
                    _db.Staff.Add(driver);
                    await _db.SaveChangesAsync(cancellationToken);
                }

                order.AssignDeliveryPerson(driver.Id);
                delivery.AssignDeliveryPerson(driver.Id);

                await _db.SaveChangesAsync(cancellationToken);
            }

            return Ok(new
            {
                backendOrderId = order.Id,
                deliveryId = delivery.Id,
                status = delivery.Status.ToString()
            });
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    private static bool IsDuplicateOrderNumber(DbUpdateException ex)
    {
        return ex.InnerException is PostgresException
        {
            SqlState: PostgresErrorCodes.UniqueViolation,
            ConstraintName: "UQ_Orders_CompanyOrderNumber"
        };
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

    [HttpPost("assignments/{deliveryId}/driver")]
    public async Task<IActionResult> AssignDriverToDelivery(
        string deliveryId,
        [FromBody] AssignDriverToDeliveryRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            if (!Guid.TryParse(deliveryId, out var parsedDeliveryId))
                throw new ArgumentException("Invalid delivery ID.", nameof(deliveryId));

            var companyId = GetCompanyId();
            var delivery = await _db.Deliveries
                .FirstOrDefaultAsync(x => x.Id == parsedDeliveryId && x.CompanyId == companyId, cancellationToken)
                ?? throw new KeyNotFoundException("Delivery not found.");

            var driverPhone = request.DriverPhone?.Trim();
            var driverName = string.IsNullOrWhiteSpace(request.DriverName)
                ? driverPhone ?? "Delivery Driver"
                : request.DriverName.Trim();
            var driver = await _db.Staff
                .FirstOrDefaultAsync(x => x.CompanyId == companyId && x.Phone == driverPhone, cancellationToken);
            if (driver == null)
            {
                driver = new Staff(companyId, driverName, StaffRole.Driver, null, driverPhone, null);
                _db.Staff.Add(driver);
                await _db.SaveChangesAsync(cancellationToken);
            }

            delivery.AssignDeliveryPerson(driver.Id);
            await _db.SaveChangesAsync(cancellationToken);

            return Ok(new { success = true, status = delivery.Status.ToString() });
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

public sealed class MobileDeliveryAssignmentSyncRequest
{
    public string? OrderNumber { get; set; }
    public string? CustomerName { get; set; }
    public string? CustomerPhone { get; set; }
    public string? RecipientName { get; set; }
    public string? RecipientPhone { get; set; }
    public string? DeliveryAddress { get; set; }
    public string? DeliveryPincode { get; set; }
    public DateTime? DeliveryDate { get; set; }
    public string? DeliverySlot { get; set; }
    public string? DriverName { get; set; }
    public string? DriverPhone { get; set; }
}

public sealed class AssignDriverToDeliveryRequest
{
    public string? DriverName { get; set; }
    public string? DriverPhone { get; set; }
}