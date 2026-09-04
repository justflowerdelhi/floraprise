namespace Sumpooj.Domain.Entities;

public class Payment : BaseEntity
{
    private Payment() { }

    public Payment(
        Guid companyId,
        Guid orderId,
        PaymentMethod method,
        decimal amount)
    {
        CompanyId = companyId;
        OrderId = orderId;
        Method = method;
        Amount = amount;
        Status = PaymentTransactionStatus.Pending;
    }

    public Guid CompanyId { get; private set; }
    public Guid OrderId { get; private set; }
    public Guid? LocationId { get; private set; }
    public PaymentMethod Method { get; private set; }
    public decimal Amount { get; private set; }
    public PaymentTransactionStatus Status { get; private set; }

    // Transaction Details
    public string? TransactionId { get; private set; }
    public string? AuthorizationCode { get; private set; }
    public string? CardBrand { get; private set; }
    public string? Last4 { get; private set; }

    // Terminal Response
    public string? TerminalId { get; private set; }
    public string? TerminalResponseCode { get; private set; }
    public string? TerminalMessage { get; private set; }
    public string? ReceiptData { get; private set; }

    public Guid? ProcessedByUserId { get; private set; }
    public string? ClientPaymentId { get; private set; }
    public string? Reference { get; private set; }

    public void Approve(string? transactionId, string? authorizationCode)
    {
        Status = PaymentTransactionStatus.Approved;
        TransactionId = transactionId;
        AuthorizationCode = authorizationCode;
        MarkUpdated();
    }

    public void SetCardDetails(string? cardBrand, string? last4)
    {
        CardBrand = cardBrand;
        Last4 = last4;
        MarkUpdated();
    }

    public void SetTerminalResponse(string terminalId, string responseCode, string message, string? receiptData)
    {
        TerminalId = terminalId;
        TerminalResponseCode = responseCode;
        TerminalMessage = message;
        ReceiptData = receiptData;
        MarkUpdated();
    }

    public void Decline()
    {
        Status = PaymentTransactionStatus.Declined;
        MarkUpdated();
    }

    public void Void()
    {
        Status = PaymentTransactionStatus.Voided;
        MarkUpdated();
    }

    public void Refund()
    {
        Status = PaymentTransactionStatus.Refunded;
        MarkUpdated();
    }

    public void SetLocation(Guid locationId)
    {
        LocationId = locationId;
        MarkUpdated();
    }

    public void SetProcessedBy(Guid userId)
    {
        ProcessedByUserId = userId;
        MarkUpdated();
    }

    public void SetPosReference(string? clientPaymentId, string? reference)
    {
        ClientPaymentId = string.IsNullOrWhiteSpace(clientPaymentId) ? null : clientPaymentId.Trim();
        Reference = string.IsNullOrWhiteSpace(reference) ? null : reference.Trim();
        MarkUpdated();
    }
}
