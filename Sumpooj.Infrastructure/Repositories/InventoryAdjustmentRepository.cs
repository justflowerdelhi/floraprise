using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class InventoryAdjustmentRepository : IInventoryAdjustmentRepository
{
    private readonly SumpoojDbContext _db;

    public InventoryAdjustmentRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public Task<InventoryAdjustment?> GetByIdAsync(Guid id)
        => _db.InventoryAdjustments.FirstOrDefaultAsync(a => a.Id == id);

    public async Task AddAsync(InventoryAdjustment adjustment)
    {
        _db.InventoryAdjustments.Add(adjustment);
        await _db.SaveChangesAsync();
    }

    public async Task ApplyStockChangeAsync(
        Product product,
        InventoryAdjustment adjustment,
        InventoryLedger ledger)
    {
        var executionStrategy = _db.Database.CreateExecutionStrategy();
        await executionStrategy.ExecuteAsync(async () =>
        {
            await using var transaction = await _db.Database.BeginTransactionAsync();
            _db.Products.Update(product);
            _db.InventoryAdjustments.Add(adjustment);
            _db.InventoryLedgers.Add(ledger);
            await _db.SaveChangesAsync();
            await transaction.CommitAsync();
        });
    }

    public async Task<(List<InventoryAdjustment> Items, int TotalCount)> SearchAsync(
        Guid? productId,
        Guid? batchId,
        string? adjustmentType,
        DateTime? fromDate,
        DateTime? toDate,
        int page,
        int pageSize)
    {
        var q = _db.InventoryAdjustments.AsNoTracking().AsQueryable();

        if (productId.HasValue)
        {
            q = q.Where(a => a.ProductId == productId.Value);
        }

        if (batchId.HasValue)
        {
            q = q.Where(a => a.BatchId == batchId.Value);
        }

        if (!string.IsNullOrWhiteSpace(adjustmentType))
        {
            if (Enum.TryParse<AdjustmentType>(adjustmentType, true, out var at))
            {
                q = q.Where(a => a.AdjustmentType == at);
            }
        }

        if (fromDate.HasValue)
        {
            q = q.Where(a => a.AdjustmentDate >= fromDate.Value);
        }

        if (toDate.HasValue)
        {
            q = q.Where(a => a.AdjustmentDate <= toDate.Value);
        }

        var total = await q.CountAsync();

        var items = await q
            .OrderByDescending(a => a.AdjustmentDate)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return (items, total);
    }

    public async Task<List<InventoryAdjustment>> GetRecentAdjustmentsAsync(int count)
    {
        return await _db.InventoryAdjustments
            .AsNoTracking()
            .OrderByDescending(a => a.AdjustmentDate)
            .Take(count)
            .ToListAsync();
    }
}
