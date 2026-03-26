using Sumpooj.Application.Accounting;
using Sumpooj.Application.Interfaces;

namespace Sumpooj.Application.UseCases;

public class AccountingService
{
	private readonly IJournalEntryRepository _journalEntryRepository;
	private readonly IAccountRepository _accountRepository;

	public AccountingService(IJournalEntryRepository journalEntryRepository, IAccountRepository accountRepository)
	{
		_journalEntryRepository = journalEntryRepository;
		_accountRepository = accountRepository;
	}

	public async Task<List<TrialBalanceRowDto>> GetTrialBalanceAsync(Guid companyId)
	{
		var entries = await _journalEntryRepository.GetAllAsync(companyId);
		var accounts = await _accountRepository.GetAllAsync(companyId);

		var accountsById = accounts.ToDictionary(a => a.Id);

		var result = entries
			.Where(e => e.AccountId != null)
			.GroupBy(e => e.AccountId)
			.Select(g =>
			{
				var accountId = g.Key!.Value;
				accountsById.TryGetValue(accountId, out var account);

				return new TrialBalanceRowDto
				{
					AccountId = accountId,
					Code = account?.Code ?? string.Empty,
					Name = account?.Name ?? "Unknown",
					Type = account?.Type ?? string.Empty,
					Debit = g.Sum(x => x.Debit),
					Credit = g.Sum(x => x.Credit),
				};
			})
			.Where(r => r.Debit != 0 || r.Credit != 0)
			.OrderBy(r => r.Code)
			.ToList();

		return result;
	}

	public async Task<BalanceSheetDto> GetBalanceSheetAsync(Guid companyId)
	{
		var trialBalance = await GetTrialBalanceAsync(companyId);

		var assets = new List<BalanceSheetRowDto>();
		var liabilities = new List<BalanceSheetRowDto>();
		var equity = new List<BalanceSheetRowDto>();

		foreach (var account in trialBalance)
		{
			var accountType = account.Type.Trim();
			var amount = account.Debit - account.Credit;

			var row = new BalanceSheetRowDto
			{
				AccountId = account.AccountId,
				Code = account.Code,
				Name = account.Name,
				Type = account.Type,
				Amount = amount,
			};

			if (accountType.Equals("Asset", StringComparison.OrdinalIgnoreCase))
				assets.Add(row);
			else if (accountType.Equals("Liability", StringComparison.OrdinalIgnoreCase))
				liabilities.Add(row);
			else if (accountType.Equals("Equity", StringComparison.OrdinalIgnoreCase))
				equity.Add(row);
		}

		// Add profit into equity as retained earnings.
		var netProfit = await CalculateNetProfitAsync(companyId);

		if (netProfit != 0)
		{
			equity.Add(new BalanceSheetRowDto
			{
				AccountId = Guid.Empty,
				Code = "9999",
				Name = "Retained Earnings (Profit)",
				Type = "Equity",
				Amount = netProfit
			});
		}

		return new BalanceSheetDto
		{
			Assets = assets.OrderBy(x => x.Code).ToList(),
			Liabilities = liabilities.OrderBy(x => x.Code).ToList(),
			Equity = equity.OrderBy(x => x.Code).ToList(),
			TotalAssets = assets.Sum(x => x.Amount),
			TotalLiabilities = liabilities.Sum(x => x.Amount),
			TotalEquity = equity.Sum(x => x.Amount),
		};
	}

	private async Task<decimal> CalculateNetProfitAsync(Guid companyId)
	{
		var entries = await _journalEntryRepository.GetAllAsync(companyId);
		var accounts = await _accountRepository.GetAllAsync(companyId);

		var accountMap = accounts.ToDictionary(a => a.Id);

		decimal revenue = 0;
		decimal expenses = 0;

		foreach (var entry in entries.Where(e => e.AccountId != null))
		{
			var account = accountMap[entry.AccountId!.Value];

			if (account.Type.Equals("Income", StringComparison.OrdinalIgnoreCase))
			{
				revenue += (entry.Credit - entry.Debit);
			}
			else if (account.Type.Equals("Expense", StringComparison.OrdinalIgnoreCase))
			{
				expenses += (entry.Debit - entry.Credit);
			}
		}

		return revenue - expenses;
	}
}
