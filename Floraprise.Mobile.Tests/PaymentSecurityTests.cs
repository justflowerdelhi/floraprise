using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using Sumpooj.Application.Payments;
using Xunit;

namespace Floraprise.Mobile.Tests;

public class PaymentSecurityTests : IDisposable
{
    public PaymentSecurityTests()
    {
        BasePaymentGateway.ResetTestingOverrides();
    }

    public void Dispose()
    {
        BasePaymentGateway.ResetTestingOverrides();
    }

    [Fact]
    public void EncryptSecret_ProducesV2PrefixAndNonEmptyCiphertext()
    {
        var plain = "rzp_live_secret_key_123456789";
        var encrypted = BasePaymentGateway.EncryptSecret(plain);

        Assert.NotNull(encrypted);
        Assert.StartsWith(BasePaymentGateway.EncryptedV2Prefix, encrypted);
        Assert.NotEqual(plain, encrypted);
    }

    [Fact]
    public void EncryptAndDecrypt_RoundTripsSuccessfully_WithAesGcm()
    {
        var plain = "super_secret_payu_salt_abc!@#$%^&*()_+";
        var encrypted = BasePaymentGateway.EncryptSecret(plain);
        var decrypted = BasePaymentGateway.DecryptSecretValue(encrypted);

        Assert.Equal(plain, decrypted);
    }

    [Fact]
    public void Production_MissingMasterKey_ThrowsInvalidOperationException()
    {
        BasePaymentGateway.SetProductionModeForTesting(true);
        BasePaymentGateway.SetMasterKeyForTesting(null);

        // Clear environment variable if set
        var existingEnv = Environment.GetEnvironmentVariable("FLORAPRISE_PAYMENT_MASTER_KEY");
        Environment.SetEnvironmentVariable("FLORAPRISE_PAYMENT_MASTER_KEY", null);

        try
        {
            // ValidateConfiguration must fail in production without master key
            var ex = Assert.Throws<InvalidOperationException>(() => BasePaymentGateway.ValidateConfiguration(true));
            Assert.Contains("FLORAPRISE_PAYMENT_MASTER_KEY", ex.Message);

            // Encryption in production without master key must fail
            var encryptEx = Assert.Throws<InvalidOperationException>(() => BasePaymentGateway.EncryptSecret("my_secret"));
            Assert.Contains("FLORAPRISE_PAYMENT_MASTER_KEY", encryptEx.Message);

            // Decryption of encrypted payload in production without master key must fail
            var decryptEx = Assert.Throws<InvalidOperationException>(() => BasePaymentGateway.DecryptSecretValue("enc:v2:AAAA"));
            Assert.Contains("FLORAPRISE_PAYMENT_MASTER_KEY", decryptEx.Message);
        }
        finally
        {
            Environment.SetEnvironmentVariable("FLORAPRISE_PAYMENT_MASTER_KEY", existingEnv);
        }
    }

    [Fact]
    public void Production_ConfiguredMasterKey_WorksSuccessfully()
    {
        BasePaymentGateway.SetProductionModeForTesting(true);
        BasePaymentGateway.SetMasterKeyForTesting("prod_master_key_9876543210_floraprise_super_secure");

        // ValidateConfiguration must pass
        BasePaymentGateway.ValidateConfiguration(true);

        var plain = "rzp_live_prod_credential_abcdef123456";
        var encrypted = BasePaymentGateway.EncryptSecret(plain);

        Assert.StartsWith(BasePaymentGateway.EncryptedV2Prefix, encrypted);
        var decrypted = BasePaymentGateway.DecryptSecretValue(encrypted);
        Assert.Equal(plain, decrypted);
    }

    [Fact]
    public void WrongKey_CannotDecrypt_ReturnsEmptyString()
    {
        // Encrypt with Key A
        BasePaymentGateway.SetMasterKeyForTesting("key_A_1111111111111111111111111111");
        var plain = "top_secret_gateway_credential";
        var encrypted = BasePaymentGateway.EncryptSecret(plain);

        // Switch to Key B (wrong key)
        BasePaymentGateway.SetMasterKeyForTesting("key_B_2222222222222222222222222222");
        var decryptedWithWrongKey = BasePaymentGateway.DecryptSecretValue(encrypted);

        // GCM authentication tag mismatch must fail and return empty (not throwing or leaking data)
        Assert.Equal(string.Empty, decryptedWithWrongKey);

        // Switch back to Key A -> decrypts correctly
        BasePaymentGateway.SetMasterKeyForTesting("key_A_1111111111111111111111111111");
        var decryptedWithOriginalKey = BasePaymentGateway.DecryptSecretValue(encrypted);
        Assert.Equal(plain, decryptedWithOriginalKey);
    }

    [Fact]
    public void DecryptSecret_SupportsV1BackwardCompatibility()
    {
        // Simulate a legacy enc:v1: (AES-256-CBC) encrypted secret
        var plain = "legacy_v1_encrypted_secret_data";
        var masterKeyBytes = SHA256.HashData(Encoding.UTF8.GetBytes("Floraprise:Development:PaymentMasterKey:ControlledDevOnly"));

        using var aes = Aes.Create();
        aes.Key = masterKeyBytes;
        aes.GenerateIV();
        aes.Mode = CipherMode.CBC;
        aes.Padding = PaddingMode.PKCS7;

        using var encryptor = aes.CreateEncryptor(aes.Key, aes.IV);
        var plainBytes = Encoding.UTF8.GetBytes(plain);
        var cipherBytes = encryptor.TransformFinalBlock(plainBytes, 0, plainBytes.Length);

        var combined = new byte[aes.IV.Length + cipherBytes.Length];
        Buffer.BlockCopy(aes.IV, 0, combined, 0, aes.IV.Length);
        Buffer.BlockCopy(cipherBytes, 0, combined, aes.IV.Length, cipherBytes.Length);

        var v1EncryptedString = BasePaymentGateway.EncryptedV1Prefix + Convert.ToBase64String(combined);

        // Decrypt using BasePaymentGateway.DecryptSecretValue
        var decrypted = BasePaymentGateway.DecryptSecretValue(v1EncryptedString);
        Assert.Equal(plain, decrypted);
    }

    [Fact]
    public void DecryptSecret_SupportsLegacyBase64()
    {
        var plain = "legacy_secret_987654";
        var legacyBase64 = Convert.ToBase64String(Encoding.UTF8.GetBytes(plain));

        var decrypted = BasePaymentGateway.DecryptSecretValue(legacyBase64);

        Assert.Equal(plain, decrypted);
    }

    [Fact]
    public void DecryptSecret_SupportsPlainTextFallback()
    {
        var plain = "plain_unencrypted_secret";

        var decrypted = BasePaymentGateway.DecryptSecretValue(plain);

        Assert.Equal(plain, decrypted);
    }

    [Fact]
    public void EncryptSecret_DoesNotDoubleEncrypt()
    {
        var plain = "rzp_test_secret";
        var encryptedOnce = BasePaymentGateway.EncryptSecret(plain);
        var encryptedTwice = BasePaymentGateway.EncryptSecret(encryptedOnce);

        Assert.Equal(encryptedOnce, encryptedTwice);
        Assert.Equal(plain, BasePaymentGateway.DecryptSecretValue(encryptedTwice));
    }

    [Fact]
    public void EncryptAndDecrypt_HandlesEmptyOrNull()
    {
        Assert.Equal(string.Empty, BasePaymentGateway.EncryptSecret(""));
        Assert.Equal(string.Empty, BasePaymentGateway.DecryptSecretValue(""));
        Assert.Equal(string.Empty, BasePaymentGateway.EncryptSecret(null!));
        Assert.Equal(string.Empty, BasePaymentGateway.DecryptSecretValue(null!));
    }

    [Fact]
    public void PaymentGatewayConfigDto_NeverExposesSecretProperties()
    {
        var properties = typeof(PaymentGatewayConfigDto).GetProperties(BindingFlags.Public | BindingFlags.Instance);
        var propertyNames = properties.Select(p => p.Name.ToLowerInvariant()).ToList();

        Assert.DoesNotContain("secretkey", propertyNames);
        Assert.DoesNotContain("secretkeyencrypted", propertyNames);
        Assert.DoesNotContain("webhooksecret", propertyNames);
        Assert.DoesNotContain("webhooksecretencrypted", propertyNames);
        Assert.DoesNotContain("masterkey", propertyNames);
    }

    [Fact]
    public void PaymentTransactionDto_NeverExposesSecretProperties()
    {
        var properties = typeof(PaymentTransactionDto).GetProperties(BindingFlags.Public | BindingFlags.Instance);
        var propertyNames = properties.Select(p => p.Name.ToLowerInvariant()).ToList();

        Assert.DoesNotContain("secretkey", propertyNames);
        Assert.DoesNotContain("secretkeyencrypted", propertyNames);
        Assert.DoesNotContain("webhooksecret", propertyNames);
        Assert.DoesNotContain("masterkey", propertyNames);
    }
}
