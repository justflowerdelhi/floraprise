namespace Sumpooj.Application.Accounting;

public class AccountDto
{
    public Guid Id { get; set; }
    public string Code { get; set; } = default!;
    public string Name { get; set; } = default!;
    public string Type { get; set; } = default!;
    public bool IsActive { get; set; }
}

public class CreateAccountRequest
{
    public string Code { get; set; } = default!;
    public string Name { get; set; } = default!;
    public string Type { get; set; } = "Expense";
}

public class UpdateAccountRequest
{
    public string Code { get; set; } = default!;
    public string Name { get; set; } = default!;
    public string Type { get; set; } = default!;
}

public class ExpenseDto
{
    public Guid Id { get; set; }
    public string Category { get; set; } = default!;
    public decimal Amount { get; set; }
    public string? Description { get; set; }
    public string ExpenseDate { get; set; } = default!;
    public bool IsActive { get; set; }
}

public class CreateExpenseRequest
{
    public string Category { get; set; } = default!;
    public decimal Amount { get; set; }
    public string? Description { get; set; }
    public string? ExpenseDate { get; set; }
}

public class UpdateExpenseRequest
{
    public string Category { get; set; } = default!;
    public decimal Amount { get; set; }
    public string? Description { get; set; }
}

public class JournalEntryDto
{
    public Guid Id { get; set; }
    public string Date { get; set; } = default!;
    public string Reference { get; set; } = default!;
    public string ReferenceType { get; set; } = default!;
    public string Description { get; set; } = default!;
    public decimal Debit { get; set; }
    public decimal Credit { get; set; }
    public Guid? AccountId { get; set; }
}

public class CreateJournalEntryRequest
{
    public string Date { get; set; } = default!;
    public string Reference { get; set; } = default!;
    public string ReferenceType { get; set; } = "OTHER";
    public string Description { get; set; } = default!;
    public decimal Debit { get; set; }
    public decimal Credit { get; set; }
    public Guid? AccountId { get; set; }
}

public class AccountingDashboardDto
{
    public decimal RevenueToday { get; set; }
    public decimal ExpensesToday { get; set; }
    public decimal ProfitToday { get; set; }
    public decimal CashBalance { get; set; }
    public List<TrendPoint> RevenueTrend { get; set; } = [];
    public List<TrendPoint> ExpenseTrend { get; set; } = [];
    public List<CategoryAmount> TopExpenseCategories { get; set; } = [];
}

public class TrendPoint
{
    public string Day { get; set; } = default!;
    public decimal Revenue { get; set; }
    public decimal Expense { get; set; }
}

public class CategoryAmount
{
    public string Category { get; set; } = default!;
    public decimal Amount { get; set; }
}

public class ProfitLossDto
{
    public decimal Revenue { get; set; }
    public decimal Cogs { get; set; }
    public decimal Expenses { get; set; }
    public decimal GrossProfit { get; set; }
    public decimal NetProfit { get; set; }
}

public class TaxSummaryDto
{
    public string TaxType { get; set; } = default!;
    public decimal Rate { get; set; }
    public decimal TaxableAmount { get; set; }
    public decimal TaxAmount { get; set; }
}

public class LedgerEntryDto
{
    public string Date { get; set; } = default!;
    public string Reference { get; set; } = default!;
    public string Description { get; set; } = default!;
    public decimal Debit { get; set; }
    public decimal Credit { get; set; }
    public decimal Balance { get; set; }
}

public class TrialBalanceRowDto
{
    public Guid AccountId { get; set; }
    public string Code { get; set; } = default!;
    public string Name { get; set; } = default!;
    public string Type { get; set; } = default!;
    public decimal Debit { get; set; }
    public decimal Credit { get; set; }
}

public class ManualSaleRequest
{
    public string OrderSource { get; set; } = "MANUAL";
    public string? SaleDate { get; set; }
    public string PaymentMethod { get; set; } = "Cash";
    public string? Reason { get; set; }
    public decimal Total { get; set; }
    public List<ManualSaleItemRequest> Items { get; set; } = new();
}

public class ManualSaleItemRequest
{
    public string ProductId { get; set; } = default!;
    public string Name { get; set; } = default!;
    public int Qty { get; set; }
    public decimal Price { get; set; }
}
