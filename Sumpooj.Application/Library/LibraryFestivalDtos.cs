namespace Sumpooj.Application.Library;

public class LibraryFestivalListItemDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public DateTime FestivalDate { get; set; }
    public int Month { get; set; }
    public int Day { get; set; }
    public string? Description { get; set; }
    public bool IsRecurring { get; set; }
    public string? FlowerDemands { get; set; }
    public string? ImageUrl { get; set; }
    public int SortOrder { get; set; }
    public bool IsActive { get; set; }
    public int Version { get; set; }
}

public class LibraryFestivalDetailDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public DateTime FestivalDate { get; set; }
    public int Month { get; set; }
    public int Day { get; set; }
    public string? Description { get; set; }
    public bool IsRecurring { get; set; }
    public string? FlowerDemands { get; set; }
    public string? SearchKeywords { get; set; }
    public string? ImageUrl { get; set; }
    public int SortOrder { get; set; }
    public bool IsActive { get; set; }
    public int Version { get; set; }
    public DateTime CreatedAtUtc { get; set; }
    public DateTime? UpdatedAtUtc { get; set; }
}

public class LibraryFestivalQueryRequest
{
    public string? Search { get; set; }
    public int? Month { get; set; }
    public DateTime? From { get; set; }
    public DateTime? To { get; set; }
    public bool? IsActive { get; set; } = true;
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 50;
}

public class CreateOrUpdateLibraryFestivalRequest
{
    public string Name { get; set; } = string.Empty;
    public string? Slug { get; set; }
    public DateTime FestivalDate { get; set; }
    public int Month { get; set; }
    public int Day { get; set; }
    public string? Description { get; set; }
    public bool IsRecurring { get; set; } = true;
    public string? FlowerDemands { get; set; }
    public string? SearchKeywords { get; set; }
    public string? ImageUrl { get; set; }
    public int SortOrder { get; set; } = 0;
}
