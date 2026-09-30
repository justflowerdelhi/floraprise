namespace Sumpooj.Application.Library;

public class LibraryCardListItemDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public string? Occasion { get; set; }
    public string? Tone { get; set; }
    public string Language { get; set; } = "en";
    public Guid? CategoryId { get; set; }
    public string? CategoryName { get; set; }
    public string? ImageUrl { get; set; }
    public int SortOrder { get; set; }
    public bool IsActive { get; set; }
    public int Version { get; set; }
}

public class LibraryCardDetailDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public string? Occasion { get; set; }
    public string? Tone { get; set; }
    public string Language { get; set; } = "en";
    public Guid? CategoryId { get; set; }
    public string? CategoryName { get; set; }
    public string? ImageUrl { get; set; }
    public string? SearchKeywords { get; set; }
    public int SortOrder { get; set; }
    public bool IsActive { get; set; }
    public int Version { get; set; }
    public DateTime CreatedAtUtc { get; set; }
    public DateTime? UpdatedAtUtc { get; set; }
}

public class LibraryCardQueryRequest
{
    public string? Search { get; set; }
    public string? Occasion { get; set; }
    public string? Tone { get; set; }
    public string? Language { get; set; }
    public Guid? CategoryId { get; set; }
    public bool? IsActive { get; set; } = true;
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 50;
}

public class LibraryCardOccasionSummaryDto
{
    public string Occasion { get; set; } = string.Empty;
    public int Count { get; set; }
}
