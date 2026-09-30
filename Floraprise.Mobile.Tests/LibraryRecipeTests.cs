using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.EntityFrameworkCore.Storage;
using Microsoft.Extensions.Logging.Abstractions;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Library;
using Sumpooj.Application.UseCases;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;
using Sumpooj.Infrastructure.Repositories;
using Xunit;

namespace Floraprise.Mobile.Tests;

public sealed class LibraryRecipeTests
{
    private readonly string _databaseName = $"LibraryRecipeTest_{Guid.NewGuid():N}";
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


    [Fact]
    public async Task GetRecipesAsync_ReturnsPagedAndFilteredResults()
    {
        var (service, db, _) = CreateService();

        var category = new LibraryCategory("Wedding Arrangements", "wedding-arrangements", null, null, null, null, 1);
        db.LibraryCategories.Add(category);
        await db.SaveChangesAsync();

        var r1 = new LibraryRecipe("Royal Bridal Bouquet", "royal-bridal-bouquet", "Cascade bridal bouquet with roses and lilies", category.Id, "/images/bridal.jpg", 1, "Piece", "1. Arrange roses. 2. Add lilies.", "Keep cool");
        var r2 = new LibraryRecipe("Sweetheart Table Centerpiece", "sweetheart-centerpiece", "Low floral arrangement for sweetheart table", category.Id, null, 1, "Piece", "1. Foam setup. 2. Insert greenery.");
        var r3 = new LibraryRecipe("Classic Birthday Hand-tied", "birthday-handtied", "Simple hand-tied wrap", null, null, 1, "Piece");
        r3.Deactivate();

        db.LibraryRecipes.AddRange(r1, r2, r3);
        await db.SaveChangesAsync();

        // 1. Active filter
        var activeResult = await service.GetRecipesAsync(new LibraryRecipeQueryRequest { IsActive = true });
        Assert.Equal(2, activeResult.TotalCount);

        // 2. Search query filter
        var searchResult = await service.GetRecipesAsync(new LibraryRecipeQueryRequest { Search = "Bridal" });
        Assert.Single(searchResult.Items);
        Assert.Equal("Royal Bridal Bouquet", searchResult.Items[0].Name);

        // 3. Category filter
        var catResult = await service.GetRecipesAsync(new LibraryRecipeQueryRequest { CategoryId = category.Id });
        Assert.Equal(2, catResult.TotalCount);
    }

    [Fact]
    public async Task GetRecipeByIdAsync_ReturnsCompleteRecipeDetail_WithItemsAndProducts()
    {
        var (service, db, _) = CreateService();

        var roseProduct = new LibraryProduct("Red Rose", "red-rose", null, ProductType.SingleFlower, UnitOfMeasure.Stem, "ROSE-RED");
        db.LibraryProducts.Add(roseProduct);
        await db.SaveChangesAsync();

        var recipe = new LibraryRecipe("Dozen Red Roses Bouquet", "dozen-red-roses-bouquet", "Standard 12 red roses bouquet", null, null, 1, "Bouquet", "Assemble 12 stems with gypsophila.", "Check hydration");
        db.LibraryRecipes.Add(recipe);
        await db.SaveChangesAsync();

        var item1 = new LibraryRecipeItem(recipe.Id, "Red Rose", 12, "Stem", roseProduct.Id, "Long stem premium", 1);
        var item2 = new LibraryRecipeItem(recipe.Id, "Gypsophila Filler", 2, "Bunch", null, "White filler", 2);
        db.LibraryRecipeItems.AddRange(item1, item2);
        await db.SaveChangesAsync();

        var detail = await service.GetRecipeByIdAsync(recipe.Id);

        Assert.NotNull(detail);
        Assert.Equal("Dozen Red Roses Bouquet", detail.Name);
        Assert.Equal(2, detail.Items.Count);

        var firstItem = detail.Items.First(i => i.ProductName == "Red Rose");
        Assert.Equal(12, firstItem.Quantity);
        Assert.Equal(roseProduct.Id, firstItem.LibraryProductId);
        Assert.Equal("Red Rose", firstItem.LibraryProductName);

        var secondItem = detail.Items.First(i => i.ProductName == "Gypsophila Filler");
        Assert.Equal(2, secondItem.Quantity);
        Assert.Null(secondItem.LibraryProductId);
    }

    [Fact]
    public async Task ImportRecipeAsync_CreatesCompanyRecipe_WithProvenanceAndZeroOperationalDefaults()
    {
        var (service, db, companyId) = CreateService();

        // 1. Create a Library Product and a company-imported Product
        var libraryProduct = new LibraryProduct("Red Rose", "red-rose", null, ProductType.SingleFlower, UnitOfMeasure.Stem, "ROSE-RED");
        db.LibraryProducts.Add(libraryProduct);
        await db.SaveChangesAsync();

        var companyProduct = new Product(companyId, "Company Red Rose", "ROSE-RED-LOCAL", ProductType.SingleFlower, ProductCategory.Other, 150m, 60m, null);
        companyProduct.SetSourceLibraryProductId(libraryProduct.Id);
        db.Products.Add(companyProduct);
        await db.SaveChangesAsync();

        // 2. Create Library Recipe referencing the Library Product and a snapshot-only item
        var libraryRecipe = new LibraryRecipe("Romantic Rose Trio", "romantic-rose-trio", "3 roses with ribbon", null, "/images/trio.jpg", 1, "Piece");
        db.LibraryRecipes.Add(libraryRecipe);
        await db.SaveChangesAsync();

        var item1 = new LibraryRecipeItem(libraryRecipe.Id, "Red Rose", 3, "Stem", libraryProduct.Id, null, 1);
        var item2 = new LibraryRecipeItem(libraryRecipe.Id, "Satin Ribbon 1m", 1, "Meter", null, "Red ribbon", 2);
        db.LibraryRecipeItems.AddRange(item1, item2);
        await db.SaveChangesAsync();

        // 3. Import
        var importResult = await service.ImportRecipeAsync(libraryRecipe.Id);

        Assert.True(importResult.Success);
        Assert.False(importResult.AlreadyImported);
        Assert.NotNull(importResult.Recipe);
        Assert.Equal("Romantic Rose Trio", importResult.Recipe.Name);
        Assert.Equal(libraryRecipe.Id, importResult.Recipe.SourceLibraryRecipeId);
        Assert.Equal(0m, importResult.Recipe.SellingPrice);
        Assert.Equal(0m, importResult.Recipe.LaborCost);
        Assert.Equal(2, importResult.Recipe.Components.Count);

        // Verify company product was linked to item 1
        var matchedComponent = importResult.Recipe.Components.First(c => c.ProductName == "Company Red Rose");
        Assert.Equal(companyProduct.Id, matchedComponent.ProductId);
        Assert.Equal(3, matchedComponent.QuantityRequired);

        // Verify snapshot item was imported safely
        var unlinkedComponent = importResult.Recipe.Components.First(c => c.ProductName == "Satin Ribbon 1m");
        Assert.Equal(Guid.Empty, unlinkedComponent.ProductId);
        Assert.Equal(1, unlinkedComponent.QuantityRequired);

        // Verify database persistence
        var savedRecipe = await db.FloralRecipes.Include(r => r.Components).FirstOrDefaultAsync(r => r.Id == importResult.RecipeId);
        Assert.NotNull(savedRecipe);
        Assert.Equal(companyId, savedRecipe.CompanyId);
        Assert.Equal(libraryRecipe.Id, savedRecipe.SourceLibraryRecipeId);
    }

    [Fact]
    public async Task ImportRecipeAsync_IsIdempotent_ForSameCompany()
    {
        var (service, db, _) = CreateService();

        var libraryRecipe = new LibraryRecipe("Graceful Orchid Vase", "graceful-orchid-vase", null, null, null, 1, "Piece");
        db.LibraryRecipes.Add(libraryRecipe);
        await db.SaveChangesAsync();

        // First import
        var firstResult = await service.ImportRecipeAsync(libraryRecipe.Id);
        Assert.True(firstResult.Success);
        Assert.False(firstResult.AlreadyImported);

        // Second import
        var secondResult = await service.ImportRecipeAsync(libraryRecipe.Id);
        Assert.True(secondResult.Success);
        Assert.True(secondResult.AlreadyImported);
        Assert.Equal(firstResult.RecipeId, secondResult.RecipeId);

        // Ensure only 1 recipe in DB
        var count = await db.FloralRecipes.CountAsync();
        Assert.Equal(1, count);
    }

    [Fact]
    public async Task ImportRecipeAsync_TenantIsolation()
    {
        var companyA = Guid.NewGuid();
        var companyB = Guid.NewGuid();

        var (serviceA, db, _) = CreateService(companyA);
        var (serviceB, _, _) = CreateService(companyB);

        var libraryRecipe = new LibraryRecipe("Sunshine Mix", "sunshine-mix", null, null, null, 1, "Piece");
        db.LibraryRecipes.Add(libraryRecipe);
        await db.SaveChangesAsync();

        var resultA = await serviceA.ImportRecipeAsync(libraryRecipe.Id);
        var resultB = await serviceB.ImportRecipeAsync(libraryRecipe.Id);

        Assert.True(resultA.Success);
        Assert.True(resultB.Success);
        Assert.NotEqual(resultA.RecipeId, resultB.RecipeId);

        await using var readDbA = CreateDb(companyA);
        await using var readDbB = CreateDb(companyB);

        var recipeA = await readDbA.FloralRecipes.FirstOrDefaultAsync(r => r.Id == resultA.RecipeId);
        var recipeB = await readDbB.FloralRecipes.FirstOrDefaultAsync(r => r.Id == resultB.RecipeId);

        Assert.NotNull(recipeA);
        Assert.NotNull(recipeB);
        Assert.Equal(companyA, recipeA.CompanyId);
        Assert.Equal(companyB, recipeB.CompanyId);
        Assert.Equal(libraryRecipe.Id, recipeA.SourceLibraryRecipeId);
        Assert.Equal(libraryRecipe.Id, recipeB.SourceLibraryRecipeId);
    }

    [Fact]
    public async Task LibraryRecipe_UpdateAndDeletionIsolation()
    {
        var (service, db, companyId) = CreateService();

        var libraryRecipe = new LibraryRecipe("Original Recipe Name", "orig-recipe", "Original description", null, null, 1, "Piece");
        db.LibraryRecipes.Add(libraryRecipe);
        await db.SaveChangesAsync();

        var item = new LibraryRecipeItem(libraryRecipe.Id, "Original Flower", 5, "Stem");
        db.LibraryRecipeItems.Add(item);
        await db.SaveChangesAsync();

        // 1. Import
        var importResult = await service.ImportRecipeAsync(libraryRecipe.Id);
        Assert.True(importResult.Success);

        // 2. Modify Library Recipe and Item
        libraryRecipe.Update("Updated Library Name", "updated-recipe", "Updated description");
        item.Update("Updated Flower Name", 10, "Stem");
        await db.SaveChangesAsync();

        // 3. Verify company recipe is UNCHANGED
        await using var readDb1 = CreateDb(companyId);
        var companyRecipe = await readDb1.FloralRecipes.Include(r => r.Components).FirstOrDefaultAsync(r => r.Id == importResult.RecipeId);
        Assert.NotNull(companyRecipe);
        Assert.Equal("Original Recipe Name", companyRecipe.Name);
        Assert.Single(companyRecipe.Components);
        Assert.Equal("Original Flower", companyRecipe.Components[0].ProductName);
        Assert.Equal(5, companyRecipe.Components[0].QuantityRequired);

        // 4. Delete Library Recipe and Items
        db.LibraryRecipeItems.Remove(item);
        db.LibraryRecipes.Remove(libraryRecipe);
        await db.SaveChangesAsync();

        // 5. Verify company recipe is still safe and intact
        await using var readDb2 = CreateDb(companyId);
        var remainingCompanyRecipe = await readDb2.FloralRecipes.Include(r => r.Components).FirstOrDefaultAsync(r => r.Id == importResult.RecipeId);
        Assert.NotNull(remainingCompanyRecipe);
        Assert.Equal("Original Recipe Name", remainingCompanyRecipe.Name);
        Assert.Single(remainingCompanyRecipe.Components);
    }

    private sealed class TestTenantContext : ITenantContext
    {
        public TestTenantContext(Guid companyId) => CompanyId = companyId;
        public Guid? CompanyId { get; }
        public bool IsPlatformUser => false;
        public string? Region => "IN";
    }
}
