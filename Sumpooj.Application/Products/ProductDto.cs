using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Products;

public class ProductDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = default!;
    public string Sku { get; set; } = default!;
    public string? Barcode { get; set; }
    public string? Brand { get; set; }
    public string ProductType { get; set; } = default!;
    public string Category { get; set; } = default!;
    public string? Description { get; set; }
    public string UnitOfMeasure { get; set; } = default!;
    public bool IsActive { get; set; }

    // Pricing
    public decimal RetailPrice { get; set; }
    public decimal CostPrice { get; set; }
    public decimal? WholesalePrice { get; set; }
    public decimal? WeddingEventPrice { get; set; }
    public string TaxCategory { get; set; } = default!;

    // Inventory
    public bool TrackInventory { get; set; }
    public bool TrackBatch { get; set; }
    public int StockQuantity { get; set; }
    public int MinimumStockLevel { get; set; }
    public int ReorderLevel { get; set; }
    public bool IsLowStock { get; set; }
    public bool NeedsReorder { get; set; }

    // Perishable
    public bool IsPerishable { get; set; }
    public int? ShelfLifeDays { get; set; }
    public int? ExpiryAlertDays { get; set; }
    public string? TemperatureNotes { get; set; }

    // Flower-specific
    public string? Color { get; set; }
    public string? Variety { get; set; }
    public string? FlowerGrade { get; set; }
    public string? CountryOfOrigin { get; set; }
    public string? SeasonalAvailability { get; set; }

    // Supplier
    public Guid? DefaultSupplierId { get; set; }
    public int? LeadTimeDays { get; set; }

    // Accounting
    public string? IncomeAccount { get; set; }
    public string? ExpenseAccount { get; set; }

    // Settings
    public bool AllowAsRawMaterial { get; set; }
    public bool AvailableOnline { get; set; }
    public bool CommissionEligible { get; set; }

    // Tags
    public List<string> Tags { get; set; } = new();

    public DateTime CreatedAtUtc { get; set; }
    public DateTime? UpdatedAtUtc { get; set; }
}

public class ProductListDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = default!;
    public string Sku { get; set; } = default!;
    public string ProductType { get; set; } = default!;
    public string Category { get; set; } = default!;
    public decimal RetailPrice { get; set; }
    public decimal CostPrice { get; set; }
    public int StockQuantity { get; set; }
    public bool IsActive { get; set; }
    public bool IsLowStock { get; set; }
    public bool IsPerishable { get; set; }
    public int? ShelfLifeDays { get; set; }
}
