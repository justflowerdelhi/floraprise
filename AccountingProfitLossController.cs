using Microsoft.AspNetCore.Mvc;
using System;
using System.Linq;
using System.Threading.Tasks;
using FlorapriseERP.Accounting;

namespace FlorapriseERP.Controllers
{
    [ApiController]
    [Route("accounting/profit-loss")]
    public class AccountingProfitLossController : ControllerBase
    {
        private readonly AccountingDbContext _db;
        public AccountingProfitLossController(AccountingDbContext db)
        {
            _db = db;
        }

        [HttpGet]
        public async Task<IActionResult> GetProfitLoss([FromQuery] DateTime startDate, [FromQuery] DateTime endDate, [FromQuery] Guid? locationId)
        {
            // Filter JournalLines by date and location
            var journalLines = _db.JournalLines
                .Where(jl => jl.JournalEntry.TransactionDate >= startDate && jl.JournalEntry.TransactionDate <= endDate);
            if (locationId.HasValue)
            {
                journalLines = journalLines.Where(jl => jl.JournalEntry.LocationId == locationId);
            }

            // Revenue: credits for Income accounts
            var revenueLines = journalLines.Where(jl => jl.Account.Type == AccountType.Income);
            var revenueTotal = revenueLines.Sum(jl => jl.Credit);
            var revenueBreakdown = revenueLines
                .GroupBy(jl => jl.Account.Name)
                .Select(g => new { Account = g.Key, Amount = g.Sum(x => x.Credit) })
                .ToList();

            // COGS: debits for COGS accounts
            var cogsLines = journalLines.Where(jl => jl.Account.Type == AccountType.COGS);
            var cogsTotal = cogsLines.Sum(jl => jl.Debit);

            // Expenses: debits for Expense accounts
            var expenseLines = journalLines.Where(jl => jl.Account.Type == AccountType.Expense);
            var expenseTotal = expenseLines.Sum(jl => jl.Debit);
            var expenseBreakdown = expenseLines
                .GroupBy(jl => jl.Account.Name)
                .Select(g => new { Account = g.Key, Amount = g.Sum(x => x.Debit) })
                .ToList();

            var grossProfit = revenueTotal - cogsTotal;
            var netProfit = grossProfit - expenseTotal;

            var result = new
            {
                RevenueBreakdown = revenueBreakdown,
                COGSTotal = cogsTotal,
                ExpenseBreakdown = expenseBreakdown,
                GrossProfit = grossProfit,
                NetProfit = netProfit
            };

            return Ok(result);
        }
    }
}
