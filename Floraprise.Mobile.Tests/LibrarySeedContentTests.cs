using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.EntityFrameworkCore.Storage;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure;
using Sumpooj.Infrastructure.Persistence;
using Xunit;

namespace Floraprise.Mobile.Tests;

public sealed class LibrarySeedContentTests
{
    private readonly string _databaseName = $"LibrarySeedContentTest_{Guid.NewGuid():N}";
    private readonly InMemoryDatabaseRoot _databaseRoot = new();

    private SumpoojDbContext CreateDb(Guid? companyId = null)
    {
        var options = new DbContextOptionsBuilder<SumpoojDbContext>()
            .UseInMemoryDatabase(_databaseName, _databaseRoot)
            .ConfigureWarnings(w => w.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options;

        return new SumpoojDbContext(options, new TestTenantContext(companyId ?? Guid.NewGuid()));
    }

    [Fact]
    public void CanonicalStarterCatalogue_ContainsExact142Products()
    {
        var products = LibraryDataSeeder.LoadCanonicalStarterCatalogue();

        Assert.Equal(142, products.Count);
        Assert.Equal(142, products.Select(p => p.Name).Distinct().Count());

        // Verify key sample items from each of the 6 categories
        Assert.Contains(products, p => p.Name == "Red Rose" && p.Category == "Flowers" && p.DefaultUnit == "Stem");
        Assert.Contains(products, p => p.Name == "White Gypsophila" && p.Category == "Fillers" && p.DefaultUnit == "Bunch");
        Assert.Contains(products, p => p.Name == "Leather Fern" && p.Category == "Foliage" && p.DefaultUnit == "Bunch");
        Assert.Contains(products, p => p.Name == "Korean Wrapping Paper" && p.Category == "Packing" && p.DefaultUnit == "Roll");
        Assert.Contains(products, p => p.Name == "Wet Floral Foam" && p.Category == "Accessories" && p.DefaultUnit == "Piece");
        Assert.Contains(products, p => p.Name == "Ferrero Rocher 16" && p.Category == "Finished Products" && p.DefaultUnit == "Piece");
    }

    [Fact]
    public async Task LibraryDataSeeder_SeedsAll142SoloProducts_AndPreservesHierarchy()
    {
        await using var db = CreateDb();

        var result = await LibraryDataSeeder.SeedAsync(db);

        Assert.Equal(142, result.ProductsCreated);
        Assert.True(result.CategoriesCreated >= 19);

        // Verify All 142 Solo products exist in Library by name
        var canonical = LibraryDataSeeder.LoadCanonicalStarterCatalogue();
        var allLibraryProducts = await db.LibraryProducts.Include(p => p.Category).ToListAsync();
        var libraryByName = allLibraryProducts.ToDictionary(p => p.Name, StringComparer.OrdinalIgnoreCase);

        foreach (var soloItem in canonical)
        {
            Assert.True(libraryByName.ContainsKey(soloItem.Name), $"Solo product '{soloItem.Name}' should be represented in Library.");
            var libProduct = libraryByName[soloItem.Name];
            Assert.NotNull(libProduct);
            Assert.NotNull(libProduct.Category);
            Assert.True(libProduct.IsActive);
            Assert.False(string.IsNullOrWhiteSpace(libProduct.StandardSku));
        }

        // Verify Hierarchy: Flowers children
        var flowers = await db.LibraryCategories.FirstOrDefaultAsync(c => c.Slug == "flowers");
        Assert.NotNull(flowers);
        Assert.Null(flowers!.ParentCategoryId);

        var flowerChildren = await db.LibraryCategories.Where(c => c.ParentCategoryId == flowers.Id).Select(c => c.Slug).ToListAsync();
        Assert.Contains("fillers", flowerChildren);
        Assert.Contains("foliage", flowerChildren);
        Assert.Contains("roses", flowerChildren);
        Assert.Contains("lilies", flowerChildren);
        Assert.Contains("carnations", flowerChildren);
        Assert.Contains("orchids", flowerChildren);

        // Verify Hierarchy: Supplies children
        var supplies = await db.LibraryCategories.FirstOrDefaultAsync(c => c.Slug == "supplies");
        Assert.NotNull(supplies);
        Assert.Null(supplies!.ParentCategoryId);

        var suppliesChildren = await db.LibraryCategories.Where(c => c.ParentCategoryId == supplies.Id).Select(c => c.Slug).ToListAsync();
        Assert.Contains("packing", suppliesChildren);
        Assert.Contains("accessories", suppliesChildren);

        // Verify Top-Level Finished Products
        var finishedProducts = await db.LibraryCategories.FirstOrDefaultAsync(c => c.Slug == "finished-products");
        Assert.NotNull(finishedProducts);
        Assert.Null(finishedProducts!.ParentCategoryId);
    }

    [Fact]
    public async Task LibraryDataSeeder_IsStrictlyIdempotent_OnMultipleRuns()
    {
        await using var db = CreateDb();

        // First run
        var run1 = await LibraryDataSeeder.SeedAsync(db);
        Assert.Equal(142, run1.ProductsCreated);

        var totalCategories = await db.LibraryCategories.CountAsync();
        var totalProducts = await db.LibraryProducts.CountAsync();
        Assert.Equal(142, totalProducts);

        // Second run
        var run2 = await LibraryDataSeeder.SeedAsync(db);
        Assert.Equal(0, run2.CategoriesCreated);
        Assert.Equal(0, run2.ProductsCreated);
        Assert.Equal(0, run2.ProductsReconciled);
        Assert.Equal(142, run2.ProductsRetainedUnchanged);

        var totalCategories2 = await db.LibraryCategories.CountAsync();
        var totalProducts2 = await db.LibraryProducts.CountAsync();
        Assert.Equal(totalCategories, totalCategories2);
        Assert.Equal(totalProducts, totalProducts2);
    }

    [Fact]
    public async Task LibraryDataSeeder_NonDestructivelyPreserves_ExistingLibraryRecords()
    {
        await using var db = CreateDb();

        // Simulate pre-existing curated composite bouquet and non-Solo card
        var customCategory = new LibraryCategory("Custom Master Category", "custom-master-cat", null, null, null, null, 100);
        db.LibraryCategories.Add(customCategory);

        var curatedBouquet = new LibraryProduct(
            name: "Grand Floral Symphony Bouquet",
            slug: "grand-floral-symphony-bouquet",
            categoryId: customCategory.Id,
            productType: ProductType.Bouquet,
            standardUnit: UnitOfMeasure.Piece,
            standardSku: "BQT-SYMPHONY-01"
        );
        db.LibraryProducts.Add(curatedBouquet);
        await db.SaveChangesAsync();

        // Run Seeder
        var result = await LibraryDataSeeder.SeedAsync(db);

        // Verify curated custom product and category are completely preserved
        Assert.Equal(1, result.ProductsRetainedNonSolo);
        var preserved = await db.LibraryProducts.FirstOrDefaultAsync(p => p.Slug == "grand-floral-symphony-bouquet");
        Assert.NotNull(preserved);
        Assert.Equal("Grand Floral Symphony Bouquet", preserved!.Name);

        var preservedCat = await db.LibraryCategories.FirstOrDefaultAsync(c => c.Slug == "custom-master-cat");
        Assert.NotNull(preservedCat);
    }

    [Fact]
    public async Task LibraryDataSeeder_DoesNotTouchCompanyOperationalData_AndMaintainsIndependence()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);

        // Pre-existing company operational catalog
        var companyCat = new ProductCategoryEntity(companyId, "Store Front Displays", false, false);
        db.ProductCategories.Add(companyCat);

        var companyProduct = new Product(
            companyId: companyId,
            name: "Local Red Rose",
            sku: "LOCAL-ROSE-99",
            productType: ProductType.SingleFlower,
            category: ProductCategory.Roses,
            retailPrice: 85.00m,
            costPrice: 40.00m,
            description: "Store local inventory"
        );
        db.Products.Add(companyProduct);

        var companyCustomer = new Customer(companyId, "Alice Smith", "alice@example.com", "+91-9876500000");
        db.Customers.Add(companyCustomer);
        await db.SaveChangesAsync();

        // Run Library Seeder
        await LibraryDataSeeder.SeedAsync(db);

        // 1. Verify company product & customer are untouched
        var remainingProduct = await db.Products.FirstOrDefaultAsync(p => p.Id == companyProduct.Id);
        Assert.NotNull(remainingProduct);
        Assert.Equal(85.00m, remainingProduct!.RetailPrice);
        Assert.Equal(40.00m, remainingProduct.CostPrice);
        Assert.Equal("LOCAL-ROSE-99", remainingProduct.Sku);

        var remainingCustomer = await db.Customers.FirstOrDefaultAsync(c => c.Id == companyCustomer.Id);
        Assert.NotNull(remainingCustomer);

        // 2. Simulate tenant importing a Library product
        var libRedRose = await db.LibraryProducts.FirstOrDefaultAsync(p => p.Name == "Red Rose");
        Assert.NotNull(libRedRose);

        var importedProduct = new Product(
            companyId: companyId,
            name: libRedRose!.Name,
            sku: "SHOP-ROSE-01",
            productType: libRedRose.ProductType,
            category: ProductCategory.Roses,
            retailPrice: 150.00m,
            costPrice: 70.00m,
            description: "Imported from library with store-specific markup"
        );
        importedProduct.SetSourceLibraryProductId(libRedRose.Id);
        db.Products.Add(importedProduct);
        await db.SaveChangesAsync();

        // Verify independent operational pricing and provenance
        var loadedImport = await db.Products.FirstOrDefaultAsync(p => p.Id == importedProduct.Id);
        Assert.NotNull(loadedImport);
        Assert.Equal(libRedRose.Id, loadedImport!.SourceLibraryProductId);
        Assert.Equal(150.00m, loadedImport.RetailPrice);
        Assert.Equal(70.00m, loadedImport.CostPrice);
    }

    private sealed class TestTenantContext : ITenantContext
    {
        public TestTenantContext(Guid companyId) => CompanyId = companyId;
        public Guid? CompanyId { get; }
        public bool IsPlatformUser => false;
        public string? Region => "IN";
    }
}
