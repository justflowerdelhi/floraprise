namespace Sumpooj.Application.Inventory;

public class ProductBatchDto
{
    public Guid Id { get; set; }
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = default!;
    public string? ProductType { get; set; }
    public string BatchNumber { get; set; } = default!;
    public int QuantityReceived { get; set; }
    public int QuantityRemaining { get; set; }
    public decimal CostPerUnit { get; set; }
    public decimal SellingPricePerUnit { get; set; }
    public DateTime ReceivedDate { get; set; }
    public DateTime? ExpiryDate { get; set; }
    public int? DaysUntilExpiry { get; set; }
    public bool IsExpired { get; set; }
    public bool IsExpiringSoon { get; set; }
    public Guid? SupplierId { get; set; }
    public string? SupplierName { get; set; }
    public Guid? LocationId { get; set; }
    public string? LocationName { get; set; }
    public string? StorageLocation { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAtUtc { get; set; }
}

public class InventoryAdjustmentDto
{
    public Guid Id { get; set; }
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = default!;
    public Guid? BatchId { get; set; }
    public string? BatchNumber { get; set; }
    public string AdjustmentType { get; set; } = default!;
    public int Quantity { get; set; }
    public decimal CostPerUnit { get; set; }
    public decimal TotalValue { get; set; }
    public string Reason { get; set; } = default!;
    public string? AdjustedByName { get; set; }
    public DateTime AdjustmentDate { get; set; }
    public string? Notes { get; set; }
    public DateTime CreatedAtUtc { get; set; }
}

public class InventorySummaryDto
{
    public int TotalProducts { get; set; }
    public int TotalBatches { get; set; }
    public int LowStockProducts { get; set; }
    public int ExpiringBatches { get; set; }
    public int ExpiredBatches { get; set; }
    public decimal TotalInventoryValue { get; set; }
    public decimal TotalRetailValue { get; set; }
}

public class ExpiryAlertDto
{
    public Guid BatchId { get; set; }
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = default!;
    public string BatchNumber { get; set; } = default!;
    public int QuantityRemaining { get; set; }
    public DateTime ExpiryDate { get; set; }
    public int DaysUntilExpiry { get; set; }
    public decimal CostPerUnit { get; set; }
    public decimal TotalValue { get; set; }
    public string? StorageLocation { get; set; }
    public string AlertLevel { get; set; } = default!; // Critical, Warning, Upcoming
}
