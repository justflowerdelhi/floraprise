using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class SalesOrderRepository : ISalesOrderRepository
{
    private readonly SumpoojDbContext _db;
    private readonly ITenantContext _tenantContext;

    public SalesOrderRepository(SumpoojDbContext db, ITenantContext tenantContext)
    {
        _db = db;
        _tenantContext = tenantContext;
    }

    private Guid CompanyId => _tenantContext.CompanyId
        ?? throw new UnauthorizedAccessException("Company context required");

    public Task<SalesOrder?> GetByIdAsync(Guid id)
        => _db.SalesOrders
            .Include(o => o.Items)
            .FirstOrDefaultAsync(o => o.Id == id && o.CompanyId == CompanyId);

    public async Task<IReadOnlyList<SalesOrder>> GetAllAsync()
        => await _db.SalesOrders
            .Include(o => o.Items)
            .Where(o => o.CompanyId == CompanyId)
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
