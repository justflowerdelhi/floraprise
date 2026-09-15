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
    private readonly IOrderRepository _orderRepository;
    private readonly OrderService _orderService;
    private readonly ITenantContext _tenantContext;
    private readonly IUnitOfWork _unitOfWork;

    public DeliveriesController(
        SumpoojDbContext db,
        IDeliveryRepository deliveryRepo,
        AssignDeliveryPersonHandler assignHandler,
        IOrderRepository orderRepository,
        OrderService orderService,
        ITenantContext tenantContext,
        IUnitOfWork unitOfWork)
    {
        _db = db;
        _deliveryRepo = deliveryRepo;
        _assignHandler = assignHandler;
        _orderRepository = orderRepository;
        _orderService = orderService;
        _tenantContext = tenantContext;
        _unitOfWork = unitOfWork;
    }

    private Guid CompanyId => _tenantContext.CompanyId
        ?? throw new UnauthorizedAccessException("Company context required");

    /// <summary>
    /// Get deliveries for a specific date (or all active deliveries if date is null).
    /// Supports optional status and routeId filters.
    /// Includes tenant isolation and enriched florist metadata without N+1 queries.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetDeliveries(
        [FromQuery] DateTime? date,
        [FromQuery] string? status,
        [FromQuery] string? routeId)
    {
        var query = from d in _db.Deliveries
                    join o in _db.Orders on d.SalesOrderId equals o.Id
                    join c in _db.Customers on o.CustomerId equals c.Id
                    where d.CompanyId == CompanyId && o.CompanyId == CompanyId
                    select new { d, o, c };

        if (date.HasValue)
        {
            var targetDate = DateTime.SpecifyKind(date.Value.Date, DateTimeKind.Utc);
            query = query.Where(x => x.d.DeliveryDate.Date == targetDate);
        }

        // Filter by status (e.g. "Scheduled", "OutForDelivery", "Delivered")
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

        var deliveriesData = await query
            .OrderBy(x => x.d.DeliveryDate).ThenBy(x => x.d.TimeSlot)
            .Select(x => new
            {
                Delivery = x.d,
                Order = x.o,
                Customer = x.c,
                DeliveryPersonName =
                    _db.Staff
                        .Where(s => s.Id == x.d.DeliveryPersonId && s.CompanyId == CompanyId)
                        .Select(s => s.Name)
                        .FirstOrDefault()
                    ??
                    (
                        from r in _db.DeliveryRoutes
                        join s in _db.Staff on r.DeliveryPersonId equals s.Id
                        where x.d.DeliveryRouteId != null
                              && r.Id == x.d.DeliveryRouteId
                              && r.DeliveryPersonId != Guid.Empty
                              && s.CompanyId == CompanyId
                        select s.Name
                    ).FirstOrDefault()
            })
            .AsNoTracking()
            .ToListAsync();

        var orderIds = deliveriesData.Select(x => x.Order.Id).Distinct().ToList();

        // Single query for all items to eliminate N+1 database queries
        var orderItemsData = await _db.Orders
            .Where(o => o.CompanyId == CompanyId && orderIds.Contains(o.Id))
            .Select(o => new
            {
                OrderId = o.Id,
                Items = o.Items.Select(i => new { i.ProductName, i.Quantity })
            })
            .AsNoTracking()
            .ToListAsync();

        var itemsByOrderId = orderItemsData
            .ToDictionary(
                x => x.OrderId,
                x => new
                {
                    Count = x.Items.Sum(i => i.Quantity),
                    Summary = string.Join(", ", x.Items.Select(i => $"{i.Quantity}x {i.ProductName}"))
                });

        var result = deliveriesData.Select(x =>
        {
            itemsByOrderId.TryGetValue(x.Order.Id, out var itemInfo);

            return new DeliveryListDto
            {
                DeliveryId = x.Delivery.Id,
                OrderId = x.Order.Id,
                OrderNumber = x.Order.OrderNumber,
                CustomerName = x.Customer.Name,
                Phone = x.Customer.Phone,
                RecipientName = string.IsNullOrWhiteSpace(x.Order.RecipientName) ? x.Customer.Name : x.Order.RecipientName,
                RecipientPhone = string.IsNullOrWhiteSpace(x.Order.RecipientPhone) ? x.Customer.Phone : x.Order.RecipientPhone,
                DeliveryDate = x.Delivery.DeliveryDate,
                TimeSlot = x.Delivery.TimeSlot,
                Address = x.Delivery.DeliveryAddress,
                PostalCode = x.Delivery.PostalCode,
                CardMessage = x.Order.CardMessage,
                DeliveryPriority = x.Order.DeliveryPriority.ToString(),
                DeliveryFee = x.Order.DeliveryFee,
                TotalAmount = x.Order.TotalAmount,
                PaymentStatus = x.Order.PaymentStatus.ToString(),
                Status = x.Delivery.Status.ToString(),
                DeliveryPersonId = x.Delivery.DeliveryPersonId,
                DeliveryPersonName = x.DeliveryPersonName,
                ItemCount = itemInfo?.Count ?? 0,
                ItemsSummary = itemInfo?.Summary ?? string.Empty
            };
        }).ToList();

        return Ok(result);
    }

    /// <summary>
    /// Get available delivery drivers for the company.
    /// Accessible to staff/cashier role under CompanyOnly policy.
    /// </summary>
    [HttpGet("drivers")]
    public async Task<IActionResult> GetAvailableDrivers()
    {
        var staffList = await _db.Staff
            .Where(s => s.CompanyId == CompanyId && s.IsActive)
            .OrderBy(s => s.Name)
            .AsNoTracking()
            .ToListAsync();

        var drivers = staffList.Select(s => new DeliveryDriverOptionDto
        {
            Id = s.Id,
            Name = s.Name,
            Phone = s.Phone,
            Role = s.Role.ToString(),
            IsDeliveryRole = s.Role == StaffRole.Driver
        }).ToList();

        return Ok(drivers);
    }

    /// <summary>
    /// Mark a delivery as out for delivery.
    /// Requires an explicitly assigned driver.
    /// Uses authoritative domain state transitions and atomic transaction.
    /// </summary>
    [HttpPut("{id:guid}/out-for-delivery")]
    public async Task<IActionResult> MarkOutForDelivery(Guid id)
    {
        var delivery = await _deliveryRepo.GetByIdAsync(id);
        if (delivery == null || delivery.CompanyId != CompanyId)
            return NotFound(new { message = "Delivery not found" });

        var order = await _orderRepository.GetByIdAsync(CompanyId, delivery.SalesOrderId);
        if (order == null || order.CompanyId != CompanyId)
            return NotFound(new { message = "Linked order not found" });

        // Mandatory Rule 2: An unassigned delivery cannot be dispatched out; user must explicitly assign a driver first.
        if (!delivery.DeliveryPersonId.HasValue || delivery.DeliveryPersonId.Value == Guid.Empty)
        {
            return BadRequest(new { message = "A driver must be explicitly assigned to this delivery before dispatching out for delivery." });
        }

        var driverId = delivery.DeliveryPersonId.Value;

        var driverExists = await _db.Staff.AnyAsync(s => s.Id == driverId && s.CompanyId == CompanyId && s.IsActive);
        if (!driverExists)
        {
            return BadRequest(new { message = "Assigned driver is inactive or does not belong to this company." });
        }

        // Authoritative domain state transitions
        if (delivery.Status == DeliveryStatus.Delivered || delivery.Status == DeliveryStatus.SettlementCompleted)
            return BadRequest(new { message = "Cannot dispatch a delivery that has already been delivered." });

        if (delivery.Status == DeliveryStatus.Cancelled)
            return BadRequest(new { message = "Cannot dispatch a cancelled delivery." });

        if (delivery.Status == DeliveryStatus.OutForDelivery || delivery.Status == DeliveryStatus.ArrivedNearby)
            return Ok(new { message = "Delivery is already out for delivery." });

        // Advance Delivery entity through valid domain state machine
        if (delivery.Status == DeliveryStatus.Created || delivery.Status == DeliveryStatus.Scheduled)
        {
            delivery.AssignDeliveryPerson(driverId);
        }

        if (delivery.Status == DeliveryStatus.Assigned)
        {
            delivery.MarkAccepted(driverId);
        }

        if (delivery.Status == DeliveryStatus.Accepted)
        {
            delivery.MarkPickedUp();
        }

        if (delivery.Status == DeliveryStatus.PickedUp)
        {
            delivery.MarkOutForDelivery();
        }

        if (delivery.Status != DeliveryStatus.OutForDelivery)
        {
            return BadRequest(new { message = $"Unexpected delivery status '{delivery.Status}'. Cannot dispatch." });
        }

        // Advance Order entity through valid domain state machine
        if (order.Status == OrderStatus.Cancelled || order.Status == OrderStatus.Delivered)
            return BadRequest(new { message = $"Cannot dispatch order in '{order.Status}' status." });

        if (order.Status == OrderStatus.Pending)
        {
            order.Confirm();
        }

        if (order.Status == OrderStatus.Confirmed)
        {
            order.StartProcessing();
        }

        if (order.Status == OrderStatus.Processing)
        {
            order.MarkReadyForDelivery();
        }

        if (order.Status == OrderStatus.ReadyForDelivery)
        {
            order.MarkOutForDelivery();
        }

        if (order.Status != OrderStatus.OutForDelivery)
        {
            return BadRequest(new { message = $"Unexpected order status '{order.Status}'. Cannot dispatch." });
        }

        // Atomic transaction save
        await _unitOfWork.ExecuteInTransactionAsync(async () =>
        {
            await _deliveryRepo.UpdateAsync(delivery);
            await _orderRepository.UpdateAsync(order);
        });

        return Ok(new { message = "Delivery marked as out for delivery" });
    }

    /// <summary>
    /// Mark a delivery as delivered.
    /// Atomically updates delivery status, order status, and consumes inventory via Design 2.
    /// </summary>
    [HttpPut("{id:guid}/delivered")]
    public async Task<IActionResult> MarkDelivered(Guid id)
    {
        var delivery = await _deliveryRepo.GetByIdAsync(id);
        if (delivery == null || delivery.CompanyId != CompanyId)
            return NotFound(new { message = "Delivery not found" });

        var order = await _orderRepository.GetByIdAsync(CompanyId, delivery.SalesOrderId);
        if (order == null || order.CompanyId != CompanyId)
            return NotFound(new { message = "Linked order not found" });

        if (delivery.Status == DeliveryStatus.Delivered)
            return Ok(new { message = "Delivery is already marked as delivered." });

        if (delivery.Status == DeliveryStatus.Cancelled || delivery.Status == DeliveryStatus.SettlementCompleted)
            return BadRequest(new { message = $"Cannot deliver from status '{delivery.Status}'." });

        if (delivery.Status == DeliveryStatus.Created || delivery.Status == DeliveryStatus.Scheduled)
            return BadRequest(new { message = "Delivery must be assigned and dispatched out for delivery before marking as delivered." });

        // Advance Delivery entity through valid domain state machine
        if (delivery.Status == DeliveryStatus.Assigned && delivery.DeliveryPersonId.HasValue)
        {
            delivery.MarkAccepted(delivery.DeliveryPersonId.Value);
        }

        if (delivery.Status == DeliveryStatus.Accepted)
        {
            delivery.MarkPickedUp();
        }

        if (delivery.Status == DeliveryStatus.PickedUp)
        {
            delivery.MarkOutForDelivery();
        }

        if (delivery.Status == DeliveryStatus.OutForDelivery || delivery.Status == DeliveryStatus.ArrivedNearby)
        {
            delivery.MarkDelivered();
        }
        else
        {
            return BadRequest(new { message = $"Unexpected delivery status '{delivery.Status}'. Cannot deliver." });
        }

        // Advance Order entity
        if (order.Status != OrderStatus.Delivered)
        {
            order.MarkDeliveredDirect();
        }

        // Atomic transaction: delivery update + order update + inventory consumption
        await _unitOfWork.ExecuteInTransactionAsync(async () =>
        {
            await _deliveryRepo.UpdateAsync(delivery);
            await _orderRepository.UpdateAsync(order);

            if (!order.IsInventoryProcessed)
            {
                await _orderService.ConsumeInventoryForOrderAsync(CompanyId, order);
            }
        });

        return Ok(new { message = "Delivery marked as delivered successfully" });
    }

    /// <summary>
    /// Assign a delivery person to a delivery.
    /// Synchronizes both Delivery and Order records.
    /// </summary>
    [HttpPut("{id:guid}/assign")]
    public async Task<IActionResult> AssignDeliveryPerson(Guid id, [FromBody] AssignDriverRequest request)
    {
        if (request.StaffId == Guid.Empty)
            return BadRequest(new { message = "Valid staff member must be selected." });

        var delivery = await _deliveryRepo.GetByIdAsync(id);
        if (delivery == null || delivery.CompanyId != CompanyId)
            return NotFound(new { message = "Delivery not found" });

        var staff = await _db.Staff.FirstOrDefaultAsync(s => s.Id == request.StaffId && s.CompanyId == CompanyId && s.IsActive);
        if (staff == null)
            return BadRequest(new { message = "Selected delivery staff not found or inactive in this company." });

        try
        {
            await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                await _assignHandler.HandleAsync(new AssignDeliveryPersonCommand(id, request.StaffId));

                // Synchronize Order's DeliveryPersonId if order exists
                var order = await _orderRepository.GetByIdAsync(CompanyId, delivery.SalesOrderId);
                if (order != null)
                {
                    order.AssignDeliveryPerson(request.StaffId);
                    await _orderRepository.UpdateAsync(order);
                }
            });

            return Ok(new { message = "Delivery person assigned successfully", driverName = staff.Name });
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
    public Guid OrderId { get; set; }
    public string OrderNumber { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string RecipientName { get; set; } = string.Empty;
    public string? RecipientPhone { get; set; }
    public DateTime DeliveryDate { get; set; }
    public string TimeSlot { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public string? PostalCode { get; set; }
    public string? CardMessage { get; set; }
    public string DeliveryPriority { get; set; } = "Standard";
    public decimal DeliveryFee { get; set; }
    public decimal TotalAmount { get; set; }
    public string PaymentStatus { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public Guid? DeliveryPersonId { get; set; }
    public string? DeliveryPersonName { get; set; }
    public int ItemCount { get; set; }
    public string ItemsSummary { get; set; } = string.Empty;
}

public class AssignDriverRequest
{
    public Guid StaffId { get; set; }
}

public class DeliveryDriverOptionDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string Role { get; set; } = string.Empty;
    public bool IsDeliveryRole { get; set; }
}

