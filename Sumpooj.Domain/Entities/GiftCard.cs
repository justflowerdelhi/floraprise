namespace Sumpooj.Domain.Entities;

public class GiftCard : BaseEntity
{
    private GiftCard() { }

    public GiftCard(
        Guid companyId,
        string code,
        decimal initialBalance,
        string? recipientName,
        string? recipientEmail,
        string? senderName,
        string? personalMessage)
    {
        CompanyId = companyId;
        Code = code;
        InitialBalance = initialBalance;
        CurrentBalance = initialBalance;
        RecipientName = recipientName;
        RecipientEmail = recipientEmail;
        SenderName = senderName;
        PersonalMessage = personalMessage;
        Status = GiftCardStatus.Active;
        IssuedAt = DateTime.UtcNow;
    }

    public Guid CompanyId { get; private set; }
    public string Code { get; private set; }
    public decimal InitialBalance { get; private set; }
    public decimal CurrentBalance { get; private set; }
    public GiftCardStatus Status { get; private set; }
    public DateTime IssuedAt { get; private set; }
    public DateTime? ExpiresAt { get; private set; }
    public DateTime? LastUsedAt { get; private set; }

    // Recipient Info
    public string? RecipientName { get; private set; }
    public string? RecipientEmail { get; private set; }
    public string? RecipientPhone { get; private set; }

    // Sender Info
    public string? SenderName { get; private set; }
    public string? PersonalMessage { get; private set; }

    // Design
    public string? DesignTheme { get; private set; }

    // Purchase Info
    public Guid? PurchasedByCustomerId { get; private set; }
    public Guid? SourceOrderId { get; private set; }

    public void Redeem(decimal amount)
    {
        if (Status != GiftCardStatus.Active)
            throw new InvalidOperationException("Gift card is not active");

        if (amount > CurrentBalance)
            throw new InvalidOperationException("Insufficient balance");

        CurrentBalance -= amount;
        LastUsedAt = DateTime.UtcNow;

        if (CurrentBalance <= 0)
        {
            Status = GiftCardStatus.FullyRedeemed;
        }

        MarkUpdated();
    }

    public void AddBalance(decimal amount)
    {
        if (amount <= 0)
            throw new ArgumentException("Amount must be positive");

        CurrentBalance += amount;

        if (Status == GiftCardStatus.FullyRedeemed)
        {
            Status = GiftCardStatus.Active;
        }

        MarkUpdated();
    }

    public void SetExpiry(DateTime expiryDate)
    {
        ExpiresAt = expiryDate;
        MarkUpdated();
    }

    public void SetDesignTheme(string theme)
    {
        DesignTheme = theme;
        MarkUpdated();
    }

    public void Deactivate()
    {
        Status = GiftCardStatus.Inactive;
        MarkUpdated();
    }

    public void Activate()
    {
        if (CurrentBalance > 0)
            Status = GiftCardStatus.Active;
        MarkUpdated();
    }

    public bool IsExpired() => ExpiresAt.HasValue && ExpiresAt.Value < DateTime.UtcNow;

    public bool IsValid() => Status == GiftCardStatus.Active && !IsExpired() && CurrentBalance > 0;
}
