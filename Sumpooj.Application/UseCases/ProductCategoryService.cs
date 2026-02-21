using Sumpooj.Application.Categories;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.UseCases;

public class ProductCategoryService
{
    private readonly IProductCategoryRepository _repo;
    private readonly ITenantContext _tenant;

    public ProductCategoryService(IProductCategoryRepository repo, ITenantContext tenant)
    {
        _repo = repo;
        _tenant = tenant;
    }

    public async Task<List<ProductCategoryDto>> GetAllAsync(bool includeInactive = false)
    {
        var categories = await _repo.GetAllAsync(includeInactive);
        var dtos = new List<ProductCategoryDto>();

        foreach (var c in categories)
        {
            var count = await _repo.GetProductCountAsync(c.Id);
            dtos.Add(ToDto(c, count));
        }

        return dtos;
    }

    public async Task<ProductCategoryDto?> GetAsync(Guid id)
    {
        var category = await _repo.GetByIdAsync(id);
        if (category == null) return null;

        var count = await _repo.GetProductCountAsync(id);
        return ToDto(category, count);
    }

    public async Task<Guid> CreateAsync(CreateProductCategoryRequest request)
    {
        if (_tenant.CompanyId == null)
            throw new InvalidOperationException("Company context required");

        if (await _repo.NameExistsAsync(request.Name))
            throw new InvalidOperationException($"Category '{request.Name}' already exists");

        var category = new ProductCategoryEntity(
            companyId: _tenant.CompanyId.Value,
            name: request.Name.Trim(),
            isPerishable: request.IsPerishable,
            trackBatchByDefault: request.TrackBatchByDefault);

        await _repo.AddAsync(category);
        return category.Id;
    }

    public async Task UpdateAsync(Guid id, UpdateProductCategoryRequest request)
    {
        var category = await _repo.GetByIdAsync(id)
            ?? throw new KeyNotFoundException("Category not found");

        if (await _repo.NameExistsAsync(request.Name, id))
            throw new InvalidOperationException($"Category '{request.Name}' already exists");

        category.Update(
            name: request.Name.Trim(),
            isPerishable: request.IsPerishable,
            trackBatchByDefault: request.TrackBatchByDefault);

        await _repo.UpdateAsync(category);
    }

    public async Task DeactivateAsync(Guid id)
    {
        var category = await _repo.GetByIdAsync(id)
            ?? throw new KeyNotFoundException("Category not found");

        var productCount = await _repo.GetProductCountAsync(id);
        if (productCount > 0)
            throw new InvalidOperationException(
                $"Cannot delete category with {productCount} assigned product(s). Reassign them first.");

        category.Deactivate();
        await _repo.UpdateAsync(category);
    }

    public async Task ActivateAsync(Guid id)
    {
        var category = await _repo.GetByIdAsync(id)
            ?? throw new KeyNotFoundException("Category not found");

        category.Activate();
        await _repo.UpdateAsync(category);
    }

    private static ProductCategoryDto ToDto(ProductCategoryEntity c, int productCount) => new()
    {
        Id = c.Id,
        Name = c.Name,
        IsPerishable = c.IsPerishable,
        TrackBatchByDefault = c.TrackBatchByDefault,
        IsActive = c.IsActive,
        ProductCount = productCount,
        CreatedAtUtc = c.CreatedAtUtc,
        UpdatedAtUtc = c.UpdatedAtUtc,
    };
}
