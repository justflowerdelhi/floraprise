namespace Sumpooj.Domain.Entities;

public class Product : BaseEntity
{
    private Product() { }

    public Product(
        Guid companyId,
        string name,
        string sku,
        ProductType productType,
        ProductCategory category,
        decimal retailPrice,
        decimal costPrice,
        string? description)
    {
        CompanyId = companyId;
        Name = name;
        Sku = sku;
        ProductType = productType;
        Category = category;
        RetailPrice = retailPrice;
        CostPrice = costPrice;
        Description = description;
        IsActive = true;
        StockQuantity = 0;
        TrackInventory = true;
        UnitOfMeasure = UnitOfMeasure.Stem;
        TaxCategory = TaxCategory.Standard;
    }

    public Guid CompanyId { get; private set; }
    public string Name { get; private set; }
    public string Sku { get; private set; }
    public string? Barcode { get; private set; }
    public string? Brand { get; private set; }
    public ProductType ProductType { get; private set; }
    public ProductCategory Category { get; private set; }
    public string? Description { get; private set; }
    public bool IsActive { get; private set; }
    public UnitOfMeasure UnitOfMeasure { get; private set; }

    // Dynamic category (nullable, future replacement for enum Category)
    public Guid? CategoryId { get; private set; }
    public ProductCategoryEntity? ProductCategoryRef { get; private set; }

    // Taxation
    public Guid? TaxRuleId { get; private set; }
    public TaxRule? TaxRule { get; private set; }

    // Pricing
    public decimal RetailPrice { get; private set; }
    public decimal CostPrice { get; private set; }
    public decimal? WholesalePrice { get; private set; }
    public decimal? WeddingEventPrice { get; private set; }
    public TaxCategory TaxCategory { get; private set; }

    // Inventory
    public bool TrackInventory { get; private set; }
    public bool TrackBatch { get; private set; }
    public int StockQuantity { get; private set; }
    public int MinimumStockLevel { get; private set; }
    public int ReorderLevel { get; private set; }

    // Perishable
    public bool IsPerishable { get; private set; }
    public int? ShelfLifeDays { get; private set; }
    public int? ExpiryAlertDays { get; private set; }
    public string? TemperatureNotes { get; private set; }

    // Multi-unit support (e.g. a stem may yield multiple usable units)
    public bool IsMultiUnit { get; private set; }
    public int AvgUnitsPerStem { get; private set; } = 1;

    // Flower-specific properties
    public string? Color { get; private set; }
    public string? Variety { get; private set; }
    public FlowerGrade? FlowerGrade { get; private set; }
    public string? CountryOfOrigin { get; private set; }
    public SeasonalAvailability SeasonalAvailability { get; private set; }

    // Arrangement-specific
    public int? EstimatedMinutesToAssemble { get; private set; }

    // Supplier
    public Guid? DefaultSupplierId { get; private set; }
    public int? LeadTimeDays { get; private set; }

    // Accounting
    public string? IncomeAccount { get; private set; }
    public string? ExpenseAccount { get; private set; }

    // Settings
    public bool AllowAsRawMaterial { get; private set; }
    public bool AvailableOnline { get; private set; }
    public bool CommissionEligible { get; private set; }

    // Tags (stored as JSON or comma-separated)
    public string? Tags { get; private set; }

    // Legacy property for backward compatibility
    public decimal Price => RetailPrice;

    public void SetCategoryId(Guid? categoryId)
    {
        CategoryId = categoryId;
        MarkUpdated();
    }

    public void UpdatePricing(decimal retailPrice, decimal costPrice, decimal? wholesalePrice = null, decimal? weddingEventPrice = null)
    {
        if (retailPrice < 0 || costPrice < 0)
            throw new ArgumentException("Price cannot be negative");

        RetailPrice = retailPrice;
        CostPrice = costPrice;
        WholesalePrice = wholesalePrice;
        WeddingEventPrice = weddingEventPrice;
        MarkUpdated();
    }

    public void UpdateDetails(string name, string? description, string? color)
    {
        Name = name;
        Description = description;
        Color = color;
        MarkUpdated();
    }

    public void UpdateBasicInfo(string name, string sku, string? barcode, string? brand, string? description)
    {
        Name = name;
        Sku = sku;
        Barcode = barcode;
        Brand = brand;
        Description = description;
        MarkUpdated();
    }

    /// <summary>
    /// Set shelf-life / expiry details.
    /// IsPerishable is now derived from ProductCategoryRef — do NOT set it here.
    /// </summary>
    public void SetPerishableDetails(int? shelfLifeDays, int? expiryAlertDays, string? temperatureNotes)
    {
        ShelfLifeDays = shelfLifeDays;
        ExpiryAlertDays = expiryAlertDays;
        TemperatureNotes = temperatureNotes;
        MarkUpdated();
    }

    public void SetFlowerAttributes(string? color, string? variety, FlowerGrade? grade, string? countryOfOrigin)
    {
        Color = color;
        Variety = variety;
        FlowerGrade = grade;
        CountryOfOrigin = countryOfOrigin;
        MarkUpdated();
    }

    public void SetSupplierInfo(Guid? supplierId, int? leadTimeDays)
    {
        DefaultSupplierId = supplierId;
        LeadTimeDays = leadTimeDays;
        MarkUpdated();
    }

    public void SetAccountingInfo(string? incomeAccount, string? expenseAccount)
    {
        IncomeAccount = incomeAccount;
        ExpenseAccount = expenseAccount;
        MarkUpdated();
    }

    public void SetInventorySettings(bool trackInventory, bool trackBatch, int reorderLevel)
    {
        TrackInventory = trackInventory;
        TrackBatch = trackBatch;
        ReorderLevel = reorderLevel;
        MarkUpdated();
    }

    public void SetProductSettings(bool allowAsRawMaterial, bool availableOnline, bool commissionEligible)
    {
        AllowAsRawMaterial = allowAsRawMaterial;
        AvailableOnline = availableOnline;
        CommissionEligible = commissionEligible;
        MarkUpdated();
    }

    public void SetTags(string? tags)
    {
        Tags = tags;
        MarkUpdated();
    }

    public void SetUnitOfMeasure(UnitOfMeasure unit)
    {
        UnitOfMeasure = unit;
        MarkUpdated();
    }

    public void SetTaxCategory(TaxCategory taxCategory)
    {
        TaxCategory = taxCategory;
        MarkUpdated();
    }

    public void SetTaxRuleId(Guid? taxRuleId)
    {
        TaxRuleId = taxRuleId;
        MarkUpdated();
    }

    public void AdjustStock(int quantity)
    {
        StockQuantity += quantity;
        MarkUpdated();
    }

    public void SetMinimumStockLevel(int level)
    {
        MinimumStockLevel = level;
        MarkUpdated();
    }

    public bool IsLowStock() => StockQuantity <= MinimumStockLevel;

    public bool NeedsReorder() => StockQuantity <= ReorderLevel;

    public void SetSeasonalAvailability(SeasonalAvailability availability)
    {
        SeasonalAvailability = availability;
        MarkUpdated();
    }

    public void SetMultiUnit(bool isMultiUnit, int avgUnitsPerStem = 1)
    {
        if (avgUnitsPerStem < 1)
            throw new ArgumentException("AvgUnitsPerStem must be at least 1.");

        IsMultiUnit = isMultiUnit;
        AvgUnitsPerStem = isMultiUnit ? avgUnitsPerStem : 1;
        MarkUpdated();
    }

    /// <summary>
    /// Sets multi-unit configuration with inventory existence validation.
    /// Use this overload when product may have existing batches to enforce domain invariant.
    /// </summary>
    /// <param name="isMultiUnit">Whether the product supports multi-unit consumption.</param>
    /// <param name="avgUnitsPerStem">Average units per stem (must be >= 1).</param>
    /// <param name="existingBatches">Existing product batches to validate against.</param>
    public void SetMultiUnit(bool isMultiUnit, int avgUnitsPerStem, IEnumerable<ProductBatch> existingBatches)
    {
        if (avgUnitsPerStem < 1)
            throw new ArgumentException("AvgUnitsPerStem must be at least 1.");

        // Check if any batch has existing inventory activity
        if (existingBatches != null)
        {
            var hasExistingInventory = existingBatches.Any(b =>
                b.StemsInStock > 0 || b.UsedUnits > 0 || b.ReservedUnits > 0);

            // Only prevent change if configuration is actually changing
            if (hasExistingInventory && (IsMultiUnit != isMultiUnit || AvgUnitsPerStem != avgUnitsPerStem))
            {
                throw new InvalidOperationException(
                    "Cannot change multi-unit configuration after inventory exists.");
            }
        }

        IsMultiUnit = isMultiUnit;
        AvgUnitsPerStem = isMultiUnit ? avgUnitsPerStem : 1;
        MarkUpdated();
    }

    public void SetAssemblyTime(int minutes)
    {
        EstimatedMinutesToAssemble = minutes;
        MarkUpdated();
    }

    public void Deactivate()
    {
        IsActive = false;
        MarkUpdated();
    }

    public void Activate()
    {
        IsActive = true;
        MarkUpdated();
    }
}
