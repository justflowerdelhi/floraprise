namespace Sumpooj.Domain.Entities;

/// <summary>
/// Global reference floral recipe / bill of materials in the Floraprise Library.
/// Contains assembly instructions, yield specifications, and component snapshots.
/// Reference data only (no company-specific labor costs, retail pricing, or stock).
/// </summary>
public class LibraryRecipe : BaseEntity
{
    private LibraryRecipe() { }

    public LibraryRecipe(
        string name,
        string slug,
        string? description = null,
        Guid? categoryId = null,
        string? imageUrl = null,
        decimal yieldQuantity = 1,
        string? yieldUnit = "Piece",
        string? instructions = null,
        string? preparationNotes = null,
        int sortOrder = 0)
    {
        if (string.IsNullOrWhiteSpace(name))
            throw new ArgumentException("Recipe name is required.", nameof(name));
        if (string.IsNullOrWhiteSpace(slug))
            throw new ArgumentException("Recipe slug is required.", nameof(slug));

        Name = name.Trim();
        Slug = slug.Trim().ToLowerInvariant();
        Description = description?.Trim();
        CategoryId = categoryId;
        ImageUrl = imageUrl?.Trim();
        YieldQuantity = yieldQuantity > 0 ? yieldQuantity : 1;
        YieldUnit = string.IsNullOrWhiteSpace(yieldUnit) ? "Piece" : yieldUnit.Trim();
        Instructions = instructions?.Trim();
        PreparationNotes = preparationNotes?.Trim();
        SortOrder = sortOrder;
        IsActive = true;
        Version = 1;
    }

    public string Name { get; private set; } = default!;
    public string Slug { get; private set; } = default!;
    public string? Description { get; private set; }
    public Guid? CategoryId { get; private set; }
    public LibraryCategory? Category { get; private set; }
    public string? ImageUrl { get; private set; }
    public decimal YieldQuantity { get; private set; }
    public string? YieldUnit { get; private set; }
    public string? Instructions { get; private set; }
    public string? PreparationNotes { get; private set; }
    public int SortOrder { get; private set; }
    public bool IsActive { get; private set; }
    public int Version { get; private set; }

    public ICollection<LibraryRecipeItem> Items { get; private set; } = new List<LibraryRecipeItem>();

    public void Update(
        string name,
        string slug,
        string? description = null,
        Guid? categoryId = null,
        string? imageUrl = null,
        decimal yieldQuantity = 1,
        string? yieldUnit = "Piece",
        string? instructions = null,
        string? preparationNotes = null,
        int sortOrder = 0)
    {
        if (string.IsNullOrWhiteSpace(name))
            throw new ArgumentException("Recipe name is required.", nameof(name));
        if (string.IsNullOrWhiteSpace(slug))
            throw new ArgumentException("Recipe slug is required.", nameof(slug));

        Name = name.Trim();
        Slug = slug.Trim().ToLowerInvariant();
        Description = description?.Trim();
        CategoryId = categoryId;
        ImageUrl = imageUrl?.Trim();
        YieldQuantity = yieldQuantity > 0 ? yieldQuantity : 1;
        YieldUnit = string.IsNullOrWhiteSpace(yieldUnit) ? "Piece" : yieldUnit.Trim();
        Instructions = instructions?.Trim();
        PreparationNotes = preparationNotes?.Trim();
        SortOrder = sortOrder;
        Version++;
        MarkUpdated();
    }

    public void AddItem(string productNameSnapshot, decimal quantity, string unit, Guid? libraryProductId = null, string? notes = null, int sortOrder = 0)
    {
        var item = new LibraryRecipeItem(Id, productNameSnapshot, quantity, unit, libraryProductId, notes, sortOrder);
        Items.Add(item);
    }

    public void ClearItems()
    {
        Items.Clear();
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

