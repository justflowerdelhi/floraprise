using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.EntityFrameworkCore.Storage;
using Microsoft.Extensions.Logging.Abstractions;
using Sumpooj.Application.Common;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Library;
using Sumpooj.Application.UseCases;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;
using Sumpooj.Infrastructure.Repositories;
using Xunit;

namespace Floraprise.Mobile.Tests;

public sealed class LibraryAllModulesTests
{
    private readonly string _databaseName = $"LibraryAllModulesTest_{Guid.NewGuid():N}";
    private readonly InMemoryDatabaseRoot _databaseRoot = new();

    private SumpoojDbContext CreateDb(Guid? companyId = null)
    {
        var options = new DbContextOptionsBuilder<SumpoojDbContext>()
            .UseInMemoryDatabase(_databaseName, _databaseRoot)
            .ConfigureWarnings(w => w.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options;

        return new SumpoojDbContext(options, new TestTenantContext(companyId ?? Guid.NewGuid()));
    }

    private (LibraryService Service, SumpoojDbContext Db, Guid CompanyId) CreateService(Guid? companyId = null)
    {
        var activeCompanyId = companyId ?? Guid.NewGuid();
        var db = CreateDb(activeCompanyId);
        var tenant = new TestTenantContext(activeCompanyId);

        var libraryCategoryRepo = new LibraryCategoryRepository(db);
        var libraryProductRepo = new LibraryProductRepository(db);
        var libraryRecipeRepo = new LibraryRecipeRepository(db);
        var libraryDesignRepo = new LibraryDesignRepository(db);
        var libraryCardRepo = new LibraryCardRepository(db);
        var libraryTutorialRepo = new LibraryTutorialRepository(db);
        var libraryFestivalRepo = new LibraryFestivalRepository(db);
        var libraryWeddingDateRepo = new LibraryWeddingDateRepository(db);
        var productRepo = new ProductRepository(db);
        var productCategoryRepo = new ProductCategoryRepository(db);
        var companyRecipeRepo = new FloralRecipeRepository(db);
        var companyDesignRepo = new CloudDesignRepository(db);
        var barcodeRepo = new BarcodeRepository(db);
        var barcodeService = new BarcodeService(productRepo, barcodeRepo);

        var service = new LibraryService(
            libraryCategoryRepo,
            libraryProductRepo,
            libraryRecipeRepo,
            libraryDesignRepo,
            libraryCardRepo,
            libraryTutorialRepo,
            libraryFestivalRepo,
            libraryWeddingDateRepo,
            productRepo,
            productCategoryRepo,
            companyRecipeRepo,
            companyDesignRepo,
            barcodeRepo,
            barcodeService,
            tenant,
            NullLogger<LibraryService>.Instance);

        return (service, db, activeCompanyId);
    }

    #region Design Tests

    [Fact]
    public async Task GetDesignsAsync_FiltersByOccasionStyleAndSearch()
    {
        var (service, db, _) = CreateService();

        var d1 = new LibraryDesign("Crimson Elegance", "crimson-elegance", "Luxury red rose bouquet", occasion: "Romance", style: "Modern", colorPalette: "Red, Gold", flowerTypes: "Red Rose, Eucalyptus");
        var d2 = new LibraryDesign("Pastel Sunrise", "pastel-sunrise", "Gentle pastel arrangement", occasion: "Birthday", style: "Boho", colorPalette: "Pink, Peach, Cream", flowerTypes: "Peonies, Hydrangea");
        var d3 = new LibraryDesign("Serene Sympathy Basket", "serene-sympathy", "White sympathy display", occasion: "Sympathy", style: "Classic", colorPalette: "White, Green", flowerTypes: "White Lily, Chrysanthemum");
        d3.Deactivate();

        db.LibraryDesigns.AddRange(d1, d2, d3);
        await db.SaveChangesAsync();

        // 1. Active filter
        var activeResult = await service.GetDesignsAsync(new LibraryDesignQueryRequest { IsActive = true });
        Assert.Equal(2, activeResult.TotalCount);

        // 2. Occasion filter
        var romanceResult = await service.GetDesignsAsync(new LibraryDesignQueryRequest { Occasion = "Romance" });
        Assert.Single(romanceResult.Items);
        Assert.Equal("Crimson Elegance", romanceResult.Items[0].Title);

        // 3. Search keywords filter
        var searchResult = await service.GetDesignsAsync(new LibraryDesignQueryRequest { Search = "Peonies" });
        Assert.Single(searchResult.Items);
        Assert.Equal("Pastel Sunrise", searchResult.Items[0].Title);
    }

    [Fact]
    public async Task ImportDesignAsync_CreatesCloudDesign_WithIdempotencyAndTenantIsolation()
    {
        var companyA = Guid.NewGuid();
        var companyB = Guid.NewGuid();

        var (serviceA, db, _) = CreateService(companyA);
        var (serviceB, _, _) = CreateService(companyB);

        var libraryDesign = new LibraryDesign("Velvet Dreams Bouquet", "velvet-dreams", "Premium cascading velvet flowers", imageUrl: "https://images.floraprise.com/velvet.jpg", occasion: "Anniversary", style: "Luxury", colorPalette: "Purple, Pink", flowerTypes: "Roses, Orchids");
        db.LibraryDesigns.Add(libraryDesign);
        await db.SaveChangesAsync();

        // 1. First import by Company A
        var importA1 = await serviceA.ImportDesignAsync(libraryDesign.Id);
        Assert.True(importA1.Success);
        Assert.False(importA1.AlreadyImported);
        Assert.Equal("B-0001", importA1.BouquetId);

        // 2. Idempotent second import by Company A
        var importA2 = await serviceA.ImportDesignAsync(libraryDesign.Id);
        Assert.True(importA2.Success);
        Assert.True(importA2.AlreadyImported);
        Assert.Equal(importA1.DesignId, importA2.DesignId);

        // 3. Independent import by Company B
        var importB = await serviceB.ImportDesignAsync(libraryDesign.Id);
        Assert.True(importB.Success);
        Assert.False(importB.AlreadyImported);
        Assert.NotEqual(importA1.DesignId, importB.DesignId);

        // 4. Verify Company A DB entity
        await using var readDbA = CreateDb(companyA);
        var cloudDesignA = await readDbA.CloudDesigns.FirstOrDefaultAsync(d => d.Id == importA1.DesignId);
        Assert.NotNull(cloudDesignA);
        Assert.Equal(companyA, cloudDesignA.CompanyId);
        Assert.Equal(libraryDesign.Id, cloudDesignA.SourceLibraryDesignId);
        Assert.Equal("https://images.floraprise.com/velvet.jpg", cloudDesignA.ImageReference);
        Assert.Contains("Velvet Dreams Bouquet", cloudDesignA.Description);
        Assert.Equal("needs_review", cloudDesignA.Status); // Needs pricing review
    }

    #endregion

    #region Card Template Tests

    [Fact]
    public async Task GetCardsAsync_And_GetOccasionsSummary()
    {
        var (service, db, _) = CreateService();

        var c1 = new LibraryCardTemplate("Heartfelt Birthday", "heartfelt-birthday", "Wishing you a wonderful birthday filled with love and joy!", occasion: "Birthday", tone: "Warm", language: "en");
        var c2 = new LibraryCardTemplate("Romantic Anniversary", "romantic-anniversary", "To the love of my life, every day with you is a blessing.", occasion: "Anniversary", tone: "Romantic", language: "en");
        var c3 = new LibraryCardTemplate("Birthday Fun", "birthday-fun", "Another year older, but definitely not wiser! Happy Birthday!", occasion: "Birthday", tone: "Funny", language: "en");

        db.LibraryCardTemplates.AddRange(c1, c2, c3);
        await db.SaveChangesAsync();

        // 1. Search by tone
        var romanticCards = await service.GetCardsAsync(new LibraryCardQueryRequest { Tone = "Romantic" });
        Assert.Single(romanticCards.Items);
        Assert.Equal("Romantic Anniversary", romanticCards.Items[0].Title);

        // 2. Occasions summary
        var occasions = await service.GetCardOccasionsSummaryAsync();
        Assert.Equal(2, occasions.Count);
        var birthdayOccasion = occasions.First(o => o.Occasion == "Birthday");
        Assert.Equal(2, birthdayOccasion.Count);
        var anniversaryOccasion = occasions.First(o => o.Occasion == "Anniversary");
        Assert.Equal(1, anniversaryOccasion.Count);
    }

    #endregion

    #region Tutorial Tests

    [Fact]
    public async Task GetTutorialsAsync_And_GetBySlug()
    {
        var (service, db, _) = CreateService();

        var t1 = new LibraryTutorial(
            title: "Spiral Hand-Tied Bouquet Technique",
            slug: "spiral-hand-tied-technique",
            contentMarkdown: "# Spiral Technique\nStep 1: Hold stem at 45 degrees...",
            summary: "Learn the essential florist spiral technique for hand-tied bouquets.",
            difficultyLevel: "Intermediate",
            estimatedReadingMinutes: 8,
            tags: "technique, hand-tied, spiral, bouquets");

        var t2 = new LibraryTutorial(
            title: "Flower Conditioning and Hydration",
            slug: "flower-conditioning-hydration",
            contentMarkdown: "# Conditioning Guide\nCut stems at 45 degree angle under clean water...",
            summary: "Maximize vase life and freshness with proper stem conditioning.",
            difficultyLevel: "Beginner",
            estimatedReadingMinutes: 4,
            tags: "care, hydration, conditioning, vase life");

        db.LibraryTutorials.AddRange(t1, t2);
        await db.SaveChangesAsync();

        // 1. Filter by difficulty
        var intermediate = await service.GetTutorialsAsync(new LibraryTutorialQueryRequest { DifficultyLevel = "Intermediate" });
        Assert.Single(intermediate.Items);
        Assert.Equal("Spiral Hand-Tied Bouquet Technique", intermediate.Items[0].Title);

        // 2. Query by slug
        var bySlug = await service.GetTutorialBySlugAsync("flower-conditioning-hydration");
        Assert.NotNull(bySlug);
        Assert.Equal("Flower Conditioning and Hydration", bySlug.Title);
        Assert.Contains("Cut stems at 45 degree angle", bySlug.ContentMarkdown);
    }

    #endregion

    #region Manifest Tests

    [Fact]
    public async Task GetManifestAsync_ReturnsFreshnessHashesAndCounts()
    {
        var (service, db, _) = CreateService();

        var cat = new LibraryCategory("Test Category", "test-cat");
        var prod = new LibraryProduct("Test Product", "test-prod", null, ProductType.SingleFlower, UnitOfMeasure.Stem);
        var recipe = new LibraryRecipe("Test Recipe", "test-recipe");
        var design = new LibraryDesign("Test Design", "test-design");
        var card = new LibraryCardTemplate("Test Card", "test-card", "Card message");
        var tutorial = new LibraryTutorial("Test Tutorial", "test-tutorial", "Markdown content");

        db.LibraryCategories.Add(cat);
        db.LibraryProducts.Add(prod);
        db.LibraryRecipes.Add(recipe);
        db.LibraryDesigns.Add(design);
        db.LibraryCardTemplates.Add(card);
        db.LibraryTutorials.Add(tutorial);
        await db.SaveChangesAsync();

        var manifest = await service.GetManifestAsync();

        Assert.NotNull(manifest);
        Assert.Equal(1, manifest.CategoriesCount);
        Assert.Equal(1, manifest.ProductsCount);
        Assert.Equal(1, manifest.RecipesCount);
        Assert.Equal(1, manifest.DesignsCount);
        Assert.Equal(1, manifest.CardsCount);
        Assert.Equal(1, manifest.TutorialsCount);
        Assert.False(string.IsNullOrWhiteSpace(manifest.GlobalManifestHash));
        Assert.True(manifest.GlobalManifestHash.Length >= 8);
    }

    #endregion

    #region Admin Management Tests

    [Fact]
    public async Task AdminCrud_FullLifecycleForDesignCardAndTutorial()
    {
        var (service, db, _) = CreateService();

        // 1. Create Design
        var createDesignReq = new CreateOrUpdateLibraryDesignRequest
        {
            Title = "Admin Sunset Rose",
            Slug = "admin-sunset-rose",
            Description = "Admin curated sunset roses",
            Occasion = "Celebration",
            Style = "Vibrant"
        };
        var createdDesign = await service.AdminCreateDesignAsync(createDesignReq);
        Assert.Equal("Admin Sunset Rose", createdDesign.Title);
        Assert.Equal("admin-sunset-rose", createdDesign.Slug);

        // Update Design
        createDesignReq.Title = "Admin Sunset Rose Deluxe";
        var updatedDesign = await service.AdminUpdateDesignAsync(createdDesign.Id, createDesignReq);
        Assert.Equal("Admin Sunset Rose Deluxe", updatedDesign.Title);

        // Toggle Status
        await service.AdminToggleDesignStatusAsync(createdDesign.Id, false);
        var toggledDesign = await service.GetDesignByIdAsync(createdDesign.Id);
        Assert.NotNull(toggledDesign);
        Assert.False(toggledDesign.IsActive);

        // Delete Design
        await service.AdminDeleteDesignAsync(createdDesign.Id);
        var deletedDesign = await service.GetDesignByIdAsync(createdDesign.Id);
        Assert.Null(deletedDesign);

        // 2. Create Card
        var createCardReq = new CreateOrUpdateLibraryCardRequest
        {
            Title = "Mother's Day Wish",
            Slug = "mothers-day-wish",
            Content = "Thank you Mom for always being there.",
            Occasion = "Mother's Day",
            Tone = "Heartfelt"
        };
        var createdCard = await service.AdminCreateCardAsync(createCardReq);
        Assert.Equal("Mother's Day Wish", createdCard.Title);

        // Toggle Card Status
        await service.AdminToggleCardStatusAsync(createdCard.Id, false);
        var toggledCard = await service.GetCardByIdAsync(createdCard.Id);
        Assert.NotNull(toggledCard);
        Assert.False(toggledCard.IsActive);

        // 3. Create Tutorial
        var createTutReq = new CreateOrUpdateLibraryTutorialRequest
        {
            Title = "Oasis Foam Masterclass",
            Slug = "oasis-foam-masterclass",
            ContentMarkdown = "# Oasis Foam Soaking\nNever push foam into water; let it float naturally.",
            DifficultyLevel = "Beginner"
        };
        var createdTut = await service.AdminCreateTutorialAsync(createTutReq);
        Assert.Equal("Oasis Foam Masterclass", createdTut.Title);

        // Toggle Tutorial Status
        await service.AdminToggleTutorialStatusAsync(createdTut.Id, false);
        var toggledTut = await service.GetTutorialByIdAsync(createdTut.Id);
        Assert.NotNull(toggledTut);
        Assert.False(toggledTut.IsActive);
    }

    #endregion

    #region Festival & Wedding Date Tests

    [Fact]
    public async Task GetFestivalsAsync_ReturnsSeededAndFilteredFestivals()
    {
        var (service, db, _) = CreateService();
        await Sumpooj.Infrastructure.LibraryDataSeeder.SeedAsync(db);

        // Search for Valentine
        var result = await service.GetFestivalsAsync(new LibraryFestivalQueryRequest { Search = "Valentine" });
        Assert.NotEmpty(result.Items);
        Assert.Contains(result.Items, f => f.Name.Contains("Valentine"));

        // Filter by month (February)
        var febFestivals = await service.GetFestivalsAsync(new LibraryFestivalQueryRequest { Month = 2 });
        Assert.NotEmpty(febFestivals.Items);
        Assert.All(febFestivals.Items, f => Assert.Equal(2, f.Month));

        // Get by ID
        var first = febFestivals.Items.First();
        var detailed = await service.GetFestivalByIdAsync(first.Id);
        Assert.NotNull(detailed);
        Assert.Equal(first.Name, detailed.Name);
    }

    [Fact]
    public async Task GetWeddingDatesAsync_ReturnsSeededAndFilteredMuhurats()
    {
        var (service, db, _) = CreateService();
        await Sumpooj.Infrastructure.LibraryDataSeeder.SeedAsync(db);

        // All wedding dates
        var result = await service.GetWeddingDatesAsync(new LibraryWeddingDateQueryRequest());
        Assert.NotEmpty(result.Items);
        Assert.True(result.TotalCount >= 20);

        // Filter by season (Winter)
        var winterDates = await service.GetWeddingDatesAsync(new LibraryWeddingDateQueryRequest { Season = "Winter" });
        Assert.NotEmpty(winterDates.Items);
        Assert.All(winterDates.Items, w => Assert.Equal("Winter", w.Season));

        // Filter by Peak demand
        var peakDates = await service.GetWeddingDatesAsync(new LibraryWeddingDateQueryRequest { DemandLevel = "Peak" });
        Assert.NotEmpty(peakDates.Items);
        Assert.All(peakDates.Items, w => Assert.Equal("Peak", w.DemandLevel));

        // Get by ID
        var first = peakDates.Items.First();
        var detailed = await service.GetWeddingDateByIdAsync(first.Id);
        Assert.NotNull(detailed);
        Assert.Equal(first.Title, detailed.Title);
    }

    #endregion

    private sealed class TestTenantContext : ITenantContext
    {
        public TestTenantContext(Guid companyId) => CompanyId = companyId;
        public Guid? CompanyId { get; }
        public bool IsPlatformUser => false;
        public string? Region => "IN";
    }
}
