using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class LibraryTutorialRepository : ILibraryTutorialRepository
{
    private readonly SumpoojDbContext _db;

    public LibraryTutorialRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public Task<LibraryTutorial?> GetByIdAsync(Guid id)
        => _db.LibraryTutorials
            .Include(t => t.Category)
            .FirstOrDefaultAsync(t => t.Id == id);

    public Task<LibraryTutorial?> GetBySlugAsync(string slug)
        => _db.LibraryTutorials
            .Include(t => t.Category)
            .FirstOrDefaultAsync(t => t.Slug == slug.ToLower());

    public async Task<(List<LibraryTutorial> Items, int TotalCount)> SearchAsync(
        string? search,
        Guid? categoryId,
        string? difficultyLevel,
        string? tag,
        bool? isActive,
        int page,
        int pageSize)
    {
        var query = _db.LibraryTutorials
            .AsNoTracking()
            .Include(t => t.Category)
            .AsQueryable();

        if (isActive.HasValue)
        {
            query = query.Where(t => t.IsActive == isActive.Value);
        }

        if (categoryId.HasValue)
        {
            query = query.Where(t => t.CategoryId == categoryId.Value);
        }

        if (!string.IsNullOrWhiteSpace(difficultyLevel))
        {
            var diff = difficultyLevel.Trim().ToLower();
            query = query.Where(t => t.DifficultyLevel.ToLower() == diff);
        }

        if (!string.IsNullOrWhiteSpace(tag))
        {
            var tagTerm = tag.Trim().ToLower();
            query = query.Where(t => t.Tags != null && t.Tags.ToLower().Contains(tagTerm));
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim().ToLower();
            query = query.Where(t =>
                t.Title.ToLower().Contains(term) ||
                t.Slug.ToLower().Contains(term) ||
                (t.Summary != null && t.Summary.ToLower().Contains(term)) ||
                t.ContentMarkdown.ToLower().Contains(term) ||
                (t.Tags != null && t.Tags.ToLower().Contains(term)));
        }

        var total = await query.CountAsync();
        var items = await query
            .OrderBy(t => t.SortOrder)
            .ThenBy(t => t.Title)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return (items, total);
    }

    public async Task AddAsync(LibraryTutorial tutorial)
    {
        _db.LibraryTutorials.Add(tutorial);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(LibraryTutorial tutorial)
    {
        _db.LibraryTutorials.Update(tutorial);
        await _db.SaveChangesAsync();
    }

    public async Task DeleteAsync(LibraryTutorial tutorial)
    {
        _db.LibraryTutorials.Remove(tutorial);
        await _db.SaveChangesAsync();
    }

    public async Task<bool> SlugExistsAsync(string slug, Guid? excludeId = null)
    {
        var q = _db.LibraryTutorials.Where(t => t.Slug == slug.ToLower());
        if (excludeId.HasValue)
            q = q.Where(t => t.Id != excludeId.Value);
        return await q.AnyAsync();
    }
}
