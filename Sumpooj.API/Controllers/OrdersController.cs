using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Accounting;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Orders;
using Sumpooj.Application.UseCases;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = "CompanyOnly")]
public class OrdersController : ControllerBase
{
    private readonly OrderService _orderService;
    private readonly ITenantContext _tenantContext;

    public OrdersController(OrderService orderService, ITenantContext tenantContext)
    {
        _orderService = orderService;
        _tenantContext = tenantContext;
    }

    private Guid CompanyId => _tenantContext.CompanyId 
        ?? throw new UnauthorizedAccessException("Company context required");

    [HttpGet("search")]
    public async Task<IActionResult> Search([FromQuery] OrderSearchRequest request)
    {
        var result = await _orderService.SearchAsync(CompanyId, request);
        return Ok(result);
    }

    [HttpGet("today")]
    public async Task<IActionResult> GetTodaysOrders([FromQuery] Guid? locationId = null)
    {
        var orders = await _orderService.GetTodaysOrdersAsync(CompanyId, locationId);
        return Ok(orders);
    }

    [HttpGet("by-date/{date}")]
    public async Task<IActionResult> GetByDate(DateTime date)
    {
        var orders = await _orderService.GetByDeliveryDateAsync(CompanyId, date);
        return Ok(orders);
    }

    [HttpGet("by-customer/{customerId:guid}")]
    public async Task<IActionResult> GetByCustomer(Guid customerId)
    {
        var orders = await _orderService.GetByCustomerAsync(CompanyId, customerId);
        return Ok(orders);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var order = await _orderService.GetByIdAsync(CompanyId, id);
        return order == null ? NotFound() : Ok(order);
    }

    [HttpGet("by-number/{orderNumber}")]
    public async Task<IActionResult> GetByOrderNumber(string orderNumber)
    {
        var order = await _orderService.GetByOrderNumberAsync(CompanyId, orderNumber);
        return order == null ? NotFound() : Ok(order);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateOrderRequest request)
    {
        var id = await _orderService.CreateAsync(CompanyId, request);
        return CreatedAtAction(nameof(GetById), new { id }, new { id });
    }

    [HttpPatch("{id:guid}/status")]
    public async Task<IActionResult> UpdateStatus(Guid id, [FromBody] UpdateStatusRequest request)
    {
        await _orderService.UpdateStatusAsync(CompanyId, id, request.Status);
        return NoContent();
    }

    [HttpPatch("{id:guid}/fulfillment-status")]
    public async Task<IActionResult> UpdateFulfillmentStatus(Guid id, [FromBody] UpdateStatusRequest request)
    {
        await _orderService.UpdateFulfillmentStatusAsync(CompanyId, id, request.Status);
        return NoContent();
    }

    [HttpPost("{id:guid}/assign-designer")]
    public async Task<IActionResult> AssignDesigner(Guid id, [FromBody] AssignStaffRequest request)
    {
        await _orderService.AssignDesignerAsync(CompanyId, id, request.StaffId);
        return NoContent();
    }

    [HttpPost("{id:guid}/assign-driver")]
    public async Task<IActionResult> AssignDriver(Guid id, [FromBody] AssignStaffRequest request)
    {
        await _orderService.AssignDriverAsync(CompanyId, id, request.StaffId);
        return NoContent();
    }

    [HttpPost("{id:guid}/cancel")]
    public async Task<IActionResult> Cancel(Guid id, [FromBody] CancelOrderRequest? request = null)
    {
        await _orderService.CancelAsync(CompanyId, id, request?.Reason);
        return NoContent();
    }

    [HttpPost("manual-sale")]
    public async Task<IActionResult> ManualSale([FromBody] ManualSaleRequest request)
    {
        var orderId = await _orderService.CreateManualSaleAsync(CompanyId, request);
        return CreatedAtAction(nameof(GetById), new { id = orderId }, new { id = orderId });
    }
}

public class UpdateStatusRequest
{
    public string Status { get; set; } = default!;
}

public class AssignStaffRequest
{
    public Guid StaffId { get; set; }
}

public class CancelOrderRequest
{
    public string? Reason { get; set; }
}
