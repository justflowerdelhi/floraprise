using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class InventoryLedgerRepository : IInventoryLedgerRepository
{
    private readonly SumpoojDbContext _db;

    public InventoryLedgerRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public async Task AddAsync(InventoryLedger entry)
    {
        _db.InventoryLedgers.Add(entry);
        await _db.SaveChangesAsync();
    }

    public async Task<List<InventoryLedger>> GetByProductAsync(Guid companyId, Guid productId)
    {
        return await _db.InventoryLedgers
            .AsNoTracking()
            .Where(l => l.CompanyId == companyId && l.ProductId == productId)
            .OrderByDescending(l => l.CreatedAtUtc)
            .ToListAsync();
    }
}