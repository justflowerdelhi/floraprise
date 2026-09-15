using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Common;
using Sumpooj.Application.DayClose;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Inventory;
using Sumpooj.Application.Production;
using Sumpooj.Application.UseCases;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;
using Sumpooj.Infrastructure.Repositories;

namespace Sumpooj.Infrastructure.Tests.Reporting;

public class CloudRemainingReportsParityTests
{
    private sealed class FakeTenantContext : ITenantContext
    {
        public FakeTenantContext(Guid companyId) => CompanyId = companyId;
        public Guid? CompanyId { get; }
        public bool IsPlatformUser => false;
        public string? Region => null;
    }

    private static SumpoojDbContext CreateDb(Guid companyId)
    {
        var options = new DbContextOptionsBuilder<SumpoojDbContext>()
            .UseInMemoryDatabase($"CloudReportsParity_{Guid.NewGuid():N}")
            .Options;
        return new SumpoojDbContext(options, new FakeTenantContext(companyId));
    }

    // ─── 1. Day Closing Parity Tests ──────────────────────────────

    [Fact]
    public async Task DayClose_CloseAsync_CapturesCashExpenses_AndGetHistoryAppliesFiltersAndDefaults()
    {
        var companyId = Guid.NewGuid();
        var userId = Guid.NewGuid();
        await using var db = CreateDb(companyId);

        var defaultLoc = new Location(companyId, "Main Branch", "MAIN", LocationType.Store, "123 Main St");
        defaultLoc.SetAsDefault();
        var otherLoc = new Location(companyId, "Other Branch", "OTHER", LocationType.Warehouse, "456 Side St");
        db.Locations.AddRange(defaultLoc, otherLoc);

        var today = DateTime.UtcNow.Date;
        var todayUtc = DateTime.SpecifyKind(today, DateTimeKind.Utc);

        // Add cash book expense entry for today
        var expenseEntry = new CashBookEntry(
            companyId,
            todayUtc,
            CashBookTransactionType.CashExpense,
            "Floral wire & tape",
            250.75m,
            0m,
            250.75m,
            0m);
        db.CashBookEntries.Add(expenseEntry);
        await db.SaveChangesAsync();

        var dayCloseRepo = new DayCloseRepository(db);
        var orderRepo = new OrderRepository(db);
        var paymentRepo = new PaymentRepository(db);
        var locationRepo = new LocationRepository(db);
        var dayCloseService = new DayCloseService(
            dayCloseRepo,
            orderRepo,
            paymentRepo,
            locationRepo,
            dayCloseRepo);

        // Act 1: Close day for default location
        var closeRequest = new CloseDayRequest
        {
            LocationId = defaultLoc.Id,
            BusinessDate = todayUtc,
            ActualCash = 500m,
            Notes = "Closed with ₹250.75 expenses"
        };
        var closedId = await dayCloseService.CloseAsync(companyId, closeRequest, userId);

        // Verify entity recorded CashExpenses
        var closedEntity = await db.DayCloses.FindAsync(closedId);
        Assert.NotNull(closedEntity);
        Assert.Equal(250.75m, closedEntity.CashExpenses);
        Assert.Equal(500m, closedEntity.ActualCash);

        // Act 2: Seed older day close for another date
        var pastDate = todayUtc.AddDays(-10);
        var pastClose = new Domain.Entities.DayClose(companyId, defaultLoc.Id, pastDate, userId);
        pastClose.SetCashExpenses(120m);
        pastClose.SetCashCount(800m);
        db.DayCloses.Add(pastClose);
        await db.SaveChangesAsync();

        // Query history with locationId = null -> should resolve default location
        var historyWithDefault = await dayCloseService.GetHistoryAsync(companyId, locationId: null, days: 30);
        Assert.Equal(2, historyWithDefault.Count);
        var todayItem = historyWithDefault.First(h => h.Id == closedId);
        Assert.Equal(250.75m, todayItem.CashExpenses);
        Assert.Equal(defaultLoc.Id, todayItem.LocationId);

        // Query history with strict date range covering only today
        var historyDateFiltered = await dayCloseService.GetHistoryAsync(
            companyId,
            defaultLoc.Id,
            startDate: todayUtc,
            endDate: todayUtc);
        Assert.Single(historyDateFiltered);
        Assert.Equal(closedId, historyDateFiltered[0].Id);

        // Query history for other location -> should return empty
        var historyOtherLoc = await dayCloseService.GetHistoryAsync(
            companyId,
            otherLoc.Id,
            startDate: todayUtc.AddDays(-30),
            endDate: todayUtc);
        Assert.Empty(historyOtherLoc);
    }

    // ─── 2. Wastage Adjustment Parity Tests ───────────────────────

    [Fact]
    public async Task WastageReport_SearchAdjustments_WhenWastageOnly_FiltersCorrectReasonsAndProjectsMetadata()
    {
        var companyId = Guid.NewGuid();
        var userId = Guid.NewGuid();
        var tenant = new FakeTenantContext(companyId);
        await using var db = CreateDb(companyId);

        var productRose = new Product(
            companyId,
            "Red Rose Premium",
            "ROSE-RED",
            ProductType.SingleFlower,
            ProductCategory.Roses,
            50m,
            25m,
            null);
        productRose.SetInventorySettings(true, false, 10);
        productRose.SetUnitOfMeasure(UnitOfMeasure.Stem);

        var productLily = new Product(
            companyId,
            "White Oriental Lily",
            "LILY-WHT",
            ProductType.SingleFlower,
            ProductCategory.Lilies,
            80m,
            40m,
            null);
        productLily.SetUnitOfMeasure(UnitOfMeasure.Stem);

        db.Products.AddRange(productRose, productLily);
        await db.SaveChangesAsync();

        // Seed adjustments: 5 wastage categories (negative) and 2 non-wastage categories
        var wastageDamaged = new InventoryAdjustment(
            companyId,
            productRose.Id,
            null,
            AdjustmentType.Damaged,
            -5,
            25m,
            "Damaged in transit",
            userId);
        wastageDamaged.AddNotes("Supplier: Bharat Florals | Dropped and damaged during unloading");

        var wastageSpoiled = new InventoryAdjustment(
            companyId,
            productLily.Id,
            null,
            AdjustmentType.Spoiled,
            -3,
            40m,
            "Spoiled blooms",
            userId);
        wastageSpoiled.AddNotes("Supplier: Himalayan Blooms | Petals wilted due to heat");

        var wastageExpired = new InventoryAdjustment(
            companyId,
            productRose.Id,
            null,
            AdjustmentType.Expired,
            -2,
            25m,
            "Expired shelf life",
            userId);

        var wastageLost = new InventoryAdjustment(
            companyId,
            productLily.Id,
            null,
            AdjustmentType.Lost,
            -1,
            40m,
            "Lost item",
            userId);

        var wastageTheft = new InventoryAdjustment(
            companyId,
            productRose.Id,
            null,
            AdjustmentType.Theft,
            -4,
            25m,
            "Theft loss",
            userId);

        var nonWastageFound = new InventoryAdjustment(
            companyId,
            productRose.Id,
            null,
            AdjustmentType.Found,
            10,
            25m,
            "Found extra bundle during audit",
            userId);

        var nonWastageCorrection = new InventoryAdjustment(
            companyId,
            productLily.Id,
            null,
            AdjustmentType.Correction,
            2,
            40m,
            "Count adjustment correction",
            userId);

        db.InventoryAdjustments.AddRange(
            wastageDamaged,
            wastageSpoiled,
            wastageExpired,
            wastageLost,
            wastageTheft,
            nonWastageFound,
            nonWastageCorrection);
        await db.SaveChangesAsync();

        var inventoryService = new InventoryService(
            new ProductBatchRepository(db),
            new InventoryAdjustmentRepository(db),
            new ProductRepository(db),
            new BarcodeRepository(db),
            tenant,
            new InventoryLedgerRepository(db));

        // Act: Search with WastageOnly = true
        var wastageResult = await inventoryService.SearchAdjustmentsAsync(new AdjustmentSearchRequest
        {
            WastageOnly = true
        });

        // Assert: Only 5 wastage items returned, positive adjustments excluded
        Assert.Equal(5, wastageResult.Items.Count);
        Assert.All(wastageResult.Items, item => Assert.True(item.Quantity < 0));

        // Verify metadata projection: Category, Unit, SupplierName
        var damagedDto = wastageResult.Items.First(i => i.Id == wastageDamaged.Id);
        Assert.Equal("Roses", damagedDto.Category);
        Assert.Equal("Stem", damagedDto.Unit);
        Assert.Equal("Bharat Florals", damagedDto.SupplierName);

        var spoiledDto = wastageResult.Items.First(i => i.Id == wastageSpoiled.Id);
        Assert.Equal("Lilies", spoiledDto.Category);
        Assert.Equal("Stem", spoiledDto.Unit);
        Assert.Equal("Himalayan Blooms", spoiledDto.SupplierName);

        var expiredDto = wastageResult.Items.First(i => i.Id == wastageExpired.Id);
        Assert.Equal("Roses", expiredDto.Category);
        Assert.Equal("Stem", expiredDto.Unit);
        Assert.Null(expiredDto.SupplierName); // No "Supplier:" in notes
    }

    // ─── 3. Production Report, Consumption & Reversal Tests ───────

    [Fact]
    public async Task ProductionRun_DeductsRawStock_CreatesFinishedGoodsBatch_AndWritesInventoryLedger()
    {
        var companyId = Guid.NewGuid();
        var locationId = Guid.NewGuid();
        await using var db = CreateDb(companyId);

        // 1. Create raw materials
        var rose = new Product(
            companyId,
            "Red Rose Stem",
            "RAW-ROSE",
            ProductType.SingleFlower,
            ProductCategory.Roses,
            30m,
            12m,
            null);
        rose.SetInventorySettings(true, false, 5);
        rose.AdjustStock(100);

        var ribbon = new Product(
            companyId,
            "Silk Ribbon Red",
            "RAW-RIBBON",
            ProductType.SingleFlower,
            ProductCategory.Other,
            10m,
            4m,
            null);
        ribbon.SetInventorySettings(true, false, 5);
        ribbon.AdjustStock(50);

        db.Products.AddRange(rose, ribbon);

        // 2. Create recipe with components
        var recipe = new FloralRecipe(companyId, "Classic Rose Bouquet", "Bouquets", 499m, 50m);
        recipe.Components.Add(new RecipeComponent(recipe.Id, rose.Id, rose.Name, 5, 12m));
        recipe.Components.Add(new RecipeComponent(recipe.Id, ribbon.Id, ribbon.Name, 1, 4m));
        db.FloralRecipes.Add(recipe);
        await db.SaveChangesAsync();

        var uow = new UnitOfWork(db);
        var prodService = CreateProductionService(db, uow);

        // Act: Create production run for 10 bouquets
        var request = new ProductionRunRequest
        {
            RecipeId = recipe.Id,
            Quantity = 10,
            LocationId = locationId,
            ExpectedExpiry = DateTime.UtcNow.AddDays(7).ToString("O"),
            OperatorName = "Florist Priya"
        };
        var runResult = await prodService.CreateProductionRunAsync(companyId, request);

        // Retrieve mapped batch details
        var batchDto = await prodService.GetFinishedBatchByIdAsync(companyId, runResult.BatchId);
        Assert.NotNull(batchDto);
        Assert.Equal(10, batchDto.QuantityProduced);
        Assert.Equal(10, batchDto.QuantityAvailable);
        Assert.Equal("Florist Priya", batchDto.OperatorName);
        Assert.False(batchDto.IsReversed);
        Assert.Equal("Active", batchDto.Status);

        // Cost = (5 * 12 + 1 * 4) * 10 = (60 + 4) * 10 = 640 + (50 labor * 10) = 1140
        Assert.Equal(1140m, batchDto.TotalCost);

        // Verify raw stock was deducted atomically
        var updatedRose = await db.Products.FindAsync(rose.Id);
        var updatedRibbon = await db.Products.FindAsync(ribbon.Id);
        Assert.Equal(50, updatedRose!.StockQuantity); // 100 - (5 * 10) = 50
        Assert.Equal(40, updatedRibbon!.StockQuantity); // 50 - (1 * 10) = 40

        // Verify InventoryLedger records created with ReferenceType = "PRODUCTION"
        var ledgers = await db.InventoryLedgers
            .Where(l => l.CompanyId == companyId && l.ReferenceType == "PRODUCTION")
            .ToListAsync();
        Assert.Equal(2, ledgers.Count);
        Assert.Contains(ledgers, l => l.ProductId == rose.Id && l.QuantityChange == -50);
        Assert.Contains(ledgers, l => l.ProductId == ribbon.Id && l.QuantityChange == -10);

        // Verify GetFinishedBatchByIdAsync returns populated Consumptions breakdown
        Assert.Equal(2, batchDto.Consumptions.Count);
        var roseConsumption = batchDto.Consumptions.First(c => c.RawProductId == rose.Id);
        Assert.Equal(50, roseConsumption.Quantity);
        Assert.Equal(12m, roseConsumption.UnitCost);
        Assert.Equal(600m, roseConsumption.TotalCost);

        var ribbonConsumption = batchDto.Consumptions.First(c => c.RawProductId == ribbon.Id);
        Assert.Equal(10, ribbonConsumption.Quantity);
        Assert.Equal(4m, ribbonConsumption.UnitCost);
        Assert.Equal(40m, ribbonConsumption.TotalCost);
    }

    [Fact]
    public async Task ProductionReversal_RestoresRawStock_WritesReversalLedger_AndMarksBatchReversed()
    {
        var companyId = Guid.NewGuid();
        var locationId = Guid.NewGuid();
        await using var db = CreateDb(companyId);

        var rose = new Product(
            companyId,
            "Red Rose Stem",
            "RAW-ROSE",
            ProductType.SingleFlower,
            ProductCategory.Roses,
            30m,
            12m,
            null);
        rose.SetInventorySettings(true, false, 5);
        rose.AdjustStock(100);

        var recipe = new FloralRecipe(companyId, "Rose Bunch", "Bouquets", 300m, 20m);
        recipe.Components.Add(new RecipeComponent(recipe.Id, rose.Id, rose.Name, 4, 12m));
        db.Products.Add(rose);
        db.FloralRecipes.Add(recipe);
        await db.SaveChangesAsync();

        var uow = new UnitOfWork(db);
        var prodService = CreateProductionService(db, uow);

        // Produce 5 bunches -> uses 20 roses -> remaining stock 80
        var runResult = await prodService.CreateProductionRunAsync(companyId, new ProductionRunRequest
        {
            RecipeId = recipe.Id,
            Quantity = 5,
            LocationId = locationId,
            ExpectedExpiry = DateTime.UtcNow.AddDays(7).ToString("O"),
            OperatorName = "Florist Raj"
        });

        var stockAfterProduce = (await db.Products.FindAsync(rose.Id))!.StockQuantity;
        Assert.Equal(80, stockAfterProduce);

        // Act: Reverse production batch
        await prodService.ReverseProductionBatchAsync(
            companyId,
            runResult.BatchId,
            "Customer cancelled wedding order");

        var reversedBatch = await prodService.GetFinishedBatchByIdAsync(companyId, runResult.BatchId);

        // Assert: Batch marked reversed
        Assert.NotNull(reversedBatch);
        Assert.True(reversedBatch.IsReversed);
        Assert.Equal("Reversed", reversedBatch.Status);
        Assert.Equal("Customer cancelled wedding order", reversedBatch.ReversalNote);
        Assert.NotNull(reversedBatch.ReversedAt);

        // Assert: Raw material stock restored back to 100
        var restoredRose = await db.Products.FindAsync(rose.Id);
        Assert.Equal(100, restoredRose!.StockQuantity);

        // Assert: InventoryLedger has PRODUCTION_REVERSAL entry
        var reversalLedger = await db.InventoryLedgers
            .FirstOrDefaultAsync(l => l.CompanyId == companyId && l.ReferenceType == "PRODUCTION_REVERSAL");
        Assert.NotNull(reversalLedger);
        Assert.Equal(rose.Id, reversalLedger.ProductId);
        Assert.Equal(20, reversalLedger.QuantityChange); // Restored +20
    }

    [Fact]
    public async Task ProductionReversal_WhenAlreadyReversedOrPartiallyConsumed_ThrowsInvalidOperationException()
    {
        var companyId = Guid.NewGuid();
        var locationId = Guid.NewGuid();
        await using var db = CreateDb(companyId);

        var flower = new Product(
            companyId,
            "Carnation",
            "CARN-01",
            ProductType.SingleFlower,
            ProductCategory.Carnations,
            20m,
            8m,
            null);
        flower.SetInventorySettings(true, false, 5);
        flower.AdjustStock(50);

        var recipe = new FloralRecipe(companyId, "Carnation Trio", "Bouquets", 150m, 10m);
        recipe.Components.Add(new RecipeComponent(recipe.Id, flower.Id, flower.Name, 3, 8m));
        db.Products.Add(flower);
        db.FloralRecipes.Add(recipe);
        await db.SaveChangesAsync();

        var uow = new UnitOfWork(db);
        var prodService = CreateProductionService(db, uow);

        var runResult = await prodService.CreateProductionRunAsync(companyId, new ProductionRunRequest
        {
            RecipeId = recipe.Id,
            Quantity = 4,
            LocationId = locationId,
            ExpectedExpiry = DateTime.UtcNow.AddDays(7).ToString("O")
        });

        // 1. Test partially consumed rejection
        var batchEntity = await db.FinishedGoodsBatches.FindAsync(runResult.BatchId);
        batchEntity!.Deduct(1); // Consumed 1 bouquet -> QuantityAvailable = 3 < QuantityProduced = 4
        await db.SaveChangesAsync();

        var exConsumed = await Assert.ThrowsAsync<InvalidOperationException>(() =>
            prodService.ReverseProductionBatchAsync(companyId, runResult.BatchId, "Test"));
        Assert.Contains("sold or consumed", exConsumed.Message);

        // Reset and test already reversed
        await using (var freshDb = CreateDb(companyId))
        {
            var flower2 = new Product(companyId, "Tulip", "TULIP-01", ProductType.SingleFlower, ProductCategory.Other, 25m, 10m, null);
            flower2.SetInventorySettings(true, false, 5);
            flower2.AdjustStock(50);
            var recipe2 = new FloralRecipe(companyId, "Tulip Duo", "Bouquets", 200m, 10m);
            recipe2.Components.Add(new RecipeComponent(recipe2.Id, flower2.Id, flower2.Name, 2, 10m));
            freshDb.Products.Add(flower2);
            freshDb.FloralRecipes.Add(recipe2);
            await freshDb.SaveChangesAsync();

            var uow2 = new UnitOfWork(freshDb);
            var prodService2 = CreateProductionService(freshDb, uow2);
            var run2 = await prodService2.CreateProductionRunAsync(companyId, new ProductionRunRequest
            {
                RecipeId = recipe2.Id,
                Quantity = 3,
                LocationId = locationId,
                ExpectedExpiry = DateTime.UtcNow.AddDays(7).ToString("O")
            });

            // First reversal succeeds
            await prodService2.ReverseProductionBatchAsync(companyId, run2.BatchId, "Reversing first time");

            // Second reversal throws already reversed
            var exAlready = await Assert.ThrowsAsync<InvalidOperationException>(() =>
                prodService2.ReverseProductionBatchAsync(companyId, run2.BatchId, "Reversing second time"));
            Assert.Contains("already reversed", exAlready.Message);
        }
    }

    [Fact]
    public async Task ProductionReport_GetFinishedBatches_FiltersByDateRangeAndBatchCode()
    {
        var companyId = Guid.NewGuid();
        var recipeId = Guid.NewGuid();
        var locationId = Guid.NewGuid();
        await using var db = CreateDb(companyId);

        var todayUtc = DateTime.SpecifyKind(DateTime.UtcNow.Date, DateTimeKind.Utc);
        var yesterdayUtc = todayUtc.AddDays(-1);
        var oldUtc = todayUtc.AddDays(-10);

        var batch1 = new FinishedGoodsBatch(companyId, recipeId, "Rose Bouquet", "FGB-ROSE-001", "890001", 5, todayUtc.AddDays(5), locationId, "Main Store", 400m);
        typeof(FinishedGoodsBatch).GetProperty("ProducedAt")!.SetValue(batch1, todayUtc);

        var batch2 = new FinishedGoodsBatch(companyId, recipeId, "Lily Bouquet", "FGB-LILY-002", "890002", 3, yesterdayUtc.AddDays(5), locationId, "Main Store", 300m);
        typeof(FinishedGoodsBatch).GetProperty("ProducedAt")!.SetValue(batch2, yesterdayUtc);

        var batch3 = new FinishedGoodsBatch(companyId, recipeId, "Orchid Bouquet", "FGB-ORCHID-003", "890003", 2, oldUtc.AddDays(5), locationId, "Main Store", 350m);
        typeof(FinishedGoodsBatch).GetProperty("ProducedAt")!.SetValue(batch3, oldUtc);

        db.FinishedGoodsBatches.AddRange(batch1, batch2, batch3);
        await db.SaveChangesAsync();

        var prodService = CreateProductionService(db, new UnitOfWork(db));

        // Filter by batchCode substring
        var filterCode = await prodService.GetFinishedBatchesAsync(companyId, batchCode: "ROSE");
        Assert.Single(filterCode);
        Assert.Equal("FGB-ROSE-001", filterCode[0].BatchCode);

        // Filter by date range covering yesterday and today
        var filterDates = await prodService.GetFinishedBatchesAsync(
            companyId,
            startDate: yesterdayUtc,
            endDate: todayUtc);
        Assert.Equal(2, filterDates.Count);
        Assert.Contains(filterDates, b => b.BatchCode == "FGB-ROSE-001");
        Assert.Contains(filterDates, b => b.BatchCode == "FGB-LILY-002");
    }

    // ─── Helpers ──────────────────────────────────────────────────

    private static ProductionService CreateProductionService(SumpoojDbContext db, IUnitOfWork uow)
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
            uow);
    }
}
