using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface ILibraryProductRepository
{
    Task<LibraryProduct?> GetByIdAsync(Guid id);
    Task<LibraryProduct?> GetBySlugAsync(string slug);
    Task<(List<LibraryProduct> Items, int TotalCount)> SearchAsync(
        string? search,
        Guid? categoryId,
        ProductType? productType,
        bool? isActive,
        int page,
        int pageSize);
    Task AddAsync(LibraryProduct product);
    Task UpdateAsync(LibraryProduct product);
    Task DeleteAsync(LibraryProduct product);
    Task<bool> SlugExistsAsync(string slug, Guid? excludeId = null);
}

