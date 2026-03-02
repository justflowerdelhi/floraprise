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
    private readonly ISalesOrderRepository _salesOrderRepository;
    private readonly ICustomerRepository _customerRepository;
    private readonly IPaymentRepository _paymentRepository;
    private readonly ScheduleDeliveryHandler _scheduleDeliveryHandler;
    private readonly ITenantContext _tenantContext;

    public PhoneOrdersController(
        ISalesOrderRepository salesOrderRepository,
        ICustomerRepository customerRepository,
        IPaymentRepository paymentRepository,
        ScheduleDeliveryHandler scheduleDeliveryHandler,
        ITenantContext tenantContext)
    {
        _salesOrderRepository = salesOrderRepository;
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

        // Map order type
        if (!Enum.TryParse<OrderType>(request.OrderType, true, out var orderType))
            orderType = OrderType.PhoneLocal;

        var order = new SalesOrder(
            companyId,
            customerId,
            orderType,
            request.DeliveryCity ?? "",
            null,
            request.DeliveryCity ?? "",
            "",
            null);

        await _salesOrderRepository.AddAsync(order);

        return CreatedAtAction(nameof(GetPhoneOrder), new { id = order.Id }, new PhoneOrderResponse
        {
            Id = order.Id.ToString(),
            CompanyId = companyId.ToString(),
            CustomerId = customerId.ToString(),
            CustomerName = customerName,
            OrderNumber = order.OrderNumber,
            OrderType = order.OrderType.ToString(),
            Status = order.Status.ToString(),
            DeliveryDate = request.DeliveryDate ?? "",
            DeliveryCity = request.DeliveryCity ?? "",
            TimeSlot = request.TimeSlot,
            Occasion = request.Occasion,
            Budget = request.Budget,
            Items = new List<PhoneOrderItemResponse>(),
            CreatedAtUtc = order.CreatedAtUtc.ToString("O"),
        });
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetPhoneOrder(Guid id)
    {
        var order = await _salesOrderRepository.GetByIdAsync(id);
        if (order == null) return NotFound(new { message = "Order not found" });

        var customer = await _customerRepository.GetByIdAsync(order.CustomerId);

        return Ok(new PhoneOrderResponse
        {
            Id = order.Id.ToString(),
            CompanyId = order.CompanyId.ToString(),
            CustomerId = order.CustomerId.ToString(),
            CustomerName = customer?.Name,
            OrderNumber = order.OrderNumber,
            OrderType = order.OrderType.ToString(),
            Status = order.Status.ToString(),
            DeliveryDate = "",
            DeliveryCity = order.City,
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
        });
    }

    [HttpGet]
    public async Task<IActionResult> GetPhoneOrders(
        [FromQuery] string? status,
        [FromQuery] string? type)
    {
        var orders = await _salesOrderRepository.GetAllAsync();

        var query = orders.AsQueryable();

        if (!string.IsNullOrEmpty(type))
        {
            query = query.Where(o => o.OrderType.ToString() == type);
        }

        if (!string.IsNullOrEmpty(status))
        {
            query = query.Where(o => o.Status.ToString() == status);
        }

        var result = query.Select(o => new
        {
            o.Id,
            o.CompanyId,
            o.CustomerId,
            CustomerName = o.CustomerId.ToString(), // replace later with real join
            o.OrderNumber,
            OrderType = o.OrderType.ToString(),
            Status = o.Status.ToString(),
            DeliveryDate = (DateTime?)null, // TODO: add to domain
            DeliveryCity = (string?)null,   // TODO: add to domain
            TimeSlot = (string?)null,       // TODO: add to domain
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
        var order = await _salesOrderRepository.GetByIdAsync(id);
        if (order == null)
            return NotFound(new { message = "Order not found" });

        // Generate invoice number if not set
        if (string.IsNullOrEmpty(order.InvoiceNumber))
        {
            order.SetInvoiceNumber(SalesOrder.GenerateInvoiceNumber());
            await _salesOrderRepository.UpdateAsync(order);
        }

        // Load customer
        var customer = await _customerRepository.GetByIdAsync(order.CustomerId);

        // Load payments
        var paidAmount = await _paymentRepository.GetTotalPaidForOrderAsync(order.Id);

        // Calculate totals from items
        var items = order.Items.Select(i => new InvoiceItemDto
        {
            Description = i.ProductName,
            Quantity = i.Quantity,
            UnitPrice = i.UnitPrice,
            Total = i.TotalPrice
        }).ToList();

        var subtotal = items.Sum(i => i.Total);
        decimal deliveryCharge = 0; // TODO: Add delivery charge to domain
        decimal discount = 0;       // TODO: Add discount to domain
        var total = subtotal + deliveryCharge - discount;
        var balance = total - paidAmount;

        var invoice = new InvoiceDto
        {
            InvoiceNumber = order.InvoiceNumber!,
            OrderNumber = order.OrderNumber,
            CustomerName = customer?.Name ?? "Unknown",
            Phone = customer?.Phone,
            DeliveryDate = null, // TODO: Add delivery date to domain
            OrderType = order.OrderType.ToString(),
            Items = items,
            Subtotal = subtotal,
            DeliveryCharge = deliveryCharge,
            Discount = discount,
            Total = total,
            PaidAmount = paidAmount,
            Balance = balance
        };

        return Ok(invoice);
    }

    [HttpGet("dashboard-summary")]
    public async Task<IActionResult> GetDashboardSummary()
    {
        var orders = await _salesOrderRepository.GetAllAsync();

        var today = DateTime.UtcNow.Date;

        // Today's orders: Count SalesOrders where CreatedDate = Today
        var todayOrders = orders.Count(o => o.CreatedAtUtc.Date == today);

        // Pending production: Count SalesOrders where Status = Confirmed AND OrderType = PhoneLocal
        var pendingProduction = orders.Count(o =>
            o.OrderType == OrderType.PhoneLocal &&
            o.Status == SalesOrderStatus.Confirmed);

        // Pending delivery: Count SalesOrders where Status = InProduction
        var pendingDelivery = orders.Count(o => o.Status == SalesOrderStatus.InProduction);

        // Today's revenue: Sum Payments where PaymentDate = Today
        var todayRevenue = await _paymentRepository.GetTodayTotalAsync();

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
        var order = await _salesOrderRepository.GetByIdAsync(id);
        if (order == null) return NotFound(new { message = "Order not found" });

        order.AddItem(request.ProductId, request.ProductName ?? "Product", request.Quantity, request.UnitPrice);
        await _salesOrderRepository.UpdateAsync(order);

        var customer = await _customerRepository.GetByIdAsync(order.CustomerId);
        return Ok(BuildPhoneOrderResponse(order, customer?.Name));
    }

    [HttpPost("{id:guid}/confirm-local")]
    public async Task<IActionResult> ConfirmLocal(Guid id)
    {
        var order = await _salesOrderRepository.GetByIdAsync(id);
        if (order == null) return NotFound(new { message = "Order not found" });

        order.Confirm();
        await _salesOrderRepository.UpdateAsync(order);

        var customer = await _customerRepository.GetByIdAsync(order.CustomerId);
        return Ok(BuildPhoneOrderResponse(order, customer?.Name));
    }

    [HttpPost("{id:guid}/confirm-outstation")]
    public async Task<IActionResult> ConfirmOutstation(Guid id)
    {
        var order = await _salesOrderRepository.GetByIdAsync(id);
        if (order == null) return NotFound(new { message = "Order not found" });

        order.Confirm();
        order.MarkSentToVendor();
        await _salesOrderRepository.UpdateAsync(order);

        return Ok(new { orderId = order.Id.ToString(), vendorExecutionId = Guid.NewGuid().ToString() });
    }

    [HttpPost("{id:guid}/start-production")]
    public async Task<IActionResult> StartProduction(Guid id)
    {
        var order = await _salesOrderRepository.GetByIdAsync(id);
        if (order == null) return NotFound(new { message = "Order not found" });

        order.MarkInProduction();
        await _salesOrderRepository.UpdateAsync(order);

        var customer = await _customerRepository.GetByIdAsync(order.CustomerId);
        return Ok(BuildPhoneOrderResponse(order, customer?.Name));
    }

    [HttpPost("{id:guid}/cancel")]
    public async Task<IActionResult> CancelOrder(Guid id)
    {
        var order = await _salesOrderRepository.GetByIdAsync(id);
        if (order == null) return NotFound(new { message = "Order not found" });

        order.Cancel();
        await _salesOrderRepository.UpdateAsync(order);

        var customer = await _customerRepository.GetByIdAsync(order.CustomerId);
        return Ok(BuildPhoneOrderResponse(order, customer?.Name));
    }

    private static PhoneOrderResponse BuildPhoneOrderResponse(SalesOrder order, string? customerName)
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
            DeliveryDate = "",
            DeliveryCity = order.City,
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
