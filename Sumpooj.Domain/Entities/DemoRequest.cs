namespace Sumpooj.Domain.Entities;

public enum LeadStatus
{
    NewLead,
    Contacted,
    Qualified,
    Converted
}

public class DemoRequest : BaseEntity
{
    public string FullName { get; private set; } = default!;
    public string BusinessEmail { get; private set; } = default!;
    public string? BusinessType { get; private set; }
    public string? CurrentSoftware { get; private set; }
    public string? Notes { get; private set; }
    public LeadStatus Status { get; private set; }
    public string? Comments { get; private set; }

    private DemoRequest() { } // EF Core

    public DemoRequest(
        string fullName,
        string businessEmail,
        string? businessType,
        string? currentSoftware,
        string? notes)
    {
        FullName = fullName;
        BusinessEmail = businessEmail;
        BusinessType = businessType;
        CurrentSoftware = currentSoftware;
        Notes = notes;
        Status = LeadStatus.NewLead;
    }

    public void UpdateStatus(LeadStatus status, string? comments = null)
    {
        Status = status;
        Comments = comments;
        MarkUpdated();
    }
}
