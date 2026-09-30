using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class LibraryCardRepository : ILibraryCardRepository
{
    private readonly SumpoojDbContext _db;

    public LibraryCardRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public Task<LibraryCardTemplate?> GetByIdAsync(Guid id)
        => _db.LibraryCardTemplates
            .Include(c => c.Category)
            .FirstOrDefaultAsync(c => c.Id == id);

    public Task<LibraryCardTemplate?> GetBySlugAsync(string slug)
        => _db.LibraryCardTemplates
            .Include(c => c.Category)
            .FirstOrDefaultAsync(c => c.Slug == slug.ToLower());

    public async Task<(List<LibraryCardTemplate> Items, int TotalCount)> SearchAsync(
        string? search,
        Guid? categoryId,
        string? occasion,
        string? tone,
        string? language,
        bool? isActive,
        int page,
        int pageSize)
    {
        var query = _db.LibraryCardTemplates
            .AsNoTracking()
            .Include(c => c.Category)
            .AsQueryable();

        if (isActive.HasValue)
        {
            query = query.Where(c => c.IsActive == isActive.Value);
        }

        if (categoryId.HasValue)
        {
            query = query.Where(c => c.CategoryId == categoryId.Value);
        }

        if (!string.IsNullOrWhiteSpace(occasion))
        {
            var occ = occasion.Trim().ToLower();
            query = query.Where(c => c.Occasion != null && c.Occasion.ToLower() == occ);
        }

        if (!string.IsNullOrWhiteSpace(tone))
        {
            var t = tone.Trim().ToLower();
            query = query.Where(c => c.Tone != null && c.Tone.ToLower() == t);
        }

        if (!string.IsNullOrWhiteSpace(language))
        {
            var lang = language.Trim().ToLower();
            query = query.Where(c => c.Language.ToLower() == lang);
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim().ToLower();
            query = query.Where(c =>
                c.Title.ToLower().Contains(term) ||
                c.Slug.ToLower().Contains(term) ||
                c.Content.ToLower().Contains(term) ||
                (c.Occasion != null && c.Occasion.ToLower().Contains(term)) ||
                (c.Tone != null && c.Tone.ToLower().Contains(term)) ||
                (c.SearchKeywords != null && c.SearchKeywords.ToLower().Contains(term)));
        }

        var total = await query.CountAsync();
        var items = await query
            .OrderBy(c => c.SortOrder)
            .ThenBy(c => c.Title)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return (items, total);
    }

    public async Task<List<(string Occasion, int Count)>> GetOccasionsSummaryAsync(string? language = null)
    {
        var query = _db.LibraryCardTemplates
            .AsNoTracking()
            .Where(c => c.IsActive && !string.IsNullOrEmpty(c.Occasion));

        if (!string.IsNullOrWhiteSpace(language))
        {
            var lang = language.Trim().ToLower();
            query = query.Where(c => c.Language.ToLower() == lang);
        }

        var results = await query
            .GroupBy(c => c.Occasion!)
            .Select(g => new { Occasion = g.Key, Count = g.Count() })
            .OrderByDescending(g => g.Count)
            .ThenBy(g => g.Occasion)
            .ToListAsync();

        return results.Select(r => (r.Occasion, r.Count)).ToList();
    }

    public async Task AddAsync(LibraryCardTemplate card)
    {
        _db.LibraryCardTemplates.Add(card);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(LibraryCardTemplate card)
    {
        _db.LibraryCardTemplates.Update(card);
        await _db.SaveChangesAsync();
    }

    public async Task DeleteAsync(LibraryCardTemplate card)
    {
        _db.LibraryCardTemplates.Remove(card);
        await _db.SaveChangesAsync();
    }

    public async Task<bool> SlugExistsAsync(string slug, Guid? excludeId = null)
    {
        var q = _db.LibraryCardTemplates.Where(c => c.Slug == slug.ToLower());
        if (excludeId.HasValue)
            q = q.Where(c => c.Id != excludeId.Value);
        return await q.AnyAsync();
    }
}
