using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface ILibraryFestivalRepository
{
    Task<LibraryFestival?> GetByIdAsync(Guid id);
    Task<LibraryFestival?> GetBySlugAsync(string slug);
    Task<(List<LibraryFestival> Items, int TotalCount)> SearchAsync(
        string? search,
        int? month,
        DateTime? from,
        DateTime? to,
        bool? isActive,
        int page,
        int pageSize);
    Task AddAsync(LibraryFestival festival);
    Task UpdateAsync(LibraryFestival festival);
    Task DeleteAsync(LibraryFestival festival);
    Task<bool> SlugExistsAsync(string slug, Guid? excludeId = null);
    Task<int> CountActiveAsync();
}
