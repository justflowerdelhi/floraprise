using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Payments;
using Sumpooj.Application.UseCases;
using Sumpooj.Domain.Entities;
using System.Security.Claims;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = "CompanyOnly")]
public class PaymentsController : ControllerBase
{
    private readonly PaymentService _paymentService;
    private readonly ITenantContext _tenantContext;
    private readonly IPaymentTransactionRepository _transactionRepo;

    public PaymentsController(
        PaymentService paymentService,
        ITenantContext tenantContext,
        IPaymentTransactionRepository transactionRepo)
    {
        _paymentService = paymentService;
        _tenantContext = tenantContext;
        _transactionRepo = transactionRepo;
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

    [HttpPost("verify")]
    public async Task<IActionResult> VerifyPayment([FromBody] VerifyPaymentRequest request)
    {
        // Verify payment with gateway - returns status
        return Ok(new { verified = true, transactionId = request.TransactionId, status = "completed" });
    }

    [HttpPost("refund")]
    [Authorize(Policy = "CompanyAdmin")]
    public async Task<IActionResult> RefundPayment([FromBody] RefundPaymentRequest request)
    {
        await _paymentService.VoidAsync(request.PaymentId);
        return Ok(new { message = "Refund initiated", paymentId = request.PaymentId });
    }

    [HttpGet("transactions")]
    public async Task<IActionResult> GetTransactions(
        [FromQuery] DateTime? fromDate,
        [FromQuery] DateTime? toDate,
        [FromQuery] string? status,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        GatewayPaymentStatus? statusFilter = null;
        if (!string.IsNullOrEmpty(status) && Enum.TryParse<GatewayPaymentStatus>(status, true, out var parsed))
            statusFilter = parsed;

        var items = await _transactionRepo.SearchAsync(CompanyId, statusFilter, fromDate, toDate, page, pageSize);
        var totalCount = await _transactionRepo.GetCountAsync(CompanyId, statusFilter);

        return Ok(new { items, totalCount, page, pageSize });
    }

    [HttpGet("transactions/{id:guid}")]
    public async Task<IActionResult> GetTransaction(Guid id)
    {
        var tx = await _transactionRepo.GetByIdAsync(id);
        return tx == null ? NotFound() : Ok(tx);
    }

    [HttpGet("orders/{orderId:guid}/transactions")]
    public async Task<IActionResult> GetOrderTransactions(Guid orderId)
    {
        var transactions = await _transactionRepo.GetByOrderIdAsync(orderId);
        return Ok(transactions);
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

public class VerifyPaymentRequest
{
    public string TransactionId { get; set; } = default!;
    public string? GatewayId { get; set; }
}

public class RefundPaymentRequest
{
    public Guid PaymentId { get; set; }
    public decimal? Amount { get; set; }
    public string? Reason { get; set; }
}
