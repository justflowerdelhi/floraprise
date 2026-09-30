namespace Sumpooj.Domain.Entities;

/// <summary>
/// Component item within a global reference LibraryRecipe.
/// May reference a standard LibraryProduct or capture a snapshot name.
/// </summary>
public class LibraryRecipeItem : BaseEntity
{
    private LibraryRecipeItem() { }

    public LibraryRecipeItem(
        Guid recipeId,
        string productNameSnapshot,
        decimal quantity,
        string unit,
        Guid? libraryProductId = null,
        string? notes = null,
        int sortOrder = 0)
    {
        if (recipeId == Guid.Empty)
            throw new ArgumentException("Recipe ID cannot be empty.", nameof(recipeId));
        if (string.IsNullOrWhiteSpace(productNameSnapshot))
            throw new ArgumentException("Product name snapshot is required.", nameof(productNameSnapshot));
        if (quantity <= 0)
            throw new ArgumentException("Quantity must be greater than zero.", nameof(quantity));
        if (string.IsNullOrWhiteSpace(unit))
            throw new ArgumentException("Unit is required.", nameof(unit));

        RecipeId = recipeId;
        ProductNameSnapshot = productNameSnapshot.Trim();
        Quantity = quantity;
        Unit = unit.Trim();
        LibraryProductId = libraryProductId;
        Notes = notes?.Trim();
        SortOrder = sortOrder;
    }

    public Guid RecipeId { get; private set; }
    public LibraryRecipe? Recipe { get; private set; }
    public Guid? LibraryProductId { get; private set; }
    public LibraryProduct? LibraryProduct { get; private set; }
    public string ProductNameSnapshot { get; private set; } = default!;
    public decimal Quantity { get; private set; }
    public string Unit { get; private set; } = default!;
    public string? Notes { get; private set; }
    public int SortOrder { get; private set; }

    public void Update(
        string productNameSnapshot,
        decimal quantity,
        string unit,
        Guid? libraryProductId = null,
        string? notes = null,
        int sortOrder = 0)
    {
        if (string.IsNullOrWhiteSpace(productNameSnapshot))
            throw new ArgumentException("Product name snapshot is required.", nameof(productNameSnapshot));
        if (quantity <= 0)
            throw new ArgumentException("Quantity must be greater than zero.", nameof(quantity));
        if (string.IsNullOrWhiteSpace(unit))
            throw new ArgumentException("Unit is required.", nameof(unit));

        ProductNameSnapshot = productNameSnapshot.Trim();
        Quantity = quantity;
        Unit = unit.Trim();
        LibraryProductId = libraryProductId;
        Notes = notes?.Trim();
        SortOrder = sortOrder;
        MarkUpdated();
    }
}
