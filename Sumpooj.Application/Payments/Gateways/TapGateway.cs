using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Payments.Gateways;

/// <summary>
/// Tap Payments gateway implementation (GCC/MENA)
/// </summary>
public class TapGateway : BasePaymentGateway
{
    private readonly HttpClient _httpClient;
    
    public override PaymentGatewayType GatewayType => PaymentGatewayType.TapPayments;

    public TapGateway(HttpClient httpClient, ILogger<TapGateway> logger) : base(logger)
    {
        _httpClient = httpClient;
    }

    protected override string GetApiBaseUrl() => "https://api.tap.company/v2";

    public override async Task InitializeAsync(PaymentGatewayConfig config)
    {
        await base.InitializeAsync(config);
        
        _httpClient.DefaultRequestHeaders.Clear();
        _httpClient.DefaultRequestHeaders.Add("Authorization", $"Bearer {SecretKey}");
    }

    public override async Task<CreatePaymentResultDto> CreatePaymentAsync(CreatePaymentDto request, PaymentTransaction transaction)
    {
        var chargeRequest = new
        {
            amount = request.Amount,
            currency = request.Currency,
            threeDSecure = true,
            save_card = false,
            description = request.Description ?? "FloraEdge Order",
            statement_descriptor = "FloraEdge",
            reference = new
            {
                transaction = transaction.TransactionRef,
                order = transaction.TransactionRef
            },
            receipt = new
            {
                email = true,
                sms = true
            },
            customer = new
            {
                first_name = request.CustomerEmail?.Split('@')[0] ?? "Customer",
                email = request.CustomerEmail ?? "",
                phone = new
                {
                    country_code = "971",
                    number = request.CustomerPhone ?? ""
                }
            },
            source = new { id = "src_all" }, // Accept all payment methods
            post = new { url = Config?.WebhookUrl },
            redirect = new { url = request.ReturnUrl }
        };

        var response = await _httpClient.PostAsJsonAsync($"{GetApiBaseUrl()}/charges", chargeRequest);

        if (!response.IsSuccessStatusCode)
        {
            var error = await response.Content.ReadAsStringAsync();
            Logger.LogError("Tap charge creation failed: {Error}", error);
            throw new PaymentGatewayException("Failed to create Tap charge", error);
        }

        var result = await response.Content.ReadFromJsonAsync<JsonElement>();
        var chargeId = result.GetProperty("id").GetString()!;
        var status = result.GetProperty("status").GetString();
        
        string? redirectUrl = null;
        if (result.TryGetProperty("transaction", out var txn) && 
            txn.TryGetProperty("url", out var url))
        {
            redirectUrl = url.GetString();
        }

        return new CreatePaymentResultDto(
            TransactionId: transaction.Id,
            TransactionRef: transaction.TransactionRef,
            GatewayOrderId: chargeId,
            PaymentUrl: redirectUrl,
            ClientSecret: chargeId,
            QrCode: null,
            AdditionalData: new Dictionary<string, object>
            {
                ["charge_id"] = chargeId,
                ["status"] = status ?? "",
                ["publishable_key"] = PublicKey
            }
        );
    }

    public override async Task<VerifyPaymentResultDto> VerifyPaymentAsync(VerifyPaymentDto request)
    {
        var response = await _httpClient.GetAsync($"{GetApiBaseUrl()}/charges/{request.GatewayPaymentId}");

        if (!response.IsSuccessStatusCode)
        {
            return new VerifyPaymentResultDto(false, GatewayPaymentStatus.Failed, "Charge not found", null);
        }

        var result = await response.Content.ReadFromJsonAsync<JsonElement>();
        var status = result.GetProperty("status").GetString();
        var responseMessage = result.TryGetProperty("response", out var resp) 
            ? resp.GetProperty("message").GetString() 
            : status;

        var txnStatus = status switch
        {
            "CAPTURED" => GatewayPaymentStatus.Completed,
            "AUTHORIZED" => GatewayPaymentStatus.Authorized,
            "INITIATED" or "PENDING" => GatewayPaymentStatus.Pending,
            "CANCELLED" or "ABANDONED" => GatewayPaymentStatus.Cancelled,
            "DECLINED" or "FAILED" or "RESTRICTED" => GatewayPaymentStatus.Failed,
            _ => GatewayPaymentStatus.Failed
        };

        return new VerifyPaymentResultDto(
            Success: txnStatus == GatewayPaymentStatus.Completed,
            Status: txnStatus,
            Message: responseMessage,
            Transaction: null
        );
    }

    public override async Task<RefundResultDto> RefundAsync(PaymentTransaction transaction, decimal amount, string? reason)
    {
        var refundRequest = new
        {
            charge_id = transaction.GatewayPaymentId,
            amount = amount,
            currency = transaction.Currency,
            description = reason ?? "Customer requested refund",
            reason = "requested_by_customer",
            reference = new
            {
                merchant = $"refund_{transaction.TransactionRef}"
            },
            metadata = new
            {
                original_transaction = transaction.TransactionRef
            },
            post = new { url = Config?.WebhookUrl }
        };

        var response = await _httpClient.PostAsJsonAsync($"{GetApiBaseUrl()}/refunds", refundRequest);

        if (!response.IsSuccessStatusCode)
        {
            var error = await response.Content.ReadAsStringAsync();
            return new RefundResultDto(false, null, 0, $"Refund failed: {error}");
        }

        var result = await response.Content.ReadFromJsonAsync<JsonElement>();
        var refundId = result.GetProperty("id").GetString();
        var status = result.GetProperty("status").GetString();

        return status == "PENDING" || status == "REFUNDED"
            ? new RefundResultDto(true, refundId, amount, "Refund initiated")
            : new RefundResultDto(false, refundId, 0, $"Refund status: {status}");
    }

    public override Task<WebhookEventDto?> ParseWebhookAsync(string payload, string? signature, Dictionary<string, string>? headers)
    {
        // Verify Tap signature
        if (!string.IsNullOrEmpty(WebhookSecret) && !string.IsNullOrEmpty(signature))
        {
            var expectedSignature = ComputeHmacSha256(payload, WebhookSecret);
            if (!signature.Equals(expectedSignature, StringComparison.OrdinalIgnoreCase))
            {
                Logger.LogWarning("Invalid Tap webhook signature");
                return Task.FromResult<WebhookEventDto?>(null);
            }
        }

        try
        {
            var data = JsonSerializer.Deserialize<JsonElement>(payload);
            var chargeId = data.GetProperty("id").GetString();
            var status = data.GetProperty("status").GetString();
            
            string? orderId = null;
            if (data.TryGetProperty("reference", out var reference) &&
                reference.TryGetProperty("transaction", out var txnRef))
            {
                orderId = txnRef.GetString();
            }

            decimal? amount = null;
            if (data.TryGetProperty("amount", out var amt))
            {
                amount = amt.GetDecimal();
            }

            return Task.FromResult<WebhookEventDto?>(new WebhookEventDto(
                EventType: $"charge.{status?.ToLowerInvariant()}",
                PaymentId: chargeId,
                OrderId: orderId,
                NewStatus: MapStatusToGatewayStatus(status),
                Amount: amount,
                Currency: data.TryGetProperty("currency", out var cur) ? cur.GetString() : null,
                Data: null
            ));
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Failed to parse Tap webhook");
            return Task.FromResult<WebhookEventDto?>(null);
        }
    }

    public override async Task<PaymentGatewayTestResultDto> TestConnectionAsync()
    {
        try
        {
            var response = await _httpClient.GetAsync($"{GetApiBaseUrl()}/charges?limit=1");

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
        var response = await _httpClient.GetAsync($"{GetApiBaseUrl()}/charges/{gatewayPaymentId}");

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

    private static GatewayPaymentStatus? MapStatusToGatewayStatus(string? status) => status switch
    {
        "CAPTURED" => GatewayPaymentStatus.Completed,
        "AUTHORIZED" => GatewayPaymentStatus.Authorized,
        "INITIATED" or "PENDING" => GatewayPaymentStatus.Pending,
        "CANCELLED" or "ABANDONED" => GatewayPaymentStatus.Cancelled,
        "DECLINED" or "FAILED" or "RESTRICTED" => GatewayPaymentStatus.Failed,
        "REFUNDED" => GatewayPaymentStatus.Refunded,
        _ => null
    };
}
