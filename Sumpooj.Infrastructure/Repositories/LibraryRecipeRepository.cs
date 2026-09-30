using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class LibraryRecipeRepository : ILibraryRecipeRepository
{
    private readonly SumpoojDbContext _db;

    public LibraryRecipeRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public Task<LibraryRecipe?> GetByIdAsync(Guid id)
        => _db.LibraryRecipes
            .Include(r => r.Category)
            .Include(r => r.Items.OrderBy(i => i.SortOrder))
                .ThenInclude(i => i.LibraryProduct)
            .FirstOrDefaultAsync(r => r.Id == id);

    public Task<LibraryRecipe?> GetBySlugAsync(string slug)
        => _db.LibraryRecipes
            .Include(r => r.Category)
            .Include(r => r.Items.OrderBy(i => i.SortOrder))
                .ThenInclude(i => i.LibraryProduct)
            .FirstOrDefaultAsync(r => r.Slug == slug.ToLower());

    public async Task<(List<LibraryRecipe> Items, int TotalCount)> SearchAsync(
        string? search,
        Guid? categoryId,
        bool? isActive,
        int page,
        int pageSize)
    {
        var query = _db.LibraryRecipes
            .AsNoTracking()
            .Include(r => r.Category)
            .Include(r => r.Items)
            .AsQueryable();

        if (isActive.HasValue)
        {
            query = query.Where(r => r.IsActive == isActive.Value);
        }

        if (categoryId.HasValue)
        {
            query = query.Where(r => r.CategoryId == categoryId.Value);
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim().ToLower();
            query = query.Where(r =>
                r.Name.ToLower().Contains(term) ||
                r.Slug.ToLower().Contains(term) ||
                (r.Description != null && r.Description.ToLower().Contains(term)) ||
                (r.Instructions != null && r.Instructions.ToLower().Contains(term)) ||
                (r.PreparationNotes != null && r.PreparationNotes.ToLower().Contains(term)));
        }

        var total = await query.CountAsync();
        var items = await query
            .OrderBy(r => r.SortOrder)
            .ThenBy(r => r.Name)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return (items, total);
    }

    public async Task AddAsync(LibraryRecipe recipe)
    {
        _db.LibraryRecipes.Add(recipe);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(LibraryRecipe recipe)
    {
        _db.LibraryRecipes.Update(recipe);
        await _db.SaveChangesAsync();
    }

    public async Task DeleteAsync(LibraryRecipe recipe)
    {
        _db.LibraryRecipes.Remove(recipe);
        await _db.SaveChangesAsync();
    }

    public async Task<bool> SlugExistsAsync(string slug, Guid? excludeId = null)
    {
        var q = _db.LibraryRecipes.Where(r => r.Slug == slug.ToLower());
        if (excludeId.HasValue)
            q = q.Where(r => r.Id != excludeId.Value);
        return await q.AnyAsync();
    }
}
