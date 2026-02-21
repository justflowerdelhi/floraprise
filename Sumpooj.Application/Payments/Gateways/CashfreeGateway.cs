using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Payments.Gateways;

/// <summary>
/// Cashfree payment gateway implementation (India)
/// </summary>
public class CashfreeGateway : BasePaymentGateway
{
    private readonly HttpClient _httpClient;
    
    public override PaymentGatewayType GatewayType => PaymentGatewayType.Cashfree;

    public CashfreeGateway(HttpClient httpClient, ILogger<CashfreeGateway> logger) : base(logger)
    {
        _httpClient = httpClient;
    }

    protected override string GetApiBaseUrl() => IsSandbox 
        ? "https://sandbox.cashfree.com/pg" 
        : "https://api.cashfree.com/pg";

    public override async Task InitializeAsync(PaymentGatewayConfig config)
    {
        await base.InitializeAsync(config);
        
        _httpClient.DefaultRequestHeaders.Clear();
        _httpClient.DefaultRequestHeaders.Add("x-client-id", PublicKey);
        _httpClient.DefaultRequestHeaders.Add("x-client-secret", SecretKey);
        _httpClient.DefaultRequestHeaders.Add("x-api-version", "2023-08-01");
    }

    public override async Task<CreatePaymentResultDto> CreatePaymentAsync(CreatePaymentDto request, PaymentTransaction transaction)
    {
        var orderRequest = new
        {
            order_id = transaction.TransactionRef,
            order_amount = request.Amount,
            order_currency = request.Currency,
            customer_details = new
            {
                customer_id = Guid.NewGuid().ToString("N")[..12],
                customer_email = request.CustomerEmail ?? "customer@example.com",
                customer_phone = request.CustomerPhone ?? "9999999999"
            },
            order_meta = new
            {
                return_url = request.ReturnUrl,
                notify_url = Config?.WebhookUrl
            }
        };

        var response = await _httpClient.PostAsJsonAsync($"{GetApiBaseUrl()}/orders", orderRequest);

        if (!response.IsSuccessStatusCode)
        {
            var error = await response.Content.ReadAsStringAsync();
            Logger.LogError("Cashfree order creation failed: {Error}", error);
            throw new PaymentGatewayException("Failed to create Cashfree order", error);
        }

        var result = await response.Content.ReadFromJsonAsync<JsonElement>();
        var paymentSessionId = result.GetProperty("payment_session_id").GetString()!;
        var orderId = result.GetProperty("order_id").GetString()!;

        return new CreatePaymentResultDto(
            TransactionId: transaction.Id,
            TransactionRef: transaction.TransactionRef,
            GatewayOrderId: orderId,
            PaymentUrl: null,
            ClientSecret: paymentSessionId,
            QrCode: null,
            AdditionalData: new Dictionary<string, object>
            {
                ["payment_session_id"] = paymentSessionId,
                ["order_id"] = orderId,
                ["environment"] = IsSandbox ? "sandbox" : "production"
            }
        );
    }

    public override async Task<VerifyPaymentResultDto> VerifyPaymentAsync(VerifyPaymentDto request)
    {
        var response = await _httpClient.GetAsync($"{GetApiBaseUrl()}/orders/{request.TransactionRef}");

        if (!response.IsSuccessStatusCode)
        {
            return new VerifyPaymentResultDto(false, GatewayPaymentStatus.Failed, "Order not found", null);
        }

        var order = await response.Content.ReadFromJsonAsync<JsonElement>();
        var orderStatus = order.GetProperty("order_status").GetString();

        var txnStatus = orderStatus switch
        {
            "PAID" => GatewayPaymentStatus.Completed,
            "ACTIVE" => GatewayPaymentStatus.Pending,
            "EXPIRED" or "TERMINATED" => GatewayPaymentStatus.Cancelled,
            _ => GatewayPaymentStatus.Failed
        };

        return new VerifyPaymentResultDto(
            Success: txnStatus == GatewayPaymentStatus.Completed,
            Status: txnStatus,
            Message: orderStatus,
            Transaction: null
        );
    }

    public override async Task<RefundResultDto> RefundAsync(PaymentTransaction transaction, decimal amount, string? reason)
    {
        var refundRequest = new
        {
            refund_amount = amount,
            refund_id = $"refund_{transaction.TransactionRef}_{DateTime.UtcNow:yyyyMMddHHmmss}",
            refund_note = reason ?? "Customer requested refund"
        };

        var response = await _httpClient.PostAsJsonAsync(
            $"{GetApiBaseUrl()}/orders/{transaction.TransactionRef}/refunds",
            refundRequest);

        if (!response.IsSuccessStatusCode)
        {
            var error = await response.Content.ReadAsStringAsync();
            return new RefundResultDto(false, null, 0, $"Refund failed: {error}");
        }

        var result = await response.Content.ReadFromJsonAsync<JsonElement>();
        var refundId = result.GetProperty("refund_id").GetString();
        var refundStatus = result.GetProperty("refund_status").GetString();

        return refundStatus == "SUCCESS" || refundStatus == "PENDING"
            ? new RefundResultDto(true, refundId, amount, "Refund initiated")
            : new RefundResultDto(false, refundId, 0, $"Refund status: {refundStatus}");
    }

    public override Task<WebhookEventDto?> ParseWebhookAsync(string payload, string? signature, Dictionary<string, string>? headers)
    {
        if (string.IsNullOrEmpty(WebhookSecret) || string.IsNullOrEmpty(signature))
            return Task.FromResult<WebhookEventDto?>(null);

        // Verify webhook signature
        var timestamp = headers?.GetValueOrDefault("x-webhook-timestamp") ?? "";
        var signedPayload = $"{timestamp}{payload}";
        var expectedSignature = ComputeHmacSha256(signedPayload, WebhookSecret);

        if (!signature.Equals(expectedSignature, StringComparison.OrdinalIgnoreCase))
        {
            Logger.LogWarning("Invalid Cashfree webhook signature");
            return Task.FromResult<WebhookEventDto?>(null);
        }

        try
        {
            var data = JsonSerializer.Deserialize<JsonElement>(payload);
            var eventType = data.GetProperty("type").GetString();
            var orderData = data.GetProperty("data").GetProperty("order");

            return Task.FromResult<WebhookEventDto?>(new WebhookEventDto(
                EventType: eventType ?? "unknown",
                PaymentId: orderData.TryGetProperty("cf_order_id", out var cfId) ? cfId.GetString() : null,
                OrderId: orderData.GetProperty("order_id").GetString(),
                NewStatus: MapEventToStatus(eventType),
                Amount: orderData.TryGetProperty("order_amount", out var amt) ? amt.GetDecimal() : null,
                Currency: orderData.TryGetProperty("order_currency", out var cur) ? cur.GetString() : null,
                Data: null
            ));
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Failed to parse Cashfree webhook");
            return Task.FromResult<WebhookEventDto?>(null);
        }
    }

    public override async Task<PaymentGatewayTestResultDto> TestConnectionAsync()
    {
        try
        {
            // Try to list orders (limited to 1)
            var response = await _httpClient.GetAsync($"{GetApiBaseUrl()}/orders?count=1");

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
        var response = await _httpClient.GetAsync($"{GetApiBaseUrl()}/orders/{gatewayPaymentId}");

        if (!response.IsSuccessStatusCode)
            return GatewayPaymentStatus.Pending;

        var order = await response.Content.ReadFromJsonAsync<JsonElement>();
        var status = order.GetProperty("order_status").GetString();

        return status switch
        {
            "PAID" => GatewayPaymentStatus.Completed,
            "ACTIVE" => GatewayPaymentStatus.Pending,
            "EXPIRED" or "TERMINATED" => GatewayPaymentStatus.Cancelled,
            _ => GatewayPaymentStatus.Failed
        };
    }

    private static string ComputeHmacSha256(string data, string key)
    {
        using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(key));
        var hash = hmac.ComputeHash(Encoding.UTF8.GetBytes(data));
        return Convert.ToBase64String(hash);
    }

    private static GatewayPaymentStatus? MapEventToStatus(string? eventType) => eventType switch
    {
        "PAYMENT_SUCCESS_WEBHOOK" => GatewayPaymentStatus.Completed,
        "PAYMENT_FAILED_WEBHOOK" => GatewayPaymentStatus.Failed,
        "REFUND_STATUS_WEBHOOK" => GatewayPaymentStatus.Refunded,
        _ => null
    };
}
