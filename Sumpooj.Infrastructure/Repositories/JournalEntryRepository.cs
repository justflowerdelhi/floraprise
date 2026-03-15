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
}
