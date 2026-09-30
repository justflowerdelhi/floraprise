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
    public string? PhoneNumber { get; private set; }
    public string? BusinessType { get; private set; }
    public string? CurrentSoftware { get; private set; }
    public string? Notes { get; private set; }
    public LeadStatus Status { get; private set; }
    public string? Comments { get; private set; }

    private DemoRequest() { } // EF Core

    public DemoRequest(
        string fullName,
        string businessEmail,
        string? phoneNumber,
        string? businessType,
        string? currentSoftware,
        string? notes)
    {
        FullName = fullName;
        BusinessEmail = businessEmail;
        PhoneNumber = phoneNumber;
        BusinessType = businessType;
        CurrentSoftware = currentSoftware;
        Notes = notes;
        Status = LeadStatus.NewLead;
    }

    public DemoRequest(
        string fullName,
        string businessEmail,
        string? businessType,
        string? currentSoftware,
        string? notes)
        : this(fullName, businessEmail, null, businessType, currentSoftware, notes)
    {
    }

    public void UpdateStatus(LeadStatus status, string? comments = null)
    {
        Status = status;
        Comments = comments;
        MarkUpdated();
    }
}
