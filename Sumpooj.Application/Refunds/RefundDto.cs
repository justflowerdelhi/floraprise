namespace Sumpooj.Application.Refunds;

public class RefundDto
{
    public Guid Id { get; set; }
    public Guid OrderId { get; set; }
    public string RefundNumber { get; set; } = default!;
    public string Method { get; set; } = default!;
    public string Status { get; set; } = default!;
    public string Reason { get; set; } = default!;
    public decimal RefundedAmount { get; set; }
    public string? TransactionId { get; set; }
    public string? Notes { get; set; }
    public List<RefundItemDto> Items { get; set; } = new();
    public DateTime CreatedAtUtc { get; set; }
}

public class RefundItemDto
{
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = default!;
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal RefundAmount { get; set; }
    public bool Restock { get; set; }
}

public class CreateRefundRequest
{
    public Guid OrderId { get; set; }
    public string Method { get; set; } = "Original";
    public string Reason { get; set; } = default!;
    public List<RefundItemRequest> Items { get; set; } = new();
}

public class RefundItemRequest
{
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = default!;
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public bool Restock { get; set; }
}
