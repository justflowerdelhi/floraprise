namespace Sumpooj.Application.Payments;

public class PaymentDto
{
    public Guid Id { get; set; }
    public Guid OrderId { get; set; }
    public Guid? LocationId { get; set; }
    public string Method { get; set; } = default!;
    public decimal Amount { get; set; }
    public string Status { get; set; } = default!;
    public string? TransactionId { get; set; }
    public string? AuthorizationCode { get; set; }
    public string? CardBrand { get; set; }
    public string? Last4 { get; set; }
    public string? TerminalId { get; set; }
    public DateTime CreatedAtUtc { get; set; }
}

public class CreatePaymentRequest
{
    public Guid OrderId { get; set; }
    public string Method { get; set; } = default!;
    public decimal Amount { get; set; }
    public Guid? LocationId { get; set; }
}

public class UpdatePaymentRequest
{
    public string? Status { get; set; }
    public string? TransactionId { get; set; }
    public string? AuthorizationCode { get; set; }
    public string? CardBrand { get; set; }
    public string? Last4 { get; set; }
    public TerminalResponseDto? TerminalResponse { get; set; }
}

public class TerminalResponseDto
{
    public string TerminalId { get; set; } = default!;
    public string ResponseCode { get; set; } = default!;
    public string Message { get; set; } = default!;
    public string? ReceiptData { get; set; }
}
