using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class ProductRepository : IProductRepository
{
    private readonly SumpoojDbContext _db;

    public ProductRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public Task<Product?> GetByIdAsync(Guid id)
        => _db.Products
            .Include(p => p.ProductCategoryRef)
            .Include(p => p.TaxRule)
            .FirstOrDefaultAsync(p => p.Id == id);

    public Task<Product?> GetBySkuAsync(string sku)
        => _db.Products
            .Include(p => p.ProductCategoryRef)
            .Include(p => p.TaxRule)
            .FirstOrDefaultAsync(p => p.Sku == sku);

    public async Task AddAsync(Product product)
    {
        _db.Products.Add(product);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(Product product)
    {
        _db.Products.Update(product);
        await _db.SaveChangesAsync();
    }

    public async Task<(List<Product> Items, int TotalCount)> SearchAsync(
        string? query,
        string? productType,
        string? category,
        bool? isActive,
        bool? isPerishable,
        bool? lowStockOnly,
        int page,
        int pageSize)
    {
        var q = _db.Products.AsNoTracking()
            .Include(p => p.ProductCategoryRef)
            .Include(p => p.TaxRule)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(query))
        {
            query = query.ToLower();
            q = q.Where(p =>
                p.Name.ToLower().Contains(query) ||
                p.Sku.ToLower().Contains(query) ||
                (p.Description != null && p.Description.ToLower().Contains(query)));
        }

        if (!string.IsNullOrWhiteSpace(productType))
        {
            if (Enum.TryParse<ProductType>(productType, true, out var pt))
            {
                q = q.Where(p => p.ProductType == pt);
            }
        }

        if (!string.IsNullOrWhiteSpace(category))
        {
            if (Enum.TryParse<ProductCategory>(category, true, out var cat))
            {
                q = q.Where(p => p.Category == cat);
            }
        }

        if (isActive.HasValue)
        {
            q = q.Where(p => p.IsActive == isActive.Value);
        }

        if (isPerishable.HasValue)
        {
            q = q.Where(p => p.ProductCategoryRef != null && p.ProductCategoryRef.IsPerishable == isPerishable.Value);
        }

        if (lowStockOnly == true)
        {
            q = q.Where(p => p.StockQuantity <= p.MinimumStockLevel);
        }

        var total = await q.CountAsync();

        var items = await q
            .OrderBy(p => p.Name)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return (items, total);
    }

    public async Task<List<Product>> GetLowStockProductsAsync()
    {
        return await _db.Products
            .AsNoTracking()
            .Where(p => p.IsActive && p.TrackInventory && p.StockQuantity <= p.MinimumStockLevel)
            .OrderBy(p => p.StockQuantity)
            .ToListAsync();
    }

    public async Task<List<Product>> GetProductsNeedingReorderAsync()
    {
        return await _db.Products
            .AsNoTracking()
            .Where(p => p.IsActive && p.TrackInventory && p.StockQuantity <= p.ReorderLevel)
            .OrderBy(p => p.StockQuantity)
            .ToListAsync();
    }

    public async Task<bool> SkuExistsAsync(string sku, Guid? excludeProductId = null)
    {
        var query = _db.Products.Where(p => p.Sku == sku);

        if (excludeProductId.HasValue)
        {
            query = query.Where(p => p.Id != excludeProductId.Value);
        }

        return await query.AnyAsync();
    }

    public async Task<int> GetLowStockCountAsync(Guid companyId)
    {
        return await _db.Products
            .CountAsync(p => p.CompanyId == companyId && 
                            p.IsActive && 
                            p.TrackInventory && 
                            p.StockQuantity <= p.MinimumStockLevel);
    }

    public async Task<List<Product>> GetProductsWithoutCategoryAsync()
    {
        return await _db.Products
            .IgnoreQueryFilters()
            .Where(p => p.CategoryId == null)
            .ToListAsync();
    }
}
