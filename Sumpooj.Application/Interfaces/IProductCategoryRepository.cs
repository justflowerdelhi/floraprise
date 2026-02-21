using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IProductCategoryRepository
{
    Task<ProductCategoryEntity?> GetByIdAsync(Guid id);
    Task<List<ProductCategoryEntity>> GetAllAsync(bool includeInactive = false);
    Task AddAsync(ProductCategoryEntity category);
    Task UpdateAsync(ProductCategoryEntity category);
    Task<bool> NameExistsAsync(string name, Guid? excludeId = null);
    Task<int> GetProductCountAsync(Guid categoryId);
}
