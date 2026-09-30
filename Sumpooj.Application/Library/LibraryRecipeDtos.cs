using Sumpooj.Application.Production;

namespace Sumpooj.Application.Library;

public class LibraryRecipeListItemDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string? Description { get; set; }
    public Guid? CategoryId { get; set; }
    public string? CategoryName { get; set; }
    public string? ImageUrl { get; set; }
    public decimal YieldQuantity { get; set; }
    public string? YieldUnit { get; set; }
    public int ItemCount { get; set; }
    public int SortOrder { get; set; }
    public bool IsActive { get; set; }
    public int Version { get; set; }
}

public class LibraryRecipeItemDto
{
    public Guid Id { get; set; }
    public Guid? LibraryProductId { get; set; }
    public string? LibraryProductName { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public decimal Quantity { get; set; }
    public string Unit { get; set; } = string.Empty;
    public string? Notes { get; set; }
    public int SortOrder { get; set; }
}

public class LibraryRecipeDetailDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string? Description { get; set; }
    public Guid? CategoryId { get; set; }
    public string? CategoryName { get; set; }
    public string? ImageUrl { get; set; }
    public decimal YieldQuantity { get; set; }
    public string? YieldUnit { get; set; }
    public string? Instructions { get; set; }
    public string? PreparationNotes { get; set; }
    public int SortOrder { get; set; }
    public bool IsActive { get; set; }
    public int Version { get; set; }
    public DateTime CreatedAtUtc { get; set; }
    public DateTime? UpdatedAtUtc { get; set; }
    public List<LibraryRecipeItemDto> Items { get; set; } = new();
}

public class LibraryRecipeQueryRequest
{
    public string? Search { get; set; }
    public Guid? CategoryId { get; set; }
    public bool? IsActive { get; set; } = true;
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 30;
}

public class ImportLibraryRecipeResultDto
{
    public bool Success { get; set; }
    public bool AlreadyImported { get; set; }
    public Guid RecipeId { get; set; }
    public string Message { get; set; } = string.Empty;
    public FloralRecipeDto? Recipe { get; set; }
}
