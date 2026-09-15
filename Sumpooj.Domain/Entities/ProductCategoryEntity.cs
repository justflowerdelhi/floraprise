namespace Sumpooj.Domain.Entities;

/// <summary>
/// Dynamic product category managed by company admins.
/// Provides perishable/batch defaults for products assigned to this category.
/// Does NOT replace the existing ProductCategory enum (legacy).
/// </summary>
public class ProductCategoryEntity : BaseEntity
{
    private ProductCategoryEntity() { }

    public ProductCategoryEntity(
        Guid companyId,
        string name,
        bool isPerishable,
        bool trackBatchByDefault,
        string? defaultUnit = null)
    {
        CompanyId = companyId;
        Name = name;
        IsPerishable = isPerishable;
        TrackBatchByDefault = trackBatchByDefault;
        DefaultUnit = defaultUnit;
        IsActive = true;
    }

    public Guid CompanyId { get; private set; }
    public string Name { get; private set; } = default!;
    public string? DefaultUnit { get; private set; }
    public bool IsPerishable { get; private set; }
    public bool TrackBatchByDefault { get; private set; }
    public bool IsActive { get; private set; }

    public void Update(string name, bool isPerishable, bool trackBatchByDefault, string? defaultUnit = null)
    {
        Name = name;
        IsPerishable = isPerishable;
        TrackBatchByDefault = trackBatchByDefault;
        DefaultUnit = defaultUnit;
        MarkUpdated();
    }

    public void Deactivate()
    {
        IsActive = false;
        MarkUpdated();
    }

    public void Activate()
    {
        IsActive = true;
        MarkUpdated();
    }
}
