namespace Sumpooj.Domain.Entities;

/// <summary>Double-entry journal entry line.</summary>
public class JournalEntry : BaseEntity
{
    private JournalEntry() { }

    public JournalEntry(
        Guid companyId, DateTime entryDate, string reference,
        string referenceType, string description,
        decimal debit, decimal credit, Guid? accountId)
    {
        CompanyId = companyId;
        EntryDate = EnsureUtc(entryDate);
        Reference = reference;
        ReferenceType = referenceType;
        Description = description;
        Debit = debit;
        Credit = credit;
        AccountId = accountId;
    }

    public Guid CompanyId { get; private set; }
    public Guid? LocationId { get; private set; }
    public DateTime EntryDate { get; private set; }
    public string Reference { get; private set; } = default!;
    public string ReferenceType { get; private set; } = default!;
    public string Description { get; private set; } = default!;
    public decimal Debit { get; private set; }
    public decimal Credit { get; private set; }
    public Guid? AccountId { get; private set; }

    public void SetLocation(Guid locationId) { LocationId = locationId; MarkUpdated(); }
}
