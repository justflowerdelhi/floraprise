using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface ILibraryWeddingDateRepository
{
    Task<LibraryWeddingDate?> GetByIdAsync(Guid id);
    Task<LibraryWeddingDate?> GetBySlugAsync(string slug);
    Task<(List<LibraryWeddingDate> Items, int TotalCount)> SearchAsync(
        string? search,
        string? season,
        string? demandLevel,
        DateTime? from,
        DateTime? to,
        bool? isActive,
        int page,
        int pageSize);
    Task AddAsync(LibraryWeddingDate weddingDate);
    Task UpdateAsync(LibraryWeddingDate weddingDate);
    Task DeleteAsync(LibraryWeddingDate weddingDate);
    Task<bool> SlugExistsAsync(string slug, Guid? excludeId = null);
    Task<int> CountActiveAsync();
}
