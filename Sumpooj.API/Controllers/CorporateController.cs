using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Corporate;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.UseCases;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/corporate")]
[Authorize(Policy = PolicyNames.CompanyOnly)]
public class CorporateController : ControllerBase
{
    private readonly CorporateService _service;
    private readonly ITenantContext _tenant;

    public CorporateController(CorporateService service, ITenantContext tenant)
    {
        _service = service;
        _tenant = tenant;
    }

    private Guid CompanyId => _tenant.CompanyId ?? throw new UnauthorizedAccessException("Company context required");

    [HttpGet("clients")]
    public async Task<IActionResult> SearchClients([FromQuery] string? query, [FromQuery] bool? isActive, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var result = await _service.SearchClientsAsync(CompanyId, query, isActive, page, pageSize);
        return Ok(result);
    }

    [HttpPost("clients")]
    public async Task<IActionResult> CreateClient([FromBody] CreateCorporateClientRequest request)
    {
        var created = await _service.CreateClientAsync(CompanyId, request);
        return Ok(created);
    }

    [HttpGet("clients/{clientId:guid}/employees")]
    public async Task<IActionResult> GetEmployees(Guid clientId, [FromQuery] bool activeOnly = false)
    {
        var employees = await _service.GetEmployeesAsync(CompanyId, clientId, activeOnly);
        return Ok(employees);
    }

    [HttpPost("clients/{clientId:guid}/employees")]
    public async Task<IActionResult> AddEmployee(Guid clientId, [FromBody] CreateCorporateEmployeeRequest request)
    {
        var employee = await _service.AddEmployeeAsync(CompanyId, clientId, request);
        return Ok(employee);
    }

    [HttpPost("orders")]
    public async Task<IActionResult> CreateCorporateOrder([FromBody] CreateCorporateOrderRequest request)
    {
        var order = await _service.CreateCorporateOrderAsync(CompanyId, request);
        return Ok(order);
    }

    [HttpGet("orders/auto-created")]
    public async Task<IActionResult> GetAutoCreatedOrdersForApproval()
    {
        var orders = await _service.GetPendingApprovalOrdersAsync(CompanyId);
        return Ok(orders);
    }

    [HttpPost("orders/{orderId:guid}/approve")]
    public async Task<IActionResult> ApproveAutoOrder(Guid orderId)
    {
        await _service.ApproveAutoCreatedOrderAsync(CompanyId, orderId);
        return NoContent();
    }

    [HttpPost("orders/{orderId:guid}/cancel")]
    public async Task<IActionResult> CancelAutoOrder(Guid orderId, [FromBody] CancelAutoCorporateOrderRequest? request = null)
    {
        await _service.CancelAutoCreatedOrderAsync(CompanyId, orderId, request?.Reason);
        return NoContent();
    }

    [HttpPost("invoices/generate")]
    public async Task<IActionResult> GenerateInvoice([FromBody] GenerateCorporateInvoiceRequest request)
    {
        var invoice = await _service.GenerateMonthlyInvoiceAsync(CompanyId, request);
        return Ok(invoice);
    }

    [HttpGet("clients/{clientId:guid}/invoices")]
    public async Task<IActionResult> GetClientInvoices(Guid clientId)
    {
        var invoices = await _service.GetClientInvoicesAsync(CompanyId, clientId);
        return Ok(invoices);
    }

    [HttpPost("invoices/{invoiceId:guid}/payment")]
    public async Task<IActionResult> RecordInvoicePayment(Guid invoiceId, [FromBody] RecordCorporateInvoicePaymentRequest request)
    {
        await _service.RecordInvoicePaymentAsync(CompanyId, invoiceId, request);
        return NoContent();
    }

    [HttpPost("automation/birthdays/run")]
    [Authorize(Policy = PolicyNames.CompanyAdmin)]
    public async Task<IActionResult> RunBirthdayAutomation([FromQuery] DateTime? runDateUtc = null)
    {
        var result = await _service.RunBirthdayAutomationAsync(CompanyId, runDateUtc ?? DateTime.UtcNow);
        return Ok(result);
    }
}

public class CancelAutoCorporateOrderRequest
{
    public string? Reason { get; set; }
}
