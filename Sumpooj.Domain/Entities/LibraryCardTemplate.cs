namespace Sumpooj.Domain.Entities;

/// <summary>
/// Global reference greeting card message / template in the Floraprise Library.
/// Curated collection of florist card sentiments by occasion, tone, and language.
/// </summary>
public class LibraryCardTemplate : BaseEntity
{
    private LibraryCardTemplate() { }

    public LibraryCardTemplate(
        string title,
        string slug,
        string content,
        string? occasion = null,
        string? tone = null,
        string? language = "en",
        Guid? categoryId = null,
        string? imageUrl = null,
        string? searchKeywords = null,
        int sortOrder = 0)
    {
        if (string.IsNullOrWhiteSpace(title))
            throw new ArgumentException("Card template title is required.", nameof(title));
        if (string.IsNullOrWhiteSpace(slug))
            throw new ArgumentException("Card template slug is required.", nameof(slug));
        if (string.IsNullOrWhiteSpace(content))
            throw new ArgumentException("Card template message content is required.", nameof(content));

        Title = title.Trim();
        Slug = slug.Trim().ToLowerInvariant();
        Content = content.Trim();
        Occasion = occasion?.Trim();
        Tone = tone?.Trim();
        Language = string.IsNullOrWhiteSpace(language) ? "en" : language.Trim().ToLowerInvariant();
        CategoryId = categoryId;
        ImageUrl = imageUrl?.Trim();
        SearchKeywords = searchKeywords?.Trim();
        SortOrder = sortOrder;
        IsActive = true;
        Version = 1;
    }

    public string Title { get; private set; } = default!;
    public string Slug { get; private set; } = default!;
    public string Content { get; private set; } = default!;
    public string? Occasion { get; private set; }
    public string? Tone { get; private set; }
    public string Language { get; private set; } = "en";
    public Guid? CategoryId { get; private set; }
    public LibraryCategory? Category { get; private set; }
    public string? ImageUrl { get; private set; }
    public string? SearchKeywords { get; private set; }
    public int SortOrder { get; private set; }
    public bool IsActive { get; private set; }
    public int Version { get; private set; }

    public void Update(
        string title,
        string slug,
        string content,
        string? occasion = null,
        string? tone = null,
        string? language = "en",
        Guid? categoryId = null,
        string? imageUrl = null,
        string? searchKeywords = null,
        int sortOrder = 0)
    {
        if (string.IsNullOrWhiteSpace(title))
            throw new ArgumentException("Card template title is required.", nameof(title));
        if (string.IsNullOrWhiteSpace(slug))
            throw new ArgumentException("Card template slug is required.", nameof(slug));
        if (string.IsNullOrWhiteSpace(content))
            throw new ArgumentException("Card template message content is required.", nameof(content));

        Title = title.Trim();
        Slug = slug.Trim().ToLowerInvariant();
        Content = content.Trim();
        Occasion = occasion?.Trim();
        Tone = tone?.Trim();
        Language = string.IsNullOrWhiteSpace(language) ? "en" : language.Trim().ToLowerInvariant();
        CategoryId = categoryId;
        ImageUrl = imageUrl?.Trim();
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
