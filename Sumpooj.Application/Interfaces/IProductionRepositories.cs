using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IFloralRecipeRepository
{
    Task<List<FloralRecipe>> GetAllAsync(Guid companyId);
    Task<FloralRecipe?> GetByIdAsync(Guid companyId, Guid id);
    Task AddAsync(FloralRecipe recipe);
    Task UpdateAsync(FloralRecipe recipe);
    Task DeleteAsync(FloralRecipe recipe);
}

public interface IFinishedGoodsBatchRepository
{
    Task<List<FinishedGoodsBatch>> GetAllAsync(Guid companyId);
    Task<FinishedGoodsBatch?> GetByIdAsync(Guid companyId, Guid id);
    Task AddAsync(FinishedGoodsBatch batch);
    Task UpdateAsync(FinishedGoodsBatch batch);
}

public interface IProductionJobRepository
{
    Task<List<ProductionJob>> GetAllAsync(Guid companyId);
    Task<ProductionJob?> GetByIdAsync(Guid companyId, Guid id);
    Task AddAsync(ProductionJob job);
    Task UpdateAsync(ProductionJob job);
}

public interface IProductionMaterialUsageRepository
{
    Task AddAsync(ProductionMaterialUsage usage);
}

public interface IProductionMaintenanceLogRepository
{
    Task<List<ProductionMaintenanceLog>> GetAllAsync(Guid companyId);
    Task AddAsync(ProductionMaintenanceLog log);
}

public interface IProductionWastageLogRepository
{
    Task<List<ProductionWastageLog>> GetAllAsync(Guid companyId);
    Task AddAsync(ProductionWastageLog log);
}
