using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Payments;
using Sumpooj.Domain.Entities;

namespace Sumpooj.API.Controllers;

/// <summary>
/// Webhook endpoints for payment gateway callbacks
/// These endpoints are called directly by payment gateways and don't require authentication
/// </summary>
[ApiController]
[Route("api/webhooks/payment")]
public class PaymentWebhooksController : ControllerBase
{
    private readonly GatewayPaymentService _paymentService;
    private readonly ILogger<PaymentWebhooksController> _logger;

    public PaymentWebhooksController(GatewayPaymentService paymentService, ILogger<PaymentWebhooksController> logger)
    {
        _paymentService = paymentService;
        _logger = logger;
    }

    /// <summary>
    /// Razorpay webhook handler
    /// </summary>
    [HttpPost("razorpay/{companyId:guid}")]
    public async Task<IActionResult> RazorpayWebhook(Guid companyId)
    {
        return await ProcessWebhook(PaymentGatewayType.Razorpay, companyId, "X-Razorpay-Signature");
    }

    /// <summary>
    /// Stripe webhook handler
    /// </summary>
    [HttpPost("stripe/{companyId:guid}")]
    public async Task<IActionResult> StripeWebhook(Guid companyId)
    {
        return await ProcessWebhook(PaymentGatewayType.Stripe, companyId, "Stripe-Signature");
    }

    /// <summary>
    /// PayPal webhook handler
    /// </summary>
    [HttpPost("paypal/{companyId:guid}")]
    public async Task<IActionResult> PayPalWebhook(Guid companyId)
    {
        return await ProcessWebhook(PaymentGatewayType.PayPal, companyId, "PAYPAL-TRANSMISSION-SIG");
    }

    /// <summary>
    /// Square webhook handler
    /// </summary>
    [HttpPost("square/{companyId:guid}")]
    public async Task<IActionResult> SquareWebhook(Guid companyId)
    {
        return await ProcessWebhook(PaymentGatewayType.Square, companyId, "x-square-hmacsha256-signature");
    }

    /// <summary>
    /// PayU webhook handler
    /// </summary>
    [HttpPost("payu/{companyId:guid}")]
    public async Task<IActionResult> PayUWebhook(Guid companyId)
    {
        return await ProcessWebhook(PaymentGatewayType.PayU, companyId, null);
    }

    /// <summary>
    /// Cashfree webhook handler
    /// </summary>
    [HttpPost("cashfree/{companyId:guid}")]
    public async Task<IActionResult> CashfreeWebhook(Guid companyId)
    {
        return await ProcessWebhook(PaymentGatewayType.Cashfree, companyId, "x-webhook-signature");
    }

    /// <summary>
    /// PayTabs webhook handler
    /// </summary>
    [HttpPost("paytabs/{companyId:guid}")]
    public async Task<IActionResult> PayTabsWebhook(Guid companyId)
    {
        return await ProcessWebhook(PaymentGatewayType.PayTabs, companyId, "signature");
    }

    /// <summary>
    /// HyperPay webhook handler
    /// </summary>
    [HttpPost("hyperpay/{companyId:guid}")]
    public async Task<IActionResult> HyperPayWebhook(Guid companyId)
    {
        return await ProcessWebhook(PaymentGatewayType.HyperPay, companyId, null);
    }

    /// <summary>
    /// Tap Payments webhook handler
    /// </summary>
    [HttpPost("tap/{companyId:guid}")]
    public async Task<IActionResult> TapWebhook(Guid companyId)
    {
        return await ProcessWebhook(PaymentGatewayType.TapPayments, companyId, "Tap-Signature");
    }

    /// <summary>
    /// Checkout.com webhook handler
    /// </summary>
    [HttpPost("checkout/{companyId:guid}")]
    public async Task<IActionResult> CheckoutWebhook(Guid companyId)
    {
        return await ProcessWebhook(PaymentGatewayType.CheckoutCom, companyId, "cko-signature");
    }

    private async Task<IActionResult> ProcessWebhook(PaymentGatewayType gatewayType, Guid companyId, string? signatureHeader)
    {
        try
        {
            // Read raw body
            using var reader = new StreamReader(Request.Body);
            var payload = await reader.ReadToEndAsync();

            // Get signature from header
            string? signature = null;
            if (!string.IsNullOrEmpty(signatureHeader) && Request.Headers.TryGetValue(signatureHeader, out var sigValue))
            {
                signature = sigValue.ToString();
            }

            // Collect all headers
            var headers = Request.Headers.ToDictionary(h => h.Key, h => h.Value.ToString());

            _logger.LogInformation("Received {GatewayType} webhook for company {CompanyId}", gatewayType, companyId);

            await _paymentService.ProcessWebhookAsync(gatewayType, companyId, payload, signature, headers);

            return Ok(new { received = true });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Webhook processing failed for {GatewayType} company={CompanyId}", gatewayType, companyId);
            // Return 200 to prevent retries (we've logged the error)
            return Ok(new { received = true, error = "Processing failed" });
        }
    }
}
