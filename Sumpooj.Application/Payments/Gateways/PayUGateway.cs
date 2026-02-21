using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Payments.Gateways;

/// <summary>
/// PayU payment gateway implementation (India)
/// </summary>
public class PayUGateway : BasePaymentGateway
{
    private readonly HttpClient _httpClient;
    
    public override PaymentGatewayType GatewayType => PaymentGatewayType.PayU;

    public PayUGateway(HttpClient httpClient, ILogger<PayUGateway> logger) : base(logger)
    {
        _httpClient = httpClient;
    }

    protected override string GetApiBaseUrl() => IsSandbox 
        ? "https://test.payu.in" 
        : "https://secure.payu.in";

    public override async Task<CreatePaymentResultDto> CreatePaymentAsync(CreatePaymentDto request, PaymentTransaction transaction)
    {
        // PayU uses form-based redirect, generate hash for security
        var txnId = transaction.TransactionRef;
        var amount = request.Amount.ToString("F2");
        var productInfo = request.Description ?? "FloraEdge Order";
        var firstName = request.CustomerEmail?.Split('@')[0] ?? "Customer";
        var email = request.CustomerEmail ?? "";
        var phone = request.CustomerPhone ?? "";
        
        // Generate hash: sha512(key|txnid|amount|productinfo|firstname|email|udf1|udf2|udf3|udf4|udf5||||||salt)
        var hashString = $"{PublicKey}|{txnId}|{amount}|{productInfo}|{firstName}|{email}|||||||||||{SecretKey}";
        var hash = ComputeSha512(hashString);

        var paymentUrl = $"{GetApiBaseUrl()}/_payment";

        return new CreatePaymentResultDto(
            TransactionId: transaction.Id,
            TransactionRef: transaction.TransactionRef,
            GatewayOrderId: txnId,
            PaymentUrl: paymentUrl,
            ClientSecret: null,
            QrCode: null,
            AdditionalData: new Dictionary<string, object>
            {
                ["key"] = PublicKey,
                ["txnid"] = txnId,
                ["amount"] = amount,
                ["productinfo"] = productInfo,
                ["firstname"] = firstName,
                ["email"] = email,
                ["phone"] = phone,
                ["surl"] = request.ReturnUrl ?? "",
                ["furl"] = request.CancelUrl ?? "",
                ["hash"] = hash,
                ["service_provider"] = "payu_paisa"
            }
        );
    }

    public override Task<VerifyPaymentResultDto> VerifyPaymentAsync(VerifyPaymentDto request)
    {
        // Verify reverse hash from PayU callback
        var additionalData = request.AdditionalData ?? new Dictionary<string, string>();
        
        if (!additionalData.TryGetValue("status", out var status) ||
            !additionalData.TryGetValue("mihpayid", out var mihpayid))
        {
            return Task.FromResult(new VerifyPaymentResultDto(false, GatewayPaymentStatus.Failed, "Missing callback data", null));
        }

        // Verify hash
        var reverseHashString = $"{SecretKey}|{additionalData.GetValueOrDefault("status")}|||||||||||" +
            $"{additionalData.GetValueOrDefault("email")}|{additionalData.GetValueOrDefault("firstname")}|" +
            $"{additionalData.GetValueOrDefault("productinfo")}|{additionalData.GetValueOrDefault("amount")}|" +
            $"{additionalData.GetValueOrDefault("txnid")}|{PublicKey}";
        
        var expectedHash = ComputeSha512(reverseHashString);
        var receivedHash = additionalData.GetValueOrDefault("hash", "");

        if (!string.Equals(expectedHash, receivedHash, StringComparison.OrdinalIgnoreCase))
        {
            Logger.LogWarning("PayU hash verification failed");
            return Task.FromResult(new VerifyPaymentResultDto(false, GatewayPaymentStatus.Failed, "Invalid hash", null));
        }

        var txnStatus = status.ToLowerInvariant() switch
        {
            "success" => GatewayPaymentStatus.Completed,
            "failure" => GatewayPaymentStatus.Failed,
            "pending" => GatewayPaymentStatus.Pending,
            _ => GatewayPaymentStatus.Failed
        };

        return Task.FromResult(new VerifyPaymentResultDto(
            Success: txnStatus == GatewayPaymentStatus.Completed,
            Status: txnStatus,
            Message: status,
            Transaction: null
        ));
    }

    public override async Task<RefundResultDto> RefundAsync(PaymentTransaction transaction, decimal amount, string? reason)
    {
        var command = "cancel_refund_transaction";
        var hash = ComputeSha512($"{PublicKey}|{command}|{transaction.GatewayPaymentId}|{SecretKey}");

        var formData = new Dictionary<string, string>
        {
            ["key"] = PublicKey,
            ["command"] = command,
            ["var1"] = transaction.GatewayPaymentId!,
            ["var2"] = transaction.TransactionRef,
            ["var3"] = amount.ToString("F2"),
            ["hash"] = hash
        };

        var content = new FormUrlEncodedContent(formData);
        var response = await _httpClient.PostAsync($"{GetApiBaseUrl()}/merchant/postservice.php?form=2", content);

        if (!response.IsSuccessStatusCode)
        {
            var error = await response.Content.ReadAsStringAsync();
            return new RefundResultDto(false, null, 0, $"Refund failed: {error}");
        }

        var result = await response.Content.ReadFromJsonAsync<JsonElement>();
        var refundStatus = result.GetProperty("status").GetInt32();

        return refundStatus == 1
            ? new RefundResultDto(true, result.GetProperty("request_id").GetString(), amount, "Refund initiated")
            : new RefundResultDto(false, null, 0, result.GetProperty("msg").GetString());
    }

    public override Task<WebhookEventDto?> ParseWebhookAsync(string payload, string? signature, Dictionary<string, string>? headers)
    {
        try
        {
            var data = JsonSerializer.Deserialize<JsonElement>(payload);
            var status = data.GetProperty("status").GetString();
            var txnId = data.GetProperty("txnid").GetString();
            var mihpayid = data.GetProperty("mihpayid").GetString();

            return Task.FromResult<WebhookEventDto?>(new WebhookEventDto(
                EventType: $"payment.{status}",
                PaymentId: mihpayid,
                OrderId: txnId,
                NewStatus: MapStatusToGatewayStatus(status),
                Amount: data.TryGetProperty("amount", out var amt) ? decimal.Parse(amt.GetString()!) : null,
                Currency: "INR",
                Data: null
            ));
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Failed to parse PayU webhook");
            return Task.FromResult<WebhookEventDto?>(null);
        }
    }

    public override async Task<PaymentGatewayTestResultDto> TestConnectionAsync()
    {
        try
        {
            // PayU doesn't have a direct test endpoint, verify by checking key format
            if (string.IsNullOrEmpty(PublicKey) || string.IsNullOrEmpty(SecretKey))
            {
                return new PaymentGatewayTestResultDto(false, "Missing API keys", DateTime.UtcNow);
            }

            // Try to call verify_payment API with a dummy transaction
            var hash = ComputeSha512($"{PublicKey}|verify_payment|test|{SecretKey}");
            var formData = new Dictionary<string, string>
            {
                ["key"] = PublicKey,
                ["command"] = "verify_payment",
                ["var1"] = "test",
                ["hash"] = hash
            };

            var content = new FormUrlEncodedContent(formData);
            var response = await _httpClient.PostAsync($"{GetApiBaseUrl()}/merchant/postservice.php?form=2", content);

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
        var hash = ComputeSha512($"{PublicKey}|verify_payment|{gatewayPaymentId}|{SecretKey}");
        var formData = new Dictionary<string, string>
        {
            ["key"] = PublicKey,
            ["command"] = "verify_payment",
            ["var1"] = gatewayPaymentId,
            ["hash"] = hash
        };

        var content = new FormUrlEncodedContent(formData);
        var response = await _httpClient.PostAsync($"{GetApiBaseUrl()}/merchant/postservice.php?form=2", content);

        if (!response.IsSuccessStatusCode)
            return GatewayPaymentStatus.Pending;

        var result = await response.Content.ReadFromJsonAsync<JsonElement>();
        var status = result.GetProperty("transaction_details")
            .GetProperty(gatewayPaymentId)
            .GetProperty("status").GetString();

        return MapStatusToGatewayStatus(status) ?? GatewayPaymentStatus.Pending;
    }

    private static string ComputeSha512(string input)
    {
        var bytes = SHA512.HashData(Encoding.UTF8.GetBytes(input));
        return BitConverter.ToString(bytes).Replace("-", "").ToLowerInvariant();
    }

    private static GatewayPaymentStatus? MapStatusToGatewayStatus(string? status) => status?.ToLowerInvariant() switch
    {
        "success" or "captured" => GatewayPaymentStatus.Completed,
        "failure" or "failed" => GatewayPaymentStatus.Failed,
        "pending" => GatewayPaymentStatus.Pending,
        "refunded" => GatewayPaymentStatus.Refunded,
        _ => null
    };
}
