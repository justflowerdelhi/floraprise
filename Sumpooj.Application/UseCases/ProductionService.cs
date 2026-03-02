using System.Text.Json;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Production;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.UseCases;

public class ProductionService
{
    private readonly IFloralRecipeRepository _recipeRepo;
    private readonly IFinishedGoodsBatchRepository _batchRepo;
    private readonly IProductionJobRepository _jobRepo;
    private readonly IProductionMaterialUsageRepository _materialRepo;
    private readonly IProductionMaintenanceLogRepository _maintenanceRepo;
    private readonly IProductionWastageLogRepository _wastageRepo;
    private readonly IOrderRepository _orderRepo;
    private readonly IProductRepository _productRepo;
    private readonly ILocationRepository _locationRepo;

    public ProductionService(
        IFloralRecipeRepository recipeRepo,
        IFinishedGoodsBatchRepository batchRepo,
        IProductionJobRepository jobRepo,
        IProductionMaterialUsageRepository materialRepo,
        IProductionMaintenanceLogRepository maintenanceRepo,
        IProductionWastageLogRepository wastageRepo,
        IOrderRepository orderRepo,
        IProductRepository productRepo,
        ILocationRepository locationRepo)
    {
        _recipeRepo = recipeRepo;
        _batchRepo = batchRepo;
        _jobRepo = jobRepo;
        _materialRepo = materialRepo;
        _maintenanceRepo = maintenanceRepo;
        _wastageRepo = wastageRepo;
        _orderRepo = orderRepo;
        _productRepo = productRepo;
        _locationRepo = locationRepo;
    }

    // ─── Recipes ────────────────────────────────────────────

    public async Task<List<FloralRecipeDto>> GetRecipesAsync(Guid companyId)
    {
        var recipes = await _recipeRepo.GetAllAsync(companyId);
        return recipes.Select(MapRecipe).ToList();
    }

    public async Task<FloralRecipeDto?> GetRecipeByIdAsync(Guid companyId, Guid id)
    {
        var recipe = await _recipeRepo.GetByIdAsync(companyId, id);
        return recipe == null ? null : MapRecipe(recipe);
    }

    public async Task<FloralRecipeDto> CreateRecipeAsync(Guid companyId, CreateRecipeRequest request)
    {
        var recipe = new FloralRecipe(
            companyId,
            request.Name,
            request.Category,
            request.SellingPrice,
            request.LaborCost);

        if (request.SampleImages is { Count: > 0 })
            recipe.Update(request.Name, request.Category, request.SellingPrice, request.LaborCost ?? 0,
                string.Join(",", request.SampleImages));

        foreach (var c in request.Components)
        {
            recipe.Components.Add(new RecipeComponent(recipe.Id, c.ProductId, c.ProductName, c.QuantityRequired, c.UnitCost));
        }

        await _recipeRepo.AddAsync(recipe);
        return MapRecipe(recipe);
    }

    public async Task<FloralRecipeDto?> UpdateRecipeAsync(Guid companyId, Guid id, UpdateRecipeRequest request)
    {
        var recipe = await _recipeRepo.GetByIdAsync(companyId, id);
        if (recipe == null) return null;

        recipe.Update(
            request.Name,
            request.Category,
            request.SellingPrice,
            request.LaborCost ?? 0,
            request.SampleImages is { Count: > 0 } ? string.Join(",", request.SampleImages) : null);

        // Replace components
        recipe.Components.Clear();
        foreach (var c in request.Components)
        {
            recipe.Components.Add(new RecipeComponent(recipe.Id, c.ProductId, c.ProductName, c.QuantityRequired, c.UnitCost));
        }

        await _recipeRepo.UpdateAsync(recipe);
        return MapRecipe(recipe);
    }

    public async Task<bool> DeleteRecipeAsync(Guid companyId, Guid id)
    {
        var recipe = await _recipeRepo.GetByIdAsync(companyId, id);
        if (recipe == null) return false;
        await _recipeRepo.DeleteAsync(recipe);
        return true;
    }

    // ─── Finished Goods ─────────────────────────────────────

    public async Task<List<FinishedGoodsBatchDto>> GetFinishedBatchesAsync(Guid companyId)
    {
        var batches = await _batchRepo.GetAllAsync(companyId);
        return batches.Select(MapBatch).ToList();
    }

    public async Task<FinishedGoodsBatchDto?> GetFinishedBatchByIdAsync(Guid companyId, Guid id)
    {
        var batch = await _batchRepo.GetByIdAsync(companyId, id);
        return batch == null ? null : MapBatch(batch);
    }

    public async Task DeductFromBatchAsync(Guid companyId, Guid batchId, int quantity)
    {
        var batch = await _batchRepo.GetByIdAsync(companyId, batchId)
            ?? throw new InvalidOperationException("Batch not found");

        batch.Deduct(quantity);
        await _batchRepo.UpdateAsync(batch);
    }

    // ─── Production Runs ────────────────────────────────────

    public async Task<ProductionRunResult> CreateProductionRunAsync(Guid companyId, ProductionRunRequest request)
    {
        var recipe = await _recipeRepo.GetByIdAsync(companyId, request.RecipeId)
            ?? throw new InvalidOperationException("Recipe not found");

        var location = await _locationRepo.GetByIdAsync(companyId, request.LocationId);
        var locationName = location?.Name ?? "Unknown";

        var batchCount = (await _batchRepo.GetAllAsync(companyId)).Count;
        var batchCode = $"FG-{DateTime.UtcNow:yyyyMMdd}-{(batchCount + 1):D3}";
        var barcode = $"890123456{(batchCount + 1):D4}";

        var deductions = new List<ComponentDeduction>();
        decimal totalCost = 0;

        foreach (var comp in recipe.Components)
        {
            var qty = comp.QuantityRequired * request.Quantity;
            deductions.Add(new ComponentDeduction { ProductId = comp.ProductId, QuantityDeducted = qty });
            totalCost += comp.UnitCost * qty;
        }
        totalCost += recipe.LaborCost * request.Quantity;

        var expiry = DateTime.Parse(request.ExpectedExpiry).ToUniversalTime();

        var batch = new FinishedGoodsBatch(
            companyId, recipe.Id, recipe.Name, batchCode, barcode,
            request.Quantity, expiry, request.LocationId, locationName, totalCost);

        await _batchRepo.AddAsync(batch);

        return new ProductionRunResult
        {
            BatchId = batch.Id,
            BatchCode = batchCode,
            Barcode = barcode,
            QuantityProduced = request.Quantity,
            ComponentsDeducted = deductions,
            TotalCost = totalCost
        };
    }

    // ─── On-Demand Assembly ─────────────────────────────────

    public async Task<OnDemandAssemblyResult> CreateOnDemandAssemblyAsync(Guid companyId, OnDemandAssemblyRequest request)
    {
        var recipe = await _recipeRepo.GetByIdAsync(companyId, request.RecipeId)
            ?? throw new InvalidOperationException("Recipe not found");

        var deductions = recipe.Components.Select(c => new ComponentDeduction
        {
            ProductId = c.ProductId,
            QuantityDeducted = c.QuantityRequired * request.Quantity
        }).ToList();

        return new OnDemandAssemblyResult { Success = true, ComponentsDeducted = deductions };
    }

    // ─── Custom Bouquet ─────────────────────────────────────

    public async Task<FloralRecipeDto> SaveCustomBouquetAsRecipeAsync(Guid companyId, CustomBouquetSaveRequest request)
    {
        var createReq = new CreateRecipeRequest
        {
            Name = request.Name,
            Category = request.Category,
            SellingPrice = request.SellingPrice,
            LaborCost = request.LaborCost,
            Components = request.Components.Select(c => new RecipeComponentDto
            {
                ProductId = c.ProductId,
                ProductName = c.ProductName,
                QuantityRequired = c.Quantity,
                UnitCost = c.UnitCost
            }).ToList(),
            SampleImages = request.Image != null ? new List<string> { request.Image } : null,
            IsActive = true
        };
        return await CreateRecipeAsync(companyId, createReq);
    }

    // ─── Maintenance ────────────────────────────────────────

    public async Task<List<MaintenanceLogDto>> GetMaintenanceLogsAsync(Guid companyId)
    {
        var logs = await _maintenanceRepo.GetAllAsync(companyId);
        return logs.Select(l => new MaintenanceLogDto
        {
            Id = l.Id,
            FinishedBatchId = l.FinishedBatchId,
            BatchCode = l.BatchCode,
            Replacements = DeserializeReplacements(l.ReplacementsJson),
            PerformedAt = l.PerformedAt.ToString("o"),
            PerformedBy = l.PerformedBy,
            Notes = l.Notes
        }).ToList();
    }

    public async Task<MaintenanceLogDto> CreateMaintenanceAsync(Guid companyId, MaintenanceRequest request)
    {
        var batch = await _batchRepo.GetByIdAsync(companyId, request.FinishedBatchId);
        var batchCode = batch?.BatchCode ?? "";

        var log = new ProductionMaintenanceLog(companyId, request.FinishedBatchId, batchCode, request.Notes);
        log.SetReplacements(JsonSerializer.Serialize(request.Replacements));

        await _maintenanceRepo.AddAsync(log);

        return new MaintenanceLogDto
        {
            Id = log.Id,
            FinishedBatchId = log.FinishedBatchId,
            BatchCode = batchCode,
            Replacements = request.Replacements,
            PerformedAt = log.PerformedAt.ToString("o"),
            Notes = log.Notes
        };
    }

    // ─── Wastage ────────────────────────────────────────────

    public async Task<List<WastageLogDto>> GetWastageLogsAsync(Guid companyId)
    {
        var logs = await _wastageRepo.GetAllAsync(companyId);
        return logs.Select(l => new WastageLogDto
        {
            Id = l.Id,
            ProductId = l.ProductId,
            ProductName = l.ProductName,
            Quantity = l.Quantity,
            Reason = l.Reason.ToString(),
            RelatedFinishedBatchId = l.RelatedFinishedBatchId,
            RelatedBatchCode = l.RelatedBatchCode,
            CreatedAt = l.CreatedAtUtc.ToString("o"),
            CreatedBy = l.CreatedBy
        }).ToList();
    }

    public async Task<WastageLogDto> CreateWastageAsync(Guid companyId, CreateWastageRequest request)
    {
        var reason = Enum.Parse<WastageReason>(request.Reason, ignoreCase: true);
        var log = new ProductionWastageLog(
            companyId, request.ProductId, request.ProductName,
            request.Quantity, reason, request.RelatedFinishedBatchId, request.RelatedBatchCode);

        await _wastageRepo.AddAsync(log);

        return new WastageLogDto
        {
            Id = log.Id,
            ProductId = log.ProductId,
            ProductName = log.ProductName,
            Quantity = log.Quantity,
            Reason = log.Reason.ToString(),
            RelatedFinishedBatchId = log.RelatedFinishedBatchId,
            RelatedBatchCode = log.RelatedBatchCode,
            CreatedAt = log.CreatedAtUtc.ToString("o")
        };
    }

    // ─── Production Jobs ────────────────────────────────────

    public async Task<List<ProductionJobDto>> GetJobsAsync(Guid companyId, ProductionStatus? status = null)
    {
        var jobs = await _jobRepo.GetAllAsync(companyId);
        if (status.HasValue)
            jobs = jobs.Where(j => j.Status == status.Value).ToList();

        var orderIds = jobs.Select(j => j.OrderId).Distinct().ToList();
        var orders = await _orderRepo.GetByIdsAsync(companyId, orderIds);
        var numberMap = orders.ToDictionary(o => o.Id, o => o.OrderNumber);

        return jobs.OrderBy(j => j.CreatedAtUtc).Select(j => new ProductionJobDto
        {
            JobId = j.Id,
            OrderId = j.OrderId,
            OrderNumber = numberMap.GetValueOrDefault(j.OrderId),
            Description = j.Description,
            Status = j.Status.ToString(),
            CreatedAtUtc = j.CreatedAtUtc.ToString("o")
        }).ToList();
    }

    public async Task<ProductionJobDto?> GetJobByIdAsync(Guid companyId, Guid id)
    {
        var job = await _jobRepo.GetByIdAsync(companyId, id);
        if (job == null) return null;

        return new ProductionJobDto
        {
            JobId = job.Id,
            OrderId = job.OrderId,
            Description = job.Description,
            Status = job.Status.ToString(),
            CreatedAtUtc = job.CreatedAtUtc.ToString("o"),
            MaterialUsages = job.MaterialUsages.Select(m => new MaterialUsageDto
            {
                Id = m.Id,
                ProductName = m.ProductName,
                UnitsUsed = m.UnitsUsed,
                AvailableUnits = 0
            }).ToList()
        };
    }

    public async Task<ProductionJobDto> CreateJobAsync(Guid companyId, CreateProductionJobRequest request)
    {
        var job = new ProductionJob(companyId, request.OrderId, request.Description);
        await _jobRepo.AddAsync(job);

        return new ProductionJobDto
        {
            JobId = job.Id,
            OrderId = job.OrderId,
            Description = job.Description,
            Status = job.Status.ToString(),
            CreatedAtUtc = job.CreatedAtUtc.ToString("o")
        };
    }

    public async Task<bool> StartJobAsync(Guid companyId, Guid id)
    {
        var job = await _jobRepo.GetByIdAsync(companyId, id);
        if (job == null) return false;
        job.Start();
        await _jobRepo.UpdateAsync(job);
        return true;
    }

    public async Task<bool> CompleteJobAsync(Guid companyId, Guid id)
    {
        var job = await _jobRepo.GetByIdAsync(companyId, id);
        if (job == null) return false;
        job.Complete();
        await _jobRepo.UpdateAsync(job);
        return true;
    }

    public async Task<bool> AddMaterialUsageAsync(Guid companyId, AddMaterialUsageRequest request)
    {
        var job = await _jobRepo.GetByIdAsync(companyId, request.JobId);
        if (job == null) return false;

        var product = await _productRepo.GetByIdAsync(companyId, request.ProductId);
        var productName = product?.Name ?? "Unknown";

        var usage = new ProductionMaterialUsage(request.JobId, request.ProductId, productName, request.UnitsUsed);
        await _materialRepo.AddAsync(usage);
        return true;
    }

    // ─── Inventory Products for production screen ───────────

    public async Task<List<InventoryProductDto>> GetInventoryProductsAsync(Guid companyId, Guid locationId)
    {
        var products = await _productRepo.GetAllAsync(companyId);
        return products.Select(p => new InventoryProductDto
        {
            Id = p.Id,
            Name = p.Name,
            ProductType = p.ProductType.ToString(),
            QuantityAvailable = p.StockQuantity,
            UnitCost = p.CostPrice,
            LocationId = locationId
        }).ToList();
    }

    // ─── Helpers ────────────────────────────────────────────

    private static FloralRecipeDto MapRecipe(FloralRecipe r) => new()
    {
        Id = r.Id,
        TenantId = r.CompanyId.ToString(),
        Name = r.Name,
        Category = r.Category,
        SellingPrice = r.SellingPrice,
        LaborCost = r.LaborCost,
        Components = r.Components.Select(c => new RecipeComponentDto
        {
            ProductId = c.ProductId,
            ProductName = c.ProductName,
            QuantityRequired = c.QuantityRequired,
            UnitCost = c.UnitCost
        }).ToList(),
        SampleImages = r.SampleImages?.Split(',', StringSplitOptions.RemoveEmptyEntries).ToList(),
        IsActive = r.IsActive,
        CreatedAt = r.CreatedAtUtc.ToString("o"),
        UpdatedAt = (r.UpdatedAtUtc ?? r.CreatedAtUtc).ToString("o")
    };

    private static FinishedGoodsBatchDto MapBatch(FinishedGoodsBatch b) => new()
    {
        Id = b.Id,
        RecipeId = b.RecipeId,
        RecipeName = b.RecipeName,
        BatchCode = b.BatchCode,
        Barcode = b.Barcode,
        QuantityProduced = b.QuantityProduced,
        QuantityAvailable = b.QuantityAvailable,
        ExpectedExpiry = b.ExpectedExpiry.ToString("o"),
        LocationId = b.LocationId,
        LocationName = b.LocationName,
        Status = b.Status.ToString(),
        ProducedAt = b.ProducedAt.ToString("o")
    };

    private static List<MaintenanceReplacementDto> DeserializeReplacements(string? json)
    {
        if (string.IsNullOrWhiteSpace(json)) return new();
        try
        {
            return JsonSerializer.Deserialize<List<MaintenanceReplacementDto>>(json,
                new JsonSerializerOptions { PropertyNameCaseInsensitive = true }) ?? new();
        }
        catch
        {
            return new();
        }
    }
}
