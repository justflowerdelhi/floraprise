using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Inventory;
using Sumpooj.Application.UseCases;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;
using Sumpooj.Infrastructure.Repositories;

namespace Sumpooj.Infrastructure.Tests.Inventory;

public class CloudInventoryServiceTests
{
    private sealed class FakeTenantContext : ITenantContext
    {
        public FakeTenantContext(Guid companyId) => CompanyId = companyId;
        public Guid? CompanyId { get; }
        public bool IsPlatformUser => false;
        public string? Region => null;
    }

    private sealed record Harness(
        SumpoojDbContext Db,
        InventoryService Service,
        Guid CompanyId);

    private static Harness CreateHarness()
    {
        var companyId = Guid.NewGuid();
        var tenant = new FakeTenantContext(companyId);
        var options = new DbContextOptionsBuilder<SumpoojDbContext>()
            .UseInMemoryDatabase("CloudInventory_" + Guid.NewGuid())
            .Options;
        var db = new SumpoojDbContext(options, tenant);
        var service = new InventoryService(
            new ProductBatchRepository(db),
            new InventoryAdjustmentRepository(db),
            new ProductRepository(db),
            new BarcodeRepository(db),
            tenant,
            new InventoryLedgerRepository(db));
        return new Harness(db, service, companyId);
    }

    private static Product Product(Guid companyId, string sku, int stock)
    {
        var product = new Product(
            companyId,
            "Product " + sku,
            sku,
            ProductType.SingleFlower,
            ProductCategory.Roses,
            100,
            50,
            null);
        product.AdjustStock(stock);
        return product;
    }

    [Fact]
    public async Task GetInventoryProducts_ReturnsOnlyAuthenticatedCompanyProducts()
    {
        var harness = CreateHarness();
        harness.Db.Products.AddRange(
            Product(harness.CompanyId, "OWN", 5),
            Product(Guid.NewGuid(), "OTHER", 9));
        await harness.Db.SaveChangesAsync();

        var products = await harness.Service.GetInventoryProductsAsync();

        var product = Assert.Single(products);
        Assert.Equal("OWN", product.Sku);
        Assert.Equal(5, product.CurrentQuantity);
        Assert.Equal(product.Id, product.ProductId);
    }

    [Fact]
    public async Task ApplyStockChange_WhenSaleExceedsStock_LeavesStockAndHistoryUnchanged()
    {
        var harness = CreateHarness();
        var product = Product(harness.CompanyId, "LOW", 2);
        harness.Db.Products.Add(product);
        await harness.Db.SaveChangesAsync();

        var error = await Assert.ThrowsAsync<InvalidOperationException>(() =>
            harness.Service.ApplyStockChangeAsync(
                new InventoryStockChangeRequest
                {
                    ProductId = product.Id,
                    Operation = "sale",
                    Quantity = 3
                },
                Guid.NewGuid()));

        Assert.Equal("Stock cannot go negative.", error.Message);
        Assert.Equal(2, product.StockQuantity);
        Assert.Empty(harness.Db.InventoryAdjustments);
        Assert.Empty(harness.Db.InventoryLedgers);
    }
}
