namespace Sumpooj.Domain.Entities;

/// <summary>
/// Global reference category maintained centrally in the Floraprise Library.
/// Library categories are reference taxonomy items shared across all tenants.
/// </summary>
public class LibraryCategory : BaseEntity
{
    private LibraryCategory() { }

    public LibraryCategory(
        string name,
        string slug,
        string? description = null,
        string? imageUrl = null,
        string? iconKey = null,
        Guid? parentCategoryId = null,
        int sortOrder = 0)
    {
        if (string.IsNullOrWhiteSpace(name))
            throw new ArgumentException("Category name is required.", nameof(name));
        if (string.IsNullOrWhiteSpace(slug))
            throw new ArgumentException("Category slug is required.", nameof(slug));

        Name = name.Trim();
        Slug = slug.Trim().ToLowerInvariant();
        Description = description?.Trim();
        ImageUrl = imageUrl?.Trim();
        IconKey = iconKey?.Trim();
        ParentCategoryId = parentCategoryId;
        SortOrder = sortOrder;
        IsActive = true;
    }

    public string Name { get; private set; } = default!;
    public string Slug { get; private set; } = default!;
    public string? Description { get; private set; }
    public string? ImageUrl { get; private set; }
    public string? IconKey { get; private set; }
    public Guid? ParentCategoryId { get; private set; }
    public LibraryCategory? ParentCategory { get; private set; }
    public ICollection<LibraryCategory> SubCategories { get; private set; } = new List<LibraryCategory>();
    public int SortOrder { get; private set; }
    public bool IsActive { get; private set; }

    public void Update(
        string name,
        string slug,
        string? description = null,
        string? imageUrl = null,
        string? iconKey = null,
        Guid? parentCategoryId = null,
        int sortOrder = 0)
    {
        if (string.IsNullOrWhiteSpace(name))
            throw new ArgumentException("Category name is required.", nameof(name));
        if (string.IsNullOrWhiteSpace(slug))
            throw new ArgumentException("Category slug is required.", nameof(slug));

        Name = name.Trim();
        Slug = slug.Trim().ToLowerInvariant();
        Description = description?.Trim();
        ImageUrl = imageUrl?.Trim();
        IconKey = iconKey?.Trim();
        ParentCategoryId = parentCategoryId;
        SortOrder = sortOrder;
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
