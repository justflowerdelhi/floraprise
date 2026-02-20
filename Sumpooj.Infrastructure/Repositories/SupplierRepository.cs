using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class SupplierRepository : ISupplierRepository
{
    private readonly SumpoojDbContext _db;

    public SupplierRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public Task<Supplier?> GetByIdAsync(Guid id)
        => _db.Suppliers.FirstOrDefaultAsync(s => s.Id == id);

    public async Task AddAsync(Supplier supplier)
    {
        _db.Suppliers.Add(supplier);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(Supplier supplier)
    {
        _db.Suppliers.Update(supplier);
        await _db.SaveChangesAsync();
    }

    public async Task<(List<Supplier> Items, int TotalCount)> SearchAsync(
        string? query,
        bool? isActive,
        int page,
        int pageSize)
    {
        var q = _db.Suppliers.AsNoTracking().AsQueryable();

        if (!string.IsNullOrWhiteSpace(query))
        {
            query = query.ToLower();
            q = q.Where(s =>
                s.Name.ToLower().Contains(query) ||
                (s.ContactPerson != null && s.ContactPerson.ToLower().Contains(query)) ||
                (s.Email != null && s.Email.ToLower().Contains(query)));
        }

        if (isActive.HasValue)
        {
            q = q.Where(s => s.IsActive == isActive.Value);
        }

        var total = await q.CountAsync();

        var items = await q
            .OrderBy(s => s.Name)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return (items, total);
    }

    public async Task<List<Supplier>> GetAllActiveAsync()
    {
        return await _db.Suppliers
            .AsNoTracking()
            .Where(s => s.IsActive)
            .OrderBy(s => s.Name)
            .ToListAsync();
    }
}
