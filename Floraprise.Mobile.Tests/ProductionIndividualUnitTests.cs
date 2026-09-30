using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Sumpooj.API.Services.Mobile;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Mobile;
using Sumpooj.Application.Production;
using Sumpooj.Application.UseCases;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;
using Sumpooj.Infrastructure.Repositories;
using Xunit;

namespace Floraprise.Mobile.Tests;

public sealed class ProductionIndividualUnitTests
{
    private sealed class FakeTenantContext : ITenantContext
    {
        public FakeTenantContext(Guid companyId) => CompanyId = companyId;
        public Guid? CompanyId { get; }
        public bool IsPlatformUser => false;
        public string? Region => null;
    }

    private readonly Guid _companyId = Guid.NewGuid();
    private readonly Guid _locationId = Guid.NewGuid();

    private SumpoojDbContext CreateDb()
    {
        var options = new DbContextOptionsBuilder<SumpoojDbContext>()
            .UseInMemoryDatabase($"ProdUnitTests_{Guid.NewGuid():N}")
            .ConfigureWarnings(w => w.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options;
        var db = new SumpoojDbContext(options, new FakeTenantContext(_companyId));

        // Seed location
        var location = new Location(_companyId, "Main Store", "LOC-1", LocationType.Store, "Bangalore");
        typeof(BaseEntity).GetProperty(nameof(BaseEntity.Id))!.SetValue(location, _locationId);
        db.Locations.Add(location);

        return db;
    }

    private static ProductionService CreateProductionService(SumpoojDbContext db)
    {
        return new ProductionService(
            new FloralRecipeRepository(db),
            new FinishedGoodsBatchRepository(db),
            new ProductionJobRepository(db),
            new ProductionMaterialUsageRepository(db),
            new ProductionMaintenanceLogRepository(db),
            new ProductionWastageLogRepository(db),
            new InventoryAdjustmentRepository(db),
            new OrderRepository(db),
            new ProductRepository(db),
            new LocationRepository(db),
            new InventoryLedgerRepository(db),
            new UnitOfWork(db));
    }

    private static PosSaleSyncService CreatePosService(SumpoojDbContext db)
    {
        return new PosSaleSyncService(db);
    }

    private (Product RawFlower, FloralRecipe Recipe) SeedRecipeAndMaterials(SumpoojDbContext db, int initialStock = 100)
    {
        var rawFlower = new Product(
            _companyId,
            "Red Rose Stem",
            "SKU-ROSE",
            ProductType.SingleFlower,
            ProductCategory.Roses,
            retailPrice: 20m,
            costPrice: 10m,
            description: "Fresh Red Rose");
        rawFlower.SetInventorySettings(true, false, 0);
        rawFlower.AdjustStock(initialStock);
        db.Products.Add(rawFlower);

        var recipe = new FloralRecipe(
            _companyId,
            "12 Red Roses Bouquet",
            "Bouquet",
            sellingPrice: 500m,
            laborCost: 50m);
        recipe.Components.Add(new RecipeComponent(recipe.Id, rawFlower.Id, rawFlower.Name, 12, 10m));
        db.FloralRecipes.Add(recipe);

        return (rawFlower, recipe);
    }

    [Fact]
    public async Task ProductionRun_DefaultProduceCreatesOneFinishedBatch()
    {
        await using var db = CreateDb();
        var (rawFlower, recipe) = SeedRecipeAndMaterials(db, initialStock: 50);
        await db.SaveChangesAsync();

        var prodService = CreateProductionService(db);
        var request = new ProductionRunRequest
        {
            RecipeId = recipe.Id,
            Quantity = 1,
            LocationId = _locationId,
            ExpectedExpiry = DateTime.UtcNow.AddDays(3).ToString("o"),
            OperatorName = "Florist"
        };

        var result = await prodService.CreateProductionRunAsync(_companyId, request);

        var batch = await db.FinishedGoodsBatches.SingleAsync(b => b.Id == result.BatchId);
        Assert.Equal(1, batch.QuantityProduced);
        Assert.Equal(1, batch.QuantityAvailable);
        Assert.Equal(FinishedBatchStatus.Active, batch.Status);
        Assert.Equal(recipe.Name, batch.RecipeName);
    }

    [Fact]
    public async Task ProductionDeductsExactlyOneRecipeUnit()
    {
        await using var db = CreateDb();
        var (rawFlower, recipe) = SeedRecipeAndMaterials(db, initialStock: 50);
        await db.SaveChangesAsync();

        var prodService = CreateProductionService(db);
        var request = new ProductionRunRequest
        {
            RecipeId = recipe.Id,
            Quantity = 1,
            LocationId = _locationId,
            ExpectedExpiry = DateTime.UtcNow.AddDays(3).ToString("o")
        };

        await prodService.CreateProductionRunAsync(_companyId, request);

        var updatedRaw = await db.Products.FindAsync(rawFlower.Id);
        // 50 - 12 = 38
        Assert.Equal(38, updatedRaw!.StockQuantity);
    }

    [Fact]
    public async Task ProductionCreatesUniqueFinishedBatch()
    {
        await using var db = CreateDb();
        var (rawFlower, recipe) = SeedRecipeAndMaterials(db, initialStock: 50);
        await db.SaveChangesAsync();

        var prodService = CreateProductionService(db);
        var request1 = new ProductionRunRequest
        {
            RecipeId = recipe.Id,
            Quantity = 1,
            LocationId = _locationId,
            ExpectedExpiry = DateTime.UtcNow.AddDays(3).ToString("o")
        };
        var request2 = new ProductionRunRequest
        {
            RecipeId = recipe.Id,
            Quantity = 1,
            LocationId = _locationId,
            ExpectedExpiry = DateTime.UtcNow.AddDays(3).ToString("o")
        };

        var result1 = await prodService.CreateProductionRunAsync(_companyId, request1);
        var result2 = await prodService.CreateProductionRunAsync(_companyId, request2);

        Assert.NotEqual(result1.BatchId, result2.BatchId);
        Assert.NotEqual(result1.BatchCode, result2.BatchCode);

        var batches = await db.FinishedGoodsBatches.Where(b => b.CompanyId == _companyId).ToListAsync();
        Assert.Equal(2, batches.Count);
        Assert.All(batches, b => Assert.Equal(1, b.QuantityProduced));
        Assert.All(batches, b => Assert.Equal(1, b.QuantityAvailable));
    }

    [Fact]
    public async Task ProductionTwoSeparateOperationsRemainIndependent()
    {
        await using var db = CreateDb();
        var (rawFlower, recipe) = SeedRecipeAndMaterials(db, initialStock: 50);
        await db.SaveChangesAsync();

        var prodService = CreateProductionService(db);
        var res1 = await prodService.CreateProductionRunAsync(_companyId, new ProductionRunRequest
        {
            RecipeId = recipe.Id,
            Quantity = 1,
            LocationId = _locationId,
            ExpectedExpiry = DateTime.UtcNow.AddDays(3).ToString("o")
        });
        var res2 = await prodService.CreateProductionRunAsync(_companyId, new ProductionRunRequest
        {
            RecipeId = recipe.Id,
            Quantity = 1,
            LocationId = _locationId,
            ExpectedExpiry = DateTime.UtcNow.AddDays(3).ToString("o")
        });

        // Deduct/expire Batch 1
        await prodService.DeductFromBatchAsync(_companyId, res1.BatchId, 1);

        var batch1 = await db.FinishedGoodsBatches.FindAsync(res1.BatchId);
        var batch2 = await db.FinishedGoodsBatches.FindAsync(res2.BatchId);

        Assert.Equal(0, batch1!.QuantityAvailable);
        Assert.Equal(1, batch2!.QuantityAvailable); // Batch 2 remains 1
    }

    [Fact]
    public async Task MaintenanceOneUnitDoesNotAffectSibling()
    {
        await using var db = CreateDb();
        var (rawFlower, recipe) = SeedRecipeAndMaterials(db, initialStock: 50);
        await db.SaveChangesAsync();

        var prodService = CreateProductionService(db);
        var res1 = await prodService.CreateProductionRunAsync(_companyId, new ProductionRunRequest
        {
            RecipeId = recipe.Id,
            Quantity = 1,
            LocationId = _locationId,
            ExpectedExpiry = DateTime.UtcNow.AddDays(3).ToString("o")
        });
        var res2 = await prodService.CreateProductionRunAsync(_companyId, new ProductionRunRequest
        {
            RecipeId = recipe.Id,
            Quantity = 1,
            LocationId = _locationId,
            ExpectedExpiry = DateTime.UtcNow.AddDays(3).ToString("o")
        });

        // Perform maintenance replacement on Batch 1 only
        var maintRequest = new MaintenanceRequest
        {
            FinishedBatchId = res1.BatchId,
            Notes = "Replaced 2 wilted stems",
            Replacements = new List<MaintenanceReplacementDto>
            {
                new()
                {
                    ProductId = rawFlower.Id,
                    ProductName = rawFlower.Name,
                    QuantityReplaced = 2,
                    Reason = "WiltedFlowerReplacement"
                }
            }
        };

        var maintLog = await prodService.CreateMaintenanceAsync(_companyId, maintRequest, Guid.NewGuid(), "Florist Lead");

        Assert.Equal(res1.BatchId, maintLog.FinishedBatchId);

        // Check maintenance logs for company
        var allLogs = await prodService.GetMaintenanceLogsAsync(_companyId);
        Assert.Single(allLogs);
        Assert.Equal(res1.BatchId, allLogs[0].FinishedBatchId);

        // Batch 2 has zero maintenance logs
        Assert.DoesNotContain(allLogs, l => l.FinishedBatchId == res2.BatchId);
    }

    [Fact]
    public async Task PosSaleOneUnitDeductsOnlyTargetBatch()
    {
        await using var db = CreateDb();
        var (rawFlower, recipe) = SeedRecipeAndMaterials(db, initialStock: 50);
        await db.SaveChangesAsync();

        var prodService = CreateProductionService(db);
        var res1 = await prodService.CreateProductionRunAsync(_companyId, new ProductionRunRequest
        {
            RecipeId = recipe.Id,
            Quantity = 1,
            LocationId = _locationId,
            ExpectedExpiry = DateTime.UtcNow.AddDays(3).ToString("o")
        });
        var res2 = await prodService.CreateProductionRunAsync(_companyId, new ProductionRunRequest
        {
            RecipeId = recipe.Id,
            Quantity = 1,
            LocationId = _locationId,
            ExpectedExpiry = DateTime.UtcNow.AddDays(3).ToString("o")
        });

        // POS sells Unit Batch 1
        var posRequest = new PosSaleSyncRequest
        {
            ClientSyncId = "pos-unit-sync-1",
            LocalOrderId = 801,
            Order = new PosSaleOrderSnapshot
            {
                OrderNo = "POS-UNIT-1",
                GrandTotalPaise = 50000,
                SubtotalPaise = 50000,
                CustomerName = "Walk-in",
                CustomerPhone = "9988776655"
            },
            Lines = new List<PosSaleLineSnapshot>
            {
                new()
                {
                    Id = 1,
                    CloudProductId = res1.BatchId,
                    Description = recipe.Name,
                    Qty = 1,
                    UnitPricePaise = 50000,
                    LineSubtotalPaise = 50000,
                    LineTotalPaise = 50000,
                    Source = "product"
                }
            },
            InventoryTransactions = new List<PosSaleInventoryTransactionSnapshot>
            {
                new()
                {
                    Id = 1,
                    LocalProductId = 1,
                    CloudProductId = res1.BatchId,
                    Qty = 1,
                    CreatedAt = DateTime.UtcNow
                }
            },
            Payments = new List<PosSalePaymentSnapshot>
            {
                new()
                {
                    Id = 1,
                    PaymentType = "Cash",
                    AmountPaise = 50000,
                    CreatedAt = DateTime.UtcNow
                }
            }
        };

        var posService = CreatePosService(db);
        var syncResult = await posService.SyncAsync(_companyId, Guid.NewGuid(), Guid.NewGuid(), "dev-1", posRequest, "hash-unit-1");

        Assert.Equal("completed", syncResult.SyncStatus);

        var batch1 = await db.FinishedGoodsBatches.FindAsync(res1.BatchId);
        var batch2 = await db.FinishedGoodsBatches.FindAsync(res2.BatchId);

        Assert.Equal(0, batch1!.QuantityAvailable); // Batch 1 deducted
        Assert.Equal(1, batch2!.QuantityAvailable); // Batch 2 remains available
    }

    [Fact]
    public async Task FinishedGoodsInventoryAggregation()
    {
        await using var db = CreateDb();
        var (rawFlower, recipe) = SeedRecipeAndMaterials(db, initialStock: 50);
        await db.SaveChangesAsync();

        var prodService = CreateProductionService(db);
        await prodService.CreateProductionRunAsync(_companyId, new ProductionRunRequest
        {
            RecipeId = recipe.Id,
            Quantity = 1,
            LocationId = _locationId,
            ExpectedExpiry = DateTime.UtcNow.AddDays(3).ToString("o")
        });
        await prodService.CreateProductionRunAsync(_companyId, new ProductionRunRequest
        {
            RecipeId = recipe.Id,
            Quantity = 1,
            LocationId = _locationId,
            ExpectedExpiry = DateTime.UtcNow.AddDays(3).ToString("o")
        });

        var activeBatches = await db.FinishedGoodsBatches
            .Where(b => b.CompanyId == _companyId && b.Status == FinishedBatchStatus.Active)
            .ToListAsync();

        var totalStock = activeBatches.Sum(b => b.QuantityAvailable);
        Assert.Equal(2, totalStock);
    }

    [Fact]
    public async Task ReverseProductionStillWorks()
    {
        await using var db = CreateDb();
        var (rawFlower, recipe) = SeedRecipeAndMaterials(db, initialStock: 50);
        await db.SaveChangesAsync();

        var prodService = CreateProductionService(db);
        var res = await prodService.CreateProductionRunAsync(_companyId, new ProductionRunRequest
        {
            RecipeId = recipe.Id,
            Quantity = 1,
            LocationId = _locationId,
            ExpectedExpiry = DateTime.UtcNow.AddDays(3).ToString("o")
        });

        var rawBeforeReversal = await db.Products.FindAsync(rawFlower.Id);
        Assert.Equal(38, rawBeforeReversal!.StockQuantity);

        // Reverse
        await prodService.ReverseProductionBatchAsync(_companyId, res.BatchId, "Mistaken production");

        var reversedBatch = await db.FinishedGoodsBatches.FindAsync(res.BatchId);
        Assert.Equal(FinishedBatchStatus.Reversed, reversedBatch!.Status);
        Assert.Equal(0, reversedBatch.QuantityAvailable);
        Assert.True(reversedBatch.IsReversed);

        var rawAfterReversal = await db.Products.FindAsync(rawFlower.Id);
        Assert.Equal(50, rawAfterReversal!.StockQuantity); // Restored!
    }
}
