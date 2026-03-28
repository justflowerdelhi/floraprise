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
    private readonly IInventoryAdjustmentRepository _inventoryAdjustmentRepo;
    private readonly IOrderRepository _orderRepo;
    private readonly IProductRepository _productRepo;
    private readonly ILocationRepository _locationRepo;
    private readonly IInventoryLedgerRepository _inventoryLedgerRepo;

    public ProductionService(
        IFloralRecipeRepository recipeRepo,
        IFinishedGoodsBatchRepository batchRepo,
        IProductionJobRepository jobRepo,
        IProductionMaterialUsageRepository materialRepo,
        IProductionMaintenanceLogRepository maintenanceRepo,
        IProductionWastageLogRepository wastageRepo,
        IInventoryAdjustmentRepository inventoryAdjustmentRepo,
        IOrderRepository orderRepo,
        IProductRepository productRepo,
        ILocationRepository locationRepo,
        IInventoryLedgerRepository inventoryLedgerRepo)
    {
        _recipeRepo = recipeRepo;
        _batchRepo = batchRepo;
        _jobRepo = jobRepo;
        _materialRepo = materialRepo;
        _maintenanceRepo = maintenanceRepo;
        _wastageRepo = wastageRepo;
        _inventoryAdjustmentRepo = inventoryAdjustmentRepo;
        _orderRepo = orderRepo;
        _productRepo = productRepo;
        _locationRepo = locationRepo;
        _inventoryLedgerRepo = inventoryLedgerRepo;
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

    public async Task<SellableFinishedGoodDto> CreateCustomBouquetAndSellAsync(Guid companyId, CustomBouquetRequest request)
    {
        if (request.Components.Count == 0)
            throw new InvalidOperationException("At least one component is required");

        if (request.LocationId == Guid.Empty)
            throw new InvalidOperationException("Location is required to create a custom bouquet");

        var bouquetName = string.IsNullOrWhiteSpace(request.Name) ||
                          string.Equals(request.Name.Trim(), "Custom Bouquet", StringComparison.OrdinalIgnoreCase)
            ? GenerateCustomBouquetName(request.Components)
            : request.Name.Trim();

        var recipe = new FloralRecipe(
            companyId,
            bouquetName,
            string.IsNullOrWhiteSpace(request.Category) ? "Custom" : request.Category,
            request.SellingPrice,
            request.LaborCost);

        var ledgerReference = $"CUSTOM-{DateTime.UtcNow:yyyyMMddHHmmss}";

        foreach (var component in request.Components)
        {
            var product = await _productRepo.GetByIdAsync(companyId, component.ProductId)
                ?? throw new InvalidOperationException($"Component product not found: {component.ProductId}");

            if (!product.TrackInventory)
                throw new InvalidOperationException($"Component {product.Name} is not inventory tracked");

            if (component.Quantity <= 0)
                throw new InvalidOperationException($"Quantity must be greater than zero for {product.Name}");

            if (product.StockQuantity < component.Quantity)
                throw new InvalidOperationException(
                    $"Insufficient stock for {product.Name}. Available: {product.StockQuantity}, required: {component.Quantity}");

            product.AdjustStock(-component.Quantity);
            await _productRepo.UpdateAsync(product);

            await _inventoryLedgerRepo.AddAsync(
                new InventoryLedger(
                    companyId,
                    product.Id,
                    ledgerReference,
                    "ADJUSTMENT",
                    -component.Quantity,
                    product.StockQuantity,
                    $"Custom bouquet component usage: {bouquetName}"
                )
            );

            recipe.Components.Add(new RecipeComponent(recipe.Id, product.Id, product.Name, component.Quantity, product.CostPrice));
        }

        if (!string.IsNullOrWhiteSpace(request.Image))
        {
            recipe.Update(recipe.Name, recipe.Category, recipe.SellingPrice, recipe.LaborCost, request.Image);
        }

        await _recipeRepo.AddAsync(recipe);

        var location = await _locationRepo.GetByIdAsync(companyId, request.LocationId)
            ?? throw new InvalidOperationException("Location not found");

        var batchCount = (await _batchRepo.GetAllAsync(companyId)).Count;
        var batchCode = $"FG-{DateTime.UtcNow:yyyyMMdd}-{(batchCount + 1):D3}";
        var barcode = $"890123456{(batchCount + 1):D4}";
        var totalCost = request.Components.Sum(c => c.UnitCost * c.Quantity) + (request.LaborCost ?? 0m);
        var expectedExpiry = DateTime.UtcNow.AddDays(3);

        var batch = new FinishedGoodsBatch(
            companyId,
            recipe.Id,
            recipe.Name,
            batchCode,
            barcode,
            quantityProduced: 1,
            expectedExpiry,
            request.LocationId,
            location.Name,
            totalCost);

        await _batchRepo.AddAsync(batch);

        return new SellableFinishedGoodDto
        {
            Id = batch.Id,
            Name = recipe.Name,
            Sku = batch.BatchCode,
            Barcode = batch.Barcode,
            Category = "Bouquets",
            ProductType = "FinishedGood",
            RetailPrice = recipe.SellingPrice,
            CostPrice = totalCost,
            StockQuantity = batch.QuantityAvailable,
            IsActive = true,
            IsPerishable = true,
            RecipeId = recipe.Id,
            RecipeName = recipe.Name,
            BatchCode = batch.BatchCode,
            LocationId = batch.LocationId,
            LocationName = batch.LocationName,
        };
    }

    private static string GenerateCustomBouquetName(List<CustomBouquetComponent> components)
    {
        if (components.Count == 0)
            return $"Custom Bouquet {DateTime.UtcNow:HHmm}";

        var ordered = components
            .OrderByDescending(c => c.Quantity)
            .ThenBy(c => c.ProductName)
            .ToList();

        var main = ordered[0];
        var stamp = DateTime.UtcNow.ToString("HHmm");

        if (ordered.Count == 1)
            return $"{main.Quantity} {main.ProductName} Bouquet {stamp}";

        if (ordered.Count == 2)
            return $"{main.Quantity} {main.ProductName} + {ordered[1].ProductName} {stamp}";

        return $"{main.Quantity} {main.ProductName} Mixed Bouquet {stamp}";
    }

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

    public async Task<MaintenanceLogDto> CreateMaintenanceAsync(
        Guid companyId,
        MaintenanceRequest request,
        Guid userId,
        string? userName)
    {
        var batch = await _batchRepo.GetByIdAsync(companyId, request.FinishedBatchId)
            ?? throw new InvalidOperationException("Finished batch not found");

        if (batch.Status != FinishedBatchStatus.Active || batch.QuantityAvailable <= 0)
            throw new InvalidOperationException("Only active finished goods with available quantity can be repaired");

        if (request.Replacements.Count == 0)
            throw new InvalidOperationException("At least one replacement item is required");

        var batchCode = batch.BatchCode;

        var log = new ProductionMaintenanceLog(companyId, request.FinishedBatchId, batchCode, request.Notes);
        if (!string.IsNullOrWhiteSpace(userName))
        {
            log.SetPerformedBy(userName);
        }

        foreach (var replacement in request.Replacements)
        {
            var product = await _productRepo.GetByIdAsync(companyId, replacement.ProductId)
                ?? throw new InvalidOperationException($"Replacement product not found: {replacement.ProductId}");

            if (!product.TrackInventory)
                throw new InvalidOperationException($"Product {product.Name} is not inventory-tracked and cannot be used for repair deductions");

            if (replacement.QuantityReplaced <= 0)
                throw new InvalidOperationException($"Replacement quantity must be greater than 0 for {product.Name}");

            if (product.StockQuantity < replacement.QuantityReplaced)
                throw new InvalidOperationException(
                    $"Insufficient stock for {product.Name}. Available: {product.StockQuantity}, required: {replacement.QuantityReplaced}");

            product.AdjustStock(-replacement.QuantityReplaced);
            await _productRepo.UpdateAsync(product);

            var wastageReason = ParseWastageReason(replacement.Reason);
            var inventoryAdjustment = new InventoryAdjustment(
                companyId,
                product.Id,
                batchId: null,
                adjustmentType: ToAdjustmentType(wastageReason),
                quantity: replacement.QuantityReplaced,
                costPerUnit: product.CostPrice,
                reason: BuildRepairReason(batch, product.Name, replacement.Reason),
                adjustedByUserId: userId);

            inventoryAdjustment.AddNotes($"Finished batch: {batch.BatchCode} ({batch.RecipeName})");
            if (!string.IsNullOrWhiteSpace(request.Notes))
            {
                inventoryAdjustment.AddNotes(request.Notes!);
            }

            await _inventoryAdjustmentRepo.AddAsync(inventoryAdjustment);

            var wastageLog = new ProductionWastageLog(
                companyId,
                product.Id,
                product.Name,
                replacement.QuantityReplaced,
                wastageReason,
                batch.Id,
                batch.BatchCode);

            if (!string.IsNullOrWhiteSpace(userName))
            {
                wastageLog.SetCreatedBy(userName);
            }

            await _wastageRepo.AddAsync(wastageLog);
        }

        log.SetReplacements(JsonSerializer.Serialize(request.Replacements));

        await _maintenanceRepo.AddAsync(log);

        return new MaintenanceLogDto
        {
            Id = log.Id,
            FinishedBatchId = log.FinishedBatchId,
            BatchCode = batchCode,
            Replacements = request.Replacements,
            PerformedAt = log.PerformedAt.ToString("o"),
            PerformedBy = log.PerformedBy,
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

    private static WastageReason ParseWastageReason(string value)
    {
        if (Enum.TryParse<WastageReason>(value, true, out var result))
            return result;

        return WastageReason.Spoiled;
    }

    private static AdjustmentType ToAdjustmentType(WastageReason reason) => reason switch
    {
        WastageReason.Damaged => AdjustmentType.Damaged,
        WastageReason.Wilted => AdjustmentType.Spoiled,
        _ => AdjustmentType.Spoiled,
    };

    private static string BuildRepairReason(FinishedGoodsBatch batch, string productName, string reason)
        => $"Repair replacement for {batch.RecipeName} ({batch.BatchCode}) using {productName}; issue: {reason}";

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

    // ─── Sellable Finished Goods (for Walk-In POS) ────────────

    /// <summary>
    /// Returns active finished goods batches with available quantity as sellable product items.
    /// Used by the Walk-In Sales POS to include production items in the product list.
    /// </summary>
    public async Task<List<SellableFinishedGoodDto>> GetSellableFinishedGoodsAsync(Guid companyId)
    {
        var batches = await _batchRepo.GetAllAsync(companyId);
        var activeBatches = batches
            .Where(b => b.Status == FinishedBatchStatus.Active && b.QuantityAvailable > 0)
            .ToList();

        if (activeBatches.Count == 0)
            return [];

        // Look up recipes to get selling prices
        var recipeIds = activeBatches.Select(b => b.RecipeId).Distinct().ToList();
        var recipes = await _recipeRepo.GetAllAsync(companyId);
        var recipePriceMap = recipes.ToDictionary(r => r.Id, r => r.SellingPrice);

        return activeBatches.Select(b =>
        {
            var sellingPrice = recipePriceMap.GetValueOrDefault(b.RecipeId, 0);
            var costPerUnit = b.QuantityProduced > 0 ? b.TotalCost / b.QuantityProduced : 0;

            return new SellableFinishedGoodDto
            {
                Id = b.Id,
                Name = b.RecipeName,
                Sku = b.BatchCode,
                Barcode = b.Barcode,
                Category = "Bouquets",
                ProductType = "FinishedGood",
                RetailPrice = sellingPrice,
                CostPrice = costPerUnit,
                StockQuantity = b.QuantityAvailable,
                IsActive = true,
                IsPerishable = true,
                RecipeId = b.RecipeId,
                RecipeName = b.RecipeName,
                BatchCode = b.BatchCode,
                LocationId = b.LocationId,
                LocationName = b.LocationName,
            };
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
