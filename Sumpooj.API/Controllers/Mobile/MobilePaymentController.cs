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
    private readonly ISubscriptionPaymentGatewayFactory _paymentGatewayFactory;

    public MobilePaymentController(
        IMobileClientService mobileClientService,
        ITenantContext tenantContext,
        IConfiguration configuration,
        ISubscriptionPaymentGatewayFactory paymentGatewayFactory)
        : base(tenantContext)
    {
        _mobileClientService = mobileClientService;
        _configuration = configuration;
        _paymentGatewayFactory = paymentGatewayFactory;
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

    /// <summary>
    /// Handles PayPal webhook notifications for mobile subscription payments.
    /// </summary>
    [AllowAnonymous]
    [HttpPost("webhook/paypal", Name = "MobilePayment_PayPalWebhook")]
    [ProducesResponseType(typeof(PaymentCallbackResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> PayPalWebhook(CancellationToken cancellationToken)
    {
        try
        {
            var authAlgo = Request.Headers["PAYPAL-AUTH-ALGO"].FirstOrDefault() ?? Request.Headers["paypal-auth-algo"].FirstOrDefault();
            var certUrl = Request.Headers["PAYPAL-CERT-URL"].FirstOrDefault() ?? Request.Headers["paypal-cert-url"].FirstOrDefault();
            var transmissionId = Request.Headers["PAYPAL-TRANSMISSION-ID"].FirstOrDefault() ?? Request.Headers["paypal-transmission-id"].FirstOrDefault();
            var transmissionSig = Request.Headers["PAYPAL-TRANSMISSION-SIG"].FirstOrDefault() ?? Request.Headers["paypal-transmission-sig"].FirstOrDefault();
            var transmissionTime = Request.Headers["PAYPAL-TRANSMISSION-TIME"].FirstOrDefault() ?? Request.Headers["paypal-transmission-time"].FirstOrDefault();

            if (string.IsNullOrWhiteSpace(authAlgo) ||
                string.IsNullOrWhiteSpace(certUrl) ||
                string.IsNullOrWhiteSpace(transmissionId) ||
                string.IsNullOrWhiteSpace(transmissionSig) ||
                string.IsNullOrWhiteSpace(transmissionTime))
            {
                return Unauthorized();
            }

            using var reader = new StreamReader(Request.Body, Encoding.UTF8);
            var rawBody = await reader.ReadToEndAsync(cancellationToken);

            if (string.IsNullOrWhiteSpace(rawBody))
                return BadRequest();

            var paypalGateway = _paymentGatewayFactory.Resolve(MobilePaymentGatewayType.PayPal) as PayPalSubscriptionPaymentGateway;
            if (paypalGateway == null)
                return Unauthorized();

            var isSignatureValid = await paypalGateway.VerifyWebhookSignatureAsync(
                rawBody,
                authAlgo,
                certUrl,
                transmissionId,
                transmissionSig,
                transmissionTime,
                cancellationToken);

            if (!isSignatureValid)
                return Unauthorized();

            using var doc = JsonDocument.Parse(rawBody);
            var root = doc.RootElement;
            var eventType = root.TryGetProperty("event_type", out var typeNode) ? typeNode.GetString() ?? string.Empty : string.Empty;

            var resource = root.TryGetProperty("resource", out var resNode) ? resNode : default;
            var gatewayOrderId = string.Empty;
            var gatewayPaymentId = string.Empty;

            if (resource.ValueKind == JsonValueKind.Object)
            {
                // For checkout order events, resource.id is the order ID
                if (resource.TryGetProperty("id", out var idNode))
                {
                    gatewayOrderId = idNode.GetString() ?? string.Empty;
                }

                // For payment capture events, supplementary_data or custom_id may contain order_id
                if (resource.TryGetProperty("supplementary_data", out var suppNode) &&
                    suppNode.TryGetProperty("related_ids", out var relNode) &&
                    relNode.TryGetProperty("order_id", out var orderIdNode))
                {
                    gatewayOrderId = orderIdNode.GetString() ?? gatewayOrderId;
                    gatewayPaymentId = idNode.GetString() ?? string.Empty;
                }
            }

            if (string.IsNullOrWhiteSpace(gatewayOrderId))
                return BadRequest();

            var normalizedStatus = eventType switch
            {
                "CHECKOUT.ORDER.APPROVED" => "paid",
                "PAYMENT.CAPTURE.COMPLETED" => "paid",
                "PAYMENT.CAPTURE.DENIED" => "failed",
                "PAYMENT.CAPTURE.REFUNDED" => "refunded",
                _ => "pending"
            };

            var callbackRequest = new PaymentCallbackRequest(
                Gateway: MobilePaymentGatewayType.PayPal,
                TransactionRef: string.Empty,
                GatewayOrderId: gatewayOrderId,
                GatewayPaymentId: gatewayPaymentId,
                Status: normalizedStatus,
                Signature: transmissionSig,
                PlanCode: null,
                BillingCycle: null,
                Metadata: null);

            var response = await _mobileClientService.PaymentCallbackAsync(
                companyId: GetCompanyIdOrEmpty(),
                mobileUserId: Guid.Empty,
                request: callbackRequest,
                cancellationToken: cancellationToken);

            return Ok(response);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
        catch (UnauthorizedAccessException)
        {
            return Unauthorized();
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    private Guid GetCompanyIdOrEmpty()
    {
        if (RouteData?.Values != null && RouteData.Values.TryGetValue("companyId", out var raw) && raw != null)
        {
            return Guid.TryParse(raw.ToString(), out var companyId) ? companyId : Guid.Empty;
        }
        return Guid.Empty;
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