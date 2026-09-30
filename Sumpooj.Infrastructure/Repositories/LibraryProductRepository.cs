using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class LibraryProductRepository : ILibraryProductRepository
{
    private readonly SumpoojDbContext _db;

    public LibraryProductRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public Task<LibraryProduct?> GetByIdAsync(Guid id)
        => _db.LibraryProducts
            .Include(p => p.Category)
            .FirstOrDefaultAsync(p => p.Id == id);

    public Task<LibraryProduct?> GetBySlugAsync(string slug)
        => _db.LibraryProducts
            .Include(p => p.Category)
            .FirstOrDefaultAsync(p => p.Slug == slug.ToLower());

    public async Task<(List<LibraryProduct> Items, int TotalCount)> SearchAsync(
        string? search,
        Guid? categoryId,
        ProductType? productType,
        bool? isActive,
        int page,
        int pageSize)
    {
        var query = _db.LibraryProducts
            .AsNoTracking()
            .Include(p => p.Category)
            .AsQueryable();

        if (isActive.HasValue)
        {
            query = query.Where(p => p.IsActive == isActive.Value);
        }

        if (categoryId.HasValue)
        {
            query = query.Where(p => p.CategoryId == categoryId.Value);
        }

        if (productType.HasValue)
        {
            query = query.Where(p => p.ProductType == productType.Value);
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim().ToLower();
            query = query.Where(p =>
                p.Name.ToLower().Contains(term) ||
                p.Slug.ToLower().Contains(term) ||
                (p.StandardSku != null && p.StandardSku.ToLower().Contains(term)) ||
                (p.SearchKeywords != null && p.SearchKeywords.ToLower().Contains(term)) ||
                (p.Description != null && p.Description.ToLower().Contains(term)));
        }

        var total = await query.CountAsync();
        var items = await query
            .OrderBy(p => p.SortOrder)
            .ThenBy(p => p.Name)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return (items, total);
    }

    public async Task AddAsync(LibraryProduct product)
    {
        _db.LibraryProducts.Add(product);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(LibraryProduct product)
    {
        _db.LibraryProducts.Update(product);
        await _db.SaveChangesAsync();
    }

    public async Task DeleteAsync(LibraryProduct product)
    {
        _db.LibraryProducts.Remove(product);
        await _db.SaveChangesAsync();
    }

    public async Task<bool> SlugExistsAsync(string slug, Guid? excludeId = null)
    {
        var q = _db.LibraryProducts.Where(p => p.Slug == slug.ToLower());
        if (excludeId.HasValue)
            q = q.Where(p => p.Id != excludeId.Value);
        return await q.AnyAsync();
    }
}

