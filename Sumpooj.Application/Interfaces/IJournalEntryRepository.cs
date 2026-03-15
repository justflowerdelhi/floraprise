using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IJournalEntryRepository
{
    Task AddAsync(JournalEntry entry);
    Task AddRangeAsync(IEnumerable<JournalEntry> entries);
}
