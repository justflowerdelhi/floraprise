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
        decimal price,
        string? description)
    {
        CompanyId = companyId;
        Name = name;
        Sku = sku;
        ProductType = productType;
        Category = category;
        Price = price;
        Description = description;
        IsActive = true;
        StockQuantity = 0;
    }

    public Guid CompanyId { get; private set; }
    public string Name { get; private set; }
    public string Sku { get; private set; }
    public ProductType ProductType { get; private set; }
    public ProductCategory Category { get; private set; }
    public decimal Price { get; private set; }
    public string? Description { get; private set; }
    public bool IsActive { get; private set; }

    // Inventory
    public int StockQuantity { get; private set; }
    public int MinimumStockLevel { get; private set; }

    // Flower-specific properties
    public string? Color { get; private set; }
    public SeasonalAvailability SeasonalAvailability { get; private set; }

    // Arrangement-specific
    public int? EstimatedMinutesToAssemble { get; private set; }

    public void UpdatePricing(decimal newPrice)
    {
        if (newPrice < 0)
            throw new ArgumentException("Price cannot be negative");

        Price = newPrice;
        MarkUpdated();
    }

    public void UpdateDetails(string name, string? description, string? color)
    {
        Name = name;
        Description = description;
        Color = color;
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

    public void SetSeasonalAvailability(SeasonalAvailability availability)
    {
        SeasonalAvailability = availability;
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
