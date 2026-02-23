using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class SalesOrderRepository : ISalesOrderRepository
{
    private readonly SumpoojDbContext _db;

    public SalesOrderRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public Task<SalesOrder?> GetByIdAsync(Guid id)
        => _db.SalesOrders
            .Include(o => o.Items)
            .FirstOrDefaultAsync(o => o.Id == id);

    public async Task<IReadOnlyList<SalesOrder>> GetAllAsync()
        => await _db.SalesOrders
            .Include(o => o.Items)
            .AsNoTracking()
            .ToListAsync();

    public async Task AddAsync(SalesOrder order)
    {
        _db.SalesOrders.Add(order);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(SalesOrder order)
    {
        _db.SalesOrders.Update(order);
        await _db.SaveChangesAsync();
    }
}
