using Sumpooj.Application.Products;

namespace Sumpooj.Application.Library;

public class LibraryProductListItemDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public Guid? CategoryId { get; set; }
    public string? CategoryName { get; set; }
    public string ProductType { get; set; } = string.Empty;
    public string StandardUnit { get; set; } = string.Empty;
    public string? StandardSku { get; set; }
    public string? ReferenceImageUrl { get; set; }
    public string? ThumbnailUrl { get; set; }
    public int SortOrder { get; set; }
    public bool IsActive { get; set; }
    public int Version { get; set; }
}

public class LibraryProductDetailDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public Guid? CategoryId { get; set; }
    public string? CategoryName { get; set; }
    public string ProductType { get; set; } = string.Empty;
    public string StandardUnit { get; set; } = string.Empty;
    public string? StandardSku { get; set; }
    public string? Description { get; set; }
    public string? ReferenceImageUrl { get; set; }
    public string? ThumbnailUrl { get; set; }
    public string? SearchKeywords { get; set; }
    public int SortOrder { get; set; }
    public bool IsActive { get; set; }
    public int Version { get; set; }
    public DateTime CreatedAtUtc { get; set; }
    public DateTime? UpdatedAtUtc { get; set; }
}

public class LibraryProductQueryRequest
{
    public string? Search { get; set; }
    public Guid? CategoryId { get; set; }
    public string? ProductType { get; set; }
    public bool? IsActive { get; set; } = true;
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 30;
}

public class ImportLibraryProductRequest
{
    public Guid? CustomCategoryId { get; set; }
    public string? CustomSku { get; set; }
    public decimal? CustomRetailPrice { get; set; }
    public decimal? CustomCostPrice { get; set; }
}

public class ImportLibraryProductResultDto
{
    public bool Success { get; set; }
    public bool AlreadyImported { get; set; }
    public Guid ProductId { get; set; }
    public string Message { get; set; } = string.Empty;
    public ProductDto? Product { get; set; }
}
