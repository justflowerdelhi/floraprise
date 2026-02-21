using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Payments.Gateways;

/// <summary>
/// Razorpay payment gateway implementation (India)
/// </summary>
public class RazorpayGateway : BasePaymentGateway
{
    private readonly HttpClient _httpClient;
    
    public override PaymentGatewayType GatewayType => PaymentGatewayType.Razorpay;

    public RazorpayGateway(HttpClient httpClient, ILogger<RazorpayGateway> logger) : base(logger)
    {
        _httpClient = httpClient;
    }

    protected override string GetApiBaseUrl() => "https://api.razorpay.com/v1";

    public override async Task InitializeAsync(PaymentGatewayConfig config)
    {
        await base.InitializeAsync(config);
        
        // Set up Basic Auth
        var credentials = Convert.ToBase64String(Encoding.UTF8.GetBytes($"{PublicKey}:{SecretKey}"));
        _httpClient.DefaultRequestHeaders.Authorization = 
            new System.Net.Http.Headers.AuthenticationHeaderValue("Basic", credentials);
    }

    public override async Task<CreatePaymentResultDto> CreatePaymentAsync(CreatePaymentDto request, PaymentTransaction transaction)
    {
        var orderRequest = new
        {
            amount = (int)(request.Amount * 100), // Razorpay expects amount in paise
            currency = request.Currency,
            receipt = transaction.TransactionRef,
            notes = request.Metadata ?? new Dictionary<string, string>()
        };

        var response = await _httpClient.PostAsJsonAsync($"{GetApiBaseUrl()}/orders", orderRequest);
        
        if (!response.IsSuccessStatusCode)
        {
            var error = await response.Content.ReadAsStringAsync();
            Logger.LogError("Razorpay order creation failed: {Error}", error);
            throw new PaymentGatewayException("Failed to create Razorpay order", error);
        }

        var result = await response.Content.ReadFromJsonAsync<JsonElement>();
        var orderId = result.GetProperty("id").GetString()!;

        return new CreatePaymentResultDto(
            TransactionId: transaction.Id,
            TransactionRef: transaction.TransactionRef,
            GatewayOrderId: orderId,
            PaymentUrl: null, // Razorpay uses client-side checkout
            ClientSecret: orderId, // Used by frontend SDK
            QrCode: null,
            AdditionalData: new Dictionary<string, object>
            {
                ["key"] = PublicKey,
                ["amount"] = (int)(request.Amount * 100),
                ["currency"] = request.Currency,
                ["name"] = Config?.Company?.Name ?? "FloraEdge",
                ["order_id"] = orderId
            }
        );
    }

    public override async Task<VerifyPaymentResultDto> VerifyPaymentAsync(VerifyPaymentDto request)
    {
        // Verify signature
        var payload = $"{request.AdditionalData?["razorpay_order_id"]}|{request.GatewayPaymentId}";
        var expectedSignature = ComputeHmacSha256(payload, SecretKey);

        if (request.GatewaySignature != expectedSignature)
        {
            return new VerifyPaymentResultDto(false, GatewayPaymentStatus.Failed, "Invalid signature", null);
        }

        // Fetch payment details
        var response = await _httpClient.GetAsync($"{GetApiBaseUrl()}/payments/{request.GatewayPaymentId}");
        
        if (!response.IsSuccessStatusCode)
        {
            return new VerifyPaymentResultDto(false, GatewayPaymentStatus.Failed, "Payment not found", null);
        }

        var payment = await response.Content.ReadFromJsonAsync<JsonElement>();
        var status = payment.GetProperty("status").GetString();

        var txnStatus = status switch
        {
            "captured" => GatewayPaymentStatus.Completed,
            "authorized" => GatewayPaymentStatus.Authorized,
            "failed" => GatewayPaymentStatus.Failed,
            _ => GatewayPaymentStatus.Pending
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
        var refundRequest = new
        {
            amount = (int)(amount * 100),
            notes = new { reason = reason ?? "Customer requested refund" }
        };

        var response = await _httpClient.PostAsJsonAsync(
            $"{GetApiBaseUrl()}/payments/{transaction.GatewayPaymentId}/refund", 
            refundRequest);

        if (!response.IsSuccessStatusCode)
        {
            var error = await response.Content.ReadAsStringAsync();
            return new RefundResultDto(false, null, 0, $"Refund failed: {error}");
        }

        var result = await response.Content.ReadFromJsonAsync<JsonElement>();
        var refundId = result.GetProperty("id").GetString();

        return new RefundResultDto(true, refundId, amount, "Refund initiated successfully");
    }

    public override Task<WebhookEventDto?> ParseWebhookAsync(string payload, string? signature, Dictionary<string, string>? headers)
    {
        if (string.IsNullOrEmpty(WebhookSecret) || string.IsNullOrEmpty(signature))
            return Task.FromResult<WebhookEventDto?>(null);

        var expectedSignature = ComputeHmacSha256(payload, WebhookSecret);
        if (signature != expectedSignature)
        {
            Logger.LogWarning("Invalid Razorpay webhook signature");
            return Task.FromResult<WebhookEventDto?>(null);
        }

        var data = JsonSerializer.Deserialize<JsonElement>(payload);
        var eventType = data.GetProperty("event").GetString();
        var paymentEntity = data.GetProperty("payload").GetProperty("payment").GetProperty("entity");

        return Task.FromResult<WebhookEventDto?>(new WebhookEventDto(
            EventType: eventType ?? "unknown",
            PaymentId: paymentEntity.GetProperty("id").GetString(),
            OrderId: paymentEntity.TryGetProperty("order_id", out var oid) ? oid.GetString() : null,
            NewStatus: MapEventToStatus(eventType),
            Amount: paymentEntity.GetProperty("amount").GetDecimal() / 100,
            Currency: paymentEntity.GetProperty("currency").GetString(),
            Data: null
        ));
    }

    public override async Task<PaymentGatewayTestResultDto> TestConnectionAsync()
    {
        try
        {
            var response = await _httpClient.GetAsync($"{GetApiBaseUrl()}/payments?count=1");
            
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
        var response = await _httpClient.GetAsync($"{GetApiBaseUrl()}/payments/{gatewayPaymentId}");
        
        if (!response.IsSuccessStatusCode)
            return GatewayPaymentStatus.Pending;

        var payment = await response.Content.ReadFromJsonAsync<JsonElement>();
        var status = payment.GetProperty("status").GetString();

        return status switch
        {
            "captured" => GatewayPaymentStatus.Completed,
            "authorized" => GatewayPaymentStatus.Authorized,
            "failed" => GatewayPaymentStatus.Failed,
            "refunded" => GatewayPaymentStatus.Refunded,
            _ => GatewayPaymentStatus.Pending
        };
    }

    private static string ComputeHmacSha256(string data, string key)
    {
        using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(key));
        var hash = hmac.ComputeHash(Encoding.UTF8.GetBytes(data));
        return BitConverter.ToString(hash).Replace("-", "").ToLowerInvariant();
    }

    private static GatewayPaymentStatus? MapEventToStatus(string? eventType) => eventType switch
    {
        "payment.captured" => GatewayPaymentStatus.Completed,
        "payment.authorized" => GatewayPaymentStatus.Authorized,
        "payment.failed" => GatewayPaymentStatus.Failed,
        "refund.created" or "refund.processed" => GatewayPaymentStatus.Refunded,
        _ => null
    };
}
