namespace Sumpooj.Domain.Entities;

public class InventoryLedger : BaseEntity
{
    private InventoryLedger() { }

    public InventoryLedger(
        Guid companyId,
        Guid productId,
        string reference,
        string referenceType,
        int quantityChange,
        int balanceAfter,
        string? notes)
    {
        CompanyId = companyId;
        ProductId = productId;
        Reference = reference;
        ReferenceType = referenceType;
        QuantityChange = quantityChange;
        BalanceAfter = balanceAfter;
        Notes = notes;
        CreatedAtUtc = DateTime.UtcNow;
    }

    public Guid CompanyId { get; private set; }
    public Guid ProductId { get; private set; }

    public string Reference { get; private set; } = default!;
    public string ReferenceType { get; private set; } = default!;

    /// <summary>Alias for ReferenceType. Values: "SALE", "PURCHASE", "ADJUSTMENT", "DAMAGED"</summary>
    public string Type => ReferenceType;

    public int QuantityChange { get; private set; }
    public int BalanceAfter { get; private set; }

    public string? Notes { get; private set; }
}