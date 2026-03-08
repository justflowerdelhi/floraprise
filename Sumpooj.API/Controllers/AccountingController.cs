using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Accounting;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/accounting")]
[Authorize(Policy = "CompanyOnly")]
public class AccountingController : ControllerBase
{
    private readonly SumpoojDbContext _db;
    private readonly ITenantContext _tenantContext;

    public AccountingController(SumpoojDbContext db, ITenantContext tenantContext)
    {
        _db = db;
        _tenantContext = tenantContext;
    }

    private Guid CompanyId => _tenantContext.CompanyId
        ?? throw new UnauthorizedAccessException("Company context required");

    // ─── Dashboard ──────────────────────────────────────────

    [HttpGet("dashboard")]
    public async Task<IActionResult> GetDashboard()
    {
        var cid = CompanyId;
        var todayUtc = DateTime.UtcNow.Date;
        var weekAgo = todayUtc.AddDays(-6);

        var revenueToday = await _db.Orders
            .Where(o => o.CompanyId == cid && o.OrderDate >= todayUtc)
            .SumAsync(o => o.TotalAmount);

        var expensesToday = await _db.Expenses
            .Where(e => e.CompanyId == cid && e.IsActive && e.ExpenseDate >= todayUtc)
            .SumAsync(e => e.Amount);

        var recentOrders = await _db.Orders
            .Where(o => o.CompanyId == cid && o.OrderDate >= weekAgo)
            .ToListAsync();

        var revenueTrend = Enumerable.Range(0, 7).Select(i =>
        {
            var day = weekAgo.AddDays(i);
            return new TrendPoint
            {
                Day = day.ToString("ddd"),
                Revenue = recentOrders.Where(o => o.OrderDate.Date == day).Sum(o => o.TotalAmount),
            };
        }).ToList();

        var recentExpenses = await _db.Expenses
            .Where(e => e.CompanyId == cid && e.IsActive && e.ExpenseDate >= weekAgo)
            .ToListAsync();

        var expenseTrend = Enumerable.Range(0, 7).Select(i =>
        {
            var day = weekAgo.AddDays(i);
            return new TrendPoint
            {
                Day = day.ToString("ddd"),
                Expense = recentExpenses.Where(e => e.ExpenseDate.Date == day).Sum(e => e.Amount),
            };
        }).ToList();

        var topCategories = recentExpenses
            .GroupBy(e => e.Category)
            .Select(g => new CategoryAmount { Category = g.Key, Amount = g.Sum(e => e.Amount) })
            .OrderByDescending(c => c.Amount).Take(5).ToList();

        var totalPayments = await _db.Payments.Where(p => p.CompanyId == cid).SumAsync(p => p.Amount);
        var totalExpenses = await _db.Expenses.Where(e => e.CompanyId == cid && e.IsActive).SumAsync(e => e.Amount);

        return Ok(new AccountingDashboardDto
        {
            RevenueToday = revenueToday,
            ExpensesToday = expensesToday,
            ProfitToday = revenueToday - expensesToday,
            CashBalance = totalPayments - totalExpenses,
            RevenueTrend = revenueTrend,
            ExpenseTrend = expenseTrend,
            TopExpenseCategories = topCategories,
        });
    }

    // ─── Accounts ───────────────────────────────────────────

    [HttpGet("accounts")]
    public async Task<IActionResult> GetAccounts()
    {
        var list = await _db.Accounts
            .Where(a => a.CompanyId == CompanyId).OrderBy(a => a.Code)
            .Select(a => new AccountDto { Id = a.Id, Code = a.Code, Name = a.Name, Type = a.Type, IsActive = a.IsActive })
            .ToListAsync();
        return Ok(list);
    }

    [HttpPost("accounts")]
    public async Task<IActionResult> CreateAccount([FromBody] CreateAccountRequest req)
    {
        var account = new Account(CompanyId, req.Code, req.Name, req.Type);
        _db.Accounts.Add(account);
        await _db.SaveChangesAsync();
        return Ok(new AccountDto { Id = account.Id, Code = account.Code, Name = account.Name, Type = account.Type, IsActive = true });
    }

    [HttpPut("accounts/{id:guid}")]
    public async Task<IActionResult> UpdateAccount(Guid id, [FromBody] UpdateAccountRequest req)
    {
        var account = await _db.Accounts.FirstOrDefaultAsync(a => a.CompanyId == CompanyId && a.Id == id);
        if (account == null) return NotFound();
        account.Update(req.Code, req.Name, req.Type);
        await _db.SaveChangesAsync();
        return NoContent();
    }

    [HttpPut("accounts/{id:guid}/disable")]
    public async Task<IActionResult> DisableAccount(Guid id)
    {
        var account = await _db.Accounts.FirstOrDefaultAsync(a => a.CompanyId == CompanyId && a.Id == id);
        if (account == null) return NotFound();
        account.Disable();
        await _db.SaveChangesAsync();
        return NoContent();
    }

    [HttpPut("accounts/{id:guid}/enable")]
    public async Task<IActionResult> EnableAccount(Guid id)
    {
        var account = await _db.Accounts.FirstOrDefaultAsync(a => a.CompanyId == CompanyId && a.Id == id);
        if (account == null) return NotFound();
        account.Enable();
        await _db.SaveChangesAsync();
        return NoContent();
    }

    // ─── Expenses ───────────────────────────────────────────

    [HttpGet("expenses")]
    public async Task<IActionResult> GetExpenses()
    {
        var list = await _db.Expenses
            .Where(e => e.CompanyId == CompanyId).OrderByDescending(e => e.ExpenseDate)
            .Select(e => new ExpenseDto { Id = e.Id, Category = e.Category, Amount = e.Amount, Description = e.Description, ExpenseDate = e.ExpenseDate.ToString("o"), IsActive = e.IsActive })
            .ToListAsync();
        return Ok(list);
    }

    [HttpPost("expenses")]
    public async Task<IActionResult> CreateExpense([FromBody] CreateExpenseRequest req)
    {
        var date = string.IsNullOrEmpty(req.ExpenseDate) ? DateTime.UtcNow : DateTime.Parse(req.ExpenseDate).ToUniversalTime();
        var expense = new Expense(CompanyId, req.Category, req.Amount, req.Description, date);
        _db.Expenses.Add(expense);
        await _db.SaveChangesAsync();
        return Ok(new ExpenseDto { Id = expense.Id, Category = expense.Category, Amount = expense.Amount, Description = expense.Description, ExpenseDate = expense.ExpenseDate.ToString("o"), IsActive = true });
    }

    [HttpPut("expenses/{id:guid}")]
    public async Task<IActionResult> UpdateExpense(Guid id, [FromBody] UpdateExpenseRequest req)
    {
        var expense = await _db.Expenses.FirstOrDefaultAsync(e => e.CompanyId == CompanyId && e.Id == id);
        if (expense == null) return NotFound();
        expense.Update(req.Category, req.Amount, req.Description);
        await _db.SaveChangesAsync();
        return NoContent();
    }

    [HttpPut("expenses/{id:guid}/disable")]
    public async Task<IActionResult> DisableExpense(Guid id)
    {
        var expense = await _db.Expenses.FirstOrDefaultAsync(e => e.CompanyId == CompanyId && e.Id == id);
        if (expense == null) return NotFound();
        expense.Disable();
        await _db.SaveChangesAsync();
        return NoContent();
    }

    // ─── Journal Entries ────────────────────────────────────

    [HttpGet("journal")]
    public async Task<IActionResult> GetJournalEntries()
    {
        var list = await _db.JournalEntries
            .Where(j => j.CompanyId == CompanyId).OrderByDescending(j => j.EntryDate)
            .Select(j => new JournalEntryDto { Id = j.Id, Date = j.EntryDate.ToString("yyyy-MM-dd"), Reference = j.Reference, ReferenceType = j.ReferenceType, Description = j.Description, Debit = j.Debit, Credit = j.Credit, AccountId = j.AccountId })
            .ToListAsync();
        return Ok(list);
    }

    [HttpPost("journal")]
    public async Task<IActionResult> CreateJournalEntry([FromBody] CreateJournalEntryRequest req)
    {
        var date = DateTime.Parse(req.Date).ToUniversalTime();
        var entry = new JournalEntry(CompanyId, date, req.Reference, req.ReferenceType, req.Description, req.Debit, req.Credit, req.AccountId);
        _db.JournalEntries.Add(entry);
        await _db.SaveChangesAsync();
        return Ok(new JournalEntryDto { Id = entry.Id, Date = entry.EntryDate.ToString("yyyy-MM-dd"), Reference = entry.Reference, ReferenceType = entry.ReferenceType, Description = entry.Description, Debit = entry.Debit, Credit = entry.Credit, AccountId = entry.AccountId });
    }

    // ─── Reports ────────────────────────────────────────────

    [HttpGet("profit-loss")]
    public async Task<IActionResult> GetProfitLoss()
    {
        var cid = CompanyId;
        var revenue = await _db.Orders.Where(o => o.CompanyId == cid).SumAsync(o => o.TotalAmount);
        var cogs = await _db.Orders.Where(o => o.CompanyId == cid).SumAsync(o => o.SubTotal) * 0.4m;
        var expenses = await _db.Expenses.Where(e => e.CompanyId == cid && e.IsActive).SumAsync(e => e.Amount);
        var grossProfit = revenue - cogs;
        return Ok(new ProfitLossDto { Revenue = revenue, Cogs = cogs, Expenses = expenses, GrossProfit = grossProfit, NetProfit = grossProfit - expenses });
    }

    [HttpGet("tax-summary")]
    public async Task<IActionResult> GetTaxSummary()
    {
        var cid = CompanyId;
        var totalTax = await _db.Orders.Where(o => o.CompanyId == cid).SumAsync(o => o.TaxAmount);
        var totalTaxable = await _db.Orders.Where(o => o.CompanyId == cid).SumAsync(o => o.SubTotal);
        var rate = totalTaxable > 0 ? Math.Round(totalTax / totalTaxable * 100, 2) : 0;
        return Ok(new List<TaxSummaryDto> { new() { TaxType = "Sales Tax", Rate = rate, TaxableAmount = totalTaxable, TaxAmount = totalTax } });
    }

    [HttpGet("ledger")]
    public async Task<IActionResult> GetLedger([FromQuery] Guid? accountId)
    {
        var query = _db.JournalEntries.Where(j => j.CompanyId == CompanyId);
        if (accountId.HasValue) query = query.Where(j => j.AccountId == accountId.Value);
        var entries = await query.OrderBy(j => j.EntryDate).ToListAsync();
        decimal balance = 0;
        var result = entries.Select(j => { balance += j.Debit - j.Credit; return new LedgerEntryDto { Date = j.EntryDate.ToString("yyyy-MM-dd"), Reference = j.Reference, Description = j.Description, Debit = j.Debit, Credit = j.Credit, Balance = balance }; }).ToList();
        return Ok(result);
    }

    // ─── Trial Balance ──────────────────────────────────────

    [HttpGet("trial-balance")]
    public async Task<IActionResult> GetTrialBalance()
    {
        var cid = CompanyId;
        var accounts = await _db.Accounts.Where(a => a.CompanyId == cid).ToListAsync();
        var entries = await _db.JournalEntries.Where(j => j.CompanyId == cid).ToListAsync();

        var grouped = entries
            .Where(j => j.AccountId.HasValue)
            .GroupBy(j => j.AccountId!.Value)
            .ToDictionary(g => g.Key, g => new { Debit = g.Sum(j => j.Debit), Credit = g.Sum(j => j.Credit) });

        var result = accounts.Select(a =>
        {
            grouped.TryGetValue(a.Id, out var totals);
            return new TrialBalanceRowDto
            {
                AccountId = a.Id,
                Code = a.Code,
                Name = a.Name,
                Type = a.Type,
                Debit = totals?.Debit ?? 0,
                Credit = totals?.Credit ?? 0,
            };
        }).Where(r => r.Debit != 0 || r.Credit != 0).OrderBy(r => r.Code).ToList();

        return Ok(result);
    }
}
