namespace Sumpooj.Domain.Entities;

/// <summary>
/// Educational tutorial, floral care guide, arrangement technique, or business guide in Floraprise Library.
/// </summary>
public class LibraryTutorial : BaseEntity
{
    private LibraryTutorial() { }

    public LibraryTutorial(
        string title,
        string slug,
        string contentMarkdown,
        string? summary = null,
        Guid? categoryId = null,
        string? videoUrl = null,
        string? thumbnailUrl = null,
        string? difficultyLevel = "Beginner",
        int? estimatedReadingMinutes = 5,
        string? tags = null,
        int sortOrder = 0)
    {
        if (string.IsNullOrWhiteSpace(title))
            throw new ArgumentException("Tutorial title is required.", nameof(title));
        if (string.IsNullOrWhiteSpace(slug))
            throw new ArgumentException("Tutorial slug is required.", nameof(slug));
        if (string.IsNullOrWhiteSpace(contentMarkdown))
            throw new ArgumentException("Tutorial content markdown is required.", nameof(contentMarkdown));

        Title = title.Trim();
        Slug = slug.Trim().ToLowerInvariant();
        ContentMarkdown = contentMarkdown.Trim();
        Summary = summary?.Trim();
        CategoryId = categoryId;
        VideoUrl = videoUrl?.Trim();
        ThumbnailUrl = thumbnailUrl?.Trim();
        DifficultyLevel = string.IsNullOrWhiteSpace(difficultyLevel) ? "Beginner" : difficultyLevel.Trim();
        EstimatedReadingMinutes = estimatedReadingMinutes.HasValue && estimatedReadingMinutes.Value > 0 ? estimatedReadingMinutes.Value : 5;
        Tags = tags?.Trim();
        SortOrder = sortOrder;
        IsActive = true;
        Version = 1;
    }

    public string Title { get; private set; } = default!;
    public string Slug { get; private set; } = default!;
    public string? Summary { get; private set; }
    public string ContentMarkdown { get; private set; } = default!;
    public Guid? CategoryId { get; private set; }
    public LibraryCategory? Category { get; private set; }
    public string? VideoUrl { get; private set; }
    public string? ThumbnailUrl { get; private set; }
    public string DifficultyLevel { get; private set; } = "Beginner";
    public int? EstimatedReadingMinutes { get; private set; }
    public string? Tags { get; private set; }
    public int SortOrder { get; private set; }
    public bool IsActive { get; private set; }
    public int Version { get; private set; }

    public void Update(
        string title,
        string slug,
        string contentMarkdown,
        string? summary = null,
        Guid? categoryId = null,
        string? videoUrl = null,
        string? thumbnailUrl = null,
        string? difficultyLevel = "Beginner",
        int? estimatedReadingMinutes = 5,
        string? tags = null,
        int sortOrder = 0)
    {
        if (string.IsNullOrWhiteSpace(title))
            throw new ArgumentException("Tutorial title is required.", nameof(title));
        if (string.IsNullOrWhiteSpace(slug))
            throw new ArgumentException("Tutorial slug is required.", nameof(slug));
        if (string.IsNullOrWhiteSpace(contentMarkdown))
            throw new ArgumentException("Tutorial content markdown is required.", nameof(contentMarkdown));

        Title = title.Trim();
        Slug = slug.Trim().ToLowerInvariant();
        ContentMarkdown = contentMarkdown.Trim();
        Summary = summary?.Trim();
        CategoryId = categoryId;
        VideoUrl = videoUrl?.Trim();
        ThumbnailUrl = thumbnailUrl?.Trim();
        DifficultyLevel = string.IsNullOrWhiteSpace(difficultyLevel) ? "Beginner" : difficultyLevel.Trim();
        EstimatedReadingMinutes = estimatedReadingMinutes.HasValue && estimatedReadingMinutes.Value > 0 ? estimatedReadingMinutes.Value : 5;
        Tags = tags?.Trim();
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
