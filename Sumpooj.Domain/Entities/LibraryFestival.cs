namespace Sumpooj.Domain.Entities;

/// <summary>
/// Global reference festival/occasion date in the Floraprise Library.
/// Curated collection of Indian and international festivals with floral demands and marketing themes.
/// </summary>
public class LibraryFestival : BaseEntity
{
    private LibraryFestival() { }

    public LibraryFestival(
        string name,
        string slug,
        DateTime festivalDate,
        int month,
        int day,
        string? description = null,
        bool isRecurring = true,
        string? flowerDemands = null,
        string? searchKeywords = null,
        string? imageUrl = null,
        int sortOrder = 0)
    {
        if (string.IsNullOrWhiteSpace(name))
            throw new ArgumentException("Festival name is required.", nameof(name));
        if (string.IsNullOrWhiteSpace(slug))
            throw new ArgumentException("Festival slug is required.", nameof(slug));

        Name = name.Trim();
        Slug = slug.Trim().ToLowerInvariant();
        FestivalDate = festivalDate;
        Month = month;
        Day = day;
        Description = description?.Trim();
        IsRecurring = isRecurring;
        FlowerDemands = flowerDemands?.Trim();
        SearchKeywords = searchKeywords?.Trim();
        ImageUrl = imageUrl?.Trim();
        SortOrder = sortOrder;
        IsActive = true;
        Version = 1;
    }

    public string Name { get; private set; } = default!;
    public string Slug { get; private set; } = default!;
    public DateTime FestivalDate { get; private set; }
    public int Month { get; private set; }
    public int Day { get; private set; }
    public string? Description { get; private set; }
    public bool IsRecurring { get; private set; }
    public string? FlowerDemands { get; private set; }
    public string? SearchKeywords { get; private set; }
    public string? ImageUrl { get; private set; }
    public int SortOrder { get; private set; }
    public bool IsActive { get; private set; }
    public int Version { get; private set; }

    public void Update(
        string name,
        string slug,
        DateTime festivalDate,
        int month,
        int day,
        string? description = null,
        bool isRecurring = true,
        string? flowerDemands = null,
        string? searchKeywords = null,
        string? imageUrl = null,
        int sortOrder = 0)
    {
        if (string.IsNullOrWhiteSpace(name))
            throw new ArgumentException("Festival name is required.", nameof(name));
        if (string.IsNullOrWhiteSpace(slug))
            throw new ArgumentException("Festival slug is required.", nameof(slug));

        Name = name.Trim();
        Slug = slug.Trim().ToLowerInvariant();
        FestivalDate = festivalDate;
        Month = month;
        Day = day;
        Description = description?.Trim();
        IsRecurring = isRecurring;
        FlowerDemands = flowerDemands?.Trim();
        SearchKeywords = searchKeywords?.Trim();
        ImageUrl = imageUrl?.Trim();
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
