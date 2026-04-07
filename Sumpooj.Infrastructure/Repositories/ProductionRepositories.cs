using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class FloralRecipeRepository : IFloralRecipeRepository
{
    private readonly SumpoojDbContext _db;

    public FloralRecipeRepository(SumpoojDbContext db) => _db = db;

    public async Task<List<FloralRecipe>> GetAllAsync(Guid companyId)
    {
        return await _db.FloralRecipes
            .Include(r => r.Components)
            .Where(r => r.CompanyId == companyId)
            .OrderBy(r => r.Name)
            .ToListAsync();
    }

    public async Task<FloralRecipe?> GetByIdAsync(Guid companyId, Guid id)
    {
        return await _db.FloralRecipes
            .Include(r => r.Components)
            .FirstOrDefaultAsync(r => r.CompanyId == companyId && r.Id == id);
    }

    public async Task AddAsync(FloralRecipe recipe)
    {
        _db.FloralRecipes.Add(recipe);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(FloralRecipe recipe)
    {
        // The recipe entity is loaded as tracked (with Components) in the same request scope.
        // Persist in-memory changes directly to avoid duplicate delete/update state conflicts.
        await _db.SaveChangesAsync();
    }

    public async Task DeleteAsync(FloralRecipe recipe)
    {
        _db.FloralRecipes.Remove(recipe);
        await _db.SaveChangesAsync();
    }
}

public class FinishedGoodsBatchRepository : IFinishedGoodsBatchRepository
{
    private readonly SumpoojDbContext _db;

    public FinishedGoodsBatchRepository(SumpoojDbContext db) => _db = db;

    public async Task<List<FinishedGoodsBatch>> GetAllAsync(Guid companyId)
    {
        return await _db.FinishedGoodsBatches
            .Where(b => b.CompanyId == companyId)
            .OrderByDescending(b => b.ProducedAt)
            .ToListAsync();
    }

    public async Task<FinishedGoodsBatch?> GetByIdAsync(Guid companyId, Guid id)
    {
        return await _db.FinishedGoodsBatches
            .FirstOrDefaultAsync(b => b.CompanyId == companyId && b.Id == id);
    }

    public async Task AddAsync(FinishedGoodsBatch batch)
    {
        _db.FinishedGoodsBatches.Add(batch);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(FinishedGoodsBatch batch)
    {
        _db.FinishedGoodsBatches.Update(batch);
        await _db.SaveChangesAsync();
    }
}

public class ProductionJobRepository : IProductionJobRepository
{
    private readonly SumpoojDbContext _db;

    public ProductionJobRepository(SumpoojDbContext db) => _db = db;

    public async Task<List<ProductionJob>> GetAllAsync(Guid companyId)
    {
        return await _db.ProductionJobs
            .Where(j => j.CompanyId == companyId)
            .OrderByDescending(j => j.CreatedAtUtc)
            .ToListAsync();
    }

    public async Task<ProductionJob?> GetByIdAsync(Guid companyId, Guid id)
    {
        return await _db.ProductionJobs
            .Include(j => j.MaterialUsages)
            .FirstOrDefaultAsync(j => j.CompanyId == companyId && j.Id == id);
    }

    public async Task AddAsync(ProductionJob job)
    {
        _db.ProductionJobs.Add(job);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(ProductionJob job)
    {
        _db.ProductionJobs.Update(job);
        await _db.SaveChangesAsync();
    }
}

public class ProductionMaterialUsageRepository : IProductionMaterialUsageRepository
{
    private readonly SumpoojDbContext _db;

    public ProductionMaterialUsageRepository(SumpoojDbContext db) => _db = db;

    public async Task AddAsync(ProductionMaterialUsage usage)
    {
        _db.ProductionMaterialUsages.Add(usage);
        await _db.SaveChangesAsync();
    }
}

public class ProductionMaintenanceLogRepository : IProductionMaintenanceLogRepository
{
    private readonly SumpoojDbContext _db;

    public ProductionMaintenanceLogRepository(SumpoojDbContext db) => _db = db;

    public async Task<List<ProductionMaintenanceLog>> GetAllAsync(Guid companyId)
    {
        return await _db.ProductionMaintenanceLogs
            .Where(l => l.CompanyId == companyId)
            .OrderByDescending(l => l.PerformedAt)
            .ToListAsync();
    }

    public async Task AddAsync(ProductionMaintenanceLog log)
    {
        _db.ProductionMaintenanceLogs.Add(log);
        await _db.SaveChangesAsync();
    }
}

public class ProductionWastageLogRepository : IProductionWastageLogRepository
{
    private readonly SumpoojDbContext _db;

    public ProductionWastageLogRepository(SumpoojDbContext db) => _db = db;

    public async Task<List<ProductionWastageLog>> GetAllAsync(Guid companyId)
    {
        return await _db.ProductionWastageLogs
            .Where(l => l.CompanyId == companyId)
            .OrderByDescending(l => l.CreatedAtUtc)
            .ToListAsync();
    }

    public async Task AddAsync(ProductionWastageLog log)
    {
        _db.ProductionWastageLogs.Add(log);
        await _db.SaveChangesAsync();
    }
}
