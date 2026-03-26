using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class JournalEntryRepository : IJournalEntryRepository
{
    private readonly SumpoojDbContext _db;

    public JournalEntryRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public async Task AddAsync(JournalEntry entry)
    {
        _db.JournalEntries.Add(entry);
        await _db.SaveChangesAsync();
    }

    public async Task AddRangeAsync(IEnumerable<JournalEntry> entries)
    {
        _db.JournalEntries.AddRange(entries);
        await _db.SaveChangesAsync();
    }

    public async Task<List<JournalEntry>> GetAllAsync(Guid companyId)
    {
        return await _db.JournalEntries
            .AsNoTracking()
            .Where(j => j.CompanyId == companyId)
            .ToListAsync();
    }

    public async Task<List<Account>> GetAccountsAsync(Guid companyId)
    {
        return await _db.Accounts
            .AsNoTracking()
            .Where(a => a.CompanyId == companyId)
            .ToListAsync();
    }

    public async Task<Guid> GetOrCreateAccountIdAsync(Guid companyId, string code, string name, string type)
    {
        var account = await _db.Accounts
            .FirstOrDefaultAsync(a => a.CompanyId == companyId && a.Code == code);

        if (account != null)
            return account.Id;

        account = new Account(companyId, code, name, type);
        _db.Accounts.Add(account);
        await _db.SaveChangesAsync();
        return account.Id;
    }
}
