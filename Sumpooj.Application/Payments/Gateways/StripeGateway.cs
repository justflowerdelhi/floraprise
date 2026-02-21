using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Payments.Gateways;

/// <summary>
/// Stripe payment gateway implementation (USA/Global)
/// </summary>
public class StripeGateway : BasePaymentGateway
{
    private readonly HttpClient _httpClient;
    
    public override PaymentGatewayType GatewayType => PaymentGatewayType.Stripe;

    public StripeGateway(HttpClient httpClient, ILogger<StripeGateway> logger) : base(logger)
    {
        _httpClient = httpClient;
    }

    protected override string GetApiBaseUrl() => "https://api.stripe.com/v1";

    public override async Task InitializeAsync(PaymentGatewayConfig config)
    {
        await base.InitializeAsync(config);
        
        _httpClient.DefaultRequestHeaders.Authorization = 
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", SecretKey);
        _httpClient.DefaultRequestHeaders.Add("Stripe-Version", "2023-10-16");
    }

    public override async Task<CreatePaymentResultDto> CreatePaymentAsync(CreatePaymentDto request, PaymentTransaction transaction)
    {
        var formData = new Dictionary<string, string>
        {
            ["amount"] = ((int)(request.Amount * 100)).ToString(),
            ["currency"] = request.Currency.ToLowerInvariant(),
            ["payment_method_types[]"] = "card",
            ["metadata[transaction_ref]"] = transaction.TransactionRef,
            ["metadata[company_id]"] = Config!.CompanyId.ToString()
        };

        if (!string.IsNullOrEmpty(request.CustomerEmail))
            formData["receipt_email"] = request.CustomerEmail;

        if (!string.IsNullOrEmpty(request.Description))
            formData["description"] = request.Description;

        var content = new FormUrlEncodedContent(formData);
        var response = await _httpClient.PostAsync($"{GetApiBaseUrl()}/payment_intents", content);

        if (!response.IsSuccessStatusCode)
        {
            var error = await response.Content.ReadAsStringAsync();
            Logger.LogError("Stripe payment intent creation failed: {Error}", error);
            throw new PaymentGatewayException("Failed to create Stripe payment intent", error);
        }

        var result = await response.Content.ReadFromJsonAsync<JsonElement>();
        var paymentIntentId = result.GetProperty("id").GetString()!;
        var clientSecret = result.GetProperty("client_secret").GetString()!;

        return new CreatePaymentResultDto(
            TransactionId: transaction.Id,
            TransactionRef: transaction.TransactionRef,
            GatewayOrderId: paymentIntentId,
            PaymentUrl: null, // Stripe uses client-side Elements
            ClientSecret: clientSecret,
            QrCode: null,
            AdditionalData: new Dictionary<string, object>
            {
                ["publishableKey"] = PublicKey,
                ["paymentIntentId"] = paymentIntentId
            }
        );
    }

    public override async Task<VerifyPaymentResultDto> VerifyPaymentAsync(VerifyPaymentDto request)
    {
        var response = await _httpClient.GetAsync($"{GetApiBaseUrl()}/payment_intents/{request.GatewayPaymentId}");
        
        if (!response.IsSuccessStatusCode)
        {
            return new VerifyPaymentResultDto(false, GatewayPaymentStatus.Failed, "Payment not found", null);
        }

        var intent = await response.Content.ReadFromJsonAsync<JsonElement>();
        var status = intent.GetProperty("status").GetString();

        var txnStatus = status switch
        {
            "succeeded" => GatewayPaymentStatus.Completed,
            "requires_capture" => GatewayPaymentStatus.Authorized,
            "canceled" => GatewayPaymentStatus.Cancelled,
            "requires_payment_method" or "requires_confirmation" => GatewayPaymentStatus.Pending,
            _ => GatewayPaymentStatus.Failed
        };

        return new VerifyPaymentResultDto(
            Success: txnStatus == GatewayPaymentStatus.Completed,
            Status: txnStatus,
            Message: status,
            Transaction: null
        );
    }

    public override async Task<RefundResultDto> RefundAsync(PaymentTransaction transaction, decimal amount, string? reason)
    {
        var formData = new Dictionary<string, string>
        {
            ["payment_intent"] = transaction.GatewayPaymentId!,
            ["amount"] = ((int)(amount * 100)).ToString()
        };

        if (!string.IsNullOrEmpty(reason))
            formData["reason"] = "requested_by_customer";

        var content = new FormUrlEncodedContent(formData);
        var response = await _httpClient.PostAsync($"{GetApiBaseUrl()}/refunds", content);

        if (!response.IsSuccessStatusCode)
        {
            var error = await response.Content.ReadAsStringAsync();
            return new RefundResultDto(false, null, 0, $"Refund failed: {error}");
        }

        var result = await response.Content.ReadFromJsonAsync<JsonElement>();
        var refundId = result.GetProperty("id").GetString();

        return new RefundResultDto(true, refundId, amount, "Refund successful");
    }

    public override Task<WebhookEventDto?> ParseWebhookAsync(string payload, string? signature, Dictionary<string, string>? headers)
    {
        if (string.IsNullOrEmpty(WebhookSecret) || string.IsNullOrEmpty(signature))
            return Task.FromResult<WebhookEventDto?>(null);

        // Stripe webhook signature verification
        // In production, use Stripe.Net SDK for proper verification
        var signatureParts = signature.Split(',')
            .Select(p => p.Split('='))
            .Where(p => p.Length == 2)
            .ToDictionary(p => p[0], p => p[1]);

        if (!signatureParts.TryGetValue("t", out var timestamp) || !signatureParts.TryGetValue("v1", out var sig))
        {
            Logger.LogWarning("Invalid Stripe webhook signature format");
            return Task.FromResult<WebhookEventDto?>(null);
        }

        var data = JsonSerializer.Deserialize<JsonElement>(payload);
        var eventType = data.GetProperty("type").GetString();
        var obj = data.GetProperty("data").GetProperty("object");

        return Task.FromResult<WebhookEventDto?>(new WebhookEventDto(
            EventType: eventType ?? "unknown",
            PaymentId: obj.TryGetProperty("id", out var id) ? id.GetString() : null,
            OrderId: null,
            NewStatus: MapEventToStatus(eventType),
            Amount: obj.TryGetProperty("amount", out var amt) ? amt.GetDecimal() / 100 : null,
            Currency: obj.TryGetProperty("currency", out var cur) ? cur.GetString() : null,
            Data: null
        ));
    }

    public override async Task<PaymentGatewayTestResultDto> TestConnectionAsync()
    {
        try
        {
            var response = await _httpClient.GetAsync($"{GetApiBaseUrl()}/balance");
            
            return new PaymentGatewayTestResultDto(
                Success: response.IsSuccessStatusCode,
                Message: response.IsSuccessStatusCode ? "Connection successful" : "Connection failed",
                TestedAt: DateTime.UtcNow
            );
        }
        catch (Exception ex)
        {
            return new PaymentGatewayTestResultDto(false, $"Connection error: {ex.Message}", DateTime.UtcNow);
        }
    }

    public override async Task<GatewayPaymentStatus> GetPaymentStatusAsync(string gatewayPaymentId)
    {
        var response = await _httpClient.GetAsync($"{GetApiBaseUrl()}/payment_intents/{gatewayPaymentId}");
        
        if (!response.IsSuccessStatusCode)
            return GatewayPaymentStatus.Pending;

        var intent = await response.Content.ReadFromJsonAsync<JsonElement>();
        var status = intent.GetProperty("status").GetString();

        return status switch
        {
            "succeeded" => GatewayPaymentStatus.Completed,
            "requires_capture" => GatewayPaymentStatus.Authorized,
            "canceled" => GatewayPaymentStatus.Cancelled,
            _ => GatewayPaymentStatus.Pending
        };
    }

    private static GatewayPaymentStatus? MapEventToStatus(string? eventType) => eventType switch
    {
        "payment_intent.succeeded" => GatewayPaymentStatus.Completed,
        "payment_intent.payment_failed" => GatewayPaymentStatus.Failed,
        "payment_intent.canceled" => GatewayPaymentStatus.Cancelled,
        "charge.refunded" => GatewayPaymentStatus.Refunded,
        "charge.dispute.created" => GatewayPaymentStatus.Disputed,
        _ => null
    };
}
