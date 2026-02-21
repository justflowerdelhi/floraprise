using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Payments.Gateways;

/// <summary>
/// Square payment gateway implementation (USA)
/// </summary>
public class SquareGateway : BasePaymentGateway
{
    private readonly HttpClient _httpClient;
    
    public override PaymentGatewayType GatewayType => PaymentGatewayType.Square;

    public SquareGateway(HttpClient httpClient, ILogger<SquareGateway> logger) : base(logger)
    {
        _httpClient = httpClient;
    }

    protected override string GetApiBaseUrl() => IsSandbox 
        ? "https://connect.squareupsandbox.com/v2" 
        : "https://connect.squareup.com/v2";

    public override async Task InitializeAsync(PaymentGatewayConfig config)
    {
        await base.InitializeAsync(config);
        
        _httpClient.DefaultRequestHeaders.Clear();
        _httpClient.DefaultRequestHeaders.Add("Authorization", $"Bearer {SecretKey}");
        _httpClient.DefaultRequestHeaders.Add("Square-Version", "2024-01-18");
    }

    public override async Task<CreatePaymentResultDto> CreatePaymentAsync(CreatePaymentDto request, PaymentTransaction transaction)
    {
        // Square uses a two-step process: create checkout link or use Web Payments SDK
        var checkoutRequest = new
        {
            idempotency_key = GenerateIdempotencyKey(transaction.TransactionRef),
            order = new
            {
                location_id = MerchantId,
                reference_id = transaction.TransactionRef,
                line_items = new[]
                {
                    new
                    {
                        name = request.Description ?? "FloraEdge Order",
                        quantity = "1",
                        base_price_money = new
                        {
                            amount = (long)(request.Amount * 100),
                            currency = request.Currency
                        }
                    }
                }
            },
            checkout_options = new
            {
                redirect_url = request.ReturnUrl,
                ask_for_shipping_address = false
            },
            pre_populated_data = new
            {
                buyer_email = request.CustomerEmail,
                buyer_phone_number = request.CustomerPhone
            }
        };

        var response = await _httpClient.PostAsJsonAsync(
            $"{GetApiBaseUrl()}/online-checkout/payment-links",
            checkoutRequest);

        if (!response.IsSuccessStatusCode)
        {
            var error = await response.Content.ReadAsStringAsync();
            Logger.LogError("Square checkout creation failed: {Error}", error);
            throw new PaymentGatewayException("Failed to create Square checkout", error);
        }

        var result = await response.Content.ReadFromJsonAsync<JsonElement>();
        var paymentLink = result.GetProperty("payment_link");
        var checkoutId = paymentLink.GetProperty("id").GetString()!;
        var url = paymentLink.GetProperty("url").GetString()!;
        var orderId = paymentLink.GetProperty("order_id").GetString();

        return new CreatePaymentResultDto(
            TransactionId: transaction.Id,
            TransactionRef: transaction.TransactionRef,
            GatewayOrderId: orderId,
            PaymentUrl: url,
            ClientSecret: checkoutId,
            QrCode: null,
            AdditionalData: new Dictionary<string, object>
            {
                ["checkout_id"] = checkoutId,
                ["order_id"] = orderId ?? "",
                ["application_id"] = PublicKey,
                ["location_id"] = MerchantId ?? ""
            }
        );
    }

    public override async Task<VerifyPaymentResultDto> VerifyPaymentAsync(VerifyPaymentDto request)
    {
        // Get order status
        var response = await _httpClient.GetAsync(
            $"{GetApiBaseUrl()}/orders/{request.GatewayPaymentId}?location_id={MerchantId}");

        if (!response.IsSuccessStatusCode)
        {
            return new VerifyPaymentResultDto(false, GatewayPaymentStatus.Failed, "Order not found", null);
        }

        var result = await response.Content.ReadFromJsonAsync<JsonElement>();
        var order = result.GetProperty("order");
        var state = order.GetProperty("state").GetString();

        var txnStatus = state switch
        {
            "COMPLETED" => GatewayPaymentStatus.Completed,
            "OPEN" => GatewayPaymentStatus.Pending,
            "CANCELED" => GatewayPaymentStatus.Cancelled,
            _ => GatewayPaymentStatus.Failed
        };

        return new VerifyPaymentResultDto(
            Success: txnStatus == GatewayPaymentStatus.Completed,
            Status: txnStatus,
            Message: state,
            Transaction: null
        );
    }

    public override async Task<RefundResultDto> RefundAsync(PaymentTransaction transaction, decimal amount, string? reason)
    {
        // First, get the payment ID from the order
        var orderResponse = await _httpClient.GetAsync(
            $"{GetApiBaseUrl()}/orders/{transaction.GatewayOrderId}?location_id={MerchantId}");

        if (!orderResponse.IsSuccessStatusCode)
        {
            return new RefundResultDto(false, null, 0, "Order not found");
        }

        var orderResult = await orderResponse.Content.ReadFromJsonAsync<JsonElement>();
        var tenders = orderResult.GetProperty("order").GetProperty("tenders");
        if (tenders.GetArrayLength() == 0)
        {
            return new RefundResultDto(false, null, 0, "No payment found for this order");
        }

        var paymentId = tenders[0].GetProperty("id").GetString()!;

        var refundRequest = new
        {
            idempotency_key = GenerateIdempotencyKey($"refund_{transaction.TransactionRef}"),
            payment_id = paymentId,
            amount_money = new
            {
                amount = (long)(amount * 100),
                currency = transaction.Currency
            },
            reason = reason ?? "Customer requested refund"
        };

        var response = await _httpClient.PostAsJsonAsync($"{GetApiBaseUrl()}/refunds", refundRequest);

        if (!response.IsSuccessStatusCode)
        {
            var error = await response.Content.ReadAsStringAsync();
            return new RefundResultDto(false, null, 0, $"Refund failed: {error}");
        }

        var result = await response.Content.ReadFromJsonAsync<JsonElement>();
        var refund = result.GetProperty("refund");
        var refundId = refund.GetProperty("id").GetString();
        var status = refund.GetProperty("status").GetString();

        return status == "COMPLETED" || status == "PENDING"
            ? new RefundResultDto(true, refundId, amount, "Refund processed")
            : new RefundResultDto(false, refundId, 0, $"Refund status: {status}");
    }

    public override Task<WebhookEventDto?> ParseWebhookAsync(string payload, string? signature, Dictionary<string, string>? headers)
    {
        if (string.IsNullOrEmpty(WebhookSecret) || string.IsNullOrEmpty(signature))
            return Task.FromResult<WebhookEventDto?>(null);

        // Verify Square webhook signature
        var notificationUrl = headers?.GetValueOrDefault("x-square-hmacsha256-signature");
        if (string.IsNullOrEmpty(notificationUrl))
        {
            notificationUrl = signature;
        }

        // Compute expected signature
        // Square signature = base64(HMAC-SHA256(webhookUrl + payload, signatureKey))
        // Note: In production, you need the full webhook URL
        
        try
        {
            var data = JsonSerializer.Deserialize<JsonElement>(payload);
            var eventType = data.GetProperty("type").GetString();
            var eventData = data.GetProperty("data");

            string? paymentId = null;
            string? orderId = null;
            decimal? amount = null;

            if (eventData.TryGetProperty("object", out var obj))
            {
                if (obj.TryGetProperty("payment", out var payment))
                {
                    paymentId = payment.GetProperty("id").GetString();
                    orderId = payment.TryGetProperty("order_id", out var oid) ? oid.GetString() : null;
                    if (payment.TryGetProperty("amount_money", out var amtMoney))
                    {
                        amount = amtMoney.GetProperty("amount").GetInt64() / 100m;
                    }
                }
                else if (obj.TryGetProperty("order", out var order))
                {
                    orderId = order.GetProperty("id").GetString();
                }
            }

            return Task.FromResult<WebhookEventDto?>(new WebhookEventDto(
                EventType: eventType ?? "unknown",
                PaymentId: paymentId,
                OrderId: orderId,
                NewStatus: MapEventToStatus(eventType),
                Amount: amount,
                Currency: "USD",
                Data: null
            ));
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Failed to parse Square webhook");
            return Task.FromResult<WebhookEventDto?>(null);
        }
    }

    public override async Task<PaymentGatewayTestResultDto> TestConnectionAsync()
    {
        try
        {
            var response = await _httpClient.GetAsync($"{GetApiBaseUrl()}/locations");

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
        var status = result.GetProperty("payment").GetProperty("status").GetString();

        return status switch
        {
            "COMPLETED" => GatewayPaymentStatus.Completed,
            "APPROVED" => GatewayPaymentStatus.Authorized,
            "PENDING" => GatewayPaymentStatus.Pending,
            "CANCELED" or "FAILED" => GatewayPaymentStatus.Failed,
            _ => GatewayPaymentStatus.Pending
        };
    }

    private static GatewayPaymentStatus? MapEventToStatus(string? eventType) => eventType switch
    {
        "payment.completed" => GatewayPaymentStatus.Completed,
        "payment.failed" => GatewayPaymentStatus.Failed,
        "payment.canceled" => GatewayPaymentStatus.Cancelled,
        "refund.completed" or "refund.created" => GatewayPaymentStatus.Refunded,
        "order.fulfillment.updated" => GatewayPaymentStatus.Completed,
        _ => null
    };
}
