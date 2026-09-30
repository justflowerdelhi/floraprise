using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class LibraryCategoryRepository : ILibraryCategoryRepository
{
    private readonly SumpoojDbContext _db;

    public LibraryCategoryRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public Task<LibraryCategory?> GetByIdAsync(Guid id)
        => _db.LibraryCategories
            .Include(c => c.ParentCategory)
            .Include(c => c.SubCategories)
            .FirstOrDefaultAsync(c => c.Id == id);

    public Task<LibraryCategory?> GetBySlugAsync(string slug)
        => _db.LibraryCategories
            .Include(c => c.ParentCategory)
            .Include(c => c.SubCategories)
            .FirstOrDefaultAsync(c => c.Slug == slug.ToLower());

    public async Task<(List<LibraryCategory> Items, int TotalCount)> SearchAsync(
        string? search,
        bool? isActive,
        Guid? parentCategoryId,
        int page,
        int pageSize)
    {
        var query = _db.LibraryCategories
            .AsNoTracking()
            .Include(c => c.ParentCategory)
            .AsQueryable();

        if (isActive.HasValue)
        {
            query = query.Where(c => c.IsActive == isActive.Value);
        }

        if (parentCategoryId.HasValue)
        {
            query = query.Where(c => c.ParentCategoryId == parentCategoryId.Value);
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim().ToLower();
            query = query.Where(c => c.Name.ToLower().Contains(term) || c.Slug.ToLower().Contains(term));
        }

        var total = await query.CountAsync();
        var items = await query
            .OrderBy(c => c.SortOrder)
            .ThenBy(c => c.Name)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return (items, total);
    }

    public Task<List<LibraryCategory>> GetAllActiveAsync()
        => _db.LibraryCategories
            .AsNoTracking()
            .Where(c => c.IsActive)
            .OrderBy(c => c.SortOrder)
            .ThenBy(c => c.Name)
            .ToListAsync();

    public Task<List<LibraryCategory>> GetAllAsync(bool includeInactive = false)
    {
        var query = _db.LibraryCategories.AsNoTracking().AsQueryable();
        if (!includeInactive)
            query = query.Where(c => c.IsActive);
        return query.OrderBy(c => c.SortOrder).ThenBy(c => c.Name).ToListAsync();
    }

    public Task<int> GetProductCountAsync(Guid categoryId)
        => _db.LibraryProducts.CountAsync(p => p.CategoryId == categoryId && p.IsActive);

    public async Task AddAsync(LibraryCategory category)
    {
        _db.LibraryCategories.Add(category);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(LibraryCategory category)
    {
        _db.LibraryCategories.Update(category);
        await _db.SaveChangesAsync();
    }

    public async Task DeleteAsync(LibraryCategory category)
    {
        _db.LibraryCategories.Remove(category);
        await _db.SaveChangesAsync();
    }

    public async Task<bool> SlugExistsAsync(string slug, Guid? excludeId = null)
    {
        var q = _db.LibraryCategories.Where(c => c.Slug == slug.ToLower());
        if (excludeId.HasValue)
            q = q.Where(c => c.Id != excludeId.Value);
        return await q.AnyAsync();
    }
}

