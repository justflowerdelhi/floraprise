using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
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

    /// <summary>
    /// List delivery routes for a given date.
    /// Frontend: GET /api/delivery-routes?date=2025-01-15
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetRoutes([FromQuery] DateTime? date)
    {
        var targetDate = date?.Date ?? DateTime.UtcNow.Date;

        var routes = await _db.DeliveryRoutes
            .Where(r => r.RouteDate.Date == targetDate)
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

    /// <summary>
    /// Create a new delivery route and assign selected deliveries to it.
    /// Frontend: POST /api/delivery-routes { routeDate, deliveryIds }
    /// </summary>
    [HttpPost]
    public async Task<IActionResult> CreateRoute([FromBody] CreateRouteRequest request)
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
