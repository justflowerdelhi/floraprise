using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Barcodes;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Products;
using Sumpooj.Application.UseCases;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;
using Sumpooj.Infrastructure.Repositories;
using Xunit;

namespace Sumpooj.Infrastructure.Tests.Products;

/// <summary>
/// Purchase cost belongs to each inventory stock addition, not the product
/// master, so CostPrice must be optional on create/update and must never be
/// silently zeroed on edit when omitted.
/// </summary>
public class ProductCostPriceOptionalTests
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
        public required ProductService ProductService { get; init; }
    }

    private static Harness CreateHarness()
    {
        var companyId = Guid.NewGuid();
        var options = new DbContextOptionsBuilder<SumpoojDbContext>()
            .UseInMemoryDatabase($"ProductCostPriceOptional_{Guid.NewGuid():N}")
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

        return new Harness { Db = db, CompanyId = companyId, ProductService = productService };
    }

    private static async Task<Guid> CreateCategoryAsync(SumpoojDbContext db, Guid companyId, string name)
    {
        var category = new ProductCategoryEntity(companyId, name, isPerishable: false, trackBatchByDefault: false);
        db.ProductCategories.Add(category);
        await db.SaveChangesAsync();
        return category.Id;
    }

    [Fact]
    public async Task CreateProduct_WithoutCostPrice_Succeeds()
    {
        var h = CreateHarness();
        var categoryId = await CreateCategoryAsync(h.Db, h.CompanyId, "Roses");

        var productId = await h.ProductService.CreateAsync(new CreateProductRequest
        {
            ProductName = "No Cost Rose",
            Sku = "SKU-NOCOST-1",
            CategoryId = categoryId,
            RetailPrice = 150,
            // CostPrice intentionally omitted.
        });

        var product = await h.ProductService.GetAsync(productId);
        Assert.NotNull(product);
        Assert.Equal(0m, product!.CostPrice);
        Assert.Equal(150m, product.RetailPrice);
    }

    [Fact]
    public async Task CreateProduct_WithCostPrice_StillWorks()
    {
        var h = CreateHarness();
        var categoryId = await CreateCategoryAsync(h.Db, h.CompanyId, "Roses");

        var productId = await h.ProductService.CreateAsync(new CreateProductRequest
        {
            ProductName = "Costed Rose",
            Sku = "SKU-COST-1",
            CategoryId = categoryId,
            RetailPrice = 150,
            CostPrice = 60,
        });

        var product = await h.ProductService.GetAsync(productId);
        Assert.NotNull(product);
        Assert.Equal(60m, product!.CostPrice);
    }

    [Fact]
    public async Task EditProduct_WithoutCostPrice_Succeeds()
    {
        var h = CreateHarness();
        var categoryId = await CreateCategoryAsync(h.Db, h.CompanyId, "Roses");
        var productId = await h.ProductService.CreateAsync(new CreateProductRequest
        {
            ProductName = "Edit Rose",
            Sku = "SKU-EDIT-1",
            CategoryId = categoryId,
            RetailPrice = 100,
            CostPrice = 40,
        });

        await h.ProductService.UpdateAsync(productId, new UpdateProductRequest
        {
            RetailPrice = 120,
            // CostPrice intentionally omitted.
        });

        var product = await h.ProductService.GetAsync(productId);
        Assert.NotNull(product);
        Assert.Equal(120m, product!.RetailPrice);
    }

    [Fact]
    public async Task EditProduct_WithoutCostPrice_PreservesExistingCost()
    {
        var h = CreateHarness();
        var categoryId = await CreateCategoryAsync(h.Db, h.CompanyId, "Roses");
        var productId = await h.ProductService.CreateAsync(new CreateProductRequest
        {
            ProductName = "Preserve Cost Rose",
            Sku = "SKU-PRESERVE-1",
            CategoryId = categoryId,
            RetailPrice = 100,
            CostPrice = 45,
        });

        await h.ProductService.UpdateAsync(productId, new UpdateProductRequest
        {
            ProductName = "Preserve Cost Rose Renamed",
            // CostPrice intentionally omitted: must not zero out the existing cost.
        });

        var product = await h.ProductService.GetAsync(productId);
        Assert.NotNull(product);
        Assert.Equal(45m, product!.CostPrice);
        Assert.Equal("Preserve Cost Rose Renamed", product.Name);
    }

    [Fact]
    public async Task EditProduct_WithNewCostPrice_UpdatesCost()
    {
        var h = CreateHarness();
        var categoryId = await CreateCategoryAsync(h.Db, h.CompanyId, "Roses");
        var productId = await h.ProductService.CreateAsync(new CreateProductRequest
        {
            ProductName = "Update Cost Rose",
            Sku = "SKU-UPDATECOST-1",
            CategoryId = categoryId,
            RetailPrice = 100,
            CostPrice = 45,
        });

        await h.ProductService.UpdateAsync(productId, new UpdateProductRequest { CostPrice = 55 });

        var product = await h.ProductService.GetAsync(productId);
        Assert.NotNull(product);
        Assert.Equal(55m, product!.CostPrice);
    }
}
