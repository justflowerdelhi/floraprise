using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Barcodes;
using Sumpooj.Application.Common;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Products;
using Sumpooj.Application.UseCases;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;
using Sumpooj.Infrastructure.Repositories;
using Xunit;

namespace Sumpooj.Infrastructure.Tests.Barcodes;

public class BarcodeArchitectureTests
{
    private sealed class FakeTenantContext : ITenantContext
    {
        public FakeTenantContext(Guid companyId) => CompanyId = companyId;
        public Guid? CompanyId { get; }
        public bool IsPlatformUser => false;
        public string? Region => null;
    }

    private sealed class Harness
    {
        public required SumpoojDbContext Db { get; init; }
        public required Guid CompanyId { get; init; }
        public required IProductRepository ProductRepo { get; init; }
        public required IBarcodeRepository BarcodeRepo { get; init; }
        public required BarcodeService BarcodeService { get; init; }
        public required ProductService ProductService { get; init; }
    }

    private static Harness CreateHarness(string dbName, Guid companyId)
    {
        var options = new DbContextOptionsBuilder<SumpoojDbContext>()
            .UseInMemoryDatabase(dbName)
            .Options;
        var tenant = new FakeTenantContext(companyId);
        var db = new SumpoojDbContext(options, tenant);
        var productRepo = new ProductRepository(db);
        var barcodeRepo = new BarcodeRepository(db);
        var categoryRepo = new ProductCategoryRepository(db);
        var taxRuleRepo = new TaxRuleRepository(db);
        var batchRepo = new ProductBatchRepository(db);
        var barcodeService = new BarcodeService(productRepo, barcodeRepo);
        var productService = new ProductService(
            productRepo, categoryRepo, taxRuleRepo, batchRepo, barcodeRepo, barcodeService,
            tenant, Microsoft.Extensions.Logging.Abstractions.NullLogger<ProductService>.Instance);

        return new Harness
        {
            Db = db,
            CompanyId = companyId,
            ProductRepo = productRepo,
            BarcodeRepo = barcodeRepo,
            BarcodeService = barcodeService,
            ProductService = productService
        };
    }

    private static async Task<Guid> CreateCategoryAsync(SumpoojDbContext db, Guid companyId, string name)
    {
        var category = new ProductCategoryEntity(companyId, name, isPerishable: false, trackBatchByDefault: false);
        db.ProductCategories.Add(category);
        await db.SaveChangesAsync();
        return category.Id;
    }

    private static CreateProductRequest BuildCreateRequest(Guid categoryId, string sku, string? manufacturerBarcode = null) => new()
    {
        ProductName = "Test Product " + sku,
        Sku = sku,
        CategoryId = categoryId,
        Barcode = manufacturerBarcode,
        RetailPrice = 100,
        CostPrice = 50
    };

    [Fact]
    public async Task CreateProduct_GeneratesAndPersistsInternalBarcode()
    {
        var dbName = "Barcode_" + Guid.NewGuid();
        var companyId = Guid.NewGuid();
        var h = CreateHarness(dbName, companyId);
        var categoryId = await CreateCategoryAsync(h.Db, companyId, "Cat");

        var productId = await h.ProductService.CreateAsync(BuildCreateRequest(categoryId, "SKU-INT-1"));

        var barcodes = await h.BarcodeRepo.GetByProductIdAsync(productId);
        var internalBarcode = Assert.Single(barcodes, b => b.Type == BarcodeType.Internal);
        Assert.StartsWith("FL", internalBarcode.Value);
        Assert.Equal(companyId, internalBarcode.CompanyId);
        Assert.Equal(productId, internalBarcode.ProductId);
    }

    [Fact]
    public async Task CreateProduct_WithManufacturerBarcode_PersistsBoth()
    {
        var dbName = "Barcode_" + Guid.NewGuid();
        var companyId = Guid.NewGuid();
        var h = CreateHarness(dbName, companyId);
        var categoryId = await CreateCategoryAsync(h.Db, companyId, "Cat");

        var productId = await h.ProductService.CreateAsync(BuildCreateRequest(categoryId, "SKU-MAN-1", "MFR-001"));

        var barcodes = await h.BarcodeRepo.GetByProductIdAsync(productId);
        Assert.Equal(2, barcodes.Count);
        Assert.Contains(barcodes, b => b.Type == BarcodeType.Manufacturer && b.Value == "MFR-001");
        Assert.Contains(barcodes, b => b.Type == BarcodeType.Internal);
    }

    [Fact]
    public async Task SearchAsync_FindsProductByManufacturerBarcode()
    {
        var dbName = "Barcode_" + Guid.NewGuid();
        var companyId = Guid.NewGuid();
        var h = CreateHarness(dbName, companyId);
        var categoryId = await CreateCategoryAsync(h.Db, companyId, "Cat");
        var productId = await h.ProductService.CreateAsync(BuildCreateRequest(categoryId, "SKU-SEARCH-1", "MFR-SEARCH"));

        var result = await h.BarcodeService.SearchAsync(companyId, new SearchBarcodeRequest { Barcode = "MFR-SEARCH", IncludeOutOfStock = true });

        Assert.True(result.Found);
        Assert.Equal(productId, result.Product!.ProductId);
        Assert.Equal("MANUFACTURER", result.Product.FoundByType);
    }

    [Fact]
    public async Task SearchAsync_FindsProductByInternalBarcode()
    {
        var dbName = "Barcode_" + Guid.NewGuid();
        var companyId = Guid.NewGuid();
        var h = CreateHarness(dbName, companyId);
        var categoryId = await CreateCategoryAsync(h.Db, companyId, "Cat");
        var productId = await h.ProductService.CreateAsync(BuildCreateRequest(categoryId, "SKU-SEARCH-2"));
        var barcodes = await h.BarcodeRepo.GetByProductIdAsync(productId);
        var internalValue = barcodes.Single(b => b.Type == BarcodeType.Internal).Value;

        var result = await h.BarcodeService.SearchAsync(companyId, new SearchBarcodeRequest { Barcode = internalValue, IncludeOutOfStock = true });

        Assert.True(result.Found);
        Assert.Equal(productId, result.Product!.ProductId);
        Assert.Equal("INTERNAL", result.Product.FoundByType);
    }

    [Fact]
    public async Task DuplicateBarcode_WithinSameCompany_IsRejected()
    {
        var dbName = "Barcode_" + Guid.NewGuid();
        var companyId = Guid.NewGuid();
        var h = CreateHarness(dbName, companyId);
        var categoryId = await CreateCategoryAsync(h.Db, companyId, "Cat");
        await h.ProductService.CreateAsync(BuildCreateRequest(categoryId, "SKU-DUP-1", "DUP-VALUE"));

        await Assert.ThrowsAsync<InvalidOperationException>(
            () => h.ProductService.CreateAsync(BuildCreateRequest(categoryId, "SKU-DUP-2", "DUP-VALUE")));
    }

    [Fact]
    public async Task SameBarcodeValue_InDifferentCompanies_IsAllowed()
    {
        var dbName = "Barcode_" + Guid.NewGuid();
        var companyA = Guid.NewGuid();
        var companyB = Guid.NewGuid();
        var hA = CreateHarness(dbName, companyA);
        var hB = CreateHarness(dbName, companyB);
        var categoryA = await CreateCategoryAsync(hA.Db, companyA, "CatA");
        var categoryB = await CreateCategoryAsync(hB.Db, companyB, "CatB");

        var productAId = await hA.ProductService.CreateAsync(BuildCreateRequest(categoryA, "SKU-A-1", "SHARED-123"));
        var productBId = await hB.ProductService.CreateAsync(BuildCreateRequest(categoryB, "SKU-B-1", "SHARED-123"));

        Assert.NotEqual(Guid.Empty, productAId);
        Assert.NotEqual(Guid.Empty, productBId);
    }

    [Fact]
    public async Task CompanyA_CannotSearch_CompanyBBarcode()
    {
        var dbName = "Barcode_" + Guid.NewGuid();
        var companyA = Guid.NewGuid();
        var companyB = Guid.NewGuid();
        var hA = CreateHarness(dbName, companyA);
        var hB = CreateHarness(dbName, companyB);
        var categoryB = await CreateCategoryAsync(hB.Db, companyB, "CatB");
        await hB.ProductService.CreateAsync(BuildCreateRequest(categoryB, "SKU-ISOLATION-1", "ISOLATED-VALUE"));

        // Company A searches for a barcode that only exists for Company B.
        var result = await hA.BarcodeService.SearchAsync(companyA, new SearchBarcodeRequest { Barcode = "ISOLATED-VALUE", IncludeOutOfStock = true });

        Assert.False(result.Found);
    }

    [Fact]
    public async Task CompanyA_CannotValidate_CompanyBBarcodeAsDuplicate()
    {
        var dbName = "Barcode_" + Guid.NewGuid();
        var companyA = Guid.NewGuid();
        var companyB = Guid.NewGuid();
        var hA = CreateHarness(dbName, companyA);
        var hB = CreateHarness(dbName, companyB);
        var categoryB = await CreateCategoryAsync(hB.Db, companyB, "CatB");
        await hB.ProductService.CreateAsync(BuildCreateRequest(categoryB, "SKU-ISOLATION-2", "COMPANYB-ONLY"));

        var validation = await hA.BarcodeService.ValidateAsync(companyA, new ValidateBarcodeRequest { Barcode = "COMPANYB-ONLY" });

        Assert.False(validation.IsDuplicate);
    }

    [Fact]
    public async Task GenerateUniqueInternalValue_DoesNotCollideAcrossSequentialCalls()
    {
        var dbName = "Barcode_" + Guid.NewGuid();
        var companyId = Guid.NewGuid();
        var h = CreateHarness(dbName, companyId);
        var categoryId = await CreateCategoryAsync(h.Db, companyId, "Cat");

        var product1 = await h.ProductService.CreateAsync(BuildCreateRequest(categoryId, "SKU-GEN-1"));
        var product2 = await h.ProductService.CreateAsync(BuildCreateRequest(categoryId, "SKU-GEN-2"));

        var value1 = (await h.BarcodeRepo.GetByProductIdAsync(product1)).Single(b => b.Type == BarcodeType.Internal).Value;
        var value2 = (await h.BarcodeRepo.GetByProductIdAsync(product2)).Single(b => b.Type == BarcodeType.Internal).Value;

        Assert.NotEqual(value1, value2);
    }

    [Fact]
    public async Task ProductCreation_And_BarcodeCreation_AreAtomic_OnConflict()
    {
        var dbName = "Barcode_" + Guid.NewGuid();
        var companyId = Guid.NewGuid();
        var h = CreateHarness(dbName, companyId);
        var categoryId = await CreateCategoryAsync(h.Db, companyId, "Cat");
        await h.ProductService.CreateAsync(BuildCreateRequest(categoryId, "SKU-ATOMIC-1", "ATOMIC-DUP"));

        var countBefore = (await h.Db.Products.CountAsync());

        await Assert.ThrowsAsync<InvalidOperationException>(
            () => h.ProductService.CreateAsync(BuildCreateRequest(categoryId, "SKU-ATOMIC-2", "ATOMIC-DUP")));

        // The second product must not have been created either: failure to
        // attach the manufacturer barcode must not leave an orphan product.
        var countAfter = (await h.Db.Products.CountAsync());
        Assert.Equal(countBefore, countAfter);
    }

    [Fact]
    public async Task UpdateAsync_ChangingManufacturerBarcode_DoesNotAffectInternalBarcode()
    {
        var dbName = "Barcode_" + Guid.NewGuid();
        var companyId = Guid.NewGuid();
        var h = CreateHarness(dbName, companyId);
        var categoryId = await CreateCategoryAsync(h.Db, companyId, "Cat");
        var productId = await h.ProductService.CreateAsync(BuildCreateRequest(categoryId, "SKU-UPD-1", "OLD-MFR"));
        var internalBefore = (await h.BarcodeRepo.GetByProductIdAsync(productId)).Single(b => b.Type == BarcodeType.Internal).Value;

        await h.ProductService.UpdateAsync(productId, new UpdateProductRequest { Barcode = "NEW-MFR" });

        var barcodesAfter = await h.BarcodeRepo.GetByProductIdAsync(productId);
        Assert.Equal("NEW-MFR", barcodesAfter.Single(b => b.Type == BarcodeType.Manufacturer).Value);
        Assert.Equal(internalBefore, barcodesAfter.Single(b => b.Type == BarcodeType.Internal).Value);
    }
}
