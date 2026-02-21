using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Payments.Gateways;

/// <summary>
/// HyperPay payment gateway implementation (GCC/MENA)
/// </summary>
public class HyperPayGateway : BasePaymentGateway
{
    private readonly HttpClient _httpClient;
    
    public override PaymentGatewayType GatewayType => PaymentGatewayType.HyperPay;

    public HyperPayGateway(HttpClient httpClient, ILogger<HyperPayGateway> logger) : base(logger)
    {
        _httpClient = httpClient;
    }

    protected override string GetApiBaseUrl() => IsSandbox 
        ? "https://eu-test.oppwa.com" 
        : "https://eu-prod.oppwa.com";

    public override async Task<CreatePaymentResultDto> CreatePaymentAsync(CreatePaymentDto request, PaymentTransaction transaction)
    {
        var formData = new Dictionary<string, string>
        {
            ["entityId"] = MerchantId!,
            ["amount"] = request.Amount.ToString("F2"),
            ["currency"] = request.Currency,
            ["paymentType"] = "DB", // Debit
            ["merchantTransactionId"] = transaction.TransactionRef,
            ["customer.email"] = request.CustomerEmail ?? "",
            ["customer.phone"] = request.CustomerPhone ?? "",
            ["shopperResultUrl"] = request.ReturnUrl ?? ""
        };

        var content = new FormUrlEncodedContent(formData);
        
        using var httpRequest = new HttpRequestMessage(HttpMethod.Post, $"{GetApiBaseUrl()}/v1/checkouts");
        httpRequest.Headers.Add("Authorization", $"Bearer {SecretKey}");
        httpRequest.Content = content;

        var response = await _httpClient.SendAsync(httpRequest);

        if (!response.IsSuccessStatusCode)
        {
            var error = await response.Content.ReadAsStringAsync();
            Logger.LogError("HyperPay checkout creation failed: {Error}", error);
            throw new PaymentGatewayException("Failed to create HyperPay checkout", error);
        }

        var result = await response.Content.ReadFromJsonAsync<JsonElement>();
        var checkoutId = result.GetProperty("id").GetString()!;
        
        var paymentUrl = IsSandbox
            ? $"https://eu-test.oppwa.com/v1/paymentWidgets.js?checkoutId={checkoutId}"
            : $"https://eu-prod.oppwa.com/v1/paymentWidgets.js?checkoutId={checkoutId}";

        return new CreatePaymentResultDto(
            TransactionId: transaction.Id,
            TransactionRef: transaction.TransactionRef,
            GatewayOrderId: checkoutId,
            PaymentUrl: paymentUrl,
            ClientSecret: checkoutId,
            QrCode: null,
            AdditionalData: new Dictionary<string, object>
            {
                ["checkoutId"] = checkoutId,
                ["entityId"] = MerchantId!,
                ["shopperResultUrl"] = request.ReturnUrl ?? "",
                ["brands"] = "VISA MASTER MADA"
            }
        );
    }

    public override async Task<VerifyPaymentResultDto> VerifyPaymentAsync(VerifyPaymentDto request)
    {
        var resourcePath = request.AdditionalData?.GetValueOrDefault("resourcePath") ?? 
                          $"/v1/checkouts/{request.GatewayPaymentId}/payment";
        
        using var httpRequest = new HttpRequestMessage(
            HttpMethod.Get, 
            $"{GetApiBaseUrl()}{resourcePath}?entityId={MerchantId}");
        httpRequest.Headers.Add("Authorization", $"Bearer {SecretKey}");

        var response = await _httpClient.SendAsync(httpRequest);

        if (!response.IsSuccessStatusCode)
        {
            return new VerifyPaymentResultDto(false, GatewayPaymentStatus.Failed, "Payment not found", null);
        }

        var result = await response.Content.ReadFromJsonAsync<JsonElement>();
        var resultCode = result.GetProperty("result").GetProperty("code").GetString()!;
        var resultDescription = result.GetProperty("result").GetProperty("description").GetString();

        var txnStatus = GetStatusFromResultCode(resultCode);

        return new VerifyPaymentResultDto(
            Success: txnStatus == GatewayPaymentStatus.Completed,
            Status: txnStatus,
            Message: resultDescription,
            Transaction: null
        );
    }

    public override async Task<RefundResultDto> RefundAsync(PaymentTransaction transaction, decimal amount, string? reason)
    {
        var formData = new Dictionary<string, string>
        {
            ["entityId"] = MerchantId!,
            ["amount"] = amount.ToString("F2"),
            ["currency"] = transaction.Currency,
            ["paymentType"] = "RF" // Refund
        };

        var content = new FormUrlEncodedContent(formData);
        
        using var httpRequest = new HttpRequestMessage(
            HttpMethod.Post, 
            $"{GetApiBaseUrl()}/v1/payments/{transaction.GatewayPaymentId}");
        httpRequest.Headers.Add("Authorization", $"Bearer {SecretKey}");
        httpRequest.Content = content;

        var response = await _httpClient.SendAsync(httpRequest);

        if (!response.IsSuccessStatusCode)
        {
            var error = await response.Content.ReadAsStringAsync();
            return new RefundResultDto(false, null, 0, $"Refund failed: {error}");
        }

        var result = await response.Content.ReadFromJsonAsync<JsonElement>();
        var resultCode = result.GetProperty("result").GetProperty("code").GetString()!;
        var refundId = result.TryGetProperty("id", out var id) ? id.GetString() : null;

        return IsSuccessCode(resultCode)
            ? new RefundResultDto(true, refundId, amount, "Refund processed")
            : new RefundResultDto(false, refundId, 0, result.GetProperty("result").GetProperty("description").GetString());
    }

    public override Task<WebhookEventDto?> ParseWebhookAsync(string payload, string? signature, Dictionary<string, string>? headers)
    {
        try
        {
            var data = JsonSerializer.Deserialize<JsonElement>(payload);
            var paymentId = data.GetProperty("id").GetString();
            var merchantTxnId = data.TryGetProperty("merchantTransactionId", out var mtid) ? mtid.GetString() : null;
            var resultCode = data.GetProperty("result").GetProperty("code").GetString()!;

            return Task.FromResult<WebhookEventDto?>(new WebhookEventDto(
                EventType: $"payment.{resultCode}",
                PaymentId: paymentId,
                OrderId: merchantTxnId,
                NewStatus: GetStatusFromResultCode(resultCode),
                Amount: data.TryGetProperty("amount", out var amt) ? decimal.Parse(amt.GetString()!) : null,
                Currency: data.TryGetProperty("currency", out var cur) ? cur.GetString() : null,
                Data: null
            ));
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Failed to parse HyperPay webhook");
            return Task.FromResult<WebhookEventDto?>(null);
        }
    }

    public override async Task<PaymentGatewayTestResultDto> TestConnectionAsync()
    {
        try
        {
            // Create a minimal checkout to test credentials
            var formData = new Dictionary<string, string>
            {
                ["entityId"] = MerchantId!,
                ["amount"] = "0.01",
                ["currency"] = Currency,
                ["paymentType"] = "DB"
            };

            var content = new FormUrlEncodedContent(formData);
            
            using var httpRequest = new HttpRequestMessage(HttpMethod.Post, $"{GetApiBaseUrl()}/v1/checkouts");
            httpRequest.Headers.Add("Authorization", $"Bearer {SecretKey}");
            httpRequest.Content = content;

            var response = await _httpClient.SendAsync(httpRequest);

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
        using var httpRequest = new HttpRequestMessage(
            HttpMethod.Get, 
            $"{GetApiBaseUrl()}/v1/payments/{gatewayPaymentId}?entityId={MerchantId}");
        httpRequest.Headers.Add("Authorization", $"Bearer {SecretKey}");

        var response = await _httpClient.SendAsync(httpRequest);

        if (!response.IsSuccessStatusCode)
            return GatewayPaymentStatus.Pending;

        var result = await response.Content.ReadFromJsonAsync<JsonElement>();
        var resultCode = result.GetProperty("result").GetProperty("code").GetString()!;

        return GetStatusFromResultCode(resultCode);
    }

    private static GatewayPaymentStatus GetStatusFromResultCode(string code)
    {
        // HyperPay result codes: https://wordpresshyperpay.docs.oppwa.com/reference/resultCodes
        return code switch
        {
            var c when c.StartsWith("000.000.") || c.StartsWith("000.100.") => GatewayPaymentStatus.Completed,
            var c when c.StartsWith("000.200.") => GatewayPaymentStatus.Pending, // Pending review
            var c when c.StartsWith("800.") || c.StartsWith("900.") => GatewayPaymentStatus.Failed,
            var c when c.StartsWith("700.") => GatewayPaymentStatus.Cancelled,
            _ => GatewayPaymentStatus.Pending
        };
    }

    private static bool IsSuccessCode(string code) => 
        code.StartsWith("000.000.") || code.StartsWith("000.100.");
}
