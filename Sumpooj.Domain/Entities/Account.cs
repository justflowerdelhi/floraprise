namespace Sumpooj.Domain.Entities;

/// <summary>Chart of Accounts entry (Asset, Liability, Income, Expense, Equity).</summary>
public class Account : BaseEntity
{
    private Account() { }

    public Account(Guid companyId, string code, string name, string type)
    {
        CompanyId = companyId;
        Code = code;
        Name = name;
        Type = type;
    }

    public Guid CompanyId { get; private set; }
    public string Code { get; private set; } = default!;
    public string Name { get; private set; } = default!;

    /// <summary>Asset, Liability, Income, Expense, Equity</summary>
    public string Type { get; private set; } = default!;
    public bool IsActive { get; private set; } = true;

    public void Update(string code, string name, string type)
    {
        Code = code;
        Name = name;
        Type = type;
        MarkUpdated();
    }

    public void Disable() { IsActive = false; MarkUpdated(); }
    public void Enable() { IsActive = true; MarkUpdated(); }
}
