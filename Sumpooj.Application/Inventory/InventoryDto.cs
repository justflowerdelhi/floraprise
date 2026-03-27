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

public class InventoryReconciliationDto
{
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = default!;
    public bool TrackInventory { get; set; }
    public bool TrackBatch { get; set; }
    public int ProductStockQuantity { get; set; }
    public int BatchStockQuantity { get; set; }
    public int Difference { get; set; }
    public int BatchCount { get; set; }
}

public class ReconciliationApplyResultDto
{
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = default!;
    public int BeforeDifference { get; set; }
    public int AppliedQuantity { get; set; }
    public int AfterDifference { get; set; }
    public string AppliedAdjustmentType { get; set; } = default!;
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

/// <summary>
/// Projection DTO exposing computed values from ProductBatch.
/// </summary>
public class InventoryBatchProjection
{
    public Guid BatchId { get; set; }
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = default!;
    public string BatchNumber { get; set; } = default!;
    public int StemsInStock { get; set; }
    public int TotalUnits { get; set; }
    public int UsedUnits { get; set; }
    public int DamagedUnits { get; set; }
    public int ReservedUnits { get; set; }
    public int AvailableUnits { get; set; }
    public int ConsumedStems { get; set; }
    public int RemainingStems { get; set; }
    public int PartialUsedUnits { get; set; }
}
