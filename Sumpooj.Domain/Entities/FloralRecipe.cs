namespace Sumpooj.Domain.Entities;

/// <summary>
/// A floral recipe (BOM) that defines how to assemble a finished product
/// </summary>
public class FloralRecipe : BaseEntity
{
    private FloralRecipe() { }

    public FloralRecipe(
        Guid companyId,
        string name,
        string? category,
        decimal sellingPrice,
        decimal? laborCost)
    {
        CompanyId = companyId;
        Name = name;
        Category = category;
        SellingPrice = sellingPrice;
        LaborCost = laborCost ?? 0;
        IsActive = true;
    }

    public Guid CompanyId { get; private set; }
    public string Name { get; private set; } = default!;
    public string? Category { get; private set; }
    public decimal SellingPrice { get; private set; }
    public decimal LaborCost { get; private set; }
    public string? SampleImages { get; private set; }
    public bool IsActive { get; private set; }

    public List<RecipeComponent> Components { get; private set; } = new();

    public void Update(string name, string? category, decimal sellingPrice, decimal laborCost, string? sampleImages)
    {
        Name = name;
        Category = category;
        SellingPrice = sellingPrice;
        LaborCost = laborCost;
        SampleImages = sampleImages;
        MarkUpdated();
    }

    public void Activate() { IsActive = true; MarkUpdated(); }
    public void Deactivate() { IsActive = false; MarkUpdated(); }
}

/// <summary>
/// A component (ingredient) in a floral recipe
/// </summary>
public class RecipeComponent : BaseEntity
{
    private RecipeComponent() { }

    public RecipeComponent(Guid recipeId, Guid productId, string productName, int quantityRequired, decimal unitCost)
    {
        RecipeId = recipeId;
        ProductId = productId;
        ProductName = productName;
        QuantityRequired = quantityRequired;
        UnitCost = unitCost;
    }

    public Guid RecipeId { get; private set; }
    public Guid ProductId { get; private set; }
    public string ProductName { get; private set; } = default!;
    public int QuantityRequired { get; private set; }
    public decimal UnitCost { get; private set; }
}
