namespace Sumpooj.Application.Inventory;

public class CreateBatchRequest
{
    public Guid ProductId { get; set; }
    public string BatchNumber { get; set; } = default!;
    public int Quantity { get; set; }
    public decimal CostPerUnit { get; set; }
    public decimal? SellingPricePerUnit { get; set; }
    public DateTime ReceivedDate { get; set; } = DateTime.UtcNow;
    public DateTime? ExpiryDate { get; set; }
    public Guid? SupplierId { get; set; }
    public Guid? LocationId { get; set; }
    public string? StorageLocation { get; set; }
}

public class CreateAdjustmentRequest
{
    public Guid ProductId { get; set; }
    public Guid? BatchId { get; set; }
    public string AdjustmentType { get; set; } = default!;
    public int Quantity { get; set; }
    public decimal CostPerUnit { get; set; }
    public string Reason { get; set; } = default!;
    public DateTime AdjustmentDate { get; set; } = DateTime.UtcNow;
    public string? Notes { get; set; }
}

public class BatchSearchRequest
{
    public string? Query { get; set; }
    public Guid? ProductId { get; set; }
    public Guid? SupplierId { get; set; }
    public Guid? LocationId { get; set; }
    public bool? IsActive { get; set; }
    public bool? IsPerishable { get; set; }
    public bool? ExpiringOnly { get; set; }
    public int? ExpiringWithinDays { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}

public class AdjustmentSearchRequest
{
    public Guid? ProductId { get; set; }
    public Guid? BatchId { get; set; }
    public string? AdjustmentType { get; set; }
    public DateTime? FromDate { get; set; }
    public DateTime? ToDate { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}

public class ReconciliationApplyRequest
{
    public Guid ProductId { get; set; }
    public int? ExpectedDifference { get; set; }
    public string Reason { get; set; } = "Stock reconciliation correction";
    public string? Notes { get; set; }
}
