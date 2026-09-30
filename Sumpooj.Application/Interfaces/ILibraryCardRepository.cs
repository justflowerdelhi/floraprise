using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface ILibraryCardRepository
{
    Task<LibraryCardTemplate?> GetByIdAsync(Guid id);
    Task<LibraryCardTemplate?> GetBySlugAsync(string slug);
    Task<(List<LibraryCardTemplate> Items, int TotalCount)> SearchAsync(
        string? search,
        Guid? categoryId,
        string? occasion,
        string? tone,
        string? language,
        bool? isActive,
        int page,
        int pageSize);
    Task<List<(string Occasion, int Count)>> GetOccasionsSummaryAsync(string? language = null);
    Task AddAsync(LibraryCardTemplate card);
    Task UpdateAsync(LibraryCardTemplate card);
    Task DeleteAsync(LibraryCardTemplate card);
    Task<bool> SlugExistsAsync(string slug, Guid? excludeId = null);
}
