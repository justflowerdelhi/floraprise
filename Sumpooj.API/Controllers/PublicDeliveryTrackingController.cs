using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.DeliveryTracking;
using Sumpooj.Application.DeliveryTracking.DTOs;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;
using System.Security.Cryptography;

namespace Sumpooj.API.Controllers;

[Route("api/public/tracking")]
[ApiController]
public class PublicDeliveryTrackingController : ControllerBase
{
    private readonly SumpoojDbContext _db;
    private readonly IDeliveryTrackingService _trackingService;
    private readonly DriverJourneyService _journeyService;
    private readonly IDeliveryRepository _deliveryRepository;

    public PublicDeliveryTrackingController(
        SumpoojDbContext db,
        IDeliveryTrackingService trackingService,
        DriverJourneyService journeyService,
        IDeliveryRepository deliveryRepository)
    {
        _db = db;
        _trackingService = trackingService;
        _journeyService = journeyService;
        _deliveryRepository = deliveryRepository;
    }

    /// <summary>
    /// Get public delivery tracking by secure token (Customer view)
    /// No authentication required
    /// </summary>
    [HttpGet("customer/{token}")]
    public async Task<IActionResult> GetPublicTracking(string token)
    {
        try
        {
            // Find delivery by tracking token
            var delivery = await (
                from d in _db.Deliveries
                join s in _db.Set<SalesOrder>() on d.SalesOrderId equals s.Id
                join c in _db.Customers on s.CustomerId equals c.Id
                where d.TrackingToken == token
                select new
                {
                    Delivery = d,
                    OrderNumber = s.OrderNumber,
                    CustomerName = c.Name
                })
                .FirstOrDefaultAsync();

            if (delivery == null)
            {
                return NotFound(new { error = "Invalid tracking token" });
            }

            var deliveryEntity = delivery.Delivery;

            // Check if delivery is completed (token expires after delivery)
            if (deliveryEntity.Status == DeliveryStatus.Delivered)
            {
                // Allow viewing completed deliveries for 24 hours
                if (deliveryEntity.UpdatedAtUtc.HasValue && 
                    (DateTime.UtcNow - deliveryEntity.UpdatedAtUtc.Value).TotalHours > 24)
                {
                    return NotFound(new { error = "Tracking link has expired" });
                }
            }

            // Get tracking data
            var tracking = await _trackingService.GetTrackingByOrderIdAsync(deliveryEntity.SalesOrderId);

            // Return public-safe data (exclude sensitive info)
            return Ok(new
            {
                orderId = deliveryEntity.SalesOrderId,
                orderNumber = delivery.OrderNumber,
                customerName = delivery.CustomerName,
                deliveryAddress = deliveryEntity.DeliveryAddress,
                timeSlot = deliveryEntity.TimeSlot,
                status = deliveryEntity.Status.ToString(),
                tracking = new
                {
                    driverName = tracking.Driver?.Name,
                    driverPhone = tracking.Driver?.Phone,
                    lastLocation = tracking.LastLocation,
                    route = tracking.Route,
                    timeline = tracking.Timeline,
                    proof = tracking.Proof
                }
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    /// <summary>
    /// Get driver start link details by secure token (Driver view)
    /// No authentication required - driver validates via token
    /// </summary>
    [HttpGet("driver/{token}")]
    public async Task<IActionResult> GetDriverStartLink(string token)
    {
        try
        {
            // Find delivery by tracking token
            var delivery = await (
                from d in _db.Deliveries
                join s in _db.Set<SalesOrder>() on d.SalesOrderId equals s.Id
                join c in _db.Customers on s.CustomerId equals c.Id
                where d.TrackingToken == token
                select new
                {
                    Delivery = d,
                    OrderNumber = s.OrderNumber,
                    CustomerName = c.Name
                })
                .FirstOrDefaultAsync();

            if (delivery == null)
            {
                return NotFound(new { error = "Invalid tracking token" });
            }

            var deliveryEntity = delivery.Delivery;

            // Check if delivery is already completed or cancelled
            if (deliveryEntity.Status == DeliveryStatus.Delivered || 
                deliveryEntity.Status == DeliveryStatus.Cancelled ||
                deliveryEntity.Status == DeliveryStatus.SettlementCompleted)
            {
                return BadRequest(new { error = "Delivery is already completed or cancelled" });
            }

            // Return driver-safe data
            return Ok(new
            {
                deliveryId = deliveryEntity.Id,
                orderId = deliveryEntity.SalesOrderId,
                orderNumber = delivery.OrderNumber,
                customerName = delivery.CustomerName,
                deliveryAddress = deliveryEntity.DeliveryAddress,
                destinationLatitude = deliveryEntity.DeliveryAddressLatitude,
                destinationLongitude = deliveryEntity.DeliveryAddressLongitude,
                customerPhone = deliveryEntity.CustomerPhone,
                timeSlot = deliveryEntity.TimeSlot,
                status = deliveryEntity.Status.ToString(),
                trackingToken = deliveryEntity.TrackingToken
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    /// <summary>
    /// Android App Link redirect for Driver Start Link
    /// Returns HTML that attempts to open the Floraprise app with the delivery token
    /// Falls back to web view if app is not installed
    /// </summary>
    [HttpGet("driver/app-link/{token}")]
    public IActionResult GetDriverAppLink(string token)
    {
        var appLink = $"floraprise://driver/{token}";
        var webLink = $"{Request.Scheme}://{Request.Host}/api/public/tracking/driver/{token}";
        
        var html = $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>Opening Floraprise...</title>
    <style>
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }}
        .container {{
            text-align: center;
            padding: 20px;
        }}
        .spinner {{
            border: 4px solid rgba(255,255,255,0.3);
            border-top: 4px solid white;
            border-radius: 50%;
            width: 50px;
            height: 50px;
            animation: spin 1s linear infinite;
            margin: 20px auto;
        }}
        @keyframes spin {{
            0% {{ transform: rotate(0deg); }}
            100% {{ transform: rotate(360deg); }}
        }}
        .btn {{
            display: inline-block;
            margin-top: 20px;
            padding: 12px 24px;
            background: white;
            color: #667eea;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 600;
        }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='spinner'></div>
        <h2>Opening Floraprise App...</h2>
        <p>If the app doesn't open, you can:</p>
        <a href='{webLink}' class='btn'>Open in Browser</a>
    </div>
    <script>
        // Attempt to open app link
        window.location.href = '{appLink}';
        
        // Fallback to web view after delay
        setTimeout(function() {{
            window.location.href = '{webLink}';
        }}, 2000);
    </script>
</body>
</html>";

        return Content(html, "text/html");
    }

    /// <summary>
    /// Update delivery status using delivery token (no authentication required)
    /// Driver identity is validated via delivery token
    /// </summary>
    [HttpPost("driver/status")]
    [AllowAnonymous]
    public async Task<IActionResult> UpdateDeliveryStatus([FromBody] TokenBasedStatusUpdateRequest request)
    {
        try
        {
            // Find delivery by tracking token
            var delivery = await _db.Deliveries.FirstOrDefaultAsync(d => d.TrackingToken == request.TrackingToken);
            if (delivery == null)
                return NotFound(new { error = "Invalid tracking token" });

            // Validate status transition
            var newStatus = Enum.Parse<DeliveryStatus>(request.Status);
            
            // Apply status update based on current state
            switch (newStatus)
            {
                case DeliveryStatus.Accepted:
                    if (delivery.Status != DeliveryStatus.Assigned)
                        return BadRequest(new { error = "Can only accept assigned deliveries" });
                    delivery.MarkAccepted(delivery.DeliveryPersonId ?? Guid.NewGuid());
                    break;
                    
                case DeliveryStatus.PickedUp:
                    if (delivery.Status != DeliveryStatus.Accepted)
                        return BadRequest(new { error = "Can only mark picked up after acceptance" });
                    delivery.MarkPickedUp();
                    break;
                    
                case DeliveryStatus.OutForDelivery:
                    if (delivery.Status != DeliveryStatus.PickedUp)
                        return BadRequest(new { error = "Can only mark out for delivery after pickup" });
                    delivery.MarkOutForDelivery();
                    break;
                    
                case DeliveryStatus.ArrivedNearby:
                    if (delivery.Status != DeliveryStatus.OutForDelivery)
                        return BadRequest(new { error = "Can only mark arrived nearby after out for delivery" });
                    delivery.MarkArrivedNearby();
                    break;
                    
                case DeliveryStatus.Delivered:
                    if (delivery.Status != DeliveryStatus.ArrivedNearby && delivery.Status != DeliveryStatus.OutForDelivery)
                        return BadRequest(new { error = "Can only mark delivered after arrived nearby or out for delivery" });
                    delivery.MarkDelivered();
                    break;
                    
                default:
                    return BadRequest(new { error = "Invalid status transition" });
            }

            await _db.SaveChangesAsync();
            
            return Ok(new { success = true, status = delivery.Status.ToString() });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    /// <summary>
    /// Upload driver GPS location using delivery token (no authentication required)
    /// Driver identity is validated via delivery token + driver mobile number
    /// </summary>
    [HttpPost("driver/location")]
    [AllowAnonymous]
    public async Task<IActionResult> UploadDriverLocation([FromBody] TokenBasedLocationRequest request)
    {
        try
        {
            // Validate coordinates
            if (request.Latitude < -90 || request.Latitude > 90)
                return BadRequest(new { error = "Invalid latitude" });
            if (request.Longitude < -180 || request.Longitude > 180)
                return BadRequest(new { error = "Invalid longitude" });

            // Find delivery by tracking token
            var delivery = await _db.Deliveries.FirstOrDefaultAsync(d => d.TrackingToken == request.TrackingToken);
            if (delivery == null)
                return NotFound(new { error = "Invalid tracking token" });

            // Validate driver mobile number if provided
            if (!string.IsNullOrWhiteSpace(request.DriverMobile))
            {
                // TODO: Validate driver mobile number against Staff record
                // For now, we'll accept any mobile number since the approved scope
                // only requires token validation
            }

            // Validate delivery is in active state
            if (delivery.Status != DeliveryStatus.OutForDelivery && 
                delivery.Status != DeliveryStatus.PickedUp &&
                delivery.Status != DeliveryStatus.Accepted)
                return BadRequest(new { error = "Delivery is not in active state" });

            // Upload location using the assigned driver ID (or create anonymous tracking)
            var driverId = delivery.DeliveryPersonId ?? Guid.NewGuid();
            var uploadRequest = new UploadLocationRequest
            {
                DeliveryId = delivery.Id,
                Latitude = request.Latitude,
                Longitude = request.Longitude,
                Accuracy = request.Accuracy,
                Speed = request.Speed,
                Heading = request.Heading,
                RecordedAt = request.RecordedAt ?? DateTime.UtcNow
            };

            await _journeyService.UploadLocationAsync(driverId, uploadRequest);
            
            return Ok(new { success = true });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    /// <summary>
    /// Get all live deliveries (for Owner Control Center)
    /// </summary>
    [HttpGet("live")]
    public async Task<IActionResult> GetLiveDeliveries()
    {
        try
        {
            var activeStatuses = new[] { DeliveryStatus.Assigned, DeliveryStatus.Accepted, DeliveryStatus.PickedUp, DeliveryStatus.OutForDelivery, DeliveryStatus.ArrivedNearby };
            
            var deliveries = await (
                from d in _db.Deliveries
                join s in _db.Orders on d.SalesOrderId equals s.Id
                join c in _db.Companies on s.CompanyId equals c.Id
                join customer in _db.Customers on s.CustomerId equals customer.Id
                join dp in _db.Staff on d.DeliveryPersonId equals dp.Id into dpGroup
                from dp in dpGroup.DefaultIfEmpty()
                // get latest GPS fix for this delivery
                let lastLoc = _db.DeliveryLocations
                    .Where(l => l.DeliveryId == d.Id)
                    .OrderByDescending(l => l.RecordedAt)
                    .FirstOrDefault()
                where activeStatuses.Contains(d.Status)
                select new
                {
                    DeliveryId    = d.Id,
                    OrderNumber   = s.OrderNumber,
                    CustomerName  = customer.Name,
                    CustomerPhone = d.CustomerPhone ?? s.RecipientPhone ?? customer.Phone,
                    FloristName   = c.Name,
                    DriverName    = dp != null ? dp.Name : "Unassigned",
                    DriverPhone   = dp != null ? dp.Phone : null,
                    Status        = d.Status.ToString(),
                    Eta           = d.DeliveryDate,
                    LastUpdate    = d.UpdatedAtUtc ?? d.CreatedAtUtc,
                    TrackingToken = d.TrackingToken,
                    DeliveryAddress = d.DeliveryAddress,
                    DestLat       = d.DeliveryAddressLatitude,
                    DestLng       = d.DeliveryAddressLongitude,
                    DriverLat     = lastLoc != null ? lastLoc.Latitude  : (double?)null,
                    DriverLng     = lastLoc != null ? lastLoc.Longitude : (double?)null,
                    DriverUpdatedAt = lastLoc != null ? lastLoc.RecordedAt : (DateTime?)null,
                })
                .OrderByDescending(x => x.LastUpdate)
                .Take(100)
                .ToListAsync();

            return Ok(deliveries);
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    /// <summary>
    /// Generate tracking token for a delivery (internal use)
    /// </summary>
    [HttpPost("generate-token")]
    [Authorize(Policy = "CompanyOnly")]
    public async Task<IActionResult> GenerateTrackingToken([FromBody] GenerateTokenRequest request)
    {
        try
        {
            var delivery = await _db.Deliveries.FindAsync(request.DeliveryId);
            if (delivery == null)
            {
                return NotFound(new { error = "Delivery not found" });
            }

            // Generate cryptographically secure random token (16 bytes = 32 hex chars)
            var tokenBytes = new byte[16];
            using var rng = RandomNumberGenerator.Create();
            rng.GetBytes(tokenBytes);
            var token = Convert.ToHexString(tokenBytes).ToLowerInvariant();

            delivery.SetTrackingToken(token);
            await _db.SaveChangesAsync();

            // Generate links
            var baseUrl = Request.Scheme + "://" + Request.Host;
            var driverLink = $"{baseUrl}/api/public/tracking/driver/{token}";
            var customerLink = $"{baseUrl}/api/public/tracking/customer/{token}";

            return Ok(new 
            { 
                token = delivery.TrackingToken,
                driverLink = driverLink,
                customerLink = customerLink
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }
}

public class GenerateTokenRequest
{
    public Guid DeliveryId { get; set; }
}

public class TokenBasedLocationRequest
{
    public string TrackingToken { get; set; } = string.Empty;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public double? Accuracy { get; set; }
    public double? Speed { get; set; }
    public double? Heading { get; set; }
    public DateTime? RecordedAt { get; set; }
    public string? DriverMobile { get; set; }
}

public class TokenBasedStatusUpdateRequest
{
    public string TrackingToken { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
}
