namespace Sumpooj.Domain.Entities;

/// <summary>
/// Global reference arrangement / bouquet design in the Floraprise Design Gallery.
/// Reference showcase item with high-res photography, flower recipe links, and design aesthetics.
/// </summary>
public class LibraryDesign : BaseEntity
{
    private LibraryDesign() { }

    public LibraryDesign(
        string title,
        string slug,
        string? description = null,
        Guid? categoryId = null,
        string? imageUrl = null,
        string? highResImageUrl = null,
        string? thumbnailUrl = null,
        string? occasion = null,
        string? style = null,
        string? colorPalette = null,
        string? flowerTypes = null,
        Guid? recipeId = null,
        string? searchKeywords = null,
        int sortOrder = 0)
    {
        if (string.IsNullOrWhiteSpace(title))
            throw new ArgumentException("Design title is required.", nameof(title));
        if (string.IsNullOrWhiteSpace(slug))
            throw new ArgumentException("Design slug is required.", nameof(slug));

        Title = title.Trim();
        Slug = slug.Trim().ToLowerInvariant();
        Description = description?.Trim();
        CategoryId = categoryId;
        ImageUrl = imageUrl?.Trim();
        HighResImageUrl = highResImageUrl?.Trim();
        ThumbnailUrl = thumbnailUrl?.Trim();
        Occasion = occasion?.Trim();
        Style = style?.Trim();
        ColorPalette = colorPalette?.Trim();
        FlowerTypes = flowerTypes?.Trim();
        RecipeId = recipeId;
        SearchKeywords = searchKeywords?.Trim();
        SortOrder = sortOrder;
        IsActive = true;
        Version = 1;
    }

    public string Title { get; private set; } = default!;
    public string Slug { get; private set; } = default!;
    public string? Description { get; private set; }
    public Guid? CategoryId { get; private set; }
    public LibraryCategory? Category { get; private set; }
    public string? ImageUrl { get; private set; }
    public string? HighResImageUrl { get; private set; }
    public string? ThumbnailUrl { get; private set; }
    public string? Occasion { get; private set; }
    public string? Style { get; private set; }
    public string? ColorPalette { get; private set; }
    public string? FlowerTypes { get; private set; }
    public Guid? RecipeId { get; private set; }
    public LibraryRecipe? Recipe { get; private set; }
    public string? SearchKeywords { get; private set; }
    public int SortOrder { get; private set; }
    public bool IsActive { get; private set; }
    public int Version { get; private set; }

    public void Update(
        string title,
        string slug,
        string? description = null,
        Guid? categoryId = null,
        string? imageUrl = null,
        string? highResImageUrl = null,
        string? thumbnailUrl = null,
        string? occasion = null,
        string? style = null,
        string? colorPalette = null,
        string? flowerTypes = null,
        Guid? recipeId = null,
        string? searchKeywords = null,
        int sortOrder = 0)
    {
        if (string.IsNullOrWhiteSpace(title))
            throw new ArgumentException("Design title is required.", nameof(title));
        if (string.IsNullOrWhiteSpace(slug))
            throw new ArgumentException("Design slug is required.", nameof(slug));

        Title = title.Trim();
        Slug = slug.Trim().ToLowerInvariant();
        Description = description?.Trim();
        CategoryId = categoryId;
        ImageUrl = imageUrl?.Trim();
        HighResImageUrl = highResImageUrl?.Trim();
        ThumbnailUrl = thumbnailUrl?.Trim();
        Occasion = occasion?.Trim();
        Style = style?.Trim();
        ColorPalette = colorPalette?.Trim();
        FlowerTypes = flowerTypes?.Trim();
        RecipeId = recipeId;
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
