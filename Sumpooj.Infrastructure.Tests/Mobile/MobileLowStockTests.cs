using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.API.Controllers.Mobile;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Mobile;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;
using Xunit;

namespace Sumpooj.Infrastructure.Tests.Mobile;

public class MobileLowStockTests
{
    private sealed class TenantContext(Guid companyId) : ITenantContext
    {
        public Guid? CompanyId => companyId;
        public bool IsPlatformUser => false;
        public string? Region => null;
    }

    private static SumpoojDbContext CreateDb(Guid companyId)
    {
        var options = new DbContextOptionsBuilder<SumpoojDbContext>()
            .UseInMemoryDatabase($"MobileLowStock_{Guid.NewGuid():N}")
            .Options;
        return new SumpoojDbContext(options, new TenantContext(companyId));
    }

    private static async Task<Product> SeedProductAsync(
        SumpoojDbContext db,
        Guid companyId,
        string name,
        int stockQuantity,
        int minimumStockLevel,
        bool trackInventory = true,
        bool isActive = true)
    {
        var product = new Product(
            companyId,
            name,
            name.Replace(" ", "-").ToUpperInvariant(),
            ProductType.SingleFlower,
            ProductCategory.Other,
            10m,
            5m,
            null);
        product.SetMinimumStockLevel(minimumStockLevel);
        product.AdjustStock(stockQuantity);
        product.SetUnitOfMeasure(UnitOfMeasure.Piece);
        if (!trackInventory)
        {
            product.SetInventorySettings(false, false, 0);
        }
        if (!isActive)
        {
            product.Deactivate();
        }
        db.Products.Add(product);
        await db.SaveChangesAsync();
        return product;
    }

    [Fact]
    public async Task GetLowStock_ReturnsLowAndOutOfStockProducts()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        await SeedProductAsync(db, companyId, "Rose Bunch", 4, 5);
        await SeedProductAsync(db, companyId, "Lily Box", 0, 2);
        await SeedProductAsync(db, companyId, "Daisy Bunch", -2, 3);
        await SeedProductAsync(db, companyId, "Fern Pack", 10, 3);

        var controller = new MobileInventoryController(db, new TenantContext(companyId));
        var result = await controller.GetLowStock(CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var items = Assert.IsAssignableFrom<IReadOnlyList<MobileLowStockProductDto>>(ok.Value);
        Assert.Equal(3, items.Count);

        var lowStock = items.Where(i => i.Status == "lowStock").ToList();
        var outOfStock = items.Where(i => i.Status == "outOfStock").ToList();

        var rose = Assert.Single(lowStock);
        Assert.Equal("Rose Bunch", rose.Name);
        Assert.Equal("ROSE-BUNCH", rose.Sku);
        Assert.Equal(4, rose.CurrentQuantity);
        Assert.Equal(5, rose.MinimumQuantity);

        Assert.Equal(2, outOfStock.Count);
        Assert.Contains(outOfStock, i => i.Name == "Daisy Bunch" && i.CurrentQuantity == -2 && i.Status == "outOfStock");
        Assert.Contains(outOfStock, i => i.Name == "Lily Box" && i.CurrentQuantity == 0 && i.Status == "outOfStock");
    }

    [Fact]
    public async Task GetLowStock_ReturnsEmpty_WhenAllProductsInStock()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        await SeedProductAsync(db, companyId, "Only In Stock", 8, 4);

        var controller = new MobileInventoryController(db, new TenantContext(companyId));
        var result = await controller.GetLowStock(CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var items = Assert.IsAssignableFrom<IReadOnlyList<MobileLowStockProductDto>>(ok.Value);
        Assert.Empty(items);
    }

    [Fact]
    public async Task GetLowStock_FiltersInactiveAndUntrackedProducts()
    {
        var companyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        await SeedProductAsync(db, companyId, "Inactive Low Stock", 0, 5, isActive: false);
        await SeedProductAsync(db, companyId, "Untracked Low Stock", 0, 5, trackInventory: false);
        await SeedProductAsync(db, companyId, "Valid Low Stock", 2, 5);

        var controller = new MobileInventoryController(db, new TenantContext(companyId));
        var result = await controller.GetLowStock(CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var items = Assert.IsAssignableFrom<IReadOnlyList<MobileLowStockProductDto>>(ok.Value);
        var item = Assert.Single(items);
        Assert.Equal("Valid Low Stock", item.Name);
        Assert.Equal("lowStock", item.Status);
    }

    [Fact]
    public async Task GetLowStock_DoesNotLeakOtherTenantProducts()
    {
        var companyId = Guid.NewGuid();
        var otherCompanyId = Guid.NewGuid();
        await using var db = CreateDb(companyId);
        await SeedProductAsync(db, companyId, "Own Low Stock", 1, 2);
        await SeedProductAsync(db, otherCompanyId, "Other Tenant Low Stock", 0, 3);

        var controller = new MobileInventoryController(db, new TenantContext(companyId));
        var result = await controller.GetLowStock(CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        var items = Assert.IsAssignableFrom<IReadOnlyList<MobileLowStockProductDto>>(ok.Value);
        var item = Assert.Single(items);
        Assert.Equal("Own Low Stock", item.Name);
        Assert.Equal("lowStock", item.Status);
    }
}
