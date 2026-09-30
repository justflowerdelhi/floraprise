using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface ILibraryRecipeRepository
{
    Task<LibraryRecipe?> GetByIdAsync(Guid id);
    Task<LibraryRecipe?> GetBySlugAsync(string slug);
    Task<(List<LibraryRecipe> Items, int TotalCount)> SearchAsync(
        string? search,
        Guid? categoryId,
        bool? isActive,
        int page,
        int pageSize);
    Task AddAsync(LibraryRecipe recipe);
    Task UpdateAsync(LibraryRecipe recipe);
    Task DeleteAsync(LibraryRecipe recipe);
    Task<bool> SlugExistsAsync(string slug, Guid? excludeId = null);
}
