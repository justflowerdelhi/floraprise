using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Deliveries;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.UseCases;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.API.Controllers;

[Route("api/deliveries")]
[ApiController]
[Authorize(Policy = "CompanyOnly")]
public class DeliveriesController : ControllerBase
{
    private readonly SumpoojDbContext _db;
    private readonly IDeliveryRepository _deliveryRepo;
    private readonly AssignDeliveryPersonHandler _assignHandler;

    public DeliveriesController(
        SumpoojDbContext db,
        IDeliveryRepository deliveryRepo,
        AssignDeliveryPersonHandler assignHandler)
    {
        _db = db;
        _deliveryRepo = deliveryRepo;
        _assignHandler = assignHandler;
    }

    /// <summary>
    /// Get deliveries for a specific date (defaults to today).
    /// Supports optional status and routeId filters for the delivery-routes page.
    /// Pass routeId=null to get unassigned deliveries.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetDeliveries(
        [FromQuery] DateTime? date,
        [FromQuery] string? status,
        [FromQuery] string? routeId)
    {
        var targetDate = (date?.Date ?? DateTime.UtcNow.Date);
        targetDate = DateTime.SpecifyKind(targetDate, DateTimeKind.Utc);

        var query = from d in _db.Deliveries
                join o in _db.Orders on d.SalesOrderId equals o.Id
                join c in _db.Customers on o.CustomerId equals c.Id
                where d.DeliveryDate.Date == targetDate
                select new { d, o, c };

        // Filter by status (e.g. "Scheduled")
        if (!string.IsNullOrEmpty(status)
            && Enum.TryParse<DeliveryStatus>(status, true, out var deliveryStatus))
        {
            query = query.Where(x => x.d.Status == deliveryStatus);
        }

        // Filter by routeId — "null" string means unassigned deliveries
        if (routeId != null)
        {
            if (routeId == "null" || routeId == "")
                query = query.Where(x => x.d.DeliveryRouteId == null);
            else if (Guid.TryParse(routeId, out var rid))
                query = query.Where(x => x.d.DeliveryRouteId == rid);
        }

        var deliveries = await query
            .OrderBy(x => x.d.DeliveryDate).ThenBy(x => x.d.TimeSlot)
            .Select(x => new DeliveryListDto
            {
                DeliveryId = x.d.Id,
                OrderNumber = x.o.OrderNumber,
                CustomerName = x.c.Name,
                Phone = x.c.Phone,
                DeliveryDate = x.d.DeliveryDate,
                TimeSlot = x.d.TimeSlot,
                Address = x.d.DeliveryAddress,
                PostalCode = x.d.PostalCode,
                Status = x.d.Status.ToString(),
                DeliveryPersonName =
                    _db.Staff
                        .Where(s => s.Id == x.d.DeliveryPersonId)
                        .Select(s => s.Name)
                        .FirstOrDefault()
                    ??
                    (
                        from r in _db.DeliveryRoutes
                        join s in _db.Staff on r.DeliveryPersonId equals s.Id
                        where x.d.DeliveryRouteId != null
                              && r.Id == x.d.DeliveryRouteId
                              && r.DeliveryPersonId != Guid.Empty
                        select s.Name
                    ).FirstOrDefault()
            })
            .AsNoTracking().ToListAsync();

        return Ok(deliveries);
    }

    /// <summary>
    /// Mark a delivery as out for delivery
    /// </summary>
    [HttpPut("{id:guid}/out-for-delivery")]
    public async Task<IActionResult> MarkOutForDelivery(Guid id)
    {
        var delivery = await _deliveryRepo.GetByIdAsync(id);
        if (delivery == null)
            return NotFound(new { message = "Delivery not found" });

        delivery.MarkOutForDelivery();
        await _deliveryRepo.UpdateAsync(delivery);

        return Ok(new { message = "Delivery marked as out for delivery" });
    }

    /// <summary>
    /// Mark a delivery as delivered
    /// </summary>
    [HttpPut("{id:guid}/delivered")]
    public async Task<IActionResult> MarkDelivered(Guid id)
    {
        var delivery = await _deliveryRepo.GetByIdAsync(id);
        if (delivery == null)
            return NotFound(new { message = "Delivery not found" });

        delivery.MarkDelivered();
        await _deliveryRepo.UpdateAsync(delivery);

        return Ok(new { message = "Delivery marked as delivered" });
    }

    /// <summary>
    /// Assign a delivery person to a delivery
    /// </summary>
    [HttpPut("{id:guid}/assign")]
    public async Task<IActionResult> AssignDeliveryPerson(Guid id, [FromBody] AssignDriverRequest request)
    {
        try
        {
            await _assignHandler.HandleAsync(new AssignDeliveryPersonCommand(id, request.StaffId));
            return Ok(new { message = "Delivery person assigned" });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}

public class DeliveryListDto
{
    public Guid DeliveryId { get; set; }
    public string OrderNumber { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public DateTime DeliveryDate { get; set; }
    public string TimeSlot { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public string? PostalCode { get; set; }
    public string Status { get; set; } = string.Empty;
    public string? DeliveryPersonName { get; set; }
}

public class AssignDriverRequest
{
    public Guid StaffId { get; set; }
}
