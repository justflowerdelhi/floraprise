namespace Sumpooj.Domain.Entities;

/// <summary>
/// Global reference wedding date / auspicious Vivah Muhurat in the Floraprise Library.
/// Curated list of high-demand Indian wedding dates by Hindu panchang / seasonal calendars.
/// </summary>
public class LibraryWeddingDate : BaseEntity
{
    private LibraryWeddingDate() { }

    public LibraryWeddingDate(
        string title,
        string slug,
        DateTime weddingDate,
        string? tithi = null,
        string? nakshatra = null,
        string? notes = null,
        string? season = null,
        string demandLevel = "High",
        string? searchKeywords = null,
        int sortOrder = 0)
    {
        if (string.IsNullOrWhiteSpace(title))
            throw new ArgumentException("Wedding date title is required.", nameof(title));
        if (string.IsNullOrWhiteSpace(slug))
            throw new ArgumentException("Wedding date slug is required.", nameof(slug));

        Title = title.Trim();
        Slug = slug.Trim().ToLowerInvariant();
        WeddingDate = weddingDate;
        Tithi = tithi?.Trim();
        Nakshatra = nakshatra?.Trim();
        Notes = notes?.Trim();
        Season = season?.Trim();
        DemandLevel = string.IsNullOrWhiteSpace(demandLevel) ? "High" : demandLevel.Trim();
        SearchKeywords = searchKeywords?.Trim();
        SortOrder = sortOrder;
        IsActive = true;
        Version = 1;
    }

    public string Title { get; private set; } = default!;
    public string Slug { get; private set; } = default!;
    public DateTime WeddingDate { get; private set; }
    public string? Tithi { get; private set; }
    public string? Nakshatra { get; private set; }
    public string? Notes { get; private set; }
    public string? Season { get; private set; }
    public string DemandLevel { get; private set; } = "High";
    public string? SearchKeywords { get; private set; }
    public int SortOrder { get; private set; }
    public bool IsActive { get; private set; }
    public int Version { get; private set; }

    public void Update(
        string title,
        string slug,
        DateTime weddingDate,
        string? tithi = null,
        string? nakshatra = null,
        string? notes = null,
        string? season = null,
        string demandLevel = "High",
        string? searchKeywords = null,
        int sortOrder = 0)
    {
        if (string.IsNullOrWhiteSpace(title))
            throw new ArgumentException("Wedding date title is required.", nameof(title));
        if (string.IsNullOrWhiteSpace(slug))
            throw new ArgumentException("Wedding date slug is required.", nameof(slug));

        Title = title.Trim();
        Slug = slug.Trim().ToLowerInvariant();
        WeddingDate = weddingDate;
        Tithi = tithi?.Trim();
        Nakshatra = nakshatra?.Trim();
        Notes = notes?.Trim();
        Season = season?.Trim();
        DemandLevel = string.IsNullOrWhiteSpace(demandLevel) ? "High" : demandLevel.Trim();
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
