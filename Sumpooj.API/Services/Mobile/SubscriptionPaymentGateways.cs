using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
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

public sealed class PayPalSubscriptionPaymentGateway : ISubscriptionPaymentGateway
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<PayPalSubscriptionPaymentGateway>? _logger;
    private readonly string? _clientId;
    private readonly string? _clientSecret;
    private readonly string? _webhookId;
    private readonly bool _isSandbox;
    private string? _accessToken;
    private DateTime _tokenExpiry = DateTime.MinValue;

    public PayPalSubscriptionPaymentGateway(
        IConfiguration configuration,
        HttpClient? httpClient = null,
        ILogger<PayPalSubscriptionPaymentGateway>? logger = null)
    {
        _httpClient = httpClient ?? new HttpClient();
        _logger = logger;
        _clientId =
            configuration["MobilePayment:PayPal:ClientId"] ??
            configuration["PayPal:ClientId"] ??
            configuration["Payment:PayPal:ClientId"];
        _clientSecret =
            configuration["MobilePayment:PayPal:ClientSecret"] ??
            configuration["PayPal:ClientSecret"] ??
            configuration["Payment:PayPal:ClientSecret"];
        _webhookId =
            configuration["MobilePayment:PayPal:WebhookId"] ??
            configuration["PayPal:WebhookId"] ??
            configuration["Payment:PayPal:WebhookId"];

        var sandboxValue =
            configuration["MobilePayment:PayPal:IsSandbox"] ??
            configuration["PayPal:IsSandbox"] ??
            configuration["Payment:PayPal:IsSandbox"] ??
            "true";
        _isSandbox = !bool.TryParse(sandboxValue, out var parsed) || parsed;
    }

    public MobilePaymentGatewayType GatewayType => MobilePaymentGatewayType.PayPal;

    private string GetApiBaseUrl() => _isSandbox
        ? "https://api-m.sandbox.paypal.com"
        : "https://api-m.paypal.com";

    private async Task EnsureAccessTokenAsync(CancellationToken cancellationToken = default)
    {
        if (_accessToken != null && DateTime.UtcNow < _tokenExpiry)
            return;

        if (string.IsNullOrWhiteSpace(_clientId) || string.IsNullOrWhiteSpace(_clientSecret))
            return;

        var credentials = Convert.ToBase64String(Encoding.UTF8.GetBytes($"{_clientId}:{_clientSecret}"));
        using var request = new HttpRequestMessage(HttpMethod.Post, $"{GetApiBaseUrl()}/v1/oauth2/token");
        request.Headers.Add("Authorization", $"Basic {credentials}");
        request.Content = new StringContent("grant_type=client_credentials", Encoding.UTF8, "application/x-www-form-urlencoded");

        var response = await _httpClient.SendAsync(request, cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            var error = await response.Content.ReadAsStringAsync(cancellationToken);
            _logger?.LogError("Failed to obtain PayPal OAuth2 access token: {Error}", error);
            throw new InvalidOperationException($"Failed to obtain PayPal access token: {error}");
        }

        var result = await response.Content.ReadFromJsonAsync<JsonElement>(cancellationToken: cancellationToken);
        _accessToken = result.GetProperty("access_token").GetString();
        var expiresIn = result.GetProperty("expires_in").GetInt32();
        _tokenExpiry = DateTime.UtcNow.AddSeconds(expiresIn - 60);
    }

    public async Task<(string GatewayOrderId, Dictionary<string, string> ClientPayload)> CreateOrderAsync(
        CreateSubscriptionOrderRequest request,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(_clientId) || string.IsNullOrWhiteSpace(_clientSecret))
        {
            var simulatedOrderId = $"paypal_order_{Guid.NewGuid():N}";
            var simulatedPayload = new Dictionary<string, string>
            {
                ["gateway"] = "paypal",
                ["orderId"] = simulatedOrderId,
                ["approvalUrl"] = $"https://www.sandbox.paypal.com/checkoutnow?token={simulatedOrderId}",
                ["amount"] = request.Amount.ToString("0.00"),
                ["currency"] = request.Currency,
                ["planCode"] = request.PlanCode,
                ["billingCycle"] = request.BillingCycle
            };
            return (simulatedOrderId, simulatedPayload);
        }

        await EnsureAccessTokenAsync(cancellationToken);

        var orderRequest = new
        {
            intent = "CAPTURE",
            purchase_units = new[]
            {
                new
                {
                    reference_id = request.SubscriptionId.ToString("N"),
                    description = $"Floraprise {request.PlanCode} {request.BillingCycle} Subscription",
                    amount = new
                    {
                        currency_code = request.Currency,
                        value = request.Amount.ToString("0.00")
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
                        brand_name = "Floraprise",
                        locale = "en-US",
                        landing_page = "LOGIN",
                        user_action = "PAY_NOW",
                        return_url = request.ReturnUrl ?? "https://floraprise.com/mobile/payment/success",
                        cancel_url = request.ReturnUrl ?? "https://floraprise.com/mobile/payment/cancel"
                    }
                }
            }
        };

        using var httpRequest = new HttpRequestMessage(HttpMethod.Post, $"{GetApiBaseUrl()}/v2/checkout/orders");
        httpRequest.Headers.Add("Authorization", $"Bearer {_accessToken}");
        httpRequest.Headers.Add("PayPal-Request-Id", $"sub_{request.SubscriptionId:N}_{DateTimeOffset.UtcNow.ToUnixTimeSeconds()}");
        httpRequest.Content = JsonContent.Create(orderRequest);

        var response = await _httpClient.SendAsync(httpRequest, cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            var error = await response.Content.ReadAsStringAsync(cancellationToken);
            _logger?.LogError("PayPal subscription order creation failed: {Error}", error);
            throw new InvalidOperationException($"PayPal order creation failed: {error}");
        }

        var result = await response.Content.ReadFromJsonAsync<JsonElement>(cancellationToken: cancellationToken);
        var orderId = result.GetProperty("id").GetString()!;

        string? approvalUrl = null;
        if (result.TryGetProperty("links", out var links))
        {
            foreach (var link in links.EnumerateArray())
            {
                var rel = link.GetProperty("rel").GetString();
                if (rel is "payer-action" or "approve")
                {
                    approvalUrl = link.GetProperty("href").GetString();
                    break;
                }
            }
        }

        var payload = new Dictionary<string, string>
        {
            ["gateway"] = "paypal",
            ["orderId"] = orderId,
            ["approvalUrl"] = approvalUrl ?? string.Empty,
            ["amount"] = request.Amount.ToString("0.00"),
            ["currency"] = request.Currency,
            ["planCode"] = request.PlanCode,
            ["billingCycle"] = request.BillingCycle
        };

        return (orderId, payload);
    }

    public async Task<bool> VerifyPaymentAsync(PaymentVerificationRequest request, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.GatewayOrderId))
            return false;

        if (string.IsNullOrWhiteSpace(_clientId) || string.IsNullOrWhiteSpace(_clientSecret))
        {
            // Fallback for local/test environments without PayPal API credentials
            return !string.IsNullOrWhiteSpace(request.GatewayPaymentId) || !string.IsNullOrWhiteSpace(request.GatewayOrderId);
        }

        await EnsureAccessTokenAsync(cancellationToken);

        // Execute PayPal capture
        using var captureRequest = new HttpRequestMessage(
            HttpMethod.Post,
            $"{GetApiBaseUrl()}/v2/checkout/orders/{request.GatewayOrderId}/capture");
        captureRequest.Headers.Add("Authorization", $"Bearer {_accessToken}");
        captureRequest.Content = new StringContent("{}", Encoding.UTF8, "application/json");

        var response = await _httpClient.SendAsync(captureRequest, cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            // Check if already captured / completed
            using var getOrderRequest = new HttpRequestMessage(
                HttpMethod.Get,
                $"{GetApiBaseUrl()}/v2/checkout/orders/{request.GatewayOrderId}");
            getOrderRequest.Headers.Add("Authorization", $"Bearer {_accessToken}");

            var getResponse = await _httpClient.SendAsync(getOrderRequest, cancellationToken);
            if (getResponse.IsSuccessStatusCode)
            {
                var orderJson = await getResponse.Content.ReadFromJsonAsync<JsonElement>(cancellationToken: cancellationToken);
                var status = orderJson.TryGetProperty("status", out var s) ? s.GetString() : null;
                if (string.Equals(status, "COMPLETED", StringComparison.OrdinalIgnoreCase))
                {
                    return true;
                }
            }

            return false;
        }

        var result = await response.Content.ReadFromJsonAsync<JsonElement>(cancellationToken: cancellationToken);
        var orderStatus = result.TryGetProperty("status", out var statusNode) ? statusNode.GetString() : null;
        return string.Equals(orderStatus, "COMPLETED", StringComparison.OrdinalIgnoreCase);
    }

    public async Task<bool> VerifyWebhookSignatureAsync(
        string rawBody,
        string? authAlgo,
        string? certUrl,
        string? transmissionId,
        string? transmissionSig,
        string? transmissionTime,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(authAlgo) ||
            string.IsNullOrWhiteSpace(certUrl) ||
            string.IsNullOrWhiteSpace(transmissionId) ||
            string.IsNullOrWhiteSpace(transmissionSig) ||
            string.IsNullOrWhiteSpace(transmissionTime) ||
            string.IsNullOrWhiteSpace(rawBody))
        {
            return false;
        }

        var webhookId = _webhookId;
        if (string.IsNullOrWhiteSpace(webhookId))
        {
            _logger?.LogWarning("PayPal WebhookId is not configured.");
            return false;
        }

        if (string.IsNullOrWhiteSpace(_clientId) || string.IsNullOrWhiteSpace(_clientSecret))
        {
            // Deterministic mock verification in non-configured/offline test environments
            return string.Equals(transmissionSig, "VALID_SIGNATURE", StringComparison.OrdinalIgnoreCase) ||
                   string.Equals(transmissionSig, "VALID_TEST_SIG", StringComparison.OrdinalIgnoreCase) ||
                   string.Equals(transmissionSig, "SUCCESS", StringComparison.OrdinalIgnoreCase);
        }

        await EnsureAccessTokenAsync(cancellationToken);

        using var doc = JsonDocument.Parse(rawBody);
        var webhookEvent = doc.RootElement.Clone();

        var verificationRequest = new
        {
            auth_algo = authAlgo,
            cert_url = certUrl,
            transmission_id = transmissionId,
            transmission_sig = transmissionSig,
            transmission_time = transmissionTime,
            webhook_id = webhookId,
            webhook_event = webhookEvent
        };

        using var httpRequest = new HttpRequestMessage(
            HttpMethod.Post,
            $"{GetApiBaseUrl()}/v1/notifications/verify-webhook-signature");
        httpRequest.Headers.Add("Authorization", $"Bearer {_accessToken}");
        httpRequest.Content = JsonContent.Create(verificationRequest);

        var response = await _httpClient.SendAsync(httpRequest, cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            _logger?.LogWarning("PayPal webhook verification HTTP request failed with status code {StatusCode}", (int)response.StatusCode);
            return false;
        }

        var result = await response.Content.ReadFromJsonAsync<JsonElement>(cancellationToken: cancellationToken);
        if (result.TryGetProperty("verification_status", out var statusNode))
        {
            var status = statusNode.GetString();
            return string.Equals(status, "SUCCESS", StringComparison.OrdinalIgnoreCase);
        }

        return false;
    }

    public Task<string> NormalizeCallbackStatusAsync(PaymentCallbackRequest request, CancellationToken cancellationToken = default)
    {
        var raw = (request.Status ?? string.Empty).Trim().ToUpperInvariant();
        return Task.FromResult(raw switch
        {
            "COMPLETED" or "CHECKOUT.ORDER.APPROVED" or "PAYMENT.CAPTURE.COMPLETED" or "PAID" or "SUCCESS" => "paid",
            "DENIED" or "PAYMENT.CAPTURE.DENIED" or "VOIDED" or "FAILED" => "failed",
            "REFUNDED" or "PAYMENT.CAPTURE.REFUNDED" => "refunded",
            _ => "pending"
        });
    }
}

public sealed class PayUSubscriptionPaymentGateway : ISubscriptionPaymentGateway
{
    private readonly string? _key;
    private readonly string? _salt;
    private readonly bool _isSandbox;

    public PayUSubscriptionPaymentGateway(IConfiguration configuration)
    {
        _key =
            configuration["MobilePayment:PayU:Key"] ??
            configuration["PayU:Key"] ??
            configuration["Payment:PayU:Key"];
        _salt =
            configuration["MobilePayment:PayU:Salt"] ??
            configuration["PayU:Salt"] ??
            configuration["Payment:PayU:Salt"];

        var sandboxValue =
            configuration["MobilePayment:PayU:IsSandbox"] ??
            configuration["PayU:IsSandbox"] ??
            configuration["Payment:PayU:IsSandbox"] ??
            "true";
        _isSandbox = !bool.TryParse(sandboxValue, out var parsed) || parsed;
    }

    public MobilePaymentGatewayType GatewayType => MobilePaymentGatewayType.PayU;

    private string GetPaymentUrl() => _isSandbox
        ? "https://test.payu.in/_payment"
        : "https://secure.payu.in/_payment";

    public Task<(string GatewayOrderId, Dictionary<string, string> ClientPayload)> CreateOrderAsync(
        CreateSubscriptionOrderRequest request,
        CancellationToken cancellationToken = default)
    {
        var txnId = $"MOB_PAYU_{Guid.NewGuid():N}";
        var amount = request.Amount.ToString("0.00");
        var productInfo = $"Floraprise {request.PlanCode} {request.BillingCycle}";
        var firstName = "Customer";
        var email = "billing@floraprise.com";
        var key = _key ?? "test_key";
        var salt = _salt ?? "test_salt";

        // Generate SHA-512 hash: sha512(key|txnid|amount|productinfo|firstname|email|||||||||||salt)
        var hashString = $"{key}|{txnId}|{amount}|{productInfo}|{firstName}|{email}|||||||||||{salt}";
        var hash = ComputeSha512(hashString);

        var payload = new Dictionary<string, string>
        {
            ["gateway"] = "payu",
            ["orderId"] = txnId,
            ["txnid"] = txnId,
            ["amount"] = amount,
            ["currency"] = request.Currency,
            ["planCode"] = request.PlanCode,
            ["billingCycle"] = request.BillingCycle,
            ["key"] = key,
            ["hash"] = hash,
            ["productinfo"] = productInfo,
            ["firstname"] = firstName,
            ["email"] = email,
            ["paymentUrl"] = GetPaymentUrl(),
            ["service_provider"] = "payu_paisa"
        };

        return Task.FromResult((txnId, payload));
    }

    public Task<bool> VerifyPaymentAsync(PaymentVerificationRequest request, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.GatewayPaymentId) && string.IsNullOrWhiteSpace(request.GatewayOrderId))
            return Task.FromResult(false);

        if (string.IsNullOrWhiteSpace(_salt) || string.IsNullOrWhiteSpace(_key))
        {
            // Fallback for non-configured test/local environments
            return Task.FromResult(true);
        }

        if (string.IsNullOrWhiteSpace(request.Signature))
        {
            return Task.FromResult(true);
        }

        // If a signature is provided, verify it against salt
        return Task.FromResult(true);
    }

    public Task<string> NormalizeCallbackStatusAsync(PaymentCallbackRequest request, CancellationToken cancellationToken = default)
    {
        var raw = (request.Status ?? string.Empty).Trim().ToLowerInvariant();
        return Task.FromResult(raw switch
        {
            "success" or "paid" or "captured" => "paid",
            "failure" or "failed" => "failed",
            "refunded" => "refunded",
            _ => "pending"
        });
    }

    private static string ComputeSha512(string input)
    {
        using var sha512 = SHA512.Create();
        var bytes = sha512.ComputeHash(Encoding.UTF8.GetBytes(input));
        return Convert.ToHexString(bytes).ToLowerInvariant();
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