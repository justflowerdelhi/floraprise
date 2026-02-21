namespace Sumpooj.Application.Events;

public class EventDto
{
    public Guid Id { get; set; }
    public string EventName { get; set; } = default!;
    public string EventType { get; set; } = default!;
    public DateTime EventDate { get; set; }
    public string Status { get; set; } = default!;
    public bool IsActive { get; set; }

    // Client
    public string ClientName { get; set; } = default!;
    public string ClientPhone { get; set; } = default!;
    public string? ClientEmail { get; set; }

    // Venue
    public string VenueName { get; set; } = default!;
    public string? VenueAddress { get; set; }

    // Details
    public int? EstimatedGuestCount { get; set; }
    public decimal? Budget { get; set; }
    public string? ColorTheme { get; set; }
    public string? MoodNotes { get; set; }
    public string? MoodBoardLink { get; set; }

    // Assignment
    public Guid? AssignedDesignerId { get; set; }
    public string? AssignedDesignerName { get; set; }
    public string? InternalNotes { get; set; }

    // Financial
    public decimal TotalProposedAmount { get; set; }
    public decimal TotalPaidAmount { get; set; }
    public decimal EstimatedCost { get; set; }
    public decimal EstimatedProfit { get; set; }

    public DateTime CreatedAtUtc { get; set; }
}

public class EventListDto
{
    public Guid Id { get; set; }
    public string EventName { get; set; } = default!;
    public string EventType { get; set; } = default!;
    public DateTime EventDate { get; set; }
    public string Status { get; set; } = default!;
    public string ClientName { get; set; } = default!;
    public string VenueName { get; set; } = default!;
    public decimal? Budget { get; set; }
    public decimal TotalProposedAmount { get; set; }
}

public class CreateEventRequest
{
    public string EventName { get; set; } = default!;
    public string EventType { get; set; } = "Wedding";
    public DateTime EventDate { get; set; }
    public string ClientName { get; set; } = default!;
    public string ClientPhone { get; set; } = default!;
    public string? ClientEmail { get; set; }
    public string VenueName { get; set; } = default!;
    public string? VenueAddress { get; set; }
    public int? EstimatedGuestCount { get; set; }
    public decimal? Budget { get; set; }
    public string? ColorTheme { get; set; }
    public string? MoodNotes { get; set; }
    public string? MoodBoardLink { get; set; }
    public Guid? AssignedDesignerId { get; set; }
    public string? Status { get; set; }
    public string? InternalNotes { get; set; }
}

public class UpdateEventRequest
{
    public string? EventName { get; set; }
    public string? EventType { get; set; }
    public DateTime? EventDate { get; set; }
    public string? ClientName { get; set; }
    public string? ClientPhone { get; set; }
    public string? ClientEmail { get; set; }
    public string? VenueName { get; set; }
    public string? VenueAddress { get; set; }
    public int? EstimatedGuestCount { get; set; }
    public decimal? Budget { get; set; }
    public string? ColorTheme { get; set; }
    public string? MoodNotes { get; set; }
    public string? MoodBoardLink { get; set; }
    public Guid? AssignedDesignerId { get; set; }
    public string? Status { get; set; }
    public string? InternalNotes { get; set; }
}

public class EventSearchRequest
{
    public string? Query { get; set; }
    public string? EventType { get; set; }
    public string? Status { get; set; }
    public DateTime? FromDate { get; set; }
    public DateTime? ToDate { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}
