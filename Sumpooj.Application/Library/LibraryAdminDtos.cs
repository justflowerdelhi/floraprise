namespace Sumpooj.Application.Library;

public class CreateOrUpdateLibraryCategoryRequest
{
    public string Name { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? ImageUrl { get; set; }
    public string? IconKey { get; set; }
    public Guid? ParentCategoryId { get; set; }
    public int SortOrder { get; set; } = 0;
}

public class CreateOrUpdateLibraryProductRequest
{
    public string Name { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string? BotanicalName { get; set; }
    public string? CommonName { get; set; }
    public string? Description { get; set; }
    public Guid? CategoryId { get; set; }
    public string? ImageUrl { get; set; }
    public string? DefaultUnit { get; set; } = "Stem";
    public string? StemLength { get; set; }
    public string? BloomSize { get; set; }
    public string? ColorPrimary { get; set; }
    public string? ColorSecondary { get; set; }
    public string? Seasonality { get; set; }
    public int? VaseLifeDays { get; set; }
    public string? FragranceStrength { get; set; }
    public string? CareInstructions { get; set; }
    public string? SearchKeywords { get; set; }
    public int SortOrder { get; set; } = 0;
}

public class LibraryRecipeItemInputDto
{
    public Guid? LibraryProductId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public decimal Quantity { get; set; }
    public string Unit { get; set; } = string.Empty;
    public string? Notes { get; set; }
    public int SortOrder { get; set; } = 0;
}

public class CreateOrUpdateLibraryRecipeRequest
{
    public string Name { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string? Description { get; set; }
    public Guid? CategoryId { get; set; }
    public string? ImageUrl { get; set; }
    public decimal YieldQuantity { get; set; } = 1;
    public string? YieldUnit { get; set; } = "Bouquet";
    public string? Instructions { get; set; }
    public string? PreparationNotes { get; set; }
    public int SortOrder { get; set; } = 0;
    public List<LibraryRecipeItemInputDto> Items { get; set; } = new();
}

public class CreateOrUpdateLibraryDesignRequest
{
    public string Title { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string? Description { get; set; }
    public Guid? CategoryId { get; set; }
    public string? ImageUrl { get; set; }
    public string? HighResImageUrl { get; set; }
    public string? ThumbnailUrl { get; set; }
    public string? Occasion { get; set; }
    public string? Style { get; set; }
    public string? ColorPalette { get; set; }
    public string? FlowerTypes { get; set; }
    public Guid? RecipeId { get; set; }
    public string? SearchKeywords { get; set; }
    public int SortOrder { get; set; } = 0;
}

public class CreateOrUpdateLibraryCardRequest
{
    public string Title { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public string? Occasion { get; set; }
    public string? Tone { get; set; }
    public string Language { get; set; } = "en";
    public Guid? CategoryId { get; set; }
    public string? ImageUrl { get; set; }
    public string? SearchKeywords { get; set; }
    public int SortOrder { get; set; } = 0;
}

public class CreateOrUpdateLibraryTutorialRequest
{
    public string Title { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string? Summary { get; set; }
    public string ContentMarkdown { get; set; } = string.Empty;
    public Guid? CategoryId { get; set; }
    public string? VideoUrl { get; set; }
    public string? ThumbnailUrl { get; set; }
    public string DifficultyLevel { get; set; } = "Beginner";
    public int? EstimatedReadingMinutes { get; set; } = 5;
    public string? Tags { get; set; }
    public int SortOrder { get; set; } = 0;
}

public class ToggleLibraryStatusRequest
{
    public bool IsActive { get; set; }
}
