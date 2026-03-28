using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using Sumpooj.Application.Deliveries;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/delivery-routes")]
[Authorize(Policy = "CompanyOnly")]
public class DeliveryRoutesController : ControllerBase
{
    private readonly AssignDriverToRouteHandler _assignDriverHandler;
    private readonly CompleteRouteHandler _completeRouteHandler;
    private readonly StartRouteHandler _startRouteHandler;
    private readonly SumpoojDbContext _db;
    private readonly ITenantContext _tenantContext;

    public DeliveryRoutesController(
        AssignDriverToRouteHandler assignDriverHandler,
        CompleteRouteHandler completeRouteHandler,
        StartRouteHandler startRouteHandler,
        SumpoojDbContext db,
        ITenantContext tenantContext)
    {
        _assignDriverHandler = assignDriverHandler;
        _completeRouteHandler = completeRouteHandler;
        _startRouteHandler = startRouteHandler;
        _db = db;
        _tenantContext = tenantContext;
    }

    private Guid CompanyId => _tenantContext.CompanyId
        ?? throw new UnauthorizedAccessException("Company context required");

    private static bool IsMissingDeliveryRoutesTable(PostgresException ex) =>
        ex.SqlState == PostgresErrorCodes.UndefinedTable
        && ex.MessageText.Contains("DeliveryRoutes", StringComparison.OrdinalIgnoreCase);

    private static bool IsDbUpdateMissingRoutesTable(DbUpdateException ex) =>
        ex.InnerException is PostgresException pgEx && IsMissingDeliveryRoutesTable(pgEx);

    /// <summary>
    /// List delivery routes for a given date.
    /// Frontend: GET /api/delivery-routes?date=2025-01-15
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetRoutes([FromQuery] DateTime? date, [FromQuery] string? status)
    {
        var targetDate = date?.Date ?? DateTime.UtcNow.Date;
        targetDate = DateTime.SpecifyKind(targetDate, DateTimeKind.Utc);

        var query = _db.DeliveryRoutes.Where(r => r.RouteDate.Date == targetDate);

        if (!string.IsNullOrWhiteSpace(status)
            && Enum.TryParse<DeliveryRouteStatus>(status, true, out var routeStatus))
        {
            query = query.Where(r => r.Status == routeStatus);
        }

        try
        {
            var routes = await query
                .Select(r => new
                {
                    id = r.Id.ToString(),
                    name = r.Name,
                    stopCount = _db.Deliveries.Count(d => d.DeliveryRouteId == r.Id),
                    status = r.Status.ToString(),
                })
                .ToListAsync();

            return Ok(routes);
        }
        catch (Exception ex) when (
            (ex is PostgresException pgEx1 && IsMissingDeliveryRoutesTable(pgEx1)) ||
            (ex is DbUpdateException dbEx1 && IsDbUpdateMissingRoutesTable(dbEx1)))
        {
            return Ok(Array.Empty<object>());
        }
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetRouteDetail(Guid id)
    {
        try
        {
            var route = await _db.DeliveryRoutes
                .Where(r => r.Id == id)
                .Select(r => new
                {
                    id = r.Id.ToString(),
                    name = r.Name,
                    status = r.Status.ToString(),
                    routeDate = r.RouteDate,
                    deliveryPersonName = _db.Staff
                        .Where(s => s.Id == r.DeliveryPersonId)
                        .Select(s => s.Name)
                        .FirstOrDefault()
                })
                .FirstOrDefaultAsync();

            if (route == null)
                return NotFound(new { message = "Route not found" });

            var deliveries = await (from d in _db.Deliveries
                                    join o in _db.Orders on d.SalesOrderId equals o.Id
                                    join c in _db.Customers on o.CustomerId equals c.Id
                                    where d.DeliveryRouteId == id
                                    orderby d.StopOrder
                                    select new
                                    {
                                        id = d.Id.ToString(),
                                        stopOrder = d.StopOrder ?? 0,
                                        orderNumber = o.OrderNumber,
                                        customerName = c.Name,
                                        timeSlot = d.TimeSlot,
                                        postalCode = d.PostalCode,
                                        status = d.Status.ToString()
                                    })
                .AsNoTracking()
                .ToListAsync();

            return Ok(new
            {
                route.id,
                route.name,
                route.status,
                route.routeDate,
                route.deliveryPersonName,
                deliveries,
            });
        }
        catch (Exception ex) when (
            (ex is PostgresException pgEx2 && IsMissingDeliveryRoutesTable(pgEx2)) ||
            (ex is DbUpdateException dbEx2 && IsDbUpdateMissingRoutesTable(dbEx2)))
        {
            return NotFound(new { message = "Delivery routes are not available until the database migration is applied." });
        }
    }

    /// <summary>
    /// Create a new delivery route and assign selected deliveries to it.
    /// Frontend: POST /api/delivery-routes { routeDate, deliveryIds }
    /// </summary>
    [HttpPost]
    public async Task<IActionResult> CreateRoute([FromBody] CreateRouteRequest request)
    {
        try
        {
            var routeDate = DateTime.SpecifyKind(DateTime.Parse(request.RouteDate).Date, DateTimeKind.Utc);
            var routeName = $"Route-{routeDate:yyyyMMdd}-{Guid.NewGuid().ToString()[..4]}";

            var route = new DeliveryRoute(Guid.Empty, routeDate, routeName);
            _db.DeliveryRoutes.Add(route);
            await _db.SaveChangesAsync();

            // Assign deliveries to this route
            if (request.DeliveryIds is { Count: > 0 })
            {
                var deliveryGuids = request.DeliveryIds
                    .Where(id => Guid.TryParse(id, out _))
                    .Select(Guid.Parse)
                    .ToList();

                var deliveries = await _db.Deliveries
                    .Where(d => deliveryGuids.Contains(d.Id))
                    .ToListAsync();

                var stopOrder = 1;
                foreach (var delivery in deliveries)
                {
                    delivery.AssignToRoute(route.Id, stopOrder++);
                }
                await _db.SaveChangesAsync();
            }

            return Ok(new { routeId = route.Id.ToString() });
        }
        catch (Exception ex) when (
            (ex is PostgresException pgEx3 && IsMissingDeliveryRoutesTable(pgEx3)) ||
            (ex is DbUpdateException dbEx3 && IsDbUpdateMissingRoutesTable(dbEx3)))
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new
            {
                message = "Delivery routes database table is missing. Run migration 018_add_delivery_routes_table.sql or restart the API (auto-creates on startup)."
            });
        }
    }

    [HttpPut("{id}/assign-driver")]
    public async Task<IActionResult> AssignDriver(Guid id, [FromBody] AssignRouteDriverRequest request)
    {
        try
        {
            var cmd = new AssignDriverToRouteCommand(id, request.DriverId);
            await _assignDriverHandler.Handle(cmd);
            return Ok();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpPut("{id:guid}/reorder-stop")]
    public async Task<IActionResult> ReorderStop(Guid id, [FromBody] ReorderRouteStopRequest request)
    {
        var route = await _db.DeliveryRoutes.FirstOrDefaultAsync(r => r.Id == id);
        if (route == null)
            return NotFound(new { message = "Route not found" });

        if (route.Status != DeliveryRouteStatus.Draft)
            return BadRequest(new { message = "Only Draft routes can be reordered" });

        var deliveries = await _db.Deliveries
            .Where(d => d.DeliveryRouteId == id)
            .OrderBy(d => d.StopOrder)
            .ToListAsync();

        var moving = deliveries.FirstOrDefault(d => d.Id == request.StopId);
        if (moving == null)
            return NotFound(new { message = "Stop not found on this route" });

        var targetIndex = Math.Clamp(request.NewPosition, 1, deliveries.Count) - 1;
        deliveries.Remove(moving);
        deliveries.Insert(targetIndex, moving);

        for (var i = 0; i < deliveries.Count; i++)
        {
            _db.Entry(deliveries[i]).Property(d => d.StopOrder).CurrentValue = i + 1;
        }

        await _db.SaveChangesAsync();
        return Ok();
    }

    [HttpPut("{id:guid}/move-stop")]
    public async Task<IActionResult> MoveStop(Guid id, [FromBody] MoveRouteStopRequest request)
    {
        var sourceRoute = await _db.DeliveryRoutes.FirstOrDefaultAsync(r => r.Id == id);
        if (sourceRoute == null)
            return NotFound(new { message = "Source route not found" });

        var targetRoute = await _db.DeliveryRoutes.FirstOrDefaultAsync(r => r.Id == request.TargetRouteId);
        if (targetRoute == null)
            return NotFound(new { message = "Target route not found" });

        if (sourceRoute.Status != DeliveryRouteStatus.Draft || targetRoute.Status != DeliveryRouteStatus.Draft)
            return BadRequest(new { message = "Stops can only be moved between Draft routes" });

        if (sourceRoute.RouteDate.Date != targetRoute.RouteDate.Date)
            return BadRequest(new { message = "Stops can only be moved between routes on the same date" });

        var sourceDeliveries = await _db.Deliveries
            .Where(d => d.DeliveryRouteId == id)
            .OrderBy(d => d.StopOrder)
            .ToListAsync();

        var moving = sourceDeliveries.FirstOrDefault(d => d.Id == request.StopId);
        if (moving == null)
            return NotFound(new { message = "Stop not found on this route" });

        sourceDeliveries.Remove(moving);
        for (var i = 0; i < sourceDeliveries.Count; i++)
        {
            _db.Entry(sourceDeliveries[i]).Property(d => d.StopOrder).CurrentValue = i + 1;
        }

        var targetStopCount = await _db.Deliveries.CountAsync(d => d.DeliveryRouteId == request.TargetRouteId);
        _db.Entry(moving).Property(d => d.DeliveryRouteId).CurrentValue = request.TargetRouteId;
        _db.Entry(moving).Property(d => d.StopOrder).CurrentValue = targetStopCount + 1;

        await _db.SaveChangesAsync();
        return Ok();
    }

    [HttpPut("{id}/start")]
    public async Task<IActionResult> StartRoute(Guid id)
    {
        try
        {
            await _startRouteHandler.Handle(id);
            return Ok();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpPut("{id}/complete")]
    public async Task<IActionResult> CompleteRoute(Guid id)
    {
        try
        {
            await _completeRouteHandler.Handle(id);
            return Ok();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }
}

public class AssignRouteDriverRequest
{
    public Guid DriverId { get; set; }
}

public class CreateRouteRequest
{
    public string RouteDate { get; set; } = default!;
    public List<string> DeliveryIds { get; set; } = new();
}

public class ReorderRouteStopRequest
{
    public Guid StopId { get; set; }
    public int NewPosition { get; set; }
}

public class MoveRouteStopRequest
{
    public Guid StopId { get; set; }
    public Guid TargetRouteId { get; set; }
}
