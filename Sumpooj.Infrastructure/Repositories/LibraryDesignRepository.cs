using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class LibraryDesignRepository : ILibraryDesignRepository
{
    private readonly SumpoojDbContext _db;

    public LibraryDesignRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public Task<LibraryDesign?> GetByIdAsync(Guid id)
        => _db.LibraryDesigns
            .Include(d => d.Category)
            .Include(d => d.Recipe)
            .FirstOrDefaultAsync(d => d.Id == id);

    public Task<LibraryDesign?> GetBySlugAsync(string slug)
        => _db.LibraryDesigns
            .Include(d => d.Category)
            .Include(d => d.Recipe)
            .FirstOrDefaultAsync(d => d.Slug == slug.ToLower());

    public async Task<(List<LibraryDesign> Items, int TotalCount)> SearchAsync(
        string? search,
        Guid? categoryId,
        string? occasion,
        string? style,
        bool? isActive,
        int page,
        int pageSize)
    {
        var query = _db.LibraryDesigns
            .AsNoTracking()
            .Include(d => d.Category)
            .Include(d => d.Recipe)
            .AsQueryable();

        if (isActive.HasValue)
        {
            query = query.Where(d => d.IsActive == isActive.Value);
        }

        if (categoryId.HasValue)
        {
            query = query.Where(d => d.CategoryId == categoryId.Value);
        }

        if (!string.IsNullOrWhiteSpace(occasion))
        {
            var occ = occasion.Trim().ToLower();
            query = query.Where(d => d.Occasion != null && d.Occasion.ToLower() == occ);
        }

        if (!string.IsNullOrWhiteSpace(style))
        {
            var sty = style.Trim().ToLower();
            query = query.Where(d => d.Style != null && d.Style.ToLower() == sty);
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim().ToLower();
            query = query.Where(d =>
                d.Title.ToLower().Contains(term) ||
                d.Slug.ToLower().Contains(term) ||
                (d.Description != null && d.Description.ToLower().Contains(term)) ||
                (d.FlowerTypes != null && d.FlowerTypes.ToLower().Contains(term)) ||
                (d.ColorPalette != null && d.ColorPalette.ToLower().Contains(term)) ||
                (d.Occasion != null && d.Occasion.ToLower().Contains(term)) ||
                (d.Style != null && d.Style.ToLower().Contains(term)) ||
                (d.SearchKeywords != null && d.SearchKeywords.ToLower().Contains(term)));
        }

        var total = await query.CountAsync();
        var items = await query
            .OrderBy(d => d.SortOrder)
            .ThenBy(d => d.Title)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return (items, total);
    }

    public async Task AddAsync(LibraryDesign design)
    {
        _db.LibraryDesigns.Add(design);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(LibraryDesign design)
    {
        _db.LibraryDesigns.Update(design);
        await _db.SaveChangesAsync();
    }

    public async Task DeleteAsync(LibraryDesign design)
    {
        _db.LibraryDesigns.Remove(design);
        await _db.SaveChangesAsync();
    }

    public async Task<bool> SlugExistsAsync(string slug, Guid? excludeId = null)
    {
        var q = _db.LibraryDesigns.Where(d => d.Slug == slug.ToLower());
        if (excludeId.HasValue)
            q = q.Where(d => d.Id != excludeId.Value);
        return await q.AnyAsync();
    }
}
