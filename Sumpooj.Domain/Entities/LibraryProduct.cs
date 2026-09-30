namespace Sumpooj.Domain.Entities;

/// <summary>
/// Global reference standard product definition in the Floraprise Library.
/// Contains global reference data only (no company-specific price, stock, supplier, or tax details).
/// </summary>
public class LibraryProduct : BaseEntity
{
    private LibraryProduct() { }

    public LibraryProduct(
        string name,
        string slug,
        Guid? categoryId,
        ProductType productType,
        UnitOfMeasure standardUnit,
        string? standardSku = null,
        string? description = null,
        string? referenceImageUrl = null,
        string? thumbnailUrl = null,
        string? searchKeywords = null,
        int sortOrder = 0)
    {
        if (string.IsNullOrWhiteSpace(name))
            throw new ArgumentException("Product name is required.", nameof(name));
        if (string.IsNullOrWhiteSpace(slug))
            throw new ArgumentException("Product slug is required.", nameof(slug));

        Name = name.Trim();
        Slug = slug.Trim().ToLowerInvariant();
        CategoryId = categoryId;
        ProductType = productType;
        StandardUnit = standardUnit;
        StandardSku = string.IsNullOrWhiteSpace(standardSku) ? null : standardSku.Trim();
        Description = description?.Trim();
        ReferenceImageUrl = referenceImageUrl?.Trim();
        ThumbnailUrl = thumbnailUrl?.Trim();
        SearchKeywords = searchKeywords?.Trim();
        SortOrder = sortOrder;
        IsActive = true;
        Version = 1;
    }

    public string Name { get; private set; } = default!;
    public string Slug { get; private set; } = default!;
    public Guid? CategoryId { get; private set; }
    public LibraryCategory? Category { get; private set; }
    public ProductType ProductType { get; private set; }
    public UnitOfMeasure StandardUnit { get; private set; }
    public string? StandardSku { get; private set; }
    public string? Description { get; private set; }
    public string? ReferenceImageUrl { get; private set; }
    public string? ThumbnailUrl { get; private set; }
    public string? SearchKeywords { get; private set; }
    public int SortOrder { get; private set; }
    public bool IsActive { get; private set; }
    public int Version { get; private set; }

    public void Update(
        string name,
        string slug,
        Guid? categoryId,
        ProductType productType,
        UnitOfMeasure standardUnit,
        string? standardSku = null,
        string? description = null,
        string? referenceImageUrl = null,
        string? thumbnailUrl = null,
        string? searchKeywords = null,
        int sortOrder = 0)
    {
        if (string.IsNullOrWhiteSpace(name))
            throw new ArgumentException("Product name is required.", nameof(name));
        if (string.IsNullOrWhiteSpace(slug))
            throw new ArgumentException("Product slug is required.", nameof(slug));

        Name = name.Trim();
        Slug = slug.Trim().ToLowerInvariant();
        CategoryId = categoryId;
        ProductType = productType;
        StandardUnit = standardUnit;
        StandardSku = string.IsNullOrWhiteSpace(standardSku) ? null : standardSku.Trim();
        Description = description?.Trim();
        ReferenceImageUrl = referenceImageUrl?.Trim();
        ThumbnailUrl = thumbnailUrl?.Trim();
        SearchKeywords = searchKeywords?.Trim();
        SortOrder = sortOrder;
        Version++;
        MarkUpdated();
    }

    public void Activate()
    {
        IsActive = true;
        MarkUpdated();
    }

    public void Deactivate()
    {
        IsActive = false;
        MarkUpdated();
    }
}
