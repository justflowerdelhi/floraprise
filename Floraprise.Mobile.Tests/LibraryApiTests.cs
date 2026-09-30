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

public sealed class LibraryApiTests
{
    private readonly string _databaseName = $"LibraryApiTest_{Guid.NewGuid():N}";
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
    public async Task GetCategoriesAsync_ReturnsPagedAndFilteredResults()
    {
        var (service, db, _) = CreateService();

        var cat1 = new LibraryCategory("Exotic Orchids", "exotic-orchids", "Orchid collection", null, null, null, 1);
        var cat2 = new LibraryCategory("Roses", "roses", "Rose collection", null, null, null, 2);
        var cat3 = new LibraryCategory("Indoor Plants", "indoor-plants", "Green plants", null, null, null, 3);
        cat3.Deactivate();

        db.LibraryCategories.AddRange(cat1, cat2, cat3);
        await db.SaveChangesAsync();

        // 1. Query all active
        var activeResult = await service.GetCategoriesAsync(new LibraryCategoryQueryRequest { IsActive = true, Page = 1, PageSize = 10 });
        Assert.Equal(2, activeResult.TotalCount);
        Assert.Equal(2, activeResult.Items.Count);
        Assert.Contains(activeResult.Items, c => c.Slug == "exotic-orchids");
        Assert.Contains(activeResult.Items, c => c.Slug == "roses");

        // 2. Search query filter
        var searchResult = await service.GetCategoriesAsync(new LibraryCategoryQueryRequest { Search = "Orchid" });
        Assert.Single(searchResult.Items);
        Assert.Equal("Exotic Orchids", searchResult.Items[0].Name);

        // 3. Include inactive
        var allResult = await service.GetCategoriesAsync(new LibraryCategoryQueryRequest { IsActive = null });
        Assert.Equal(3, allResult.TotalCount);
    }

    [Fact]
    public async Task GetCategoryTreeAsync_ReturnsNestedHierarchy_WithProductCounts()
    {
        var (service, db, _) = CreateService();

        var rootFlowers = new LibraryCategory("Cut Flowers", "cut-flowers", null, null, null, null, 1);
        var rootPlants = new LibraryCategory("Plants", "plants", null, null, null, null, 2);
        db.LibraryCategories.AddRange(rootFlowers, rootPlants);
        await db.SaveChangesAsync();

        var subRoses = new LibraryCategory("Roses", "roses", null, null, null, rootFlowers.Id, 1);
        var subLilies = new LibraryCategory("Lilies", "lilies", null, null, null, rootFlowers.Id, 2);
        db.LibraryCategories.AddRange(subRoses, subLilies);
        await db.SaveChangesAsync();

        var prod1 = new LibraryProduct("Red Rose", "red-rose", subRoses.Id, ProductType.SingleFlower, UnitOfMeasure.Stem);
        var prod2 = new LibraryProduct("White Rose", "white-rose", subRoses.Id, ProductType.SingleFlower, UnitOfMeasure.Stem);
        var prod3 = new LibraryProduct("Oriental Lily", "oriental-lily", subLilies.Id, ProductType.SingleFlower, UnitOfMeasure.Stem);
        db.LibraryProducts.AddRange(prod1, prod2, prod3);
        await db.SaveChangesAsync();

        var tree = await service.GetCategoryTreeAsync();

        Assert.Equal(2, tree.Count);
        var flowersNode = tree.First(t => t.Slug == "cut-flowers");
        Assert.Equal(2, flowersNode.Children.Count);

        var rosesNode = flowersNode.Children.First(c => c.Slug == "roses");
        Assert.Equal(2, rosesNode.ProductCount);

        var liliesNode = flowersNode.Children.First(c => c.Slug == "lilies");
        Assert.Equal(1, liliesNode.ProductCount);
    }

    [Fact]
    public async Task GetProductsAsync_SupportsSearch_Category_AndProductTypeFilters()
    {
        var (service, db, _) = CreateService();

        var category = new LibraryCategory("Bouquets", "bouquets", null, null, null, null, 1);
        db.LibraryCategories.Add(category);
        await db.SaveChangesAsync();

        var p1 = new LibraryProduct("Red Passion Bouquet", "red-passion-bouquet", category.Id, ProductType.Bouquet, UnitOfMeasure.Piece, "BQ-RED-01", searchKeywords: "romantic, valentine");
        var p2 = new LibraryProduct("Yellow Sunshine Bouquet", "yellow-sunshine-bouquet", category.Id, ProductType.Bouquet, UnitOfMeasure.Piece, "BQ-YLW-01", searchKeywords: "friendship, summer");
        var p3 = new LibraryProduct("Pink Lily Stem", "pink-lily-stem", null, ProductType.SingleFlower, UnitOfMeasure.Stem, "LILY-PNK-01");

        db.LibraryProducts.AddRange(p1, p2, p3);
        await db.SaveChangesAsync();

        // 1. Search by keyword
        var searchResult = await service.GetProductsAsync(new LibraryProductQueryRequest { Search = "romantic" });
        Assert.Single(searchResult.Items);
        Assert.Equal("Red Passion Bouquet", searchResult.Items[0].Name);

        // 2. Search by SKU
        var skuResult = await service.GetProductsAsync(new LibraryProductQueryRequest { Search = "LILY-PNK" });
        Assert.Single(skuResult.Items);
        Assert.Equal("Pink Lily Stem", skuResult.Items[0].Name);

        // 3. Filter by Category
        var catResult = await service.GetProductsAsync(new LibraryProductQueryRequest { CategoryId = category.Id });
        Assert.Equal(2, catResult.TotalCount);

        // 4. Filter by ProductType
        var typeResult = await service.GetProductsAsync(new LibraryProductQueryRequest { ProductType = "SingleFlower" });
        Assert.Single(typeResult.Items);
        Assert.Equal("Pink Lily Stem", typeResult.Items[0].Name);
    }

    [Fact]
    public async Task ImportProductAsync_CreatesCompanyProduct_WithProvenanceAndDefaults()
    {
        var (service, db, companyId) = CreateService();

        var category = new LibraryCategory("Carnations", "carnations", null, null, null, null, 1);
        db.LibraryCategories.Add(category);
        await db.SaveChangesAsync();

        var libraryProduct = new LibraryProduct(
            name: "Standard Red Carnation",
            slug: "standard-red-carnation",
            categoryId: category.Id,
            productType: ProductType.SingleFlower,
            standardUnit: UnitOfMeasure.Stem,
            standardSku: "CARN-RED-STD",
            description: "Fresh red carnations"
        );
        db.LibraryProducts.Add(libraryProduct);
        await db.SaveChangesAsync();

        var importResult = await service.ImportProductAsync(libraryProduct.Id, new ImportLibraryProductRequest
        {
            CustomRetailPrice = 25.50m,
            CustomCostPrice = 12.00m
        });

        Assert.True(importResult.Success);
        Assert.False(importResult.AlreadyImported);
        Assert.NotNull(importResult.Product);
        Assert.Equal("Standard Red Carnation", importResult.Product.Name);
        Assert.Equal("CARN-RED-STD", importResult.Product.Sku);
        Assert.Equal(libraryProduct.Id, importResult.Product.SourceLibraryProductId);
        Assert.Equal(25.50m, importResult.Product.RetailPrice);
        Assert.Equal(12.00m, importResult.Product.CostPrice);
        Assert.Equal(0, importResult.Product.StockQuantity);
        Assert.False(string.IsNullOrEmpty(importResult.Product.InternalBarcode));

        // Verify product in database
        var savedProduct = await db.Products.FirstOrDefaultAsync(p => p.Id == importResult.ProductId);
        Assert.NotNull(savedProduct);
        Assert.Equal(companyId, savedProduct.CompanyId);
        Assert.Equal(libraryProduct.Id, savedProduct.SourceLibraryProductId);
    }

    [Fact]
    public async Task ImportProductAsync_IsIdempotent_ForSameCompany()
    {
        var (service, db, _) = CreateService();

        var libraryProduct = new LibraryProduct(
            name: "Blue Hydrangea",
            slug: "blue-hydrangea",
            categoryId: null,
            productType: ProductType.SingleFlower,
            standardUnit: UnitOfMeasure.Stem,
            standardSku: "HYD-BLU"
        );
        db.LibraryProducts.Add(libraryProduct);
        await db.SaveChangesAsync();

        // First import
        var firstResult = await service.ImportProductAsync(libraryProduct.Id);
        Assert.True(firstResult.Success);
        Assert.False(firstResult.AlreadyImported);

        // Second import (same company, same library product)
        var secondResult = await service.ImportProductAsync(libraryProduct.Id);
        Assert.True(secondResult.Success);
        Assert.True(secondResult.AlreadyImported);
        Assert.Equal(firstResult.ProductId, secondResult.ProductId);

        // Total products in DB for this company should still be 1
        var count = await db.Products.CountAsync();
        Assert.Equal(1, count);
    }

    [Fact]
    public async Task ImportProductAsync_ResolvesSkuCollisions_Gracefully()
    {
        var (service, db, companyId) = CreateService();

        // Existing company product with SKU "TULIP-RED"
        var existingCompanyCategory = new ProductCategoryEntity(companyId, "Tulips", true, false);
        db.ProductCategories.Add(existingCompanyCategory);
        await db.SaveChangesAsync();

        var existingProduct = new Product(
            companyId: companyId,
            name: "Existing Local Tulip",
            sku: "TULIP-RED",
            productType: ProductType.SingleFlower,
            category: ProductCategory.Other,
            retailPrice: 50,
            costPrice: 20,
            description: null);
        existingProduct.SetCategoryId(existingCompanyCategory.Id);
        db.Products.Add(existingProduct);
        await db.SaveChangesAsync();

        // Library product also with StandardSku "TULIP-RED"
        var libraryProduct = new LibraryProduct(
            name: "Dutch Red Tulip",
            slug: "dutch-red-tulip",
            categoryId: null,
            productType: ProductType.SingleFlower,
            standardUnit: UnitOfMeasure.Stem,
            standardSku: "TULIP-RED"
        );
        db.LibraryProducts.Add(libraryProduct);
        await db.SaveChangesAsync();

        // Import should not fail; it should assign "TULIP-RED-1"
        var result = await service.ImportProductAsync(libraryProduct.Id);
        Assert.True(result.Success);
        Assert.Equal("TULIP-RED-1", result.Product!.Sku);
    }

    [Fact]
    public async Task ImportProductAsync_MultiCompanyIsolation()
    {
        var companyA = Guid.NewGuid();
        var companyB = Guid.NewGuid();

        var (serviceA, db, _) = CreateService(companyA);
        var (serviceB, _, _) = CreateService(companyB);

        var libraryProduct = new LibraryProduct(
            name: "White Lily",
            slug: "white-lily",
            categoryId: null,
            productType: ProductType.SingleFlower,
            standardUnit: UnitOfMeasure.Stem,
            standardSku: "LILY-WHT"
        );
        db.LibraryProducts.Add(libraryProduct);
        await db.SaveChangesAsync();

        // Company A imports
        var resultA = await serviceA.ImportProductAsync(libraryProduct.Id);
        Assert.True(resultA.Success);
        Assert.False(resultA.AlreadyImported);

        // Company B imports
        var resultB = await serviceB.ImportProductAsync(libraryProduct.Id);
        Assert.True(resultB.Success);
        Assert.False(resultB.AlreadyImported);

        // Company A and B get distinct product records
        Assert.NotEqual(resultA.ProductId, resultB.ProductId);

        await using var readDbA = CreateDb(companyA);
        await using var readDbB = CreateDb(companyB);

        var productA = await readDbA.Products.FirstOrDefaultAsync(p => p.Id == resultA.ProductId);
        var productB = await readDbB.Products.FirstOrDefaultAsync(p => p.Id == resultB.ProductId);

        Assert.NotNull(productA);
        Assert.NotNull(productB);
        Assert.Equal(companyA, productA.CompanyId);
        Assert.Equal(companyB, productB.CompanyId);
        Assert.Equal(libraryProduct.Id, productA.SourceLibraryProductId);
        Assert.Equal(libraryProduct.Id, productB.SourceLibraryProductId);
    }

    private sealed class TestTenantContext : ITenantContext
    {
        public TestTenantContext(Guid companyId) => CompanyId = companyId;
        public Guid? CompanyId { get; }
        public bool IsPlatformUser => false;
        public string? Region => "IN";
    }
}
