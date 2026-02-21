using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IProductRepository
{
    Task<Product?> GetByIdAsync(Guid id);
    Task<Product?> GetBySkuAsync(string sku);
    Task AddAsync(Product product);
    Task UpdateAsync(Product product);

    Task<(List<Product> Items, int TotalCount)> SearchAsync(
        string? query,
        string? productType,
        string? category,
        bool? isActive,
        bool? isPerishable,
        bool? lowStockOnly,
        int page,
        int pageSize);

    Task<List<Product>> GetLowStockProductsAsync();
    Task<List<Product>> GetProductsNeedingReorderAsync();
    Task<bool> SkuExistsAsync(string sku, Guid? excludeProductId = null);
    Task<int> GetLowStockCountAsync(Guid companyId);

    /// <summary>
    /// Fetch all products that have no CategoryId assigned (for migration).
    /// Bypasses tenant filter.
    /// </summary>
    Task<List<Product>> GetProductsWithoutCategoryAsync();
}
