namespace Sumpooj.Application.Products;

public class CreateProductRequest
{
    // Core identification
    public string ProductName { get; set; } = default!;
    public string Sku { get; set; } = default!;
    public string? Barcode { get; set; }

    // Classification
    public string ProductType { get; set; } = "fresh_flower";
    public string? Category { get; set; }
    public Guid? CategoryId { get; set; }
    public string? Brand { get; set; }
    public string? Description { get; set; }
    public List<string> Tags { get; set; } = new();

    // Units & Pricing
    public string UnitOfMeasure { get; set; } = "stem";
    public decimal RetailPrice { get; set; }
    public decimal CostPrice { get; set; }
    public decimal? WholesalePrice { get; set; }
    public decimal? WeddingEventPrice { get; set; }

    // Taxation
    public Guid? TaxRuleId { get; set; }
    public string TaxCategory { get; set; } = "standard";

    // Inventory
    public bool TrackInventory { get; set; } = true;
    public bool TrackBatch { get; set; }
    public int? OpeningStock { get; set; }
    public int? ReorderLevel { get; set; }

    // Perishable details (IsPerishable is derived from Category)
    public int? ShelfLifeDays { get; set; }
    public int? ExpiryAlertDays { get; set; }
    public string? TemperatureNotes { get; set; }

    // Flower Attributes
    public FlowerAttributesRequest? FlowerAttributes { get; set; }

    // Supplier
    public SupplierInfoRequest? Supplier { get; set; }

    // Accounting
    public AccountingInfoRequest Accounting { get; set; } = new();

    // Settings
    public ProductSettingsRequest Settings { get; set; } = new();
}

public class FlowerAttributesRequest
{
    public string? Color { get; set; }
    public string? Variety { get; set; }
    public string? Grade { get; set; }
    public string? CountryOfOrigin { get; set; }
    public List<string> Seasonality { get; set; } = new();
}

public class SupplierInfoRequest
{
    public Guid? SupplierId { get; set; }
    public int? LeadTimeDays { get; set; }
}

public class AccountingInfoRequest
{
    public string IncomeAccount { get; set; } = "4000";
    public string ExpenseAccount { get; set; } = "5000";
}

public class ProductSettingsRequest
{
    public string Status { get; set; } = "active";
    public bool AllowAsRawMaterial { get; set; }
    public bool AvailableOnline { get; set; }
    public bool CommissionEligible { get; set; }
}

public class UpdateProductRequest
{
    public string? ProductName { get; set; }
    public Guid? CategoryId { get; set; }
    public string? Barcode { get; set; }
    public string? Brand { get; set; }
    public string? Description { get; set; }
    public List<string>? Tags { get; set; }

    // Pricing
    public decimal? RetailPrice { get; set; }
    public decimal? CostPrice { get; set; }
    public decimal? WholesalePrice { get; set; }
    public decimal? WeddingEventPrice { get; set; }
    public Guid? TaxRuleId { get; set; }
    public string? TaxCategory { get; set; }

    // Inventory
    public bool? TrackInventory { get; set; }
    public bool? TrackBatch { get; set; }
    public int? ReorderLevel { get; set; }

    // Perishable details (IsPerishable is derived from Category)
    public int? ShelfLifeDays { get; set; }
    public int? ExpiryAlertDays { get; set; }
    public string? TemperatureNotes { get; set; }

    // Flower Attributes
    public FlowerAttributesRequest? FlowerAttributes { get; set; }

    // Supplier
    public SupplierInfoRequest? Supplier { get; set; }

    // Accounting
    public AccountingInfoRequest? Accounting { get; set; }

    // Settings
    public ProductSettingsRequest? Settings { get; set; }
}

public class ProductSearchRequest
{
    public string? Query { get; set; }
    public string? ProductType { get; set; }
    public string? Category { get; set; }
    public bool? IsActive { get; set; }
    public bool? IsPerishable { get; set; }
    public bool? LowStockOnly { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}
