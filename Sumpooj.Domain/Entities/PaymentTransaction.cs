using System.ComponentModel.DataAnnotations;

namespace Sumpooj.Domain.Entities;

/// <summary>
/// Payment gateway transaction status (extended from base PaymentTransactionStatus)
/// </summary>
public enum GatewayPaymentStatus
{
    Pending = 0,
    Processing = 1,
    Authorized = 2,
    Captured = 3,
    Completed = 4,
    Failed = 5,
    Cancelled = 6,
    Refunded = 7,
    PartiallyRefunded = 8,
    Disputed = 9
}

/// <summary>
/// Payment method type
/// </summary>
public enum GatewayPaymentMethod
{
    Card = 1,
    UPI = 2,
    NetBanking = 3,
    Wallet = 4,
    BankTransfer = 5,
    Cash = 6,
    Check = 7,
    GiftCard = 8,
    StoreCredit = 9,
    PayLater = 10
}

/// <summary>
/// Payment transaction record
/// </summary>
public class PaymentTransaction : BaseEntity
{
    public Guid CompanyId { get; private set; }
    public Company Company { get; private set; } = null!;
    
    public Guid PaymentGatewayConfigId { get; private set; }
    public PaymentGatewayConfig PaymentGatewayConfig { get; private set; } = null!;
    
    /// <summary>
    /// Reference to the order being paid for
    /// </summary>
    public Guid? OrderId { get; private set; }
    public Order? Order { get; private set; }
    
    /// <summary>
    /// Internal transaction reference
    /// </summary>
    [MaxLength(50)]
    public string TransactionRef { get; private set; } = string.Empty;
    
    /// <summary>
    /// Gateway's payment/transaction ID
    /// </summary>
    [MaxLength(200)]
    public string? GatewayPaymentId { get; private set; }
    
    /// <summary>
    /// Gateway's order ID (if different from payment ID)
    /// </summary>
    [MaxLength(200)]
    public string? GatewayOrderId { get; private set; }
    
    public decimal Amount { get; private set; }

    [MaxLength(3)]
    public string Currency { get; private set; } = "USD";

    public GatewayPaymentStatus Status { get; private set; }

    public GatewayPaymentMethod? PaymentMethod { get; private set; }
    
    /// <summary>
    /// Card last 4 digits (if applicable)
    /// </summary>
    [MaxLength(4)]
    public string? CardLast4 { get; private set; }
    
    /// <summary>
    /// Card brand (Visa, Mastercard, etc.)
    /// </summary>
    [MaxLength(20)]
    public string? CardBrand { get; private set; }
    
    /// <summary>
    /// Bank name for UPI/NetBanking
    /// </summary>
    [MaxLength(100)]
    public string? BankName { get; private set; }
    
    /// <summary>
    /// UPI ID (masked)
    /// </summary>
    [MaxLength(100)]
    public string? UpiId { get; private set; }
    
    /// <summary>
    /// Wallet name (PayTM, PhonePe, etc.)
    /// </summary>
    [MaxLength(50)]
    public string? WalletName { get; private set; }
    
    /// <summary>
    /// Customer email
    /// </summary>
    [MaxLength(200)]
    public string? CustomerEmail { get; private set; }
    
    /// <summary>
    /// Customer phone
    /// </summary>
    [MaxLength(20)]
    public string? CustomerPhone { get; private set; }
    
    /// <summary>
    /// Failure reason if failed
    /// </summary>
    [MaxLength(500)]
    public string? FailureReason { get; private set; }
    
    /// <summary>
    /// Gateway error code
    /// </summary>
    [MaxLength(50)]
    public string? ErrorCode { get; private set; }
    
    /// <summary>
    /// Total amount refunded
    /// </summary>
    public decimal RefundedAmount { get; private set; }
    
    /// <summary>
    /// Raw gateway response (JSON)
    /// </summary>
    public string? GatewayResponse { get; private set; }
    
    /// <summary>
    /// Gateway fee charged
    /// </summary>
    public decimal? GatewayFee { get; private set; }
    
    /// <summary>
    /// Net amount after fees
    /// </summary>
    public decimal? NetAmount { get; private set; }
    
    public DateTime? AuthorizedAt { get; private set; }
    public DateTime? CapturedAt { get; private set; }
    public DateTime? CompletedAt { get; private set; }
    public DateTime? FailedAt { get; private set; }
    
    /// <summary>
    /// Metadata (JSON) - additional info like receipt URLs, etc.
    /// </summary>
    public string? Metadata { get; private set; }

    private PaymentTransaction() { } // EF Core

    public PaymentTransaction(
        Guid companyId,
        Guid paymentGatewayConfigId,
        string transactionRef,
        decimal amount,
        string currency,
        Guid? orderId = null)
    {
        CompanyId = companyId;
        PaymentGatewayConfigId = paymentGatewayConfigId;
        TransactionRef = transactionRef;
        Amount = amount;
        Currency = currency;
        OrderId = orderId;
        Status = GatewayPaymentStatus.Pending;
    }

    public void SetGatewayIds(string? paymentId, string? orderId = null)
    {
        GatewayPaymentId = paymentId;
        GatewayOrderId = orderId;
    }

    public void SetCustomerInfo(string? email, string? phone)
    {
        CustomerEmail = email;
        CustomerPhone = phone;
    }

    public void SetPaymentMethodCard(string? last4, string? brand)
    {
        PaymentMethod = GatewayPaymentMethod.Card;
        CardLast4 = last4;
        CardBrand = brand;
    }

    public void SetPaymentMethodUpi(string? upiId)
    {
        PaymentMethod = GatewayPaymentMethod.UPI;
        UpiId = upiId;
    }

    public void SetPaymentMethodNetBanking(string? bankName)
    {
        PaymentMethod = GatewayPaymentMethod.NetBanking;
        BankName = bankName;
    }

    public void SetPaymentMethodWallet(string? walletName)
    {
        PaymentMethod = GatewayPaymentMethod.Wallet;
        WalletName = walletName;
    }

    public void MarkProcessing()
    {
        Status = GatewayPaymentStatus.Processing;
    }

    public void MarkAuthorized()
    {
        Status = GatewayPaymentStatus.Authorized;
        AuthorizedAt = DateTime.UtcNow;
    }

    public void MarkCaptured()
    {
        Status = GatewayPaymentStatus.Captured;
        CapturedAt = DateTime.UtcNow;
    }

    public void MarkCompleted(decimal? gatewayFee = null)
    {
        Status = GatewayPaymentStatus.Completed;
        CompletedAt = DateTime.UtcNow;
        GatewayFee = gatewayFee;
        NetAmount = Amount - (gatewayFee ?? 0);
    }

    public void MarkFailed(string? reason, string? errorCode = null)
    {
        Status = GatewayPaymentStatus.Failed;
        FailedAt = DateTime.UtcNow;
        FailureReason = reason;
        ErrorCode = errorCode;
    }

    public void MarkCancelled()
    {
        Status = GatewayPaymentStatus.Cancelled;
    }

    public void MarkRefunded(decimal refundAmount)
    {
        RefundedAmount += refundAmount;
        Status = RefundedAmount >= Amount 
            ? GatewayPaymentStatus.Refunded 
            : GatewayPaymentStatus.PartiallyRefunded;
    }

    public void SetGatewayResponse(string? response) => GatewayResponse = response;

    public void SetMetadata(string? metadata) => Metadata = metadata;
}
