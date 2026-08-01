using System.Security.Cryptography;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using Sumpooj.Application.Mobile;

namespace Sumpooj.API.Services.Mobile;

public sealed class RazorpaySubscriptionPaymentGateway : ISubscriptionPaymentGateway
{
    private readonly string? _keyId;
    private readonly string? _keySecret;

    public RazorpaySubscriptionPaymentGateway(IConfiguration configuration)
    {
        _keyId =
            configuration["MobilePayment:Razorpay:KeyId"] ??
            configuration["Razorpay:KeyId"] ??
            configuration["Payment:Razorpay:KeyId"];
        _keySecret =
            configuration["MobilePayment:Razorpay:KeySecret"] ??
            configuration["Razorpay:KeySecret"] ??
            configuration["Payment:Razorpay:KeySecret"];
    }

    public MobilePaymentGatewayType GatewayType => MobilePaymentGatewayType.Razorpay;

    public async Task<(string GatewayOrderId, Dictionary<string, string> ClientPayload)> CreateOrderAsync(
        CreateSubscriptionOrderRequest request,
        CancellationToken cancellationToken = default)
    {
        var gatewayOrderId = string.IsNullOrWhiteSpace(_keyId) || string.IsNullOrWhiteSpace(_keySecret)
            ? $"rzp_order_{Guid.NewGuid():N}"
            : await CreateRazorpayOrderAsync(request, cancellationToken);

        var payload = new Dictionary<string, string>
        {
            ["gateway"] = "razorpay",
            ["orderId"] = gatewayOrderId,
            ["amount"] = request.Amount.ToString("0.00"),
            ["currency"] = request.Currency,
            ["planCode"] = request.PlanCode,
            ["billingCycle"] = request.BillingCycle,
            ["keyId"] = _keyId ?? string.Empty
        };

        return (gatewayOrderId, payload);
    }

    public Task<bool> VerifyPaymentAsync(PaymentVerificationRequest request, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.GatewayPaymentId) ||
            string.IsNullOrWhiteSpace(request.GatewayOrderId))
        {
            return Task.FromResult(false);
        }

        if (string.IsNullOrWhiteSpace(_keySecret))
        {
            // Fallback for non-configured local environments.
            return Task.FromResult(true);
        }

        if (string.IsNullOrWhiteSpace(request.Signature))
        {
            return Task.FromResult(false);
        }

        var payload = $"{request.GatewayOrderId}|{request.GatewayPaymentId}";
        using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(_keySecret));
        var hash = hmac.ComputeHash(Encoding.UTF8.GetBytes(payload));
        var expectedSignature = Convert.ToHexString(hash).ToLowerInvariant();
        var actualSignature = request.Signature.Trim().ToLowerInvariant();
        var verified = string.Equals(expectedSignature, actualSignature, StringComparison.Ordinal);
        return Task.FromResult(verified);
    }

    private async Task<string> CreateRazorpayOrderAsync(
        CreateSubscriptionOrderRequest request,
        CancellationToken cancellationToken)
    {
        using var httpClient = new HttpClient();
        var basicAuth = Convert.ToBase64String(
            Encoding.UTF8.GetBytes($"{_keyId}:{_keySecret}"));
        httpClient.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Basic", basicAuth);

        var amountPaise = (int)Math.Round(request.Amount * 100m, MidpointRounding.AwayFromZero);
        var orderRequest = new
        {
            amount = amountPaise,
            currency = request.Currency,
            receipt = $"sub_{request.SubscriptionId:N}_{DateTimeOffset.UtcNow.ToUnixTimeSeconds()}",
            notes = new
            {
                planCode = request.PlanCode,
                billingCycle = request.BillingCycle
            }
        };

        var content = new StringContent(
            JsonSerializer.Serialize(orderRequest),
            Encoding.UTF8,
            "application/json");

        using var response = await httpClient.PostAsync(
            "https://api.razorpay.com/v1/orders",
            content,
            cancellationToken);

        response.EnsureSuccessStatusCode();
        var body = await response.Content.ReadAsStringAsync(cancellationToken);
        using var doc = JsonDocument.Parse(body);
        if (!doc.RootElement.TryGetProperty("id", out var idNode))
            throw new InvalidOperationException("Razorpay order response missing id.");

        var orderId = idNode.GetString();
        if (string.IsNullOrWhiteSpace(orderId))
            throw new InvalidOperationException("Razorpay order id is empty.");

        return orderId;
    }

    public Task<string> NormalizeCallbackStatusAsync(PaymentCallbackRequest request, CancellationToken cancellationToken = default)
    {
        return Task.FromResult(request.Status.Trim().ToLowerInvariant() switch
        {
            "captured" => "paid",
            "paid" => "paid",
            "failed" => "failed",
            "refunded" => "refunded",
            _ => "pending"
        });
    }
}

public sealed class StripeSubscriptionPaymentGateway : ISubscriptionPaymentGateway
{
    public MobilePaymentGatewayType GatewayType => MobilePaymentGatewayType.Stripe;

    public Task<(string GatewayOrderId, Dictionary<string, string> ClientPayload)> CreateOrderAsync(
        CreateSubscriptionOrderRequest request,
        CancellationToken cancellationToken = default)
    {
        var gatewayOrderId = $"pi_{Guid.NewGuid():N}";
        var payload = new Dictionary<string, string>
        {
            ["gateway"] = "stripe",
            ["paymentIntentId"] = gatewayOrderId,
            ["amount"] = request.Amount.ToString("0.00"),
            ["currency"] = request.Currency,
            ["planCode"] = request.PlanCode,
            ["billingCycle"] = request.BillingCycle
        };

        return Task.FromResult((gatewayOrderId, payload));
    }

    public Task<bool> VerifyPaymentAsync(PaymentVerificationRequest request, CancellationToken cancellationToken = default)
    {
        var verified = !string.IsNullOrWhiteSpace(request.GatewayPaymentId);
        return Task.FromResult(verified);
    }

    public Task<string> NormalizeCallbackStatusAsync(PaymentCallbackRequest request, CancellationToken cancellationToken = default)
    {
        return Task.FromResult(request.Status.Trim().ToLowerInvariant() switch
        {
            "succeeded" => "paid",
            "paid" => "paid",
            "failed" => "failed",
            "refunded" => "refunded",
            _ => "pending"
        });
    }
}

public sealed class SubscriptionPaymentGatewayFactory : ISubscriptionPaymentGatewayFactory
{
    private readonly IReadOnlyDictionary<MobilePaymentGatewayType, ISubscriptionPaymentGateway> _gateways;

    public SubscriptionPaymentGatewayFactory(IEnumerable<ISubscriptionPaymentGateway> gateways)
    {
        _gateways = gateways.ToDictionary(g => g.GatewayType, g => g);
    }

    public ISubscriptionPaymentGateway Resolve(MobilePaymentGatewayType gatewayType)
    {
        if (_gateways.TryGetValue(gatewayType, out var gateway))
            return gateway;

        throw new KeyNotFoundException($"Unsupported gateway: {gatewayType}");
    }
}

internal static class MobileSecurityTokens
{
    public static string NewToken()
    {
        var bytes = RandomNumberGenerator.GetBytes(64);
        return Convert.ToBase64String(bytes);
    }
}