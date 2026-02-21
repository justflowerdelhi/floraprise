using Microsoft.Extensions.Logging;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Payments;

/// <summary>
/// Base class for payment gateway implementations
/// </summary>
public abstract class BasePaymentGateway : IPaymentGateway
{
    protected PaymentGatewayConfig? Config { get; private set; }
    protected ILogger Logger { get; }
    
    public abstract PaymentGatewayType GatewayType { get; }
    
    protected string PublicKey => Config?.PublicKey ?? throw new InvalidOperationException("Gateway not initialized");
    protected string SecretKey { get; private set; } = string.Empty;
    protected string? WebhookSecret { get; private set; }
    protected string? MerchantId => Config?.MerchantId;
    protected bool IsSandbox => Config?.Environment == GatewayEnvironment.Sandbox;
    protected string Currency => Config?.Currency ?? "USD";

    protected BasePaymentGateway(ILogger logger)
    {
        Logger = logger;
    }

    public virtual Task InitializeAsync(PaymentGatewayConfig config)
    {
        Config = config;
        // Decrypt secrets - in production, use proper encryption service
        SecretKey = DecryptSecret(config.SecretKeyEncrypted);
        WebhookSecret = config.WebhookSecretEncrypted != null 
            ? DecryptSecret(config.WebhookSecretEncrypted) 
            : null;
        
        return Task.CompletedTask;
    }

    public abstract Task<CreatePaymentResultDto> CreatePaymentAsync(CreatePaymentDto request, PaymentTransaction transaction);
    
    public abstract Task<VerifyPaymentResultDto> VerifyPaymentAsync(VerifyPaymentDto request);
    
    public abstract Task<RefundResultDto> RefundAsync(PaymentTransaction transaction, decimal amount, string? reason);
    
    public abstract Task<WebhookEventDto?> ParseWebhookAsync(string payload, string? signature, Dictionary<string, string>? headers);
    
    public abstract Task<PaymentGatewayTestResultDto> TestConnectionAsync();
    
    public abstract Task<GatewayPaymentStatus> GetPaymentStatusAsync(string gatewayPaymentId);

    /// <summary>
    /// Decrypt encrypted secret - override with actual encryption in production
    /// </summary>
    protected virtual string DecryptSecret(string encryptedSecret)
    {
        // TODO: Implement proper AES decryption with key from secure vault
        // For now, using base64 encoding as placeholder
        try
        {
            var bytes = Convert.FromBase64String(encryptedSecret);
            return System.Text.Encoding.UTF8.GetString(bytes);
        }
        catch
        {
            // If not base64, return as-is (for development)
            return encryptedSecret;
        }
    }

    /// <summary>
    /// Encrypt secret for storage
    /// </summary>
    public static string EncryptSecret(string plainSecret)
    {
        // TODO: Implement proper AES encryption with key from secure vault
        // For now, using base64 encoding as placeholder
        var bytes = System.Text.Encoding.UTF8.GetBytes(plainSecret);
        return Convert.ToBase64String(bytes);
    }

    /// <summary>
    /// Generate idempotency key for API calls
    /// </summary>
    protected string GenerateIdempotencyKey(string transactionRef)
    {
        return $"{Config?.CompanyId}_{transactionRef}_{DateTime.UtcNow:yyyyMMddHHmm}";
    }

    /// <summary>
    /// Get API base URL based on environment
    /// </summary>
    protected abstract string GetApiBaseUrl();
}
