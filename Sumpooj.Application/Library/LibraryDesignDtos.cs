namespace Sumpooj.Application.Library;

public class LibraryDesignListItemDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string? Description { get; set; }
    public Guid? CategoryId { get; set; }
    public string? CategoryName { get; set; }
    public string? ImageUrl { get; set; }
    public string? HighResImageUrl { get; set; }
    public string? ThumbnailUrl { get; set; }
    public string? Occasion { get; set; }
    public string? Style { get; set; }
    public string? ColorPalette { get; set; }
    public string? FlowerTypes { get; set; }
    public Guid? RecipeId { get; set; }
    public string? RecipeName { get; set; }
    public int SortOrder { get; set; }
    public bool IsActive { get; set; }
    public int Version { get; set; }
}

public class LibraryDesignDetailDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string? Description { get; set; }
    public Guid? CategoryId { get; set; }
    public string? CategoryName { get; set; }
    public string? ImageUrl { get; set; }
    public string? HighResImageUrl { get; set; }
    public string? ThumbnailUrl { get; set; }
    public string? Occasion { get; set; }
    public string? Style { get; set; }
    public string? ColorPalette { get; set; }
    public string? FlowerTypes { get; set; }
    public Guid? RecipeId { get; set; }
    public string? RecipeName { get; set; }
    public string? SearchKeywords { get; set; }
    public int SortOrder { get; set; }
    public bool IsActive { get; set; }
    public int Version { get; set; }
    public DateTime CreatedAtUtc { get; set; }
    public DateTime? UpdatedAtUtc { get; set; }
}

public class LibraryDesignQueryRequest
{
    public string? Search { get; set; }
    public Guid? CategoryId { get; set; }
    public string? Occasion { get; set; }
    public string? Style { get; set; }
    public bool? IsActive { get; set; } = true;
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 30;
}

public class ImportLibraryDesignResultDto
{
    public bool Success { get; set; }
    public bool AlreadyImported { get; set; }
    public Guid DesignId { get; set; }
    public string BouquetId { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
}
