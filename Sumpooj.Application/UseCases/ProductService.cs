using Microsoft.Extensions.Logging;
using Sumpooj.Application.Common;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Products;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.UseCases;

public class ProductService
{
    private readonly IProductRepository _repo;
    private readonly IProductCategoryRepository _categoryRepo;
    private readonly ITaxRuleRepository _taxRuleRepo;
    private readonly IProductBatchRepository _batchRepo;
    private readonly ITenantContext _tenant;
    private readonly ILogger<ProductService> _logger;

    public ProductService(
        IProductRepository repo,
        IProductCategoryRepository categoryRepo,
        ITaxRuleRepository taxRuleRepo,
        IProductBatchRepository batchRepo,
        ITenantContext tenant,
        ILogger<ProductService> logger)
    {
        _repo = repo;
        _categoryRepo = categoryRepo;
        _taxRuleRepo = taxRuleRepo;
        _batchRepo = batchRepo;
        _tenant = tenant;
        _logger = logger;
    }

    public async Task<PagedResult<ProductListDto>> SearchAsync(ProductSearchRequest request)
    {
        var (items, total) = await _repo.SearchAsync(
            request.Query,
            request.ProductType,
            request.Category,
            request.IsActive,
            request.IsPerishable,
            request.LowStockOnly,
            request.Page,
            request.PageSize);

        return new PagedResult<ProductListDto>
        {
            Items = items.Select(ToListDto).ToList(),
            TotalCount = total,
            Page = request.Page,
            PageSize = request.PageSize
        };
    }

    public async Task<ProductDto?> GetAsync(Guid id)
    {
        var product = await _repo.GetByIdAsync(id);
        return product == null ? null : ToDto(product);
    }

    public async Task<Guid> CreateAsync(CreateProductRequest request)
    {
        if (_tenant.CompanyId == null)
            throw new InvalidOperationException("Company context required");

        // ── CategoryId is now required ──────────────────
        if (!request.CategoryId.HasValue || request.CategoryId == Guid.Empty)
            throw new InvalidOperationException("CategoryId is required when creating a product.");

        var categoryEntity = await _categoryRepo.GetByIdAsync(request.CategoryId.Value)
            ?? throw new InvalidOperationException($"Category '{request.CategoryId}' not found.");

        // ── TaxRuleId is optional (exempt products don't need one) ───────
        if (request.TaxRuleId.HasValue && request.TaxRuleId != Guid.Empty)
        {
            var taxRule = await _taxRuleRepo.GetByIdAsync(_tenant.CompanyId!.Value, request.TaxRuleId.Value)
                ?? throw new InvalidOperationException($"TaxRule '{request.TaxRuleId}' not found.");
        }

        // Check if SKU already exists
        if (await _repo.SkuExistsAsync(request.Sku))
            throw new InvalidOperationException($"SKU '{request.Sku}' already exists");

        var productType = ParseEnum<ProductType>(request.ProductType, ProductType.SingleFlower);
        var category = ParseEnum<ProductCategory>(request.Category, ProductCategory.Other);

        var product = new Product(
            companyId: _tenant.CompanyId.Value,
            name: request.ProductName,
            sku: request.Sku,
            productType: productType,
            category: category,
            retailPrice: request.RetailPrice,
            costPrice: request.CostPrice,
            description: request.Description
        );

        // Assign dynamic CategoryId (category is source of truth for IsPerishable)
        product.SetCategoryId(request.CategoryId.Value);

        // Assign TaxRule (optional for exempt products)
        if (request.TaxRuleId.HasValue && request.TaxRuleId != Guid.Empty)
        {
            product.SetTaxRuleId(request.TaxRuleId.Value);
        }

        // Set additional properties
        product.UpdateBasicInfo(request.ProductName, request.Sku, request.Barcode, request.Brand, request.Description);
        product.UpdatePricing(request.RetailPrice, request.CostPrice, request.WholesalePrice, request.WeddingEventPrice);
        product.SetUnitOfMeasure(ParseEnum<UnitOfMeasure>(request.UnitOfMeasure, UnitOfMeasure.Stem));
        product.SetTaxCategory(ParseEnum<TaxCategory>(request.TaxCategory, TaxCategory.Standard));
        product.SetInventorySettings(request.TrackInventory, request.TrackBatch, request.ReorderLevel ?? 0);
        product.SetPerishableDetails(request.ShelfLifeDays, request.ExpiryAlertDays, request.TemperatureNotes);

        if (request.FlowerAttributes != null)
        {
            product.SetFlowerAttributes(
                request.FlowerAttributes.Color,
                request.FlowerAttributes.Variety,
                ParseNullableEnum<FlowerGrade>(request.FlowerAttributes.Grade),
                request.FlowerAttributes.CountryOfOrigin);
        }

        if (request.Supplier != null)
        {
            product.SetSupplierInfo(request.Supplier.SupplierId, request.Supplier.LeadTimeDays);
        }

        product.SetAccountingInfo(request.Accounting.IncomeAccount, request.Accounting.ExpenseAccount);
        product.SetProductSettings(
            request.Settings.AllowAsRawMaterial,
            request.Settings.AvailableOnline,
            request.Settings.CommissionEligible);

        if (request.Tags?.Any() == true)
        {
            product.SetTags(string.Join(",", request.Tags));
        }

        // Set opening stock if provided
        if (request.OpeningStock.HasValue && request.OpeningStock.Value > 0)
        {
            product.AdjustStock(request.OpeningStock.Value);
        }

        // Set multi-unit configuration (no batches exist for new product)
        product.SetMultiUnit(request.IsMultiUnit, request.AvgUnitsPerStem);

        // Handle status
        if (request.Settings.Status == "inactive")
        {
            product.Deactivate();
        }

        await _repo.AddAsync(product);
        return product.Id;
    }

    public async Task UpdateAsync(Guid id, UpdateProductRequest request)
    {
        var product = await _repo.GetByIdAsync(id)
            ?? throw new KeyNotFoundException("Product not found");

        // ── Handle CategoryId change ──────────────────
        if (request.CategoryId.HasValue && request.CategoryId != Guid.Empty)
        {
            var categoryEntity = await _categoryRepo.GetByIdAsync(request.CategoryId.Value)
                ?? throw new InvalidOperationException($"Category '{request.CategoryId}' not found.");

            product.SetCategoryId(request.CategoryId.Value);
        }

        // ── Handle TaxRuleId change ──────────────────
        if (request.TaxRuleId.HasValue)
        {
            if (request.TaxRuleId == Guid.Empty)
                throw new InvalidOperationException("TaxRuleId cannot be empty.");

            var taxRule = await _taxRuleRepo.GetByIdAsync(_tenant.CompanyId!.Value, request.TaxRuleId.Value)
                ?? throw new InvalidOperationException($"TaxRule '{request.TaxRuleId}' not found.");

            product.SetTaxRuleId(request.TaxRuleId.Value);
        }

        if (request.ProductName != null || request.Barcode != null || request.Brand != null || request.Description != null)
        {
            product.UpdateBasicInfo(
                request.ProductName ?? product.Name,
                product.Sku,
                request.Barcode ?? product.Barcode,
                request.Brand ?? product.Brand,
                request.Description ?? product.Description);
        }

        if (request.RetailPrice.HasValue || request.CostPrice.HasValue)
        {
            product.UpdatePricing(
                request.RetailPrice ?? product.RetailPrice,
                request.CostPrice ?? product.CostPrice,
                request.WholesalePrice ?? product.WholesalePrice,
                request.WeddingEventPrice ?? product.WeddingEventPrice);
        }

        if (request.TaxCategory != null)
        {
            product.SetTaxCategory(ParseEnum<TaxCategory>(request.TaxCategory, TaxCategory.Standard));
        }

        if (request.TrackInventory.HasValue || request.TrackBatch.HasValue || request.ReorderLevel.HasValue)
        {
            product.SetInventorySettings(
                request.TrackInventory ?? product.TrackInventory,
                request.TrackBatch ?? product.TrackBatch,
                request.ReorderLevel ?? product.ReorderLevel);
        }

        if (request.ShelfLifeDays.HasValue || request.ExpiryAlertDays.HasValue || request.TemperatureNotes != null)
        {
            product.SetPerishableDetails(
                request.ShelfLifeDays ?? product.ShelfLifeDays,
                request.ExpiryAlertDays ?? product.ExpiryAlertDays,
                request.TemperatureNotes ?? product.TemperatureNotes);
        }

        if (request.FlowerAttributes != null)
        {
            product.SetFlowerAttributes(
                request.FlowerAttributes.Color ?? product.Color,
                request.FlowerAttributes.Variety ?? product.Variety,
                ParseNullableEnum<FlowerGrade>(request.FlowerAttributes.Grade) ?? product.FlowerGrade,
                request.FlowerAttributes.CountryOfOrigin ?? product.CountryOfOrigin);
        }

        if (request.Supplier != null)
        {
            product.SetSupplierInfo(
                request.Supplier.SupplierId ?? product.DefaultSupplierId,
                request.Supplier.LeadTimeDays ?? product.LeadTimeDays);
        }

        if (request.Accounting != null)
        {
            product.SetAccountingInfo(
                request.Accounting.IncomeAccount ?? product.IncomeAccount,
                request.Accounting.ExpenseAccount ?? product.ExpenseAccount);
        }

        if (request.Settings != null)
        {
            product.SetProductSettings(
                request.Settings.AllowAsRawMaterial,
                request.Settings.AvailableOnline,
                request.Settings.CommissionEligible);

            if (request.Settings.Status == "inactive")
                product.Deactivate();
            else if (request.Settings.Status == "active")
                product.Activate();
        }

        if (request.Tags != null)
        {
            product.SetTags(string.Join(",", request.Tags));
        }

        // Handle multi-unit configuration with inventory validation
        if (request.IsMultiUnit.HasValue || request.AvgUnitsPerStem.HasValue)
        {
            var existingBatches = await _batchRepo.GetBatchesByProductIdAsync(product.Id);
            product.SetMultiUnit(
                request.IsMultiUnit ?? product.IsMultiUnit,
                request.AvgUnitsPerStem ?? product.AvgUnitsPerStem,
                existingBatches);
        }

        await _repo.UpdateAsync(product);
    }

    public async Task<bool> ValidateSkuAsync(string sku, Guid? excludeProductId = null)
    {
        return !await _repo.SkuExistsAsync(sku, excludeProductId);
    }

    public async Task DeactivateAsync(Guid id)
    {
        var product = await _repo.GetByIdAsync(id)
            ?? throw new KeyNotFoundException("Product not found");

        product.Deactivate();
        await _repo.UpdateAsync(product);
    }

    public async Task ActivateAsync(Guid id)
    {
        var product = await _repo.GetByIdAsync(id)
            ?? throw new KeyNotFoundException("Product not found");

        product.Activate();
        await _repo.UpdateAsync(product);
    }

    public async Task<List<ProductListDto>> GetLowStockProductsAsync()
    {
        var products = await _repo.GetLowStockProductsAsync();
        return products.Select(ToListDto).ToList();
    }

    public async Task<List<ProductListDto>> GetReorderProductsAsync()
    {
        var products = await _repo.GetProductsNeedingReorderAsync();
        return products.Select(ToListDto).ToList();
    }

    private static ProductDto ToDto(Product p) => new()
    {
        Id = p.Id,
        Name = p.Name,
        Sku = p.Sku,
        Barcode = p.Barcode,
        Brand = p.Brand,
        ProductType = p.ProductType.ToString(),
        Category = p.Category.ToString(),
        CategoryId = p.CategoryId,
        CategoryName = p.ProductCategoryRef?.Name,
        Description = p.Description,
        UnitOfMeasure = p.UnitOfMeasure.ToString(),
        IsActive = p.IsActive,
        RetailPrice = p.RetailPrice,
        CostPrice = p.CostPrice,
        WholesalePrice = p.WholesalePrice,
        WeddingEventPrice = p.WeddingEventPrice,
        TaxCategory = p.TaxCategory.ToString(),
        TaxRuleId = p.TaxRuleId,
        TaxRuleName = p.TaxRule?.Name,
        TrackInventory = p.TrackInventory,
        TrackBatch = p.TrackBatch,
        StockQuantity = p.StockQuantity,
        MinimumStockLevel = p.MinimumStockLevel,
        ReorderLevel = p.ReorderLevel,
        IsLowStock = p.IsLowStock(),
        NeedsReorder = p.NeedsReorder(),
        IsPerishable = p.ProductCategoryRef?.IsPerishable ?? false,
        ShelfLifeDays = p.ShelfLifeDays,
        ExpiryAlertDays = p.ExpiryAlertDays,
        TemperatureNotes = p.TemperatureNotes,
        Color = p.Color,
        Variety = p.Variety,
        FlowerGrade = p.FlowerGrade?.ToString(),
        CountryOfOrigin = p.CountryOfOrigin,
        SeasonalAvailability = p.SeasonalAvailability.ToString(),
        DefaultSupplierId = p.DefaultSupplierId,
        LeadTimeDays = p.LeadTimeDays,
        IncomeAccount = p.IncomeAccount,
        ExpenseAccount = p.ExpenseAccount,
        AllowAsRawMaterial = p.AllowAsRawMaterial,
        AvailableOnline = p.AvailableOnline,
        CommissionEligible = p.CommissionEligible,
        Tags = string.IsNullOrEmpty(p.Tags) ? new List<string>() : p.Tags.Split(',').ToList(),
        CreatedAtUtc = p.CreatedAtUtc,
        UpdatedAtUtc = p.UpdatedAtUtc
    };

    private static ProductListDto ToListDto(Product p) => new()
    {
        Id = p.Id,
        Name = p.Name,
        Sku = p.Sku,
        ProductType = p.ProductType.ToString(),
        Category = p.Category.ToString(),
        CategoryId = p.CategoryId,
        CategoryName = p.ProductCategoryRef?.Name,
        TaxRuleId = p.TaxRuleId,
        TaxRuleName = p.TaxRule?.Name,
        RetailPrice = p.RetailPrice,
        CostPrice = p.CostPrice,
        StockQuantity = p.StockQuantity,
        IsActive = p.IsActive,
        IsLowStock = p.IsLowStock(),
        IsPerishable = p.ProductCategoryRef?.IsPerishable ?? false,
        ShelfLifeDays = p.ShelfLifeDays
    };

    private static T ParseEnum<T>(string? value, T defaultValue) where T : struct, Enum
    {
        if (string.IsNullOrEmpty(value))
            return defaultValue;

        // Try parsing snake_case to PascalCase
        var normalized = string.Concat(value.Split('_').Select(s =>
            char.ToUpper(s[0]) + s.Substring(1).ToLower()));

        if (Enum.TryParse<T>(normalized, true, out var result))
            return result;

        if (Enum.TryParse<T>(value, true, out result))
            return result;

        return defaultValue;
    }

    private static T? ParseNullableEnum<T>(string? value) where T : struct, Enum
    {
        if (string.IsNullOrEmpty(value))
            return null;

        var normalized = string.Concat(value.Split('_').Select(s =>
            char.ToUpper(s[0]) + s.Substring(1).ToLower()));

        if (Enum.TryParse<T>(normalized, true, out var result))
            return result;

        if (Enum.TryParse<T>(value, true, out result))
            return result;

        return null;
    }
}
