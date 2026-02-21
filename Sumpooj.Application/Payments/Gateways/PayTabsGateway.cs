using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Payments.Gateways;

/// <summary>
/// PayTabs payment gateway implementation (GCC/MENA)
/// </summary>
public class PayTabsGateway : BasePaymentGateway
{
    private readonly HttpClient _httpClient;
    
    public override PaymentGatewayType GatewayType => PaymentGatewayType.PayTabs;

    public PayTabsGateway(HttpClient httpClient, ILogger<PayTabsGateway> logger) : base(logger)
    {
        _httpClient = httpClient;
    }

    protected override string GetApiBaseUrl() => "https://secure.paytabs.sa"; // Use regional endpoint based on config

    public override async Task InitializeAsync(PaymentGatewayConfig config)
    {
        await base.InitializeAsync(config);
        
        _httpClient.DefaultRequestHeaders.Clear();
        _httpClient.DefaultRequestHeaders.Add("authorization", SecretKey);
    }

    public override async Task<CreatePaymentResultDto> CreatePaymentAsync(CreatePaymentDto request, PaymentTransaction transaction)
    {
        var paymentRequest = new
        {
            profile_id = MerchantId,
            tran_type = "sale",
            tran_class = "ecom",
            cart_id = transaction.TransactionRef,
            cart_description = request.Description ?? "FloraEdge Order",
            cart_currency = request.Currency,
            cart_amount = request.Amount,
            callback = Config?.WebhookUrl,
            @return = request.ReturnUrl,
            customer_details = new
            {
                name = request.CustomerEmail?.Split('@')[0] ?? "Customer",
                email = request.CustomerEmail ?? "customer@example.com",
                phone = request.CustomerPhone ?? "0000000000",
                street1 = "N/A",
                city = "N/A",
                state = "N/A",
                country = GetCountryCode(),
                zip = "00000"
            }
        };

        var response = await _httpClient.PostAsJsonAsync($"{GetApiBaseUrl()}/payment/request", paymentRequest);

        if (!response.IsSuccessStatusCode)
        {
            var error = await response.Content.ReadAsStringAsync();
            Logger.LogError("PayTabs payment request failed: {Error}", error);
            throw new PaymentGatewayException("Failed to create PayTabs payment", error);
        }

        var result = await response.Content.ReadFromJsonAsync<JsonElement>();
        var tranRef = result.GetProperty("tran_ref").GetString()!;
        var redirectUrl = result.GetProperty("redirect_url").GetString()!;

        return new CreatePaymentResultDto(
            TransactionId: transaction.Id,
            TransactionRef: transaction.TransactionRef,
            GatewayOrderId: tranRef,
            PaymentUrl: redirectUrl,
            ClientSecret: tranRef,
            QrCode: null,
            AdditionalData: new Dictionary<string, object>
            {
                ["tran_ref"] = tranRef,
                ["profile_id"] = MerchantId ?? ""
            }
        );
    }

    public override async Task<VerifyPaymentResultDto> VerifyPaymentAsync(VerifyPaymentDto request)
    {
        var queryRequest = new
        {
            profile_id = MerchantId,
            tran_ref = request.GatewayPaymentId
        };

        var response = await _httpClient.PostAsJsonAsync($"{GetApiBaseUrl()}/payment/query", queryRequest);

        if (!response.IsSuccessStatusCode)
        {
            return new VerifyPaymentResultDto(false, GatewayPaymentStatus.Failed, "Transaction not found", null);
        }

        var result = await response.Content.ReadFromJsonAsync<JsonElement>();
        var paymentResult = result.GetProperty("payment_result");
        var responseStatus = paymentResult.GetProperty("response_status").GetString();
        var responseMessage = paymentResult.GetProperty("response_message").GetString();

        var txnStatus = responseStatus switch
        {
            "A" => GatewayPaymentStatus.Completed,    // Authorized/Approved
            "H" => GatewayPaymentStatus.Pending,      // On Hold
            "P" => GatewayPaymentStatus.Pending,      // Pending
            "V" => GatewayPaymentStatus.Cancelled,    // Voided
            "E" or "D" => GatewayPaymentStatus.Failed, // Error/Declined
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
            profile_id = MerchantId,
            tran_type = "refund",
            tran_class = "ecom",
            cart_id = $"refund_{transaction.TransactionRef}",
            cart_description = reason ?? "Refund",
            cart_currency = transaction.Currency,
            cart_amount = amount,
            tran_ref = transaction.GatewayPaymentId
        };

        var response = await _httpClient.PostAsJsonAsync($"{GetApiBaseUrl()}/payment/request", refundRequest);

        if (!response.IsSuccessStatusCode)
        {
            var error = await response.Content.ReadAsStringAsync();
            return new RefundResultDto(false, null, 0, $"Refund failed: {error}");
        }

        var result = await response.Content.ReadFromJsonAsync<JsonElement>();
        var paymentResult = result.GetProperty("payment_result");
        var responseStatus = paymentResult.GetProperty("response_status").GetString();
        var tranRef = result.GetProperty("tran_ref").GetString();

        return responseStatus == "A"
            ? new RefundResultDto(true, tranRef, amount, "Refund processed")
            : new RefundResultDto(false, tranRef, 0, paymentResult.GetProperty("response_message").GetString());
    }

    public override Task<WebhookEventDto?> ParseWebhookAsync(string payload, string? signature, Dictionary<string, string>? headers)
    {
        try
        {
            var data = JsonSerializer.Deserialize<JsonElement>(payload);
            var tranRef = data.GetProperty("tran_ref").GetString();
            var cartId = data.GetProperty("cart_id").GetString();
            var paymentResult = data.GetProperty("payment_result");
            var responseStatus = paymentResult.GetProperty("response_status").GetString();

            return Task.FromResult<WebhookEventDto?>(new WebhookEventDto(
                EventType: $"payment.{responseStatus}",
                PaymentId: tranRef,
                OrderId: cartId,
                NewStatus: MapResponseStatus(responseStatus),
                Amount: data.TryGetProperty("cart_amount", out var amt) ? amt.GetDecimal() : null,
                Currency: data.TryGetProperty("cart_currency", out var cur) ? cur.GetString() : null,
                Data: null
            ));
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Failed to parse PayTabs webhook");
            return Task.FromResult<WebhookEventDto?>(null);
        }
    }

    public override async Task<PaymentGatewayTestResultDto> TestConnectionAsync()
    {
        try
        {
            // PayTabs doesn't have a dedicated test endpoint
            // Verify credentials by making a query request with invalid tran_ref
            var queryRequest = new
            {
                profile_id = MerchantId,
                tran_ref = "test_connection"
            };

            var response = await _httpClient.PostAsJsonAsync($"{GetApiBaseUrl()}/payment/query", queryRequest);
            
            // Even a 404 for invalid tran_ref means credentials work
            return new PaymentGatewayTestResultDto(
                Success: response.StatusCode != System.Net.HttpStatusCode.Unauthorized,
                Message: response.StatusCode != System.Net.HttpStatusCode.Unauthorized 
                    ? "Connection successful" 
                    : "Invalid credentials",
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
        var queryRequest = new
        {
            profile_id = MerchantId,
            tran_ref = gatewayPaymentId
        };

        var response = await _httpClient.PostAsJsonAsync($"{GetApiBaseUrl()}/payment/query", queryRequest);

        if (!response.IsSuccessStatusCode)
            return GatewayPaymentStatus.Pending;

        var result = await response.Content.ReadFromJsonAsync<JsonElement>();
        var responseStatus = result.GetProperty("payment_result").GetProperty("response_status").GetString();

        return MapResponseStatus(responseStatus) ?? GatewayPaymentStatus.Pending;
    }

    private string GetCountryCode()
    {
        return Config?.Currency switch
        {
            "SAR" => "SA",
            "AED" => "AE",
            "BHD" => "BH",
            "KWD" => "KW",
            "OMR" => "OM",
            "QAR" => "QA",
            _ => "SA"
        };
    }

    private static GatewayPaymentStatus? MapResponseStatus(string? status) => status switch
    {
        "A" => GatewayPaymentStatus.Completed,
        "H" or "P" => GatewayPaymentStatus.Pending,
        "V" => GatewayPaymentStatus.Cancelled,
        "E" or "D" => GatewayPaymentStatus.Failed,
        _ => null
    };
}
