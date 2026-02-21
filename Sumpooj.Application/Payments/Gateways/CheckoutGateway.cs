using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Payments.Gateways;

/// <summary>
/// Checkout.com payment gateway implementation (GCC/Global)
/// </summary>
public class CheckoutGateway : BasePaymentGateway
{
    private readonly HttpClient _httpClient;
    
    public override PaymentGatewayType GatewayType => PaymentGatewayType.CheckoutCom;

    public CheckoutGateway(HttpClient httpClient, ILogger<CheckoutGateway> logger) : base(logger)
    {
        _httpClient = httpClient;
    }

    protected override string GetApiBaseUrl() => IsSandbox 
        ? "https://api.sandbox.checkout.com" 
        : "https://api.checkout.com";

    public override async Task InitializeAsync(PaymentGatewayConfig config)
    {
        await base.InitializeAsync(config);
        
        _httpClient.DefaultRequestHeaders.Clear();
        _httpClient.DefaultRequestHeaders.Add("Authorization", $"Bearer {SecretKey}");
    }

    public override async Task<CreatePaymentResultDto> CreatePaymentAsync(CreatePaymentDto request, PaymentTransaction transaction)
    {
        // Create a hosted payment page session
        var sessionRequest = new
        {
            amount = (long)(request.Amount * 100), // Amount in minor units
            currency = request.Currency,
            reference = transaction.TransactionRef,
            description = request.Description ?? "FloraEdge Order",
            customer = new
            {
                email = request.CustomerEmail,
                name = request.CustomerEmail?.Split('@')[0] ?? "Customer"
            },
            billing = new
            {
                address = new
                {
                    country = GetCountryFromCurrency(request.Currency)
                }
            },
            success_url = request.ReturnUrl,
            failure_url = request.CancelUrl,
            cancel_url = request.CancelUrl,
            capture = true, // Auto-capture
            processing_channel_id = MerchantId, // Optional processing channel
            metadata = request.Metadata ?? new Dictionary<string, string>()
        };

        var response = await _httpClient.PostAsJsonAsync($"{GetApiBaseUrl()}/hosted-payments", sessionRequest);

        if (!response.IsSuccessStatusCode)
        {
            var error = await response.Content.ReadAsStringAsync();
            Logger.LogError("Checkout.com session creation failed: {Error}", error);
            throw new PaymentGatewayException("Failed to create Checkout.com session", error);
        }

        var result = await response.Content.ReadFromJsonAsync<JsonElement>();
        var sessionId = result.GetProperty("id").GetString()!;
        var redirectUrl = result.GetProperty("_links").GetProperty("redirect").GetProperty("href").GetString()!;

        return new CreatePaymentResultDto(
            TransactionId: transaction.Id,
            TransactionRef: transaction.TransactionRef,
            GatewayOrderId: sessionId,
            PaymentUrl: redirectUrl,
            ClientSecret: sessionId,
            QrCode: null,
            AdditionalData: new Dictionary<string, object>
            {
                ["session_id"] = sessionId,
                ["public_key"] = PublicKey
            }
        );
    }

    public override async Task<VerifyPaymentResultDto> VerifyPaymentAsync(VerifyPaymentDto request)
    {
        // Get payment details using session ID or payment ID
        var endpoint = request.GatewayPaymentId?.StartsWith("pay_") == true
            ? $"{GetApiBaseUrl()}/payments/{request.GatewayPaymentId}"
            : $"{GetApiBaseUrl()}/hosted-payments/{request.GatewayPaymentId}";

        var response = await _httpClient.GetAsync(endpoint);

        if (!response.IsSuccessStatusCode)
        {
            // If hosted payment, try to find associated payment
            if (!request.GatewayPaymentId!.StartsWith("pay_"))
            {
                var paymentsResponse = await _httpClient.GetAsync(
                    $"{GetApiBaseUrl()}/payments?reference={request.TransactionRef}");
                
                if (paymentsResponse.IsSuccessStatusCode)
                {
                    var payments = await paymentsResponse.Content.ReadFromJsonAsync<JsonElement>();
                    if (payments.TryGetProperty("data", out var data) && data.GetArrayLength() > 0)
                    {
                        var payment = data[0];
                        var status = payment.GetProperty("status").GetString();
                        return new VerifyPaymentResultDto(
                            Success: status == "Captured" || status == "Paid",
                            Status: MapStatusToGatewayStatus(status) ?? GatewayPaymentStatus.Failed,
                            Message: status,
                            Transaction: null
                        );
                    }
                }
            }
            
            return new VerifyPaymentResultDto(false, GatewayPaymentStatus.Failed, "Payment not found", null);
        }

        var result = await response.Content.ReadFromJsonAsync<JsonElement>();
        var paymentStatus = result.GetProperty("status").GetString();

        var txnStatus = MapStatusToGatewayStatus(paymentStatus) ?? GatewayPaymentStatus.Failed;

        return new VerifyPaymentResultDto(
            Success: txnStatus == GatewayPaymentStatus.Completed,
            Status: txnStatus,
            Message: paymentStatus,
            Transaction: null
        );
    }

    public override async Task<RefundResultDto> RefundAsync(PaymentTransaction transaction, decimal amount, string? reason)
    {
        var refundRequest = new
        {
            amount = (long)(amount * 100),
            reference = $"refund_{transaction.TransactionRef}",
            metadata = new
            {
                reason = reason ?? "Customer requested refund"
            }
        };

        var response = await _httpClient.PostAsJsonAsync(
            $"{GetApiBaseUrl()}/payments/{transaction.GatewayPaymentId}/refunds", 
            refundRequest);

        if (!response.IsSuccessStatusCode)
        {
            var error = await response.Content.ReadAsStringAsync();
            return new RefundResultDto(false, null, 0, $"Refund failed: {error}");
        }

        var result = await response.Content.ReadFromJsonAsync<JsonElement>();
        var actionId = result.GetProperty("action_id").GetString();

        return new RefundResultDto(true, actionId, amount, "Refund initiated");
    }

    public override Task<WebhookEventDto?> ParseWebhookAsync(string payload, string? signature, Dictionary<string, string>? headers)
    {
        // Verify Checkout.com webhook signature
        if (!string.IsNullOrEmpty(WebhookSecret) && !string.IsNullOrEmpty(signature))
        {
            var expectedSignature = ComputeHmacSha256(payload, WebhookSecret);
            if (!signature.Equals(expectedSignature, StringComparison.OrdinalIgnoreCase))
            {
                Logger.LogWarning("Invalid Checkout.com webhook signature");
                return Task.FromResult<WebhookEventDto?>(null);
            }
        }

        try
        {
            var data = JsonSerializer.Deserialize<JsonElement>(payload);
            var eventType = data.GetProperty("type").GetString();
            var eventData = data.GetProperty("data");

            var paymentId = eventData.TryGetProperty("id", out var id) ? id.GetString() : null;
            var reference = eventData.TryGetProperty("reference", out var refProp) ? refProp.GetString() : null;
            
            decimal? amount = null;
            if (eventData.TryGetProperty("amount", out var amt))
            {
                amount = amt.GetInt64() / 100m;
            }

            return Task.FromResult<WebhookEventDto?>(new WebhookEventDto(
                EventType: eventType ?? "unknown",
                PaymentId: paymentId,
                OrderId: reference,
                NewStatus: MapEventToStatus(eventType),
                Amount: amount,
                Currency: eventData.TryGetProperty("currency", out var cur) ? cur.GetString() : null,
                Data: null
            ));
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Failed to parse Checkout.com webhook");
            return Task.FromResult<WebhookEventDto?>(null);
        }
    }

    public override async Task<PaymentGatewayTestResultDto> TestConnectionAsync()
    {
        try
        {
            var response = await _httpClient.GetAsync($"{GetApiBaseUrl()}/payments?limit=1");

            return new PaymentGatewayTestResultDto(
                Success: response.IsSuccessStatusCode,
                Message: response.IsSuccessStatusCode ? "Connection successful" : "Connection failed",
                TestedAt: DateTime.UtcNow
            );
        }
        catch (Exception ex)
        {
            return new PaymentGatewayTestResultDto(false, $"Test failed: {ex.Message}", DateTime.UtcNow);
        }
    }

    public override async Task<GatewayPaymentStatus> GetPaymentStatusAsync(string gatewayPaymentId)
    {
        var response = await _httpClient.GetAsync($"{GetApiBaseUrl()}/payments/{gatewayPaymentId}");

        if (!response.IsSuccessStatusCode)
            return GatewayPaymentStatus.Pending;

        var result = await response.Content.ReadFromJsonAsync<JsonElement>();
        var status = result.GetProperty("status").GetString();

        return MapStatusToGatewayStatus(status) ?? GatewayPaymentStatus.Pending;
    }

    private static string ComputeHmacSha256(string data, string key)
    {
        using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(key));
        var hash = hmac.ComputeHash(Encoding.UTF8.GetBytes(data));
        return Convert.ToBase64String(hash);
    }

    private static string GetCountryFromCurrency(string currency) => currency switch
    {
        "AED" => "AE",
        "SAR" => "SA",
        "BHD" => "BH",
        "KWD" => "KW",
        "OMR" => "OM",
        "QAR" => "QA",
        "USD" => "US",
        "EUR" => "DE",
        "GBP" => "GB",
        _ => "US"
    };

    private static GatewayPaymentStatus? MapStatusToGatewayStatus(string? status) => status switch
    {
        "Captured" or "Paid" => GatewayPaymentStatus.Completed,
        "Authorized" => GatewayPaymentStatus.Authorized,
        "Pending" => GatewayPaymentStatus.Pending,
        "Canceled" or "Expired" => GatewayPaymentStatus.Cancelled,
        "Declined" or "Card Verified" => GatewayPaymentStatus.Failed,
        "Refunded" or "Partially Refunded" => GatewayPaymentStatus.Refunded,
        "Disputed" => GatewayPaymentStatus.Disputed,
        _ => null
    };

    private static GatewayPaymentStatus? MapEventToStatus(string? eventType) => eventType switch
    {
        "payment_captured" or "payment_paid" => GatewayPaymentStatus.Completed,
        "payment_approved" or "payment_authorized" => GatewayPaymentStatus.Authorized,
        "payment_pending" => GatewayPaymentStatus.Pending,
        "payment_declined" or "payment_expired" => GatewayPaymentStatus.Failed,
        "payment_canceled" or "payment_voided" => GatewayPaymentStatus.Cancelled,
        "payment_refunded" => GatewayPaymentStatus.Refunded,
        "payment_chargeback" or "dispute_opened" => GatewayPaymentStatus.Disputed,
        _ => null
    };
}
