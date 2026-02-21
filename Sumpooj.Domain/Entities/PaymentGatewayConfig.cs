using System.ComponentModel.DataAnnotations;

namespace Sumpooj.Domain.Entities;

/// <summary>
/// Supported payment gateway providers by region
/// </summary>
public enum PaymentGatewayType
{
    // India
    Razorpay = 1,
    PayU = 2,
    Cashfree = 3,
    
    // USA
    Stripe = 10,
    Square = 11,
    PayPal = 12,
    
    // GCC (Gulf Cooperation Council)
    PayTabs = 20,
    HyperPay = 21,
    TapPayments = 22,
    CheckoutCom = 23
}

/// <summary>
/// Payment gateway environment
/// </summary>
public enum GatewayEnvironment
{
    Sandbox = 0,
    Production = 1
}

/// <summary>
/// Tenant-specific payment gateway configuration
/// Each company can configure their own payment gateway
/// </summary>
public class PaymentGatewayConfig : BaseEntity
{
    public Guid CompanyId { get; private set; }
    public Company Company { get; private set; } = null!;
    
    public PaymentGatewayType GatewayType { get; private set; }
    
    /// <summary>
    /// Display name for this configuration (e.g., "Main Stripe Account")
    /// </summary>
    [MaxLength(100)]
    public string Name { get; private set; } = string.Empty;
    
    /// <summary>
    /// Public/Publishable Key (safe to expose to frontend)
    /// </summary>
    [MaxLength(500)]
    public string PublicKey { get; private set; } = string.Empty;
    
    /// <summary>
    /// Secret/Private Key (encrypted, never exposed)
    /// </summary>
    [MaxLength(1000)]
    public string SecretKeyEncrypted { get; private set; } = string.Empty;
    
    /// <summary>
    /// Webhook signing secret (encrypted)
    /// </summary>
    [MaxLength(500)]
    public string? WebhookSecretEncrypted { get; private set; }
    
    /// <summary>
    /// Merchant ID (required by some gateways like PayTabs, Square)
    /// </summary>
    [MaxLength(200)]
    public string? MerchantId { get; private set; }
    
    public GatewayEnvironment Environment { get; private set; }
    
    /// <summary>
    /// Primary currency for this gateway (ISO 4217)
    /// </summary>
    [MaxLength(3)]
    public string Currency { get; private set; } = "USD";
    
    /// <summary>
    /// Supported currencies (comma-separated ISO codes)
    /// </summary>
    [MaxLength(100)]
    public string? SupportedCurrencies { get; private set; }
    
    public bool IsActive { get; private set; }
    
    /// <summary>
    /// Is this the default gateway for the company?
    /// </summary>
    public bool IsDefault { get; private set; }
    
    /// <summary>
    /// Additional configuration as JSON (gateway-specific settings)
    /// </summary>
    public string? AdditionalConfig { get; private set; }
    
    /// <summary>
    /// Webhook URL for this gateway
    /// </summary>
    [MaxLength(500)]
    public string? WebhookUrl { get; private set; }
    
    public DateTime? LastTestedAt { get; private set; }
    public bool? LastTestSuccessful { get; private set; }

    private PaymentGatewayConfig() { } // EF Core

    public PaymentGatewayConfig(
        Guid companyId,
        PaymentGatewayType gatewayType,
        string name,
        string publicKey,
        string secretKeyEncrypted,
        GatewayEnvironment environment,
        string currency)
    {
        CompanyId = companyId;
        GatewayType = gatewayType;
        Name = name;
        PublicKey = publicKey;
        SecretKeyEncrypted = secretKeyEncrypted;
        Environment = environment;
        Currency = currency;
        IsActive = true;
    }

    public void UpdateCredentials(string publicKey, string secretKeyEncrypted, string? webhookSecretEncrypted)
    {
        PublicKey = publicKey;
        SecretKeyEncrypted = secretKeyEncrypted;
        WebhookSecretEncrypted = webhookSecretEncrypted;
    }

    public void SetMerchantId(string? merchantId) => MerchantId = merchantId;
    
    public void SetEnvironment(GatewayEnvironment environment) => Environment = environment;
    
    public void SetCurrency(string currency, string? supportedCurrencies = null)
    {
        Currency = currency;
        SupportedCurrencies = supportedCurrencies;
    }

    public void Activate() => IsActive = true;
    public void Deactivate() => IsActive = false;

    public void SetAsDefault()
    {
        IsDefault = true;
        IsActive = true;
    }

    public void RemoveDefault() => IsDefault = false;

    public void SetAdditionalConfig(string? config) => AdditionalConfig = config;
    
    public void SetWebhookUrl(string? url) => WebhookUrl = url;

    public void RecordTestResult(bool successful)
    {
        LastTestedAt = DateTime.UtcNow;
        LastTestSuccessful = successful;
    }

    /// <summary>
    /// Get the region for this gateway type
    /// </summary>
    public static string GetRegion(PaymentGatewayType gatewayType) => gatewayType switch
    {
        PaymentGatewayType.Razorpay or PaymentGatewayType.PayU or PaymentGatewayType.Cashfree => "IN",
        PaymentGatewayType.Stripe or PaymentGatewayType.Square or PaymentGatewayType.PayPal => "US",
        PaymentGatewayType.PayTabs or PaymentGatewayType.HyperPay or PaymentGatewayType.TapPayments or PaymentGatewayType.CheckoutCom => "GCC",
        _ => "GLOBAL"
    };
}
