namespace Sumpooj.Domain.Entities;

/// <summary>Expense record for the accounting module.</summary>
public class Expense : BaseEntity
{
    private Expense() { }

    public Expense(Guid companyId, string category, decimal amount, string? description, DateTime expenseDate)
    {
        CompanyId = companyId;
        Category = category;
        Amount = amount;
        Description = description;
        ExpenseDate = EnsureUtc(expenseDate);
    }

    public Guid CompanyId { get; private set; }
    public Guid? LocationId { get; private set; }
    public Guid? AccountId { get; private set; }
    public string Category { get; private set; } = default!;
    public decimal Amount { get; private set; }
    public string? Description { get; private set; }
    public DateTime ExpenseDate { get; private set; }
    public bool IsActive { get; private set; } = true;

    public void SetLocation(Guid locationId) { LocationId = locationId; MarkUpdated(); }
    public void SetAccount(Guid accountId) { AccountId = accountId; MarkUpdated(); }

    public void Update(string category, decimal amount, string? description)
    {
        Category = category;
        Amount = amount;
        Description = description;
        MarkUpdated();
    }

    public void Disable() { IsActive = false; MarkUpdated(); }
    public void Enable() { IsActive = true; MarkUpdated(); }
}
