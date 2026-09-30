using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface ILibraryTutorialRepository
{
    Task<LibraryTutorial?> GetByIdAsync(Guid id);
    Task<LibraryTutorial?> GetBySlugAsync(string slug);
    Task<(List<LibraryTutorial> Items, int TotalCount)> SearchAsync(
        string? search,
        Guid? categoryId,
        string? difficultyLevel,
        string? tag,
        bool? isActive,
        int page,
        int pageSize);
    Task AddAsync(LibraryTutorial tutorial);
    Task UpdateAsync(LibraryTutorial tutorial);
    Task DeleteAsync(LibraryTutorial tutorial);
    Task<bool> SlugExistsAsync(string slug, Guid? excludeId = null);
}
