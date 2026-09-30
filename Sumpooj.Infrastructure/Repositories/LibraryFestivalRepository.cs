using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class LibraryFestivalRepository : ILibraryFestivalRepository
{
    private readonly SumpoojDbContext _db;

    public LibraryFestivalRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public Task<LibraryFestival?> GetByIdAsync(Guid id)
        => _db.LibraryFestivals.FirstOrDefaultAsync(f => f.Id == id);

    public Task<LibraryFestival?> GetBySlugAsync(string slug)
        => _db.LibraryFestivals.FirstOrDefaultAsync(f => f.Slug == slug.ToLower());

    public async Task<(List<LibraryFestival> Items, int TotalCount)> SearchAsync(
        string? search,
        int? month,
        DateTime? from,
        DateTime? to,
        bool? isActive,
        int page,
        int pageSize)
    {
        var query = _db.LibraryFestivals.AsNoTracking().AsQueryable();

        if (isActive.HasValue)
            query = query.Where(f => f.IsActive == isActive.Value);

        if (month.HasValue && month.Value >= 1 && month.Value <= 12)
            query = query.Where(f => f.Month == month.Value);

        if (from.HasValue)
        {
            var fromUtc = from.Value.ToUniversalTime();
            query = query.Where(f => f.FestivalDate >= fromUtc);
        }

        if (to.HasValue)
        {
            var toUtc = to.Value.ToUniversalTime();
            query = query.Where(f => f.FestivalDate <= toUtc);
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim().ToLower();
            query = query.Where(f =>
                f.Name.ToLower().Contains(term) ||
                (f.Description != null && f.Description.ToLower().Contains(term)) ||
                (f.FlowerDemands != null && f.FlowerDemands.ToLower().Contains(term)) ||
                (f.SearchKeywords != null && f.SearchKeywords.ToLower().Contains(term)));
        }

        var total = await query.CountAsync();

        var items = await query
            .OrderBy(f => f.SortOrder)
            .ThenBy(f => f.Month)
            .ThenBy(f => f.Day)
            .ThenBy(f => f.Name)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return (items, total);
    }

    public async Task AddAsync(LibraryFestival festival)
    {
        _db.LibraryFestivals.Add(festival);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(LibraryFestival festival)
    {
        _db.LibraryFestivals.Update(festival);
        await _db.SaveChangesAsync();
    }

    public async Task DeleteAsync(LibraryFestival festival)
    {
        _db.LibraryFestivals.Remove(festival);
        await _db.SaveChangesAsync();
    }

    public Task<bool> SlugExistsAsync(string slug, Guid? excludeId = null)
    {
        var q = _db.LibraryFestivals.Where(f => f.Slug == slug.ToLower());
        if (excludeId.HasValue)
            q = q.Where(f => f.Id != excludeId.Value);
        return q.AnyAsync();
    }

    public Task<int> CountActiveAsync()
        => _db.LibraryFestivals.CountAsync(f => f.IsActive);
}
