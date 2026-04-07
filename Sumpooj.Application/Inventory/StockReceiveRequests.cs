namespace Sumpooj.Application.Inventory;

// ─── Quick Receive ───────────────────────────────────────────────────────────

public class QuickReceiveRequest
{
    /// <summary>Optional — if provided a PurchaseOrder record is created.</summary>
    public Guid? SupplierId { get; set; }

    public Guid LocationId { get; set; }

    public List<QuickReceiveItemRequest> Items { get; set; } = new();
}

public class QuickReceiveItemRequest
{
    public Guid ProductId { get; set; }
    public int Quantity { get; set; }
    public decimal CostPerUnit { get; set; }
    public decimal? SellingPricePerUnit { get; set; }
    public string? Unit { get; set; }
    public DateTime? ExpiryDate { get; set; }
    public int? ShelfLifeDays { get; set; }
    public string? StorageLocation { get; set; }
    public bool MergeWithSameDayBatch { get; set; }
}

public class QuickReceiveResult
{
    public Guid? PurchaseOrderId { get; set; }
    public string? PurchaseOrderNumber { get; set; }
    public List<Guid> BatchIds { get; set; } = new();
    public int ItemsReceived { get; set; }
}

// ─── Direct Stock Add ────────────────────────────────────────────────────────

public class DirectAddRequest
{
    public Guid ProductId { get; set; }
    public int Quantity { get; set; }
    public decimal CostPerUnit { get; set; }
    public Guid LocationId { get; set; }
    public DateTime? ExpiryDate { get; set; }
    public string? StorageLocation { get; set; }
    public bool MergeWithSameDayBatch { get; set; }
}

public class DirectAddResult
{
    public Guid BatchId { get; set; }
    public string BatchNumber { get; set; } = default!;
}
