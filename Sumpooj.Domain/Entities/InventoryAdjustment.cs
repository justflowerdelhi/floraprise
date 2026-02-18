namespace Sumpooj.Domain.Entities;

public class InventoryAdjustment : BaseEntity
{
    private InventoryAdjustment() { }

    public InventoryAdjustment(
        Guid companyId,
        Guid productId,
        Guid? batchId,
        AdjustmentType adjustmentType,
        int quantity,
        decimal costPerUnit,
        string reason,
        Guid adjustedByUserId)
    {
        CompanyId = companyId;
        ProductId = productId;
        BatchId = batchId;
        AdjustmentType = adjustmentType;
        Quantity = quantity;
        CostPerUnit = costPerUnit;
        TotalValue = quantity * costPerUnit;
        Reason = reason;
        AdjustedByUserId = adjustedByUserId;
        AdjustmentDate = DateTime.UtcNow;
    }

    public Guid CompanyId { get; private set; }
    public Guid ProductId { get; private set; }
    public Guid? BatchId { get; private set; }
    public AdjustmentType AdjustmentType { get; private set; }
    public int Quantity { get; private set; }
    public decimal CostPerUnit { get; private set; }
    public decimal TotalValue { get; private set; }
    public string Reason { get; private set; }
    public Guid AdjustedByUserId { get; private set; }
    public DateTime AdjustmentDate { get; private set; }
    public string? Notes { get; private set; }

    public void AddNotes(string notes)
    {
        Notes = string.IsNullOrEmpty(Notes)
            ? notes
            : $"{Notes}\n{notes}";
        MarkUpdated();
    }
}
