using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Payments;

// ═══════════════════════════════════════════════════════════════════
// PAYMENT GATEWAY CONFIG DTOs
// ═══════════════════════════════════════════════════════════════════

public record PaymentGatewayConfigDto(
    Guid Id,
    PaymentGatewayType GatewayType,
    string GatewayTypeName,
    string Name,
    string PublicKey,
    string? MerchantId,
    GatewayEnvironment Environment,
    string EnvironmentName,
    string Currency,
    string? SupportedCurrencies,
    bool IsActive,
    bool IsDefault,
    string? WebhookUrl,
    DateTime? LastTestedAt,
    bool? LastTestSuccessful,
    string Region,
    DateTime CreatedAt
);

public record PaymentGatewayConfigCreateDto(
    PaymentGatewayType GatewayType,
    string Name,
    string PublicKey,
    string SecretKey,
    string? WebhookSecret,
    string? MerchantId,
    GatewayEnvironment Environment,
    string Currency,
    string? SupportedCurrencies,
    bool IsDefault = false,
    string? AdditionalConfig = null
);

public record PaymentGatewayConfigUpdateDto(
    string Name,
    string? PublicKey,
    string? SecretKey,
    string? WebhookSecret,
    string? MerchantId,
    GatewayEnvironment? Environment,
    string? Currency,
    string? SupportedCurrencies,
    bool? IsActive,
    bool? IsDefault,
    string? AdditionalConfig
);

public record PaymentGatewayTestResultDto(
    bool Success,
    string Message,
    DateTime TestedAt
);

// ═══════════════════════════════════════════════════════════════════
// PAYMENT TRANSACTION DTOs
// ═══════════════════════════════════════════════════════════════════

public record PaymentTransactionDto(
    Guid Id,
    string TransactionRef,
    string? GatewayPaymentId,
    string? GatewayOrderId,
    decimal Amount,
    string Currency,
    GatewayPaymentStatus Status,
    string StatusName,
    GatewayPaymentMethod? PaymentMethod,
    string? PaymentMethodName,
    string? CardLast4,
    string? CardBrand,
    string? BankName,
    string? UpiId,
    string? WalletName,
    string? CustomerEmail,
    string? CustomerPhone,
    string? FailureReason,
    decimal RefundedAmount,
    decimal? GatewayFee,
    decimal? NetAmount,
    DateTime CreatedAt,
    DateTime? CompletedAt,
    Guid? OrderId,
    PaymentGatewayType GatewayType,
    string GatewayTypeName
);

public record CreatePaymentDto(
    decimal Amount,
    string Currency,
    Guid? OrderId,
    string? CustomerEmail,
    string? CustomerPhone,
    string? Description,
    string? ReturnUrl,
    string? CancelUrl,
    Dictionary<string, string>? Metadata
);

public record CreatePaymentResultDto(
    Guid TransactionId,
    string TransactionRef,
    string? GatewayOrderId,
    string? PaymentUrl,
    string? ClientSecret,
    string? QrCode,
    Dictionary<string, object>? AdditionalData
);

public record VerifyPaymentDto(
    string TransactionRef,
    string? GatewayPaymentId,
    string? GatewaySignature,
    Dictionary<string, string>? AdditionalData
);

public record VerifyPaymentResultDto(
    bool Success,
    GatewayPaymentStatus Status,
    string? Message,
    PaymentTransactionDto? Transaction
);

public record RefundPaymentDto(
    Guid TransactionId,
    decimal? Amount,
    string? Reason
);

public record RefundResultDto(
    bool Success,
    string? RefundId,
    decimal RefundedAmount,
    string? Message
);

// ═══════════════════════════════════════════════════════════════════
// WEBHOOK DTOs
// ═══════════════════════════════════════════════════════════════════

public record WebhookEventDto(
    string EventType,
    string? PaymentId,
    string? OrderId,
    GatewayPaymentStatus? NewStatus,
    decimal? Amount,
    string? Currency,
    Dictionary<string, object>? Data
);

// ═══════════════════════════════════════════════════════════════════
// GATEWAY INFO DTOs (for UI)
// ═══════════════════════════════════════════════════════════════════

public record PaymentGatewayInfoDto(
    PaymentGatewayType Type,
    string Name,
    string Region,
    string[] SupportedCurrencies,
    string[] SupportedPaymentMethods,
    bool RequiresMerchantId,
    string SetupDocUrl
);

public static class PaymentGatewayInfo
{
    public static IReadOnlyList<PaymentGatewayInfoDto> GetAll() =>
    [
        // India
        new(PaymentGatewayType.Razorpay, "Razorpay", "IN", ["INR", "USD"], ["Card", "UPI", "NetBanking", "Wallet"], false, "https://razorpay.com/docs/"),
        new(PaymentGatewayType.PayU, "PayU", "IN", ["INR"], ["Card", "UPI", "NetBanking", "Wallet"], true, "https://developer.payu.in/"),
        new(PaymentGatewayType.Cashfree, "Cashfree", "IN", ["INR"], ["Card", "UPI", "NetBanking", "Wallet"], false, "https://docs.cashfree.com/"),

        // USA
        new(PaymentGatewayType.Stripe, "Stripe", "US", ["USD", "EUR", "GBP", "INR", "AED"], ["Card", "ACH", "ApplePay", "GooglePay"], false, "https://stripe.com/docs"),
        new(PaymentGatewayType.Square, "Square", "US", ["USD", "CAD", "GBP", "EUR", "AUD"], ["Card", "ApplePay", "GooglePay"], true, "https://developer.squareup.com/"),
        new(PaymentGatewayType.PayPal, "PayPal", "US", ["USD", "EUR", "GBP", "CAD", "AUD"], ["PayPal", "Card"], false, "https://developer.paypal.com/"),

        // GCC
        new(PaymentGatewayType.PayTabs, "PayTabs", "GCC", ["AED", "SAR", "BHD", "KWD", "OMR", "QAR", "USD"], ["Card", "ApplePay"], true, "https://site.paytabs.com/en/developer/"),
        new(PaymentGatewayType.HyperPay, "HyperPay", "GCC", ["AED", "SAR", "BHD", "KWD", "OMR", "QAR", "USD", "EUR"], ["Card", "ApplePay", "Mada"], true, "https://wordpresshyperpay.docs.oppwa.com/"),
        new(PaymentGatewayType.TapPayments, "Tap Payments", "GCC", ["AED", "SAR", "BHD", "KWD", "OMR", "QAR", "USD"], ["Card", "ApplePay", "Benefit", "Knet"], false, "https://developers.tap.company/"),
        new(PaymentGatewayType.CheckoutCom, "Checkout.com", "GCC", ["AED", "SAR", "USD", "EUR", "GBP"], ["Card", "ApplePay", "GooglePay"], false, "https://www.checkout.com/docs"),
    ];

    public static PaymentGatewayInfoDto? GetByType(PaymentGatewayType type) =>
        GetAll().FirstOrDefault(g => g.Type == type);
}
