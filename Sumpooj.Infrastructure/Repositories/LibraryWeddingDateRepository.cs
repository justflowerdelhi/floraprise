using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class LibraryWeddingDateRepository : ILibraryWeddingDateRepository
{
    private readonly SumpoojDbContext _db;

    public LibraryWeddingDateRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public Task<LibraryWeddingDate?> GetByIdAsync(Guid id)
        => _db.LibraryWeddingDates.FirstOrDefaultAsync(w => w.Id == id);

    public Task<LibraryWeddingDate?> GetBySlugAsync(string slug)
        => _db.LibraryWeddingDates.FirstOrDefaultAsync(w => w.Slug == slug.ToLower());

    public async Task<(List<LibraryWeddingDate> Items, int TotalCount)> SearchAsync(
        string? search,
        string? season,
        string? demandLevel,
        DateTime? from,
        DateTime? to,
        bool? isActive,
        int page,
        int pageSize)
    {
        var query = _db.LibraryWeddingDates.AsNoTracking().AsQueryable();

        if (isActive.HasValue)
            query = query.Where(w => w.IsActive == isActive.Value);

        if (!string.IsNullOrWhiteSpace(season))
            query = query.Where(w => w.Season != null && w.Season.ToLower() == season.Trim().ToLower());

        if (!string.IsNullOrWhiteSpace(demandLevel))
            query = query.Where(w => w.DemandLevel.ToLower() == demandLevel.Trim().ToLower());

        if (from.HasValue)
        {
            var fromUtc = from.Value.ToUniversalTime();
            query = query.Where(w => w.WeddingDate >= fromUtc);
        }

        if (to.HasValue)
        {
            var toUtc = to.Value.ToUniversalTime();
            query = query.Where(w => w.WeddingDate <= toUtc);
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim().ToLower();
            query = query.Where(w =>
                w.Title.ToLower().Contains(term) ||
                (w.Tithi != null && w.Tithi.ToLower().Contains(term)) ||
                (w.Nakshatra != null && w.Nakshatra.ToLower().Contains(term)) ||
                (w.Notes != null && w.Notes.ToLower().Contains(term)) ||
                (w.SearchKeywords != null && w.SearchKeywords.ToLower().Contains(term)));
        }

        var total = await query.CountAsync();

        var items = await query
            .OrderBy(w => w.SortOrder)
            .ThenBy(w => w.WeddingDate)
            .ThenBy(w => w.Title)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return (items, total);
    }

    public async Task AddAsync(LibraryWeddingDate weddingDate)
    {
        _db.LibraryWeddingDates.Add(weddingDate);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(LibraryWeddingDate weddingDate)
    {
        _db.LibraryWeddingDates.Update(weddingDate);
        await _db.SaveChangesAsync();
    }

    public async Task DeleteAsync(LibraryWeddingDate weddingDate)
    {
        _db.LibraryWeddingDates.Remove(weddingDate);
        await _db.SaveChangesAsync();
    }

    public Task<bool> SlugExistsAsync(string slug, Guid? excludeId = null)
    {
        var q = _db.LibraryWeddingDates.Where(w => w.Slug == slug.ToLower());
        if (excludeId.HasValue)
            q = q.Where(w => w.Id != excludeId.Value);
        return q.AnyAsync();
    }

    public Task<int> CountActiveAsync()
        => _db.LibraryWeddingDates.CountAsync(w => w.IsActive);
}
