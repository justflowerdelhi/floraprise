namespace Sumpooj.Domain.Entities;

public class Event : BaseEntity
{
    private Event() { }

    public Event(
        Guid companyId,
        string eventName,
        EventType eventType,
        DateTime eventDate,
        string clientName,
        string clientPhone,
        string venueName)
    {
        CompanyId = companyId;
        EventName = eventName;
        EventType = eventType;
        EventDate = eventDate;
        ClientName = clientName;
        ClientPhone = clientPhone;
        VenueName = venueName;
        Status = EventStatus.Inquiry;
        IsActive = true;
    }

    public Guid CompanyId { get; private set; }
    public string EventName { get; private set; }
    public EventType EventType { get; private set; }
    public DateTime EventDate { get; private set; }
    public EventStatus Status { get; private set; }
    public bool IsActive { get; private set; }

    // Client Info
    public string ClientName { get; private set; }
    public string ClientPhone { get; private set; }
    public string? ClientEmail { get; private set; }

    // Venue Info
    public string VenueName { get; private set; }
    public string? VenueAddress { get; private set; }

    // Event Details
    public int? EstimatedGuestCount { get; private set; }
    public decimal? Budget { get; private set; }
    public string? ColorTheme { get; private set; }
    public string? MoodNotes { get; private set; }
    public string? MoodBoardLink { get; private set; }

    // Assignment
    public Guid? AssignedDesignerId { get; private set; }
    public string? InternalNotes { get; private set; }

    // Financial
    public decimal TotalProposedAmount { get; private set; }
    public decimal TotalPaidAmount { get; private set; }
    public decimal EstimatedCost { get; private set; }

    public void UpdateDetails(
        string eventName,
        EventType eventType,
        DateTime eventDate,
        string venueName,
        string? venueAddress)
    {
        EventName = eventName;
        EventType = eventType;
        EventDate = eventDate;
        VenueName = venueName;
        VenueAddress = venueAddress;
        MarkUpdated();
    }

    public void UpdateClientInfo(string clientName, string clientPhone, string? clientEmail)
    {
        ClientName = clientName;
        ClientPhone = clientPhone;
        ClientEmail = clientEmail;
        MarkUpdated();
    }

    public void SetEventDetails(int? guestCount, decimal? budget, string? colorTheme, string? moodNotes, string? moodBoardLink)
    {
        EstimatedGuestCount = guestCount;
        Budget = budget;
        ColorTheme = colorTheme;
        MoodNotes = moodNotes;
        MoodBoardLink = moodBoardLink;
        MarkUpdated();
    }

    public void AssignDesigner(Guid designerId)
    {
        AssignedDesignerId = designerId;
        MarkUpdated();
    }

    public void SetStatus(EventStatus status)
    {
        Status = status;
        MarkUpdated();
    }

    public void AddNote(string note)
    {
        InternalNotes = string.IsNullOrEmpty(InternalNotes)
            ? note
            : $"{InternalNotes}\n{note}";
        MarkUpdated();
    }

    public void UpdateFinancials(decimal proposedAmount, decimal paidAmount, decimal estimatedCost)
    {
        TotalProposedAmount = proposedAmount;
        TotalPaidAmount = paidAmount;
        EstimatedCost = estimatedCost;
        MarkUpdated();
    }

    public void Deactivate()
    {
        IsActive = false;
        MarkUpdated();
    }
}
