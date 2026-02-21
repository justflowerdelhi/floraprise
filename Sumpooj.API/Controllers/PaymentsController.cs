using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Payments;
using Sumpooj.Application.UseCases;
using System.Security.Claims;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = "CompanyOnly")]
public class PaymentsController : ControllerBase
{
    private readonly PaymentService _paymentService;
    private readonly ITenantContext _tenantContext;

    public PaymentsController(PaymentService paymentService, ITenantContext tenantContext)
    {
        _paymentService = paymentService;
        _tenantContext = tenantContext;
    }

    private Guid CompanyId => _tenantContext.CompanyId 
        ?? throw new UnauthorizedAccessException("Company context required");

    private Guid UserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier) 
        ?? throw new UnauthorizedAccessException("User not found"));

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var payment = await _paymentService.GetByIdAsync(id);
        return payment == null ? NotFound() : Ok(payment);
    }

    [HttpGet("by-order/{orderId:guid}")]
    public async Task<IActionResult> GetByOrderId(Guid orderId)
    {
        var payments = await _paymentService.GetByOrderIdAsync(orderId);
        return Ok(payments);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreatePaymentRequest request)
    {
        var payment = await _paymentService.CreateAsync(CompanyId, request, UserId);
        return CreatedAtAction(nameof(GetById), new { id = payment.Id }, payment);
    }

    [HttpPatch("{id:guid}/approve")]
    public async Task<IActionResult> Approve(Guid id, [FromBody] ApprovePaymentRequest? request = null)
    {
        await _paymentService.ApproveAsync(id, request?.TransactionId, request?.AuthorizationCode);
        return NoContent();
    }

    [HttpPatch("{id:guid}/card-details")]
    public async Task<IActionResult> SetCardDetails(Guid id, [FromBody] CardDetailsRequest request)
    {
        await _paymentService.SetCardDetailsAsync(id, request.CardBrand, request.Last4);
        return NoContent();
    }

    [HttpPatch("{id:guid}/terminal-response")]
    public async Task<IActionResult> SetTerminalResponse(Guid id, [FromBody] TerminalResponseDto request)
    {
        await _paymentService.SetTerminalResponseAsync(id, request);
        return NoContent();
    }

    [HttpPatch("{id:guid}/decline")]
    public async Task<IActionResult> Decline(Guid id)
    {
        await _paymentService.DeclineAsync(id);
        return NoContent();
    }

    [HttpPatch("{id:guid}/void")]
    [Authorize(Policy = "CompanyAdmin")]
    public async Task<IActionResult> Void(Guid id)
    {
        await _paymentService.VoidAsync(id);
        return NoContent();
    }
}

public class ApprovePaymentRequest
{
    public string? TransactionId { get; set; }
    public string? AuthorizationCode { get; set; }
}

public class CardDetailsRequest
{
    public string CardBrand { get; set; } = default!;
    public string Last4 { get; set; } = default!;
}
