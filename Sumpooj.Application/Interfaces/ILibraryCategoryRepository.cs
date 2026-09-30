using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface ILibraryCategoryRepository
{
    Task<LibraryCategory?> GetByIdAsync(Guid id);
    Task<LibraryCategory?> GetBySlugAsync(string slug);
    Task<(List<LibraryCategory> Items, int TotalCount)> SearchAsync(
        string? search,
        bool? isActive,
        Guid? parentCategoryId,
        int page,
        int pageSize);
    Task<List<LibraryCategory>> GetAllActiveAsync();
    Task<List<LibraryCategory>> GetAllAsync(bool includeInactive = false);
    Task<int> GetProductCountAsync(Guid categoryId);
    Task AddAsync(LibraryCategory category);
    Task UpdateAsync(LibraryCategory category);
    Task DeleteAsync(LibraryCategory category);
    Task<bool> SlugExistsAsync(string slug, Guid? excludeId = null);
}

