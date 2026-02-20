using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class PurchaseOrderRepository : IPurchaseOrderRepository
{
    private readonly SumpoojDbContext _db;

    public PurchaseOrderRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public Task<PurchaseOrder?> GetByIdAsync(Guid id)
        => _db.PurchaseOrders.FirstOrDefaultAsync(po => po.Id == id);

    public Task<PurchaseOrder?> GetByIdWithItemsAsync(Guid id)
        => _db.PurchaseOrders
            .Include(po => po.Items)
            .FirstOrDefaultAsync(po => po.Id == id);

    public async Task AddAsync(PurchaseOrder purchaseOrder)
    {
        _db.PurchaseOrders.Add(purchaseOrder);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(PurchaseOrder purchaseOrder)
    {
        _db.PurchaseOrders.Update(purchaseOrder);
        await _db.SaveChangesAsync();
    }

    public async Task<(List<PurchaseOrder> Items, int TotalCount)> SearchAsync(
        string? query,
        Guid? supplierId,
        string? status,
        DateTime? fromDate,
        DateTime? toDate,
        int page,
        int pageSize)
    {
        var q = _db.PurchaseOrders
            .Include(po => po.Items)
            .AsNoTracking()
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(query))
        {
            query = query.ToLower();
            q = q.Where(po => po.OrderNumber.ToLower().Contains(query));
        }

        if (supplierId.HasValue)
        {
            q = q.Where(po => po.SupplierId == supplierId.Value);
        }

        if (!string.IsNullOrWhiteSpace(status))
        {
            if (Enum.TryParse<PurchaseOrderStatus>(status, true, out var ps))
            {
                q = q.Where(po => po.Status == ps);
            }
        }

        if (fromDate.HasValue)
        {
            q = q.Where(po => po.OrderDate >= fromDate.Value);
        }

        if (toDate.HasValue)
        {
            q = q.Where(po => po.OrderDate <= toDate.Value);
        }

        var total = await q.CountAsync();

        var items = await q
            .OrderByDescending(po => po.OrderDate)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return (items, total);
    }

    public async Task<List<PurchaseOrder>> GetPendingOrdersAsync()
    {
        return await _db.PurchaseOrders
            .Include(po => po.Items)
            .AsNoTracking()
            .Where(po => po.IsActive && 
                        (po.Status == PurchaseOrderStatus.Draft || 
                         po.Status == PurchaseOrderStatus.Submitted ||
                         po.Status == PurchaseOrderStatus.Approved))
            .OrderBy(po => po.ExpectedDeliveryDate)
            .ToListAsync();
    }
}
