namespace Sumpooj.Domain.Entities;

public class Refund : BaseEntity
{
    private readonly List<RefundItem> _items = new();

    private Refund() { }

    public Refund(
        Guid companyId,
        Guid orderId,
        RefundMethod method,
        string reason,
        Guid processedByUserId)
    {
        CompanyId = companyId;
        OrderId = orderId;
        Method = method;
        Reason = reason;
        ProcessedByUserId = processedByUserId;
        Status = RefundStatus.Pending;
        RefundNumber = GenerateRefundNumber();
    }

    public Guid CompanyId { get; private set; }
    public Guid OrderId { get; private set; }
    public string RefundNumber { get; private set; }
    public RefundMethod Method { get; private set; }
    public RefundStatus Status { get; private set; }
    public string Reason { get; private set; }
    public decimal RefundedAmount { get; private set; }
    public Guid ProcessedByUserId { get; private set; }
    public string? TransactionId { get; private set; }
    public string? Notes { get; private set; }

    public IReadOnlyCollection<RefundItem> Items => _items.AsReadOnly();

    private static string GenerateRefundNumber()
    {
        return $"REF-{DateTime.UtcNow:yyyyMMdd}-{Guid.NewGuid().ToString()[..8].ToUpper()}";
    }

    public void AddItem(Guid productId, string productName, int quantity, decimal unitPrice, bool restock)
    {
        var item = new RefundItem(productId, productName, quantity, unitPrice, restock);
        _items.Add(item);
        RecalculateTotal();
    }

    private void RecalculateTotal()
    {
        RefundedAmount = _items.Sum(i => i.RefundAmount);
        MarkUpdated();
    }

    public void Process(string? transactionId = null)
    {
        Status = RefundStatus.Processed;
        TransactionId = transactionId;
        MarkUpdated();
    }

    public void Fail(string? notes = null)
    {
        Status = RefundStatus.Failed;
        Notes = notes;
        MarkUpdated();
    }
}

public class RefundItem
{
    private RefundItem() { }

    public RefundItem(Guid productId, string productName, int quantity, decimal unitPrice, bool restock)
    {
        Id = Guid.NewGuid();
        ProductId = productId;
        ProductName = productName;
        Quantity = quantity;
        UnitPrice = unitPrice;
        RefundAmount = quantity * unitPrice;
        Restock = restock;
    }

    public Guid Id { get; private set; }
    public Guid ProductId { get; private set; }
    public string ProductName { get; private set; }
    public int Quantity { get; private set; }
    public decimal UnitPrice { get; private set; }
    public decimal RefundAmount { get; private set; }
    public bool Restock { get; private set; }
}
