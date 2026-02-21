using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Common;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.UseCases;
using Sumpooj.Application.WireOrders;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/wire-orders")]
[Authorize(Policy = PolicyNames.CompanyOnly)]
public class WireOrdersController : ControllerBase
{
    private readonly WireOrderService _service;
    private readonly ITenantContext _tenant;

    public WireOrdersController(WireOrderService service, ITenantContext tenant)
    {
        _service = service;
        _tenant = tenant;
    }

    /// <summary>
    /// Search wire orders
    /// </summary>
    [HttpGet("search")]
    public async Task<ActionResult<PagedResult<WireOrderDto>>> Search([FromQuery] WireOrderSearchRequest request)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var result = await _service.SearchAsync(companyId, request);
        return Ok(result);
    }

    /// <summary>
    /// Get wire order by ID
    /// </summary>
    [HttpGet("{id:guid}")]
    public async Task<ActionResult<WireOrderDto>> GetById(Guid id)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var order = await _service.GetByIdAsync(companyId, id);
        return order == null ? NotFound() : Ok(order);
    }

    /// <summary>
    /// Get today's wire orders
    /// </summary>
    [HttpGet("today")]
    public async Task<ActionResult<List<WireOrderDto>>> GetTodaysOrders()
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var orders = await _service.GetTodaysOrdersAsync(companyId);
        return Ok(orders);
    }

    /// <summary>
    /// Get pending wire orders
    /// </summary>
    [HttpGet("pending")]
    public async Task<ActionResult<List<WireOrderDto>>> GetPendingOrders()
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var orders = await _service.GetPendingOrdersAsync(companyId);
        return Ok(orders);
    }

    /// <summary>
    /// Get wire order summary for date range
    /// </summary>
    [HttpGet("summary")]
    public async Task<ActionResult<WireOrderSummaryDto>> GetSummary(
        [FromQuery] DateTime? fromDate,
        [FromQuery] DateTime? toDate)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var from = fromDate ?? DateTime.UtcNow.AddDays(-30);
        var to = toDate ?? DateTime.UtcNow;
        var summary = await _service.GetSummaryAsync(companyId, from, to);
        return Ok(summary);
    }

    /// <summary>
    /// Create a new wire order
    /// </summary>
    [HttpPost]
    public async Task<ActionResult<WireOrderDto>> Create([FromBody] CreateWireOrderRequest request)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var order = await _service.CreateAsync(companyId, request);
        return CreatedAtAction(nameof(GetById), new { id = order.Id }, order);
    }

    /// <summary>
    /// Accept a wire order
    /// </summary>
    [HttpPost("{id:guid}/accept")]
    public async Task<ActionResult<WireOrderDto>> Accept(Guid id)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var order = await _service.AcceptAsync(companyId, id);
        return order == null ? NotFound() : Ok(order);
    }

    /// <summary>
    /// Start processing a wire order
    /// </summary>
    [HttpPost("{id:guid}/start-processing")]
    public async Task<ActionResult<WireOrderDto>> StartProcessing(Guid id)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var order = await _service.StartProcessingAsync(companyId, id);
        return order == null ? NotFound() : Ok(order);
    }

    /// <summary>
    /// Assign a wire order to a user
    /// </summary>
    [HttpPost("{id:guid}/assign")]
    public async Task<ActionResult<WireOrderDto>> Assign(Guid id, [FromBody] AssignRequest request)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var order = await _service.AssignAsync(companyId, id, request.UserId);
        return order == null ? NotFound() : Ok(order);
    }

    /// <summary>
    /// Set fulfillment cost for a wire order
    /// </summary>
    [HttpPatch("{id:guid}/fulfillment-cost")]
    public async Task<ActionResult<WireOrderDto>> SetFulfillmentCost(Guid id, [FromBody] FulfillmentCostRequest request)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var order = await _service.SetFulfillmentCostAsync(companyId, id, request.Cost);
        return order == null ? NotFound() : Ok(order);
    }

    /// <summary>
    /// Set substitution notes for a wire order
    /// </summary>
    [HttpPatch("{id:guid}/substitution-notes")]
    public async Task<ActionResult<WireOrderDto>> SetSubstitutionNotes(Guid id, [FromBody] SubstitutionNotesRequest request)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var order = await _service.SetSubstitutionNotesAsync(companyId, id, request.Notes);
        return order == null ? NotFound() : Ok(order);
    }

    /// <summary>
    /// Link wire order to an internal order
    /// </summary>
    [HttpPost("{id:guid}/link-order")]
    public async Task<ActionResult<WireOrderDto>> LinkToOrder(Guid id, [FromBody] LinkOrderRequest request)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var order = await _service.LinkToOrderAsync(companyId, id, request.OrderId);
        return order == null ? NotFound() : Ok(order);
    }

    /// <summary>
    /// Mark wire order as fulfilled
    /// </summary>
    [HttpPost("{id:guid}/fulfill")]
    public async Task<ActionResult<WireOrderDto>> MarkFulfilled(Guid id, [FromBody] FulfillRequest? request)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var order = await _service.MarkFulfilledAsync(companyId, id, request?.ConfirmationCode);
        return order == null ? NotFound() : Ok(order);
    }

    /// <summary>
    /// Reject a wire order
    /// </summary>
    [HttpPost("{id:guid}/reject")]
    public async Task<ActionResult<WireOrderDto>> Reject(Guid id, [FromBody] RejectRequest request)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var order = await _service.RejectAsync(companyId, id, request.Reason);
        return order == null ? NotFound() : Ok(order);
    }

    /// <summary>
    /// Cancel a wire order
    /// </summary>
    [HttpPost("{id:guid}/cancel")]
    public async Task<ActionResult<WireOrderDto>> Cancel(Guid id, [FromBody] CancelRequest request)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var order = await _service.CancelAsync(companyId, id, request.Reason);
        return order == null ? NotFound() : Ok(order);
    }
}

// Request DTOs
public record AssignRequest(Guid UserId);
public record FulfillmentCostRequest(decimal Cost);
public record SubstitutionNotesRequest(string Notes);
public record LinkOrderRequest(Guid OrderId);
public record FulfillRequest(string? ConfirmationCode);
public record RejectRequest(string Reason);
public record CancelRequest(string Reason);
