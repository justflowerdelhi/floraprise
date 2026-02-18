using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class ProductBatchRepository : IProductBatchRepository
{
    private readonly SumpoojDbContext _db;

    public ProductBatchRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public Task<ProductBatch?> GetByIdAsync(Guid id)
        => _db.ProductBatches.FirstOrDefaultAsync(b => b.Id == id);

    public async Task AddAsync(ProductBatch batch)
    {
        _db.ProductBatches.Add(batch);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(ProductBatch batch)
    {
        _db.ProductBatches.Update(batch);
        await _db.SaveChangesAsync();
    }

    public async Task<(List<ProductBatch> Items, int TotalCount)> SearchAsync(
        string? query,
        Guid? productId,
        Guid? supplierId,
        Guid? locationId,
        bool? isActive,
        bool? expiringOnly,
        int? expiringWithinDays,
        int page,
        int pageSize)
    {
        var q = _db.ProductBatches.AsNoTracking().AsQueryable();

        if (!string.IsNullOrWhiteSpace(query))
        {
            query = query.ToLower();
            q = q.Where(b => b.BatchNumber.ToLower().Contains(query));
        }

        if (productId.HasValue)
        {
            q = q.Where(b => b.ProductId == productId.Value);
        }

        if (supplierId.HasValue)
        {
            q = q.Where(b => b.SupplierId == supplierId.Value);
        }

        if (locationId.HasValue)
        {
            q = q.Where(b => b.LocationId == locationId.Value);
        }

        if (isActive.HasValue)
        {
            q = q.Where(b => b.IsActive == isActive.Value);
        }

        if (expiringOnly == true && expiringWithinDays.HasValue)
        {
            var threshold = DateTime.UtcNow.AddDays(expiringWithinDays.Value).Date;
            q = q.Where(b => b.ExpiryDate.HasValue && b.ExpiryDate.Value.Date <= threshold);
        }

        var total = await q.CountAsync();

        var items = await q
            .OrderByDescending(b => b.ReceivedDate)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return (items, total);
    }

    public async Task<List<ProductBatch>> GetBatchesByProductIdAsync(Guid productId)
    {
        return await _db.ProductBatches
            .AsNoTracking()
            .Where(b => b.ProductId == productId && b.IsActive && b.QuantityRemaining > 0)
            .OrderBy(b => b.ExpiryDate ?? DateTime.MaxValue)
            .ThenBy(b => b.ReceivedDate)
            .ToListAsync();
    }

    public async Task<List<ProductBatch>> GetExpiringBatchesAsync(int daysThreshold)
    {
        var threshold = DateTime.UtcNow.AddDays(daysThreshold).Date;
        var today = DateTime.UtcNow.Date;

        return await _db.ProductBatches
            .AsNoTracking()
            .Where(b => b.IsActive && 
                        b.QuantityRemaining > 0 && 
                        b.ExpiryDate.HasValue && 
                        b.ExpiryDate.Value.Date <= threshold &&
                        b.ExpiryDate.Value.Date >= today)
            .OrderBy(b => b.ExpiryDate)
            .ToListAsync();
    }

    public async Task<List<ProductBatch>> GetExpiredBatchesAsync()
    {
        var today = DateTime.UtcNow.Date;

        return await _db.ProductBatches
            .AsNoTracking()
            .Where(b => b.IsActive && 
                        b.QuantityRemaining > 0 && 
                        b.ExpiryDate.HasValue && 
                        b.ExpiryDate.Value.Date < today)
            .OrderBy(b => b.ExpiryDate)
            .ToListAsync();
    }

    public async Task<string> GenerateBatchNumberAsync(Guid productId)
    {
        var today = DateTime.UtcNow;
        var datePrefix = today.ToString("yyyyMMdd");
        
        // Count existing batches for this product today
        var count = await _db.ProductBatches
            .CountAsync(b => b.ProductId == productId && 
                            b.BatchNumber.StartsWith($"BT-{datePrefix}"));

        return $"BT-{datePrefix}-{(count + 1):D3}";
    }
}
