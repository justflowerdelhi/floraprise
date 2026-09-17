using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Logging;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Payments;

/// <summary>
/// Base class for payment gateway implementations with hardened secret encryption
/// </summary>
public abstract class BasePaymentGateway : IPaymentGateway
{
    public const string EncryptedV2Prefix = "enc:v2:";
    public const string EncryptedV1Prefix = "enc:v1:";
    
    private static readonly byte[] FallbackDevelopmentMasterKey = SHA256.HashData(Encoding.UTF8.GetBytes("Floraprise:Development:PaymentMasterKey:ControlledDevOnly"));
    private static string? _testMasterKey;
    private static bool? _forcedProductionMode;

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

    /// <summary>
    /// Checks whether the current runtime environment is considered Production.
    /// </summary>
    public static bool IsProductionEnvironment()
    {
        if (_forcedProductionMode.HasValue)
            return _forcedProductionMode.Value;

        var aspnetEnv = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT");
        var dotnetEnv = Environment.GetEnvironmentVariable("DOTNET_ENVIRONMENT");
        
        return string.Equals(aspnetEnv, "Production", StringComparison.OrdinalIgnoreCase) ||
               string.Equals(dotnetEnv, "Production", StringComparison.OrdinalIgnoreCase);
    }

    /// <summary>
    /// Validates payment security configuration during application startup.
    /// In Production, FLORAPRISE_PAYMENT_MASTER_KEY must be configured.
    /// </summary>
    public static void ValidateConfiguration(bool isProduction)
    {
        if (!isProduction)
            return;

        var envKey = _testMasterKey ?? Environment.GetEnvironmentVariable("FLORAPRISE_PAYMENT_MASTER_KEY");
        if (string.IsNullOrWhiteSpace(envKey))
        {
            throw new InvalidOperationException(
                "CRITICAL CONFIGURATION ERROR: Payment Master Key is missing in Production environment. " +
                "The environment variable 'FLORAPRISE_PAYMENT_MASTER_KEY' must be configured with a secure 256-bit key. " +
                "Silent fallback keys are strictly prohibited in Production.");
        }
    }

    /// <summary>
    /// Testing hook: Sets an in-memory master key for unit testing.
    /// </summary>
    public static void SetMasterKeyForTesting(string? key)
    {
        _testMasterKey = key;
    }

    /// <summary>
    /// Testing hook: Forces production mode check behavior.
    /// </summary>
    public static void SetProductionModeForTesting(bool? isProduction)
    {
        _forcedProductionMode = isProduction;
    }

    /// <summary>
    /// Testing hook: Resets all test overrides.
    /// </summary>
    public static void ResetTestingOverrides()
    {
        _testMasterKey = null;
        _forcedProductionMode = null;
    }

    private static byte[] GetMasterKey()
    {
        var keyString = _testMasterKey ?? Environment.GetEnvironmentVariable("FLORAPRISE_PAYMENT_MASTER_KEY");
        if (!string.IsNullOrWhiteSpace(keyString))
        {
            return SHA256.HashData(Encoding.UTF8.GetBytes(keyString));
        }

        if (IsProductionEnvironment())
        {
            throw new InvalidOperationException(
                "CRITICAL SECURITY ERROR: FLORAPRISE_PAYMENT_MASTER_KEY is not configured in Production environment. " +
                "Payment secrets cannot be encrypted or decrypted without a valid master key.");
        }

        // Controlled test/development fallback
        return FallbackDevelopmentMasterKey;
    }

    public virtual Task InitializeAsync(PaymentGatewayConfig config)
    {
        Config = config;
        // Decrypt secrets
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
    /// Decrypt encrypted secret with AES-GCM, AES-256-CBC, and backward compatibility
    /// </summary>
    protected virtual string DecryptSecret(string encryptedSecret)
    {
        return DecryptSecretValue(encryptedSecret);
    }

    /// <summary>
    /// Decrypt secret helper for static / gateway access
    /// </summary>
    public static string DecryptSecretValue(string encryptedSecret)
    {
        if (string.IsNullOrEmpty(encryptedSecret))
            return string.Empty;

        // Version 2: Authenticated AES-GCM
        if (encryptedSecret.StartsWith(EncryptedV2Prefix, StringComparison.Ordinal))
        {
            var masterKey = GetMasterKey();
            try
            {
                var base64 = encryptedSecret[EncryptedV2Prefix.Length..];
                var combined = Convert.FromBase64String(base64);
                
                // Nonce (12) + Tag (16) = 28 bytes minimum header
                if (combined.Length < 28)
                    return string.Empty;

                var nonce = combined[..12];
                var tag = combined[12..28];
                var ciphertext = combined[28..];
                var plainBytes = new byte[ciphertext.Length];

                using var aesGcm = new AesGcm(masterKey, 16);
                aesGcm.Decrypt(nonce, ciphertext, tag, plainBytes);

                return Encoding.UTF8.GetString(plainBytes);
            }
            catch (CryptographicException)
            {
                return string.Empty;
            }
            catch (FormatException)
            {
                return string.Empty;
            }
        }

        // Version 1: AES-256-CBC with PKCS7
        if (encryptedSecret.StartsWith(EncryptedV1Prefix, StringComparison.Ordinal))
        {
            var masterKey = GetMasterKey();
            try
            {
                var base64 = encryptedSecret[EncryptedV1Prefix.Length..];
                var combined = Convert.FromBase64String(base64);
                if (combined.Length <= 16)
                    return string.Empty;

                var iv = new byte[16];
                var cipherBytes = new byte[combined.Length - 16];
                Buffer.BlockCopy(combined, 0, iv, 0, 16);
                Buffer.BlockCopy(combined, 16, cipherBytes, 0, cipherBytes.Length);

                using var aes = Aes.Create();
                aes.Key = masterKey;
                aes.IV = iv;
                aes.Mode = CipherMode.CBC;
                aes.Padding = PaddingMode.PKCS7;

                using var decryptor = aes.CreateDecryptor(aes.Key, aes.IV);
                var decryptedBytes = decryptor.TransformFinalBlock(cipherBytes, 0, cipherBytes.Length);
                return Encoding.UTF8.GetString(decryptedBytes);
            }
            catch (CryptographicException)
            {
                return string.Empty;
            }
            catch (FormatException)
            {
                return string.Empty;
            }
        }

        // Backward compatibility: legacy Base64 or plaintext
        try
        {
            var bytes = Convert.FromBase64String(encryptedSecret);
            var decoded = Encoding.UTF8.GetString(bytes);
            if (decoded.All(c => !char.IsControl(c) || c == '\r' || c == '\n' || c == '\t'))
            {
                return decoded;
            }
            return encryptedSecret;
        }
        catch
        {
            return encryptedSecret;
        }
    }

    /// <summary>
    /// Encrypt secret for storage using authenticated AES-GCM (enc:v2:)
    /// </summary>
    public static string EncryptSecret(string plainSecret)
    {
        if (string.IsNullOrEmpty(plainSecret))
            return string.Empty;

        // If it's already encrypted with enc:v2: or enc:v1:, return as-is
        if (plainSecret.StartsWith(EncryptedV2Prefix, StringComparison.Ordinal) ||
            plainSecret.StartsWith(EncryptedV1Prefix, StringComparison.Ordinal))
        {
            return plainSecret;
        }

        var masterKey = GetMasterKey();
        var nonce = RandomNumberGenerator.GetBytes(12);
        var plainBytes = Encoding.UTF8.GetBytes(plainSecret);
        var ciphertext = new byte[plainBytes.Length];
        var tag = new byte[16];

        using var aesGcm = new AesGcm(masterKey, 16);
        aesGcm.Encrypt(nonce, plainBytes, ciphertext, tag);

        // Combined: Nonce (12) + Tag (16) + Ciphertext (N)
        var combined = new byte[12 + 16 + ciphertext.Length];
        Buffer.BlockCopy(nonce, 0, combined, 0, 12);
        Buffer.BlockCopy(tag, 0, combined, 12, 16);
        Buffer.BlockCopy(ciphertext, 0, combined, 28, ciphertext.Length);

        return EncryptedV2Prefix + Convert.ToBase64String(combined);
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
