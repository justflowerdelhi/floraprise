using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Deliveries;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.UseCases;
using Sumpooj.Domain.Entities;

namespace Sumpooj.API.Controllers;

[Route("api/phone-orders")]
[ApiController]
[Authorize(Policy = "CompanyOnly")]
public class PhoneOrdersController : ControllerBase
{
    private readonly IOrderRepository _orderRepository;
    private readonly ICustomerRepository _customerRepository;
    private readonly IPaymentRepository _paymentRepository;
    private readonly ScheduleDeliveryHandler _scheduleDeliveryHandler;
    private readonly ITenantContext _tenantContext;

    public PhoneOrdersController(
        IOrderRepository orderRepository,
        ICustomerRepository customerRepository,
        IPaymentRepository paymentRepository,
        ScheduleDeliveryHandler scheduleDeliveryHandler,
        ITenantContext tenantContext)
    {
        _orderRepository = orderRepository;
        _customerRepository = customerRepository;
        _paymentRepository = paymentRepository;
        _scheduleDeliveryHandler = scheduleDeliveryHandler;
        _tenantContext = tenantContext;
    }

    private Guid CompanyId => _tenantContext.CompanyId
        ?? throw new UnauthorizedAccessException("Company context required");

    [HttpPost]
    public async Task<IActionResult> CreatePhoneOrder([FromBody] CreatePhoneOrderRequest request)
    {
        var companyId = CompanyId;

        // Resolve or create customer
        Guid customerId;
        string customerName;
        if (request.CustomerId.HasValue && request.CustomerId.Value != Guid.Empty)
        {
            var existing = await _customerRepository.GetByIdAsync(request.CustomerId.Value);
            if (existing == null) return BadRequest(new { message = "Customer not found" });
            customerId = existing.Id;
            customerName = existing.Name;
        }
        else
        {
            var name = request.CustomerName ?? "Phone Customer";
            var customer = new Customer(companyId, name, null, request.PhoneNumber);
            await _customerRepository.AddAsync(customer);
            customerId = customer.Id;
            customerName = name;
        }

        // Parse delivery date
        DateTime deliveryDate;
        if (!string.IsNullOrEmpty(request.DeliveryDate) && DateTime.TryParse(request.DeliveryDate, out var parsed))
            deliveryDate = DateTime.SpecifyKind(parsed, DateTimeKind.Utc);
        else
            deliveryDate = DateTime.UtcNow;

        // Create Order with Phone source
        var order = new Order(
            companyId,
            customerId,
            deliveryDate,
            request.DeliveryCity,
            null,
            null);

        // Map order type
        if (!Enum.TryParse<OrderType>(request.OrderType, true, out var orderType))
            orderType = OrderType.PhoneLocal;

        order.SetOrderSource(OrderSource.Phone);
        order.SetOrderType(orderType);

        if (!string.IsNullOrEmpty(request.TimeSlot))
            order.SetTimeSlot(request.TimeSlot);

        if (!string.IsNullOrEmpty(request.SpecialInstructions))
            order.AddInternalNote(request.SpecialInstructions);

        // Add line items
        if (request.Items.Count > 0)
        {
            foreach (var item in request.Items)
            {
                order.AddItem(
                    item.ProductId ?? Guid.Empty,
                    item.Description,
                    item.Quantity > 0 ? item.Quantity : 1,
                    item.UnitPrice);
            }
        }
        else if (request.Budget.HasValue && request.Budget.Value > 0)
        {
            // Fallback: use budget as a single line item
            order.AddItem(Guid.Empty, request.SpecialInstructions ?? "Phone Order", 1, request.Budget.Value);
        }

        // Set delivery charge
        if (request.DeliveryCharge > 0)
            order.SetDeliveryFee(request.DeliveryCharge);

        await _orderRepository.AddAsync(order);

        return CreatedAtAction(nameof(GetPhoneOrder), new { id = order.Id }, BuildPhoneOrderResponse(order, customerName, request.DeliveryCity, request.TimeSlot, request.Occasion, request.Budget));
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetPhoneOrder(Guid id)
    {
        var order = await _orderRepository.GetByIdAsync(CompanyId, id);
        if (order == null) return NotFound(new { message = "Order not found" });

        var customer = await _customerRepository.GetByIdAsync(order.CustomerId);

        return Ok(BuildPhoneOrderResponse(order, customer?.Name, order.DeliveryAddress, order.TimeSlot, null, null));
    }

    [HttpGet]
    public async Task<IActionResult> GetPhoneOrders(
        [FromQuery] string? status,
        [FromQuery] string? type)
    {
        // Get today's phone orders
        var allOrders = await _orderRepository.GetTodaysOrdersAsync(CompanyId);

        // Filter to phone orders only
        var dayStart = DateTime.SpecifyKind(DateTime.UtcNow.Date, DateTimeKind.Utc);
        var dayEnd = dayStart.AddDays(1);
        var orders = await _orderRepository.GetByIdsAsync(CompanyId, allOrders
            .Where(o => o.OrderSource == "Phone")
            .Select(o => o.Id).ToList());

        var query = orders.AsQueryable();

        if (!string.IsNullOrEmpty(type) && Enum.TryParse<OrderType>(type, true, out var orderType))
        {
            query = query.Where(o => o.OrderType == orderType);
        }

        if (!string.IsNullOrEmpty(status) && Enum.TryParse<OrderStatus>(status, true, out var orderStatus))
        {
            query = query.Where(o => o.Status == orderStatus);
        }

        var result = query.Select(o => new
        {
            o.Id,
            o.CompanyId,
            o.CustomerId,
            CustomerName = o.Customer != null ? o.Customer.Name : "",
            o.OrderNumber,
            OrderType = o.OrderType.ToString(),
            Status = o.Status.ToString(),
            o.DeliveryDate,
            DeliveryCity = o.DeliveryAddress,
            o.TimeSlot,
            Occasion = (string?)null,
            Budget = (decimal?)null,
            Items = o.Items.Select(i => new
            {
                i.Id,
                i.ProductId,
                i.ProductName,
                i.Quantity,
                i.UnitPrice,
                TotalPrice = i.Quantity * i.UnitPrice
            }).ToList(),
            o.CreatedAtUtc,
            o.UpdatedAtUtc
        }).ToList();

        return Ok(result);
    }

    [HttpGet("{id:guid}/invoice")]
    public async Task<IActionResult> GetInvoice(Guid id)
    {
        var order = await _orderRepository.GetByIdAsync(CompanyId, id);
        if (order == null)
            return NotFound(new { message = "Order not found" });

        // Generate invoice number if not set
        if (string.IsNullOrEmpty(order.InvoiceNumber))
        {
            order.SetInvoiceNumber(Order.GenerateInvoiceNumber());
            await _orderRepository.UpdateAsync(order);
        }

        var customer = await _customerRepository.GetByIdAsync(order.CustomerId);
        var paidAmount = await _paymentRepository.GetTotalPaidForOrderAsync(order.Id);

        var items = order.Items.Select(i => new InvoiceItemDto
        {
            Description = i.ProductName,
            Quantity = i.Quantity,
            UnitPrice = i.UnitPrice,
            Total = i.TotalPrice
        }).ToList();

        var invoice = new InvoiceDto
        {
            InvoiceNumber = order.InvoiceNumber!,
            OrderNumber = order.OrderNumber,
            CustomerName = customer?.Name ?? "Unknown",
            Phone = customer?.Phone,
            DeliveryDate = order.DeliveryDate,
            OrderType = order.OrderType.ToString(),
            Items = items,
            Subtotal = order.SubTotal,
            DeliveryCharge = order.DeliveryFee,
            Discount = order.DiscountAmount,
            Total = order.TotalAmount,
            PaidAmount = paidAmount,
            Balance = order.TotalAmount - paidAmount
        };

        return Ok(invoice);
    }

    [HttpGet("dashboard-summary")]
    public async Task<IActionResult> GetDashboardSummary()
    {
        var todayOrders = await _orderRepository.GetTodaysOrderCountAsync(CompanyId);
        var todayRevenue = await _paymentRepository.GetTodayTotalAsync();

        // Get phone orders for production/delivery stats
        var allToday = await _orderRepository.GetTodaysOrdersAsync(CompanyId);
        var phoneOrders = await _orderRepository.GetByIdsAsync(CompanyId,
            allToday.Where(o => o.OrderSource == "Phone").Select(o => o.Id).ToList());

        var pendingProduction = phoneOrders.Count(o =>
            o.OrderType == OrderType.PhoneLocal &&
            o.Status == OrderStatus.Confirmed);

        var pendingDelivery = phoneOrders.Count(o => o.Status == OrderStatus.Processing);

        return Ok(new DashboardSummaryDto
        {
            TodayOrders = todayOrders,
            PendingProduction = pendingProduction,
            PendingDelivery = pendingDelivery,
            TodayRevenue = todayRevenue
        });
    }

    [HttpPost("{id:guid}/schedule-delivery")]
    public async Task<IActionResult> ScheduleDelivery(Guid id, [FromBody] ScheduleDeliveryRequest request)
    {
        var command = new ScheduleDeliveryCommand(
            SalesOrderId: id,
            DeliveryDate: request.DeliveryDate,
            TimeSlot: request.TimeSlot,
            Address: request.Address);

        await _scheduleDeliveryHandler.HandleAsync(command);

        return Ok(new { message = "Delivery scheduled successfully" });
    }

    [HttpPost("{id:guid}/items")]
    public async Task<IActionResult> AddItem(Guid id, [FromBody] AddItemRequest request)
    {
        var order = await _orderRepository.GetByIdAsync(CompanyId, id);
        if (order == null) return NotFound(new { message = "Order not found" });

        order.AddItem(request.ProductId, request.ProductName ?? "Product", request.Quantity, request.UnitPrice);
        await _orderRepository.UpdateAsync(order);

        var customer = await _customerRepository.GetByIdAsync(order.CustomerId);
        return Ok(BuildPhoneOrderResponse(order, customer?.Name, order.DeliveryAddress, order.TimeSlot, null, null));
    }

    [HttpPost("{id:guid}/confirm-local")]
    public async Task<IActionResult> ConfirmLocal(Guid id)
    {
        var order = await _orderRepository.GetByIdAsync(CompanyId, id);
        if (order == null) return NotFound(new { message = "Order not found" });

        order.Confirm();
        await _orderRepository.UpdateAsync(order);

        var customer = await _customerRepository.GetByIdAsync(order.CustomerId);
        return Ok(BuildPhoneOrderResponse(order, customer?.Name, order.DeliveryAddress, order.TimeSlot, null, null));
    }

    [HttpPost("{id:guid}/confirm-outstation")]
    public async Task<IActionResult> ConfirmOutstation(Guid id)
    {
        var order = await _orderRepository.GetByIdAsync(CompanyId, id);
        if (order == null) return NotFound(new { message = "Order not found" });

        order.Confirm();
        await _orderRepository.UpdateAsync(order);

        return Ok(new { orderId = order.Id.ToString(), vendorExecutionId = Guid.NewGuid().ToString() });
    }

    [HttpPost("{id:guid}/start-production")]
    public async Task<IActionResult> StartProduction(Guid id)
    {
        var order = await _orderRepository.GetByIdAsync(CompanyId, id);
        if (order == null) return NotFound(new { message = "Order not found" });

        order.StartProcessing();
        await _orderRepository.UpdateAsync(order);

        var customer = await _customerRepository.GetByIdAsync(order.CustomerId);
        return Ok(BuildPhoneOrderResponse(order, customer?.Name, order.DeliveryAddress, order.TimeSlot, null, null));
    }

    [HttpPost("{id:guid}/cancel")]
    public async Task<IActionResult> CancelOrder(Guid id)
    {
        var order = await _orderRepository.GetByIdAsync(CompanyId, id);
        if (order == null) return NotFound(new { message = "Order not found" });

        order.Cancel(null);
        await _orderRepository.UpdateAsync(order);

        var customer = await _customerRepository.GetByIdAsync(order.CustomerId);
        return Ok(BuildPhoneOrderResponse(order, customer?.Name, order.DeliveryAddress, order.TimeSlot, null, null));
    }

    private static PhoneOrderResponse BuildPhoneOrderResponse(Order order, string? customerName, string? deliveryCity, string? timeSlot, string? occasion, decimal? budget)
    {
        return new PhoneOrderResponse
        {
            Id = order.Id.ToString(),
            CompanyId = order.CompanyId.ToString(),
            CustomerId = order.CustomerId.ToString(),
            CustomerName = customerName,
            OrderNumber = order.OrderNumber,
            OrderType = order.OrderType.ToString(),
            Status = order.Status.ToString(),
            DeliveryDate = order.DeliveryDate.ToString("O"),
            DeliveryCity = deliveryCity ?? "",
            TimeSlot = timeSlot,
            Occasion = occasion,
            Budget = budget,
            Items = order.Items.Select(i => new PhoneOrderItemResponse
            {
                Id = i.Id.ToString(),
                ProductId = i.ProductId.ToString(),
                ProductName = i.ProductName,
                Quantity = i.Quantity,
                UnitPrice = i.UnitPrice,
                TotalPrice = i.TotalPrice,
            }).ToList(),
            CreatedAtUtc = order.CreatedAtUtc.ToString("O"),
            UpdatedAtUtc = order.UpdatedAtUtc?.ToString("O"),
        };
    }
}

public class ScheduleDeliveryRequest
{
    public DateTime DeliveryDate { get; set; }
    public string TimeSlot { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
}

public class DashboardSummaryDto
{
    public int TodayOrders { get; set; }
    public int PendingProduction { get; set; }
    public int PendingDelivery { get; set; }
    public decimal TodayRevenue { get; set; }
}

public class InvoiceDto
{
    public string InvoiceNumber { get; set; } = string.Empty;
    public string OrderNumber { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public DateTime? DeliveryDate { get; set; }
    public string OrderType { get; set; } = string.Empty;
    public List<InvoiceItemDto> Items { get; set; } = new();
    public decimal Subtotal { get; set; }
    public decimal DeliveryCharge { get; set; }
    public decimal Discount { get; set; }
    public decimal Total { get; set; }
    public decimal PaidAmount { get; set; }
    public decimal Balance { get; set; }
}

public class InvoiceItemDto
{
    public string Description { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal Total { get; set; }
}

public class CreatePhoneOrderRequest
{
    public string? CustomerName { get; set; }
    public string? PhoneNumber { get; set; }
    public Guid? CustomerId { get; set; }
    public string OrderType { get; set; } = "PhoneLocal";
    public string? DeliveryDate { get; set; }
    public string? DeliveryCity { get; set; }
    public string? TimeSlot { get; set; }
    public string? Occasion { get; set; }
    public decimal? Budget { get; set; }
    public string? SpecialInstructions { get; set; }
    public decimal DeliveryCharge { get; set; }
    public List<PhoneOrderItemRequest> Items { get; set; } = new();
}

public class PhoneOrderItemRequest
{
    public Guid? ProductId { get; set; }
    public string Description { get; set; } = "Phone Order";
    public int Quantity { get; set; } = 1;
    public decimal UnitPrice { get; set; }
}

public class AddItemRequest
{
    public Guid ProductId { get; set; }
    public string? ProductName { get; set; }
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
}

public class PhoneOrderResponse
{
    public string Id { get; set; } = string.Empty;
    public string CompanyId { get; set; } = string.Empty;
    public string CustomerId { get; set; } = string.Empty;
    public string? CustomerName { get; set; }
    public string OrderNumber { get; set; } = string.Empty;
    public string OrderType { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string DeliveryDate { get; set; } = string.Empty;
    public string DeliveryCity { get; set; } = string.Empty;
    public string? TimeSlot { get; set; }
    public string? Occasion { get; set; }
    public decimal? Budget { get; set; }
    public List<PhoneOrderItemResponse> Items { get; set; } = new();
    public string CreatedAtUtc { get; set; } = string.Empty;
    public string? UpdatedAtUtc { get; set; }
}

public class PhoneOrderItemResponse
{
    public string Id { get; set; } = string.Empty;
    public string ProductId { get; set; } = string.Empty;
    public string ProductName { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal TotalPrice { get; set; }
}
