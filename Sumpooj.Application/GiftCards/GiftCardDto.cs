namespace Sumpooj.Application.GiftCards;

public class GiftCardDto
{
    public Guid Id { get; set; }
    public string Code { get; set; } = default!;
    public decimal InitialBalance { get; set; }
    public decimal CurrentBalance { get; set; }
    public string Status { get; set; } = default!;
    public DateTime IssuedAt { get; set; }
    public DateTime? ExpiresAt { get; set; }
    public DateTime? LastUsedAt { get; set; }
    public string? RecipientName { get; set; }
    public string? RecipientEmail { get; set; }
    public string? SenderName { get; set; }
    public string? PersonalMessage { get; set; }
    public string? DesignTheme { get; set; }
}

public class CreateGiftCardRequest
{
    public decimal Amount { get; set; }
    public string? RecipientName { get; set; }
    public string? RecipientEmail { get; set; }
    public string? RecipientPhone { get; set; }
    public string? SenderName { get; set; }
    public string? PersonalMessage { get; set; }
    public string? DesignTheme { get; set; }
    public DateTime? ExpiresAt { get; set; }
}

public class RedeemGiftCardRequest
{
    public string Code { get; set; } = default!;
    public decimal Amount { get; set; }
    public Guid? OrderId { get; set; }
}

public class GiftCardSearchRequest
{
    public string? Query { get; set; }
    public string? Status { get; set; }
    public decimal? MinBalance { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}

public class GiftCardBalanceDto
{
    public string Code { get; set; } = default!;
    public decimal CurrentBalance { get; set; }
    public bool IsValid { get; set; }
    public string? Message { get; set; }
}
