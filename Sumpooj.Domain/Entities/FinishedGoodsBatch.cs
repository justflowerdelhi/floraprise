namespace Sumpooj.Domain.Entities;

/// <summary>
/// A batch of finished goods produced from a recipe
/// </summary>
public class FinishedGoodsBatch : BaseEntity
{
    private FinishedGoodsBatch() { }

    public FinishedGoodsBatch(
        Guid companyId,
        Guid recipeId,
        string recipeName,
        string batchCode,
        string barcode,
        int quantityProduced,
        DateTime expectedExpiry,
        Guid locationId,
        string locationName,
        decimal totalCost,
        string? operatorName = null)
    {
        CompanyId = companyId;
        RecipeId = recipeId;
        RecipeName = recipeName;
        BatchCode = batchCode;
        Barcode = barcode;
        QuantityProduced = quantityProduced;
        QuantityAvailable = quantityProduced;
        ExpectedExpiry = expectedExpiry;
        LocationId = locationId;
        LocationName = locationName;
        TotalCost = totalCost;
        OperatorName = operatorName;
        Status = FinishedBatchStatus.Active;
        ProducedAt = DateTime.UtcNow;
    }

    public Guid CompanyId { get; private set; }
    public Guid RecipeId { get; private set; }
    public string RecipeName { get; private set; } = default!;
    public string BatchCode { get; private set; } = default!;
    public string Barcode { get; private set; } = default!;
    public int QuantityProduced { get; private set; }
    public int QuantityAvailable { get; private set; }
    public DateTime ExpectedExpiry { get; private set; }
    public Guid LocationId { get; private set; }
    public string LocationName { get; private set; } = default!;
    public decimal TotalCost { get; private set; }
    public FinishedBatchStatus Status { get; private set; }
    public DateTime ProducedAt { get; private set; }
    public string? OperatorName { get; private set; }
    public DateTime? ReversedAt { get; private set; }
    public string? ReversalNote { get; private set; }
    public bool IsReversed => Status == FinishedBatchStatus.Reversed || ReversedAt != null;

    public void SetOperatorName(string? operatorName)
    {
        OperatorName = operatorName;
        MarkUpdated();
    }

    public void Deduct(int qty)
    {
        QuantityAvailable -= qty;
        if (QuantityAvailable < 0) QuantityAvailable = 0;
        MarkUpdated();
    }

    public void Discard()
    {
        Status = FinishedBatchStatus.Discarded;
        QuantityAvailable = 0;
        MarkUpdated();
    }

    public void MarkExpired()
    {
        Status = FinishedBatchStatus.Expired;
        MarkUpdated();
    }

    public void Reverse(string? note)
    {
        Status = FinishedBatchStatus.Reversed;
        ReversedAt = DateTime.UtcNow;
        ReversalNote = note;
        QuantityAvailable = 0;
        MarkUpdated();
    }
}

public enum FinishedBatchStatus
{
    Active,
    Expired,
    Discarded,
    Reversed
}
