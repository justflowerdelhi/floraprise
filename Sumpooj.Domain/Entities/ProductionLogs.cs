namespace Sumpooj.Domain.Entities;

/// <summary>
/// Maintenance log for a finished goods batch (stem replacement, etc.)
/// </summary>
public class ProductionMaintenanceLog : BaseEntity
{
    private ProductionMaintenanceLog() { }

    public ProductionMaintenanceLog(
        Guid companyId,
        Guid finishedBatchId,
        string batchCode,
        string? notes)
    {
        CompanyId = companyId;
        FinishedBatchId = finishedBatchId;
        BatchCode = batchCode;
        Notes = notes;
        PerformedAt = DateTime.UtcNow;
    }

    public Guid CompanyId { get; private set; }
    public Guid FinishedBatchId { get; private set; }
    public string BatchCode { get; private set; } = default!;
    public string? Notes { get; private set; }
    public DateTime PerformedAt { get; private set; }
    public string? PerformedBy { get; private set; }

    /// <summary>
    /// Replacements stored as JSON
    /// </summary>
    public string? ReplacementsJson { get; private set; }

    public void SetReplacements(string json) => ReplacementsJson = json;
    public void SetPerformedBy(string user) => PerformedBy = user;
}

/// <summary>
/// Tracks wastage of raw materials or finished goods
/// </summary>
public class ProductionWastageLog : BaseEntity
{
    private ProductionWastageLog() { }

    public ProductionWastageLog(
        Guid companyId,
        Guid productId,
        string productName,
        int quantity,
        WastageReason reason,
        Guid? relatedFinishedBatchId,
        string? relatedBatchCode)
    {
        CompanyId = companyId;
        ProductId = productId;
        ProductName = productName;
        Quantity = quantity;
        Reason = reason;
        RelatedFinishedBatchId = relatedFinishedBatchId;
        RelatedBatchCode = relatedBatchCode;
    }

    public Guid CompanyId { get; private set; }
    public Guid ProductId { get; private set; }
    public string ProductName { get; private set; } = default!;
    public int Quantity { get; private set; }
    public WastageReason Reason { get; private set; }
    public Guid? RelatedFinishedBatchId { get; private set; }
    public string? RelatedBatchCode { get; private set; }
    public string? CreatedBy { get; private set; }

    public void SetCreatedBy(string user) => CreatedBy = user;
}

public enum WastageReason
{
    Spoiled,
    Wilted,
    Damaged
}
