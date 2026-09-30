namespace Sumpooj.Application.Library;

public class LibraryWeddingDateListItemDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public DateTime WeddingDate { get; set; }
    public string? Tithi { get; set; }
    public string? Nakshatra { get; set; }
    public string? Notes { get; set; }
    public string? Season { get; set; }
    public string DemandLevel { get; set; } = "High";
    public int SortOrder { get; set; }
    public bool IsActive { get; set; }
    public int Version { get; set; }
}

public class LibraryWeddingDateDetailDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public DateTime WeddingDate { get; set; }
    public string? Tithi { get; set; }
    public string? Nakshatra { get; set; }
    public string? Notes { get; set; }
    public string? Season { get; set; }
    public string DemandLevel { get; set; } = "High";
    public string? SearchKeywords { get; set; }
    public int SortOrder { get; set; }
    public bool IsActive { get; set; }
    public int Version { get; set; }
    public DateTime CreatedAtUtc { get; set; }
    public DateTime? UpdatedAtUtc { get; set; }
}

public class LibraryWeddingDateQueryRequest
{
    public string? Search { get; set; }
    public string? Season { get; set; }
    public string? DemandLevel { get; set; }
    public DateTime? From { get; set; }
    public DateTime? To { get; set; }
    public bool? IsActive { get; set; } = true;
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 50;
}

public class CreateOrUpdateLibraryWeddingDateRequest
{
    public string Title { get; set; } = string.Empty;
    public string? Slug { get; set; }
    public DateTime WeddingDate { get; set; }
    public string? Tithi { get; set; }
    public string? Nakshatra { get; set; }
    public string? Notes { get; set; }
    public string? Season { get; set; }
    public string DemandLevel { get; set; } = "High";
    public string? SearchKeywords { get; set; }
    public int SortOrder { get; set; } = 0;
}
