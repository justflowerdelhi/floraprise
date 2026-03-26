using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IJournalEntryRepository
{
    Task AddAsync(JournalEntry entry);
    Task AddRangeAsync(IEnumerable<JournalEntry> entries);
    Task<List<JournalEntry>> GetAllAsync(Guid companyId);
    Task<List<Account>> GetAccountsAsync(Guid companyId);
    /// <summary>
    /// Get an account by code for a company. Creates it if it doesn't exist.
    /// </summary>
    Task<Guid> GetOrCreateAccountIdAsync(Guid companyId, string code, string name, string type);
}
