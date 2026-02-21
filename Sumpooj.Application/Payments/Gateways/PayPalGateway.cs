using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Payments.Gateways;

/// <summary>
/// PayPal payment gateway implementation (USA/Global)
/// </summary>
public class PayPalGateway : BasePaymentGateway
{
    private readonly HttpClient _httpClient;
    private string? _accessToken;
    private DateTime _tokenExpiry = DateTime.MinValue;
    
    public override PaymentGatewayType GatewayType => PaymentGatewayType.PayPal;

    public PayPalGateway(HttpClient httpClient, ILogger<PayPalGateway> logger) : base(logger)
    {
        _httpClient = httpClient;
    }

    protected override string GetApiBaseUrl() => IsSandbox 
        ? "https://api-m.sandbox.paypal.com" 
        : "https://api-m.paypal.com";

    private async Task EnsureAccessTokenAsync()
    {
        if (_accessToken != null && DateTime.UtcNow < _tokenExpiry)
            return;

        var credentials = Convert.ToBase64String(Encoding.UTF8.GetBytes($"{PublicKey}:{SecretKey}"));
        
        using var request = new HttpRequestMessage(HttpMethod.Post, $"{GetApiBaseUrl()}/v1/oauth2/token");
        request.Headers.Add("Authorization", $"Basic {credentials}");
        request.Content = new StringContent("grant_type=client_credentials", Encoding.UTF8, "application/x-www-form-urlencoded");

        var response = await _httpClient.SendAsync(request);
        
        if (!response.IsSuccessStatusCode)
        {
            throw new PaymentGatewayException("Failed to get PayPal access token");
        }

        var result = await response.Content.ReadFromJsonAsync<JsonElement>();
        _accessToken = result.GetProperty("access_token").GetString();
        var expiresIn = result.GetProperty("expires_in").GetInt32();
        _tokenExpiry = DateTime.UtcNow.AddSeconds(expiresIn - 60); // Refresh 1 minute early
    }

    public override async Task<CreatePaymentResultDto> CreatePaymentAsync(CreatePaymentDto request, PaymentTransaction transaction)
    {
        await EnsureAccessTokenAsync();

        var orderRequest = new
        {
            intent = "CAPTURE",
            purchase_units = new[]
            {
                new
                {
                    reference_id = transaction.TransactionRef,
                    description = request.Description ?? "FloraEdge Order",
                    amount = new
                    {
                        currency_code = request.Currency,
                        value = request.Amount.ToString("F2")
                    }
                }
            },
            payment_source = new
            {
                paypal = new
                {
                    experience_context = new
                    {
                        payment_method_preference = "IMMEDIATE_PAYMENT_REQUIRED",
                        brand_name = "FloraEdge",
                        locale = "en-US",
                        landing_page = "LOGIN",
                        user_action = "PAY_NOW",
                        return_url = request.ReturnUrl,
                        cancel_url = request.CancelUrl
                    }
                }
            }
        };

        using var httpRequest = new HttpRequestMessage(HttpMethod.Post, $"{GetApiBaseUrl()}/v2/checkout/orders");
        httpRequest.Headers.Add("Authorization", $"Bearer {_accessToken}");
        httpRequest.Headers.Add("PayPal-Request-Id", GenerateIdempotencyKey(transaction.TransactionRef));
        httpRequest.Content = JsonContent.Create(orderRequest);

        var response = await _httpClient.SendAsync(httpRequest);

        if (!response.IsSuccessStatusCode)
        {
            var error = await response.Content.ReadAsStringAsync();
            Logger.LogError("PayPal order creation failed: {Error}", error);
            throw new PaymentGatewayException("Failed to create PayPal order", error);
        }

        var result = await response.Content.ReadFromJsonAsync<JsonElement>();
        var orderId = result.GetProperty("id").GetString()!;
        
        // Find the approval link
        string? approvalUrl = null;
        if (result.TryGetProperty("links", out var links))
        {
            foreach (var link in links.EnumerateArray())
            {
                if (link.GetProperty("rel").GetString() == "payer-action")
                {
                    approvalUrl = link.GetProperty("href").GetString();
                    break;
                }
            }
        }

        return new CreatePaymentResultDto(
            TransactionId: transaction.Id,
            TransactionRef: transaction.TransactionRef,
            GatewayOrderId: orderId,
            PaymentUrl: approvalUrl,
            ClientSecret: orderId,
            QrCode: null,
            AdditionalData: new Dictionary<string, object>
            {
                ["order_id"] = orderId,
                ["client_id"] = PublicKey
            }
        );
    }

    public override async Task<VerifyPaymentResultDto> VerifyPaymentAsync(VerifyPaymentDto request)
    {
        await EnsureAccessTokenAsync();

        // Capture the order
        using var captureRequest = new HttpRequestMessage(
            HttpMethod.Post, 
            $"{GetApiBaseUrl()}/v2/checkout/orders/{request.GatewayPaymentId}/capture");
        captureRequest.Headers.Add("Authorization", $"Bearer {_accessToken}");
        captureRequest.Content = new StringContent("{}", Encoding.UTF8, "application/json");

        var response = await _httpClient.SendAsync(captureRequest);

        if (!response.IsSuccessStatusCode)
        {
            var error = await response.Content.ReadAsStringAsync();
            Logger.LogWarning("PayPal capture failed: {Error}", error);
            
            // Check if already captured
            var orderResponse = await GetOrderAsync(request.GatewayPaymentId!);
            if (orderResponse != null)
            {
                var status = orderResponse.Value.GetProperty("status").GetString();
                if (status == "COMPLETED")
                {
                    return new VerifyPaymentResultDto(true, GatewayPaymentStatus.Completed, "Already captured", null);
                }
            }
            
            return new VerifyPaymentResultDto(false, GatewayPaymentStatus.Failed, "Capture failed", null);
        }

        var result = await response.Content.ReadFromJsonAsync<JsonElement>();
        var orderStatus = result.GetProperty("status").GetString();

        var txnStatus = orderStatus switch
        {
            "COMPLETED" => GatewayPaymentStatus.Completed,
            "APPROVED" => GatewayPaymentStatus.Authorized,
            "VOIDED" => GatewayPaymentStatus.Cancelled,
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
        await EnsureAccessTokenAsync();

        // Get the capture ID from the order
        var order = await GetOrderAsync(transaction.GatewayOrderId!);
        if (order == null)
        {
            return new RefundResultDto(false, null, 0, "Order not found");
        }

        string? captureId = null;
        if (order.Value.TryGetProperty("purchase_units", out var units))
        {
            foreach (var unit in units.EnumerateArray())
            {
                if (unit.TryGetProperty("payments", out var payments) &&
                    payments.TryGetProperty("captures", out var captures))
                {
                    foreach (var capture in captures.EnumerateArray())
                    {
                        if (capture.GetProperty("status").GetString() == "COMPLETED")
                        {
                            captureId = capture.GetProperty("id").GetString();
                            break;
                        }
                    }
                }
            }
        }

        if (string.IsNullOrEmpty(captureId))
        {
            return new RefundResultDto(false, null, 0, "No completed capture found");
        }

        var refundRequest = new
        {
            amount = new
            {
                value = amount.ToString("F2"),
                currency_code = transaction.Currency
            },
            note_to_payer = reason ?? "Refund from FloraEdge"
        };

        using var httpRequest = new HttpRequestMessage(
            HttpMethod.Post,
            $"{GetApiBaseUrl()}/v2/payments/captures/{captureId}/refund");
        httpRequest.Headers.Add("Authorization", $"Bearer {_accessToken}");
        httpRequest.Headers.Add("PayPal-Request-Id", GenerateIdempotencyKey($"refund_{transaction.TransactionRef}"));
        httpRequest.Content = JsonContent.Create(refundRequest);

        var response = await _httpClient.SendAsync(httpRequest);

        if (!response.IsSuccessStatusCode)
        {
            var error = await response.Content.ReadAsStringAsync();
            return new RefundResultDto(false, null, 0, $"Refund failed: {error}");
        }

        var result = await response.Content.ReadFromJsonAsync<JsonElement>();
        var refundId = result.GetProperty("id").GetString();
        var status = result.GetProperty("status").GetString();

        return status == "COMPLETED"
            ? new RefundResultDto(true, refundId, amount, "Refund completed")
            : new RefundResultDto(true, refundId, amount, $"Refund status: {status}");
    }

    public override Task<WebhookEventDto?> ParseWebhookAsync(string payload, string? signature, Dictionary<string, string>? headers)
    {
        // PayPal webhook verification is complex - requires calling PayPal API
        // For now, parse the event
        try
        {
            var data = JsonSerializer.Deserialize<JsonElement>(payload);
            var eventType = data.GetProperty("event_type").GetString();
            var resource = data.GetProperty("resource");

            string? paymentId = null;
            string? orderId = null;
            decimal? amount = null;

            if (resource.TryGetProperty("id", out var id))
            {
                paymentId = id.GetString();
            }

            if (resource.TryGetProperty("supplementary_data", out var suppData) &&
                suppData.TryGetProperty("related_ids", out var relatedIds) &&
                relatedIds.TryGetProperty("order_id", out var oid))
            {
                orderId = oid.GetString();
            }

            if (resource.TryGetProperty("amount", out var amtObj))
            {
                amount = decimal.Parse(amtObj.GetProperty("value").GetString()!);
            }

            return Task.FromResult<WebhookEventDto?>(new WebhookEventDto(
                EventType: eventType ?? "unknown",
                PaymentId: paymentId,
                OrderId: orderId,
                NewStatus: MapEventToStatus(eventType),
                Amount: amount,
                Currency: resource.TryGetProperty("amount", out var a) ? a.GetProperty("currency_code").GetString() : null,
                Data: null
            ));
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Failed to parse PayPal webhook");
            return Task.FromResult<WebhookEventDto?>(null);
        }
    }

    public override async Task<PaymentGatewayTestResultDto> TestConnectionAsync()
    {
        try
        {
            await EnsureAccessTokenAsync();
            return new PaymentGatewayTestResultDto(true, "Connection successful", DateTime.UtcNow);
        }
        catch (Exception ex)
        {
            return new PaymentGatewayTestResultDto(false, $"Test failed: {ex.Message}", DateTime.UtcNow);
        }
    }

    public override async Task<GatewayPaymentStatus> GetPaymentStatusAsync(string gatewayPaymentId)
    {
        var order = await GetOrderAsync(gatewayPaymentId);
        if (order == null)
            return GatewayPaymentStatus.Pending;

        var status = order.Value.GetProperty("status").GetString();
        return status switch
        {
            "COMPLETED" => GatewayPaymentStatus.Completed,
            "APPROVED" => GatewayPaymentStatus.Authorized,
            "VOIDED" => GatewayPaymentStatus.Cancelled,
            "PAYER_ACTION_REQUIRED" => GatewayPaymentStatus.Pending,
            _ => GatewayPaymentStatus.Pending
        };
    }

    private async Task<JsonElement?> GetOrderAsync(string orderId)
    {
        await EnsureAccessTokenAsync();

        using var request = new HttpRequestMessage(HttpMethod.Get, $"{GetApiBaseUrl()}/v2/checkout/orders/{orderId}");
        request.Headers.Add("Authorization", $"Bearer {_accessToken}");

        var response = await _httpClient.SendAsync(request);
        if (!response.IsSuccessStatusCode)
            return null;

        return await response.Content.ReadFromJsonAsync<JsonElement>();
    }

    private static GatewayPaymentStatus? MapEventToStatus(string? eventType) => eventType switch
    {
        "CHECKOUT.ORDER.COMPLETED" or "PAYMENT.CAPTURE.COMPLETED" => GatewayPaymentStatus.Completed,
        "PAYMENT.CAPTURE.DENIED" => GatewayPaymentStatus.Failed,
        "CHECKOUT.ORDER.APPROVED" => GatewayPaymentStatus.Authorized,
        "PAYMENT.CAPTURE.REFUNDED" => GatewayPaymentStatus.Refunded,
        _ => null
    };
}
