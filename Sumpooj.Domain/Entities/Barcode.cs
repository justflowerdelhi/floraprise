namespace Sumpooj.Domain.Entities;

/// <summary>
/// Persisted barcode assigned to a Cloud Product. A product may have at most
/// one barcode per <see cref="BarcodeType"/> (one Manufacturer, one Internal).
/// Uniqueness of Value is enforced per-company at the database level.
/// </summary>
public class Barcode : BaseEntity
{
    private Barcode() { }

    public Barcode(Guid companyId, Guid productId, BarcodeType type, string value)
    {
        CompanyId = companyId;
        ProductId = productId;
        Type = type;
        Value = value.Trim();
    }

    public Guid CompanyId { get; private set; }
    public Guid ProductId { get; private set; }
    public Product? Product { get; private set; }
    public BarcodeType Type { get; private set; }
    public string Value { get; private set; } = default!;

    public void UpdateValue(string value)
    {
        Value = value.Trim();
        MarkUpdated();
    }
}
