using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class ProductCategoryRepository : IProductCategoryRepository
{
    private readonly SumpoojDbContext _db;

    public ProductCategoryRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public Task<ProductCategoryEntity?> GetByIdAsync(Guid id)
        => _db.ProductCategories.FirstOrDefaultAsync(c => c.Id == id);

    public async Task<List<ProductCategoryEntity>> GetAllAsync(bool includeInactive = false)
    {
        var q = _db.ProductCategories.AsNoTracking().AsQueryable();

        if (!includeInactive)
            q = q.Where(c => c.IsActive);

        return await q.OrderBy(c => c.Name).ToListAsync();
    }

    public async Task AddAsync(ProductCategoryEntity category)
    {
        _db.ProductCategories.Add(category);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(ProductCategoryEntity category)
    {
        _db.ProductCategories.Update(category);
        await _db.SaveChangesAsync();
    }

    public async Task<bool> NameExistsAsync(string name, Guid? excludeId = null)
    {
        var q = _db.ProductCategories.Where(c => c.Name.ToLower() == name.ToLower());

        if (excludeId.HasValue)
            q = q.Where(c => c.Id != excludeId.Value);

        return await q.AnyAsync();
    }

    public async Task<int> GetProductCountAsync(Guid categoryId)
    {
        return await _db.Products.CountAsync(p => p.CategoryId == categoryId);
    }
}
