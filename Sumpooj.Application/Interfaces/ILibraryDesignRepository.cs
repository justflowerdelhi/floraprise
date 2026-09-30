using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface ILibraryDesignRepository
{
    Task<LibraryDesign?> GetByIdAsync(Guid id);
    Task<LibraryDesign?> GetBySlugAsync(string slug);
    Task<(List<LibraryDesign> Items, int TotalCount)> SearchAsync(
        string? search,
        Guid? categoryId,
        string? occasion,
        string? style,
        bool? isActive,
        int page,
        int pageSize);
    Task AddAsync(LibraryDesign design);
    Task UpdateAsync(LibraryDesign design);
    Task DeleteAsync(LibraryDesign design);
    Task<bool> SlugExistsAsync(string slug, Guid? excludeId = null);
}
