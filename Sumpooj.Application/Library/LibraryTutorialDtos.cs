namespace Sumpooj.Application.Library;

public class LibraryTutorialListItemDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string? Summary { get; set; }
    public Guid? CategoryId { get; set; }
    public string? CategoryName { get; set; }
    public string? VideoUrl { get; set; }
    public string? ThumbnailUrl { get; set; }
    public string DifficultyLevel { get; set; } = "Beginner";
    public int? EstimatedReadingMinutes { get; set; }
    public string? Tags { get; set; }
    public int SortOrder { get; set; }
    public bool IsActive { get; set; }
    public int Version { get; set; }
}

public class LibraryTutorialDetailDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string? Summary { get; set; }
    public string ContentMarkdown { get; set; } = string.Empty;
    public Guid? CategoryId { get; set; }
    public string? CategoryName { get; set; }
    public string? VideoUrl { get; set; }
    public string? ThumbnailUrl { get; set; }
    public string DifficultyLevel { get; set; } = "Beginner";
    public int? EstimatedReadingMinutes { get; set; }
    public string? Tags { get; set; }
    public int SortOrder { get; set; }
    public bool IsActive { get; set; }
    public int Version { get; set; }
    public DateTime CreatedAtUtc { get; set; }
    public DateTime? UpdatedAtUtc { get; set; }
}

public class LibraryTutorialQueryRequest
{
    public string? Search { get; set; }
    public Guid? CategoryId { get; set; }
    public string? DifficultyLevel { get; set; }
    public string? Tag { get; set; }
    public bool? IsActive { get; set; } = true;
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 30;
}
