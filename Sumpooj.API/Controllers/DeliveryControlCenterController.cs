using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.API.Controllers;

[Route("api/delivery/control-center")]
[ApiController]
[Authorize(Policy = "PlatformSupport")]
public class DeliveryControlCenterController : ControllerBase
{
    private readonly SumpoojDbContext _db;
    private readonly IDeliveryLocationRepository _locationRepo;
    private readonly ITenantContext _tenantContext;

    public DeliveryControlCenterController(
        SumpoojDbContext db,
        IDeliveryLocationRepository locationRepo,
        ITenantContext tenantContext)
    {
        _db = db;
        _locationRepo = locationRepo;
        _tenantContext = tenantContext;
    }

    private Guid? CompanyId => _tenantContext.CompanyId;

    /// <summary>
    /// Get delivery control center dashboard data
    /// </summary>
    [HttpGet("dashboard")]
    public async Task<IActionResult> GetDashboard([FromQuery] DateTime? date)
    {
        var targetDate = date?.Date ?? DateTime.UtcNow.Date;
        targetDate = DateTime.SpecifyKind(targetDate, DateTimeKind.Utc);

        // Drivers currently online (with recent heartbeat)
        var onlineDrivers = await GetOnlineDriversAsync(targetDate);

        // Orders waiting for assignment
        var waitingOrders = await GetWaitingOrdersAsync(targetDate);

        // Deliveries in progress
        var inProgressDeliveries = await GetInProgressDeliveriesAsync(targetDate);

        // Delayed deliveries
        var delayedDeliveries = await GetDelayedDeliveriesAsync(targetDate);

        // Live driver locations
        var driverLocations = await GetDriverLocationsAsync();

        // Completed deliveries today
        var completedDeliveries = await GetCompletedDeliveriesAsync(targetDate);

        return Ok(new
        {
            date = targetDate,
            onlineDrivers,
            waitingOrders,
            inProgressDeliveries,
            delayedDeliveries,
            driverLocations,
            completedDeliveries,
            summary = new
            {
                totalDrivers = onlineDrivers.Count,
                totalWaiting = waitingOrders.Count,
                totalInProgress = inProgressDeliveries.Count,
                totalDelayed = delayedDeliveries.Count,
                totalCompleted = completedDeliveries.Count
            }
        });
    }

    /// <summary>
    /// Get drivers currently online (with recent location updates)
    /// </summary>
    [HttpGet("drivers/online")]
    public async Task<IActionResult> GetOnlineDrivers([FromQuery] DateTime? date)
    {
        var targetDate = date?.Date ?? DateTime.UtcNow.Date;
        targetDate = DateTime.SpecifyKind(targetDate, DateTimeKind.Utc);

        var onlineDrivers = await GetOnlineDriversAsync(targetDate);
        return Ok(new { items = onlineDrivers });
    }

    /// <summary>
    /// Get orders waiting for assignment
    /// </summary>
    [HttpGet("orders/waiting")]
    public async Task<IActionResult> GetWaitingOrders([FromQuery] DateTime? date)
    {
        var targetDate = date?.Date ?? DateTime.UtcNow.Date;
        targetDate = DateTime.SpecifyKind(targetDate, DateTimeKind.Utc);

        var waitingOrders = await GetWaitingOrdersAsync(targetDate);
        return Ok(new { items = waitingOrders });
    }

    /// <summary>
    /// Get deliveries in progress
    /// </summary>
    [HttpGet("deliveries/in-progress")]
    public async Task<IActionResult> GetInProgressDeliveries([FromQuery] DateTime? date)
    {
        var targetDate = date?.Date ?? DateTime.UtcNow.Date;
        targetDate = DateTime.SpecifyKind(targetDate, DateTimeKind.Utc);

        var inProgressDeliveries = await GetInProgressDeliveriesAsync(targetDate);
        return Ok(new { items = inProgressDeliveries });
    }

    /// <summary>
    /// Get delayed deliveries
    /// </summary>
    [HttpGet("deliveries/delayed")]
    public async Task<IActionResult> GetDelayedDeliveries([FromQuery] DateTime? date)
    {
        var targetDate = date?.Date ?? DateTime.UtcNow.Date;
        targetDate = DateTime.SpecifyKind(targetDate, DateTimeKind.Utc);

        var delayedDeliveries = await GetDelayedDeliveriesAsync(targetDate);
        return Ok(new { items = delayedDeliveries });
    }

    /// <summary>
    /// Get live driver locations
    /// </summary>
    [HttpGet("drivers/locations")]
    public async Task<IActionResult> GetDriverLocations()
    {
        var driverLocations = await GetDriverLocationsAsync();
        return Ok(new { items = driverLocations });
    }

    /// <summary>
    /// Get completed deliveries today
    /// </summary>
    [HttpGet("deliveries/completed")]
    public async Task<IActionResult> GetCompletedDeliveries([FromQuery] DateTime? date)
    {
        var targetDate = date?.Date ?? DateTime.UtcNow.Date;
        targetDate = DateTime.SpecifyKind(targetDate, DateTimeKind.Utc);

        var completedDeliveries = await GetCompletedDeliveriesAsync(targetDate);
        return Ok(new { items = completedDeliveries });
    }

    private async Task<List<OnlineDriverDto>> GetOnlineDriversAsync(DateTime date)
    {
        // Drivers with location updates in the last 30 minutes
        var recentThreshold = DateTime.UtcNow.AddMinutes(-30);

        var drivers = await _db.DeliveryRoutes
            .Where(r => r.RouteDate.Date == date.Date && r.Status == DeliveryRouteStatus.InProgress)
            .Join(_db.Staff, r => r.DeliveryPersonId, s => s.Id, (r, s) => new { r, s })
            .Select(x => new OnlineDriverDto
            {
                DriverId = x.r.DeliveryPersonId,
                DriverName = x.s.Name,
                DriverPhone = x.s.Phone,
                Vehicle = null,
                RouteId = x.r.Id,
                RouteName = x.r.Name,
                Status = x.r.Status.ToString()
            })
            .ToListAsync();

        // Check for recent location updates
        foreach (var driver in drivers)
        {
            var latestLocation = await _locationRepo.GetLatestDriverLocationAsync(driver.DriverId);
            driver.IsOnline = latestLocation != null && latestLocation.RecordedAt > recentThreshold;
            driver.LastLocationUpdate = latestLocation?.RecordedAt;
        }

        return drivers.Where(d => d.IsOnline).ToList();
    }

    private async Task<List<WaitingOrderDto>> GetWaitingOrdersAsync(DateTime date)
    {
        var deliveriesQuery = _db.Deliveries
            .Where(d => d.DeliveryDate.Date == date.Date
                  && d.Status == DeliveryStatus.Scheduled
                  && d.DeliveryRouteId == null);

        if (CompanyId.HasValue)
        {
            deliveriesQuery = deliveriesQuery.Where(d => d.CompanyId == CompanyId.Value);
        }

        return await (
            from d in deliveriesQuery
            join s in _db.Set<SalesOrder>() on d.SalesOrderId equals s.Id
            join c in _db.Customers on s.CustomerId equals c.Id
            select new WaitingOrderDto
            {
                DeliveryId = d.Id,
                OrderId = d.SalesOrderId,
                OrderNumber = s.OrderNumber,
                CustomerName = c.Name,
                CustomerPhone = c.Phone,
                DeliveryAddress = d.DeliveryAddress,
                TimeSlot = d.TimeSlot,
                PostalCode = d.PostalCode
            })
            .OrderBy(d => d.TimeSlot)
            .ToListAsync();
    }

    private async Task<List<InProgressDeliveryDto>> GetInProgressDeliveriesAsync(DateTime date)
    {
        var deliveriesQuery = _db.Deliveries
            .Where(d => d.DeliveryDate.Date == date.Date
                  && d.Status == DeliveryStatus.OutForDelivery);

        if (CompanyId.HasValue)
        {
            deliveriesQuery = deliveriesQuery.Where(d => d.CompanyId == CompanyId.Value);
        }

        return await (
            from d in deliveriesQuery
            join s in _db.Set<SalesOrder>() on d.SalesOrderId equals s.Id
            join c in _db.Customers on s.CustomerId equals c.Id
            join r in _db.DeliveryRoutes on d.DeliveryRouteId equals r.Id into routeLeft
            from route in routeLeft.DefaultIfEmpty()
            select new InProgressDeliveryDto
            {
                DeliveryId = d.Id,
                OrderId = d.SalesOrderId,
                OrderNumber = s.OrderNumber,
                CustomerName = c.Name,
                CustomerPhone = c.Phone,
                DeliveryAddress = d.DeliveryAddress,
                TimeSlot = d.TimeSlot,
                RouteId = d.DeliveryRouteId,
                RouteName = route != null ? route.Name : null,
                StopOrder = d.StopOrder,
                Status = d.Status.ToString()
            })
            .OrderBy(d => d.StopOrder)
            .ToListAsync();
    }

    private async Task<List<DelayedDeliveryDto>> GetDelayedDeliveriesAsync(DateTime date)
    {
        var now = DateTime.UtcNow;
        var delayedThreshold = now.AddMinutes(-30); // Consider delayed if 30+ minutes past time slot

        var deliveriesQuery = _db.Deliveries
            .Where(d => d.DeliveryDate.Date == date.Date
                  && d.Status == DeliveryStatus.OutForDelivery
                  && d.DeliveryDate < delayedThreshold);

        if (CompanyId.HasValue)
        {
            deliveriesQuery = deliveriesQuery.Where(d => d.CompanyId == CompanyId.Value);
        }

        return await (
            from d in deliveriesQuery
            join s in _db.Set<SalesOrder>() on d.SalesOrderId equals s.Id
            join c in _db.Customers on s.CustomerId equals c.Id
            join r in _db.DeliveryRoutes on d.DeliveryRouteId equals r.Id into routeLeft
            from route in routeLeft.DefaultIfEmpty()
            select new DelayedDeliveryDto
            {
                DeliveryId = d.Id,
                OrderId = d.SalesOrderId,
                OrderNumber = s.OrderNumber,
                CustomerName = c.Name,
                CustomerPhone = c.Phone,
                DeliveryAddress = d.DeliveryAddress,
                TimeSlot = d.TimeSlot,
                ScheduledTime = d.DeliveryDate,
                DelayMinutes = (int)(now - d.DeliveryDate).TotalMinutes,
                RouteId = d.DeliveryRouteId,
                RouteName = route != null ? route.Name : null,
                Status = d.Status.ToString()
            })
            .OrderBy(d => d.DelayMinutes)
            .ToListAsync();
    }

    private async Task<List<DriverLocationDto>> GetDriverLocationsAsync()
    {
        var staffQuery = _db.Staff.Where(s => s.IsActive);

        if (CompanyId.HasValue)
        {
            staffQuery = staffQuery.Where(s => s.CompanyId == CompanyId.Value);
        }

        var drivers = await staffQuery
            .Select(s => new DriverLocationDto
            {
                DriverId = s.Id,
                DriverName = s.Name,
                DriverPhone = s.Phone,
                Vehicle = null
            })
            .ToListAsync();

        // Get latest location for each driver
        foreach (var driver in drivers)
        {
            var latestLocation = await _locationRepo.GetLatestDriverLocationAsync(driver.DriverId);
            if (latestLocation != null)
            {
                driver.Latitude = latestLocation.Latitude;
                driver.Longitude = latestLocation.Longitude;
                driver.SpeedKph = latestLocation.SpeedKph;
                driver.LastUpdate = latestLocation.RecordedAt;
                driver.IsOnline = (DateTime.UtcNow - latestLocation.RecordedAt).TotalMinutes < 30;
            }
        }

        return drivers.Where(d => d.IsOnline).ToList();
    }

    private async Task<List<CompletedDeliveryDto>> GetCompletedDeliveriesAsync(DateTime date)
    {
        var deliveriesQuery = _db.Deliveries
            .Where(d => d.DeliveryDate.Date == date.Date
                  && d.Status == DeliveryStatus.Delivered);

        if (CompanyId.HasValue)
        {
            deliveriesQuery = deliveriesQuery.Where(d => d.CompanyId == CompanyId.Value);
        }

        return await (
            from d in deliveriesQuery
            join s in _db.Set<SalesOrder>() on d.SalesOrderId equals s.Id
            join c in _db.Customers on s.CustomerId equals c.Id
            select new CompletedDeliveryDto
            {
                DeliveryId = d.Id,
                OrderId = d.SalesOrderId,
                OrderNumber = s.OrderNumber,
                CustomerName = c.Name,
                DeliveryAddress = d.DeliveryAddress,
                TimeSlot = d.TimeSlot,
                CompletedAt = d.UpdatedAtUtc ?? d.CreatedAtUtc,
                Status = d.Status.ToString()
            })
            .OrderByDescending(d => d.CompletedAt)
            .ToListAsync();
    }
}

// DTOs
public class OnlineDriverDto
{
    public Guid DriverId { get; set; }
    public string DriverName { get; set; } = string.Empty;
    public string DriverPhone { get; set; } = string.Empty;
    public string? Vehicle { get; set; }
    public Guid RouteId { get; set; }
    public string RouteName { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public bool IsOnline { get; set; }
    public DateTime? LastLocationUpdate { get; set; }
}

public class WaitingOrderDto
{
    public Guid DeliveryId { get; set; }
    public Guid OrderId { get; set; }
    public string OrderNumber { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;
    public string? CustomerPhone { get; set; }
    public string DeliveryAddress { get; set; } = string.Empty;
    public string TimeSlot { get; set; } = string.Empty;
    public string? PostalCode { get; set; }
}

public class InProgressDeliveryDto
{
    public Guid DeliveryId { get; set; }
    public Guid OrderId { get; set; }
    public string OrderNumber { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;
    public string? CustomerPhone { get; set; }
    public string DeliveryAddress { get; set; } = string.Empty;
    public string TimeSlot { get; set; } = string.Empty;
    public Guid? RouteId { get; set; }
    public string? RouteName { get; set; }
    public int? StopOrder { get; set; }
    public string Status { get; set; } = string.Empty;
}

public class DelayedDeliveryDto
{
    public Guid DeliveryId { get; set; }
    public Guid OrderId { get; set; }
    public string OrderNumber { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;
    public string? CustomerPhone { get; set; }
    public string DeliveryAddress { get; set; } = string.Empty;
    public string TimeSlot { get; set; } = string.Empty;
    public DateTime ScheduledTime { get; set; }
    public int DelayMinutes { get; set; }
    public Guid? RouteId { get; set; }
    public string? RouteName { get; set; }
    public string Status { get; set; } = string.Empty;
}

public class DriverLocationDto
{
    public Guid DriverId { get; set; }
    public string DriverName { get; set; } = string.Empty;
    public string DriverPhone { get; set; } = string.Empty;
    public string? Vehicle { get; set; }
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public double SpeedKph { get; set; }
    public DateTime? LastUpdate { get; set; }
    public bool IsOnline { get; set; }
}

public class CompletedDeliveryDto
{
    public Guid DeliveryId { get; set; }
    public Guid OrderId { get; set; }
    public string OrderNumber { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;
    public string DeliveryAddress { get; set; } = string.Empty;
    public string TimeSlot { get; set; } = string.Empty;
    public DateTime CompletedAt { get; set; }
    public string Status { get; set; } = string.Empty;
}
