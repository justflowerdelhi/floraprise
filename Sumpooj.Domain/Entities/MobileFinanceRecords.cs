namespace Sumpooj.Domain.Entities;

public class ExpenseCategory : BaseEntity
{
    private ExpenseCategory() { }

    public ExpenseCategory(Guid companyId, string name, string emoji, string groupName)
    {
        CompanyId = companyId;
        Update(name, emoji, groupName);
    }

    public Guid CompanyId { get; private set; }
    public string Name { get; private set; } = default!;
    public string Emoji { get; private set; } = string.Empty;
    public string GroupName { get; private set; } = default!;
    public bool IsActive { get; private set; } = true;

    public void Update(string name, string emoji, string groupName)
    {
        if (string.IsNullOrWhiteSpace(name)) throw new InvalidOperationException("Category name is required.");
        if (string.IsNullOrWhiteSpace(groupName)) throw new InvalidOperationException("Category group is required.");
        Name = name.Trim();
        Emoji = emoji?.Trim() ?? string.Empty;
        GroupName = groupName.Trim();
        MarkUpdated();
    }

    public void Deactivate() { IsActive = false; MarkUpdated(); }
    public void Reactivate() { IsActive = true; MarkUpdated(); }
}

public class OpeningCash : BaseEntity
{
    private OpeningCash() { }

    public OpeningCash(Guid companyId, DateTime date, decimal amount)
    {
        CompanyId = companyId;
        Date = EnsureUtc(date).Date;
        SetAmount(amount);
    }

    public Guid CompanyId { get; private set; }
    public DateTime Date { get; private set; }
    public decimal Amount { get; private set; }

    public void SetAmount(decimal amount)
    {
        if (amount < 0) throw new InvalidOperationException("Opening cash cannot be negative.");
        Amount = amount;
        MarkUpdated();
    }
}

public class CashBookEntry : BaseEntity
{
    private CashBookEntry() { }

    public CashBookEntry(Guid companyId, DateTime date, CashBookTransactionType transactionType,
        string description, decimal amount, decimal cashIn, decimal cashOut, decimal runningBalance)
    {
        if (string.IsNullOrWhiteSpace(description)) throw new InvalidOperationException("Description is required.");
        if (amount < 0 || cashIn < 0 || cashOut < 0) throw new InvalidOperationException("Cash amounts cannot be negative.");
        CompanyId = companyId;
        Date = EnsureUtc(date).Date;
        TransactionType = transactionType;
        Description = description.Trim();
        Amount = amount;
        CashIn = cashIn;
        CashOut = cashOut;
        RunningBalance = runningBalance;
    }

    public Guid CompanyId { get; private set; }
    public DateTime Date { get; private set; }
    public CashBookTransactionType TransactionType { get; private set; }
    public string Description { get; private set; } = default!;
    public decimal Amount { get; private set; }
    public decimal CashIn { get; private set; }
    public decimal CashOut { get; private set; }
    public decimal RunningBalance { get; private set; }
}

public enum CashBookTransactionType { CashSale, CashRefund, CashExpense, CashReceived, CashPaid }
public enum ExpensePaymentMode { Cash, Upi, Card }