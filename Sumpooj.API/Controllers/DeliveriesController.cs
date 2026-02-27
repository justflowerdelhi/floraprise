using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Deliveries;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.UseCases;
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
    /// Get deliveries for a specific date (defaults to today)
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetDeliveries([FromQuery] DateTime? date)
    {
        var targetDate = (date?.Date ?? DateTime.UtcNow.Date);
        targetDate = DateTime.SpecifyKind(targetDate, DateTimeKind.Utc);

        var deliveries = await (
            from d in _db.Deliveries
            join o in _db.Orders on d.SalesOrderId equals o.Id
            join c in _db.Customers on o.CustomerId equals c.Id
            join s in _db.Staff on d.DeliveryPersonId equals s.Id into staffJoin
            from s in staffJoin.DefaultIfEmpty()
            where d.DeliveryDate.Date == targetDate
            orderby d.DeliveryDate, d.TimeSlot
            select new DeliveryListDto
            {
                DeliveryId = d.Id,
                OrderNumber = o.OrderNumber,
                CustomerName = c.Name,
                Phone = c.Phone,
                DeliveryDate = d.DeliveryDate,
                TimeSlot = d.TimeSlot,
                Address = d.DeliveryAddress,
                Status = d.Status.ToString(),
                DeliveryPersonName = s != null ? s.Name : null
            }
        ).AsNoTracking().ToListAsync();

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
    public string Status { get; set; } = string.Empty;
    public string? DeliveryPersonName { get; set; }
}

public class AssignDriverRequest
{
    public Guid StaffId { get; set; }
}
