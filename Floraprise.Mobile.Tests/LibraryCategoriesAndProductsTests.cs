using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.EntityFrameworkCore.Storage;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;
using Xunit;

namespace Floraprise.Mobile.Tests;

public sealed class LibraryCategoriesAndProductsTests
{
    private readonly string _databaseName = $"LibraryEntitiesTest_{Guid.NewGuid():N}";
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
    public async Task LibraryCategory_CanBePersisted_AndRetrieved()
    {
        await using var db = CreateDb();

        var parent = new LibraryCategory("Flowers", "flowers", "Fresh cut flowers", "/images/flowers.jpg", "spa", null, 1);
        db.LibraryCategories.Add(parent);
        await db.SaveChangesAsync();

        var child = new LibraryCategory("Roses", "roses", "All varieties of roses", "/images/roses.jpg", "rose", parent.Id, 2);
        db.LibraryCategories.Add(child);
        await db.SaveChangesAsync();

        await using var readDb = CreateDb();
        var retrieved = await readDb.LibraryCategories
            .Include(c => c.ParentCategory)
            .Include(c => c.SubCategories)
            .FirstOrDefaultAsync(c => c.Slug == "roses");

        Assert.NotNull(retrieved);
        Assert.Equal("Roses", retrieved.Name);
        Assert.Equal(parent.Id, retrieved.ParentCategoryId);
        Assert.NotNull(retrieved.ParentCategory);
        Assert.Equal("Flowers", retrieved.ParentCategory.Name);
    }

    [Fact]
    public async Task LibraryProduct_CanBePersisted_AndRetrieved()
    {
        await using var db = CreateDb();

        var product = new LibraryProduct(
            name: "Dutch Red Rose",
            slug: "dutch-red-rose",
            categoryId: null,
            productType: ProductType.SingleFlower,
            standardUnit: UnitOfMeasure.Stem,
            standardSku: "ROSE-RED-STD",
            description: "Premium long-stem red roses",
            referenceImageUrl: "https://cdn.floraprise.com/ref/rose-red.jpg",
            thumbnailUrl: "https://cdn.floraprise.com/ref/rose-red-thumb.jpg",
            searchKeywords: "red rose, dutch rose, valentine",
            sortOrder: 10
        );

        db.LibraryProducts.Add(product);
        await db.SaveChangesAsync();

        await using var readDb = CreateDb();
        var retrieved = await readDb.LibraryProducts.FirstOrDefaultAsync(p => p.Slug == "dutch-red-rose");

        Assert.NotNull(retrieved);
        Assert.Equal("Dutch Red Rose", retrieved.Name);
        Assert.Equal("ROSE-RED-STD", retrieved.StandardSku);
        Assert.Equal(ProductType.SingleFlower, retrieved.ProductType);
        Assert.Equal(UnitOfMeasure.Stem, retrieved.StandardUnit);
        Assert.Equal(1, retrieved.Version);
        Assert.True(retrieved.IsActive);
    }

    [Fact]
    public async Task LibraryProduct_CanReference_LibraryCategory()
    {
        await using var db = CreateDb();

        var category = new LibraryCategory("Bouquets", "bouquets", "Hand-tied bouquets", null, null, null, 1);
        db.LibraryCategories.Add(category);
        await db.SaveChangesAsync();

        var product = new LibraryProduct(
            name: "Classic Celebration Bouquet",
            slug: "classic-celebration-bouquet",
            categoryId: category.Id,
            productType: ProductType.Bouquet,
            standardUnit: UnitOfMeasure.Piece,
            standardSku: "BQT-CLS-01"
        );
        db.LibraryProducts.Add(product);
        await db.SaveChangesAsync();

        await using var readDb = CreateDb();
        var retrieved = await readDb.LibraryProducts
            .Include(p => p.Category)
            .FirstOrDefaultAsync(p => p.Slug == "classic-celebration-bouquet");

        Assert.NotNull(retrieved);
        Assert.NotNull(retrieved.Category);
        Assert.Equal(category.Id, retrieved.CategoryId);
        Assert.Equal("Bouquets", retrieved.Category.Name);
    }

    [Fact]
    public async Task LibraryEntities_AreGlobal_AndNotTenantFiltered()
    {
        var companyA = Guid.NewGuid();
        var companyB = Guid.NewGuid();

        // Persist library items under tenant A
        await using (var dbA = CreateDb(companyA))
        {
            var category = new LibraryCategory("Exotic Lilies", "exotic-lilies", null, null, null, null, 1);
            dbA.LibraryCategories.Add(category);

            var product = new LibraryProduct(
                name: "White Oriental Lily",
                slug: "white-oriental-lily",
                categoryId: category.Id,
                productType: ProductType.SingleFlower,
                standardUnit: UnitOfMeasure.Stem
            );
            dbA.LibraryProducts.Add(product);
            await dbA.SaveChangesAsync();
        }

        // Query library items under tenant B — they must still be visible
        await using (var dbB = CreateDb(companyB))
        {
            var category = await dbB.LibraryCategories.FirstOrDefaultAsync(c => c.Slug == "exotic-lilies");
            var product = await dbB.LibraryProducts.FirstOrDefaultAsync(p => p.Slug == "white-oriental-lily");

            Assert.NotNull(category);
            Assert.NotNull(product);
            Assert.Equal("Exotic Lilies", category.Name);
            Assert.Equal("White Oriental Lily", product.Name);
        }
    }

    [Fact]
    public async Task Product_SourceLibraryProductId_CanBePersisted()
    {
        var companyId = Guid.NewGuid();
        var libraryProductId = Guid.NewGuid();

        await using var db = CreateDb(companyId);

        var companyProduct = new Product(
            companyId: companyId,
            name: "Local Red Rose (imported from Library)",
            sku: "MY-ROSE-001",
            productType: ProductType.SingleFlower,
            category: ProductCategory.Roses,
            retailPrice: 120.00m,
            costPrice: 60.00m,
            description: "Store copy"
        );
        companyProduct.SetSourceLibraryProductId(libraryProductId);

        db.Products.Add(companyProduct);
        await db.SaveChangesAsync();

        await using var readDb = CreateDb(companyId);
        var retrieved = await readDb.Products.FirstOrDefaultAsync(p => p.Id == companyProduct.Id);

        Assert.NotNull(retrieved);
        Assert.Equal(libraryProductId, retrieved.SourceLibraryProductId);
        Assert.Equal(120.00m, retrieved.RetailPrice);
    }

    [Fact]
    public async Task MultipleCompanyProducts_AcrossTenants_CanReferenceSameLibraryProduct()
    {
        var company1 = Guid.NewGuid();
        var company2 = Guid.NewGuid();
        var libraryProductId = Guid.NewGuid();

        // Company 1 import
        await using (var db1 = CreateDb(company1))
        {
            var p1 = new Product(company1, "Rose Shop 1", "R-101", ProductType.SingleFlower, ProductCategory.Roses, 100m, 50m, null);
            p1.SetSourceLibraryProductId(libraryProductId);
            db1.Products.Add(p1);
            await db1.SaveChangesAsync();
        }

        // Company 2 import referencing same library product
        await using (var db2 = CreateDb(company2))
        {
            var p2 = new Product(company2, "Rose Shop 2", "R-202", ProductType.SingleFlower, ProductCategory.Roses, 150m, 70m, null);
            p2.SetSourceLibraryProductId(libraryProductId);
            db2.Products.Add(p2);
            await db2.SaveChangesAsync();
        }

        // Verify isolation and independent provenance
        await using (var readDb1 = CreateDb(company1))
        {
            var products = await readDb1.Products.Where(p => p.SourceLibraryProductId == libraryProductId).ToListAsync();
            Assert.Single(products);
            Assert.Equal("Rose Shop 1", products[0].Name);
            Assert.Equal(100m, products[0].RetailPrice);
        }

        await using (var readDb2 = CreateDb(company2))
        {
            var products = await readDb2.Products.Where(p => p.SourceLibraryProductId == libraryProductId).ToListAsync();
            Assert.Single(products);
            Assert.Equal("Rose Shop 2", products[0].Name);
            Assert.Equal(150m, products[0].RetailPrice);
        }
    }

    [Fact]
    public async Task DeletingLibraryProduct_CannotCascadeDelete_CompanyProduct()
    {
        var companyId = Guid.NewGuid();

        await using var db = CreateDb(companyId);

        var libraryProduct = new LibraryProduct("Orchid Standard", "orchid-standard", null, ProductType.SingleFlower, UnitOfMeasure.Stem);
        db.LibraryProducts.Add(libraryProduct);
        await db.SaveChangesAsync();

        var companyProduct = new Product(companyId, "My Orchid", "ORC-01", ProductType.SingleFlower, ProductCategory.Orchids, 200m, 100m, null);
        companyProduct.SetSourceLibraryProductId(libraryProduct.Id);
        db.Products.Add(companyProduct);
        await db.SaveChangesAsync();

        // Delete the library product
        db.LibraryProducts.Remove(libraryProduct);
        await db.SaveChangesAsync();

        // Verify company product is still safe and intact in the database
        await using var readDb = CreateDb(companyId);
        var remainingProduct = await readDb.Products.FirstOrDefaultAsync(p => p.Id == companyProduct.Id);

        Assert.NotNull(remainingProduct);
        Assert.Equal("My Orchid", remainingProduct.Name);
        Assert.Equal(libraryProduct.Id, remainingProduct.SourceLibraryProductId);
    }

    private sealed class TestTenantContext : ITenantContext
    {
        public TestTenantContext(Guid companyId) => CompanyId = companyId;
        public Guid? CompanyId { get; }
        public bool IsPlatformUser => false;
        public string? Region => "IN";
    }
}
