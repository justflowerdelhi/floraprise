using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Mvc;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Sumpooj.API.Services.Mobile;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Mobile;

namespace Sumpooj.API.Controllers.Mobile;

[Route("api/v1/mobile/payment")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme, Policy = PolicyNames.CompanyOnly)]
public sealed class MobilePaymentController : MobileApiControllerBase
{
    private readonly IMobileClientService _mobileClientService;
    private readonly IConfiguration _configuration;

    public MobilePaymentController(IMobileClientService mobileClientService, ITenantContext tenantContext, IConfiguration configuration)
        : base(tenantContext)
    {
        _mobileClientService = mobileClientService;
        _configuration = configuration;
    }

    /// <summary>
    /// Creates a subscription payment order with the selected gateway.
    /// </summary>
    /// <remarks>
    /// Request example:
    /// { "gateway": 1, "subscriptionId": "00000000-0000-0000-0000-000000000011", "amount": 999.00, "currency": "INR", "planCode": "PRO", "billingCycle": "monthly" }
    /// </remarks>
    [HttpPost("subscription-order", Name = "MobilePayment_CreateSubscriptionOrder")]
    [ProducesResponseType(typeof(CreateSubscriptionOrderResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> CreateSubscriptionOrder([FromBody] CreateSubscriptionOrderRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var response = await _mobileClientService.CreateSubscriptionOrderAsync(GetCompanyId(), GetMobileUserId(), request, cancellationToken);
            return Ok(response);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    /// <summary>
    /// Processes payment callback sent by the mobile payment gateway.
    /// </summary>
    [HttpPost("callback", Name = "MobilePayment_Callback")]
    [ProducesResponseType(typeof(PaymentCallbackResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> Callback([FromBody] PaymentCallbackRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var response = await _mobileClientService.PaymentCallbackAsync(GetCompanyId(), GetMobileUserId(), request, cancellationToken);
            return Ok(response);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    /// <summary>
    /// Verifies payment integrity and updates transaction status.
    /// </summary>
    [HttpPost("verify", Name = "MobilePayment_Verify")]
    [ProducesResponseType(typeof(PaymentVerificationResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> Verify([FromBody] PaymentVerificationRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var response = await _mobileClientService.VerifyPaymentAsync(GetCompanyId(), GetMobileUserId(), request, cancellationToken);
            return Ok(response);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    /// <summary>
    /// Handles Razorpay webhook notifications for mobile subscription payments.
    /// </summary>
    [AllowAnonymous]
    [HttpPost("webhook", Name = "MobilePayment_Webhook")]
    [ProducesResponseType(typeof(PaymentCallbackResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> Webhook(CancellationToken cancellationToken)
    {
        try
        {
            using var reader = new StreamReader(Request.Body, Encoding.UTF8);
            var rawBody = await reader.ReadToEndAsync(cancellationToken);
            var signature = Request.Headers["X-Razorpay-Signature"].FirstOrDefault();
            var webhookSecret = _configuration["Razorpay:WebhookSecret"];

            if (string.IsNullOrWhiteSpace(signature) || string.IsNullOrWhiteSpace(webhookSecret))
                return Unauthorized();

            using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(webhookSecret));
            var computed = Convert.ToHexString(hmac.ComputeHash(Encoding.UTF8.GetBytes(rawBody))).ToLowerInvariant();
            if (!string.Equals(computed, signature.Trim().ToLowerInvariant(), StringComparison.Ordinal))
                return Unauthorized();

            using var doc = JsonDocument.Parse(rawBody);
            var root = doc.RootElement;
            var eventName = root.TryGetProperty("event", out var eventNode) ? eventNode.GetString() ?? string.Empty : string.Empty;

            var payload = root.GetProperty("payload").GetProperty("payment").GetProperty("entity");
            var gatewayOrderId = payload.TryGetProperty("order_id", out var orderNode) ? orderNode.GetString() ?? string.Empty : string.Empty;
            var gatewayPaymentId = payload.TryGetProperty("id", out var paymentNode) ? paymentNode.GetString() : null;
            var paymentStatus = payload.TryGetProperty("status", out var statusNode) ? statusNode.GetString() ?? string.Empty : string.Empty;

            string? planCode = null;
            string? billingCycle = null;
            if (payload.TryGetProperty("notes", out var notesNode) && notesNode.ValueKind == JsonValueKind.Object)
            {
                if (notesNode.TryGetProperty("planCode", out var planNode))
                    planCode = planNode.GetString();
                if (notesNode.TryGetProperty("billingCycle", out var cycleNode))
                    billingCycle = cycleNode.GetString();
            }

            var normalizedStatus = eventName switch
            {
                "payment.captured" => "paid",
                "payment.authorized" => "pending",
                "payment.failed" => "failed",
                "refund.processed" => "refunded",
                _ => paymentStatus
            };

            var callbackRequest = new PaymentCallbackRequest(
                Gateway: MobilePaymentGatewayType.Razorpay,
                TransactionRef: string.Empty,
                GatewayOrderId: gatewayOrderId,
                GatewayPaymentId: gatewayPaymentId,
                Status: normalizedStatus,
                Signature: signature,
                PlanCode: planCode,
                BillingCycle: billingCycle,
                Metadata: null);

            // The callback service resolves the transaction by gateway order id when transactionRef is not supplied.
            var response = await _mobileClientService.PaymentCallbackAsync(
                companyId: GetCompanyIdOrEmpty(),
                mobileUserId: Guid.Empty,
                request: callbackRequest,
                cancellationToken: cancellationToken);

            return Ok(response);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    private Guid GetCompanyIdOrEmpty()
    {
        var raw = RouteData.Values["companyId"]?.ToString();
        return Guid.TryParse(raw, out var companyId) ? companyId : Guid.Empty;
    }

    /// <summary>
    /// Returns payment history for the authenticated mobile user.
    /// </summary>
    [HttpGet("history", Name = "MobilePayment_History")]
    [ProducesResponseType(typeof(List<MobilePaymentHistoryItem>), StatusCodes.Status200OK)]
    public async Task<IActionResult> History(CancellationToken cancellationToken)
    {
        try
        {
            var response = await _mobileClientService.GetPaymentHistoryAsync(GetCompanyId(), GetMobileUserId(), cancellationToken);
            return Ok(response);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }
}