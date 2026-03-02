namespace Sumpooj.Application.Production;

// ─── Floral Recipe DTOs ────────────────────────────────────

public class RecipeComponentDto
{
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = default!;
    public int QuantityRequired { get; set; }
    public decimal UnitCost { get; set; }
}

public class FloralRecipeDto
{
    public Guid Id { get; set; }
    public string TenantId { get; set; } = default!;
    public string Name { get; set; } = default!;
    public string? Category { get; set; }
    public decimal SellingPrice { get; set; }
    public decimal? LaborCost { get; set; }
    public List<RecipeComponentDto> Components { get; set; } = new();
    public List<string>? SampleImages { get; set; }
    public bool IsActive { get; set; }
    public string CreatedAt { get; set; } = default!;
    public string UpdatedAt { get; set; } = default!;
}

public class CreateRecipeRequest
{
    public string Name { get; set; } = default!;
    public string? Category { get; set; }
    public decimal SellingPrice { get; set; }
    public decimal? LaborCost { get; set; }
    public List<RecipeComponentDto> Components { get; set; } = new();
    public List<string>? SampleImages { get; set; }
    public bool IsActive { get; set; } = true;
}

public class UpdateRecipeRequest
{
    public string Name { get; set; } = default!;
    public string? Category { get; set; }
    public decimal SellingPrice { get; set; }
    public decimal? LaborCost { get; set; }
    public List<RecipeComponentDto> Components { get; set; } = new();
    public List<string>? SampleImages { get; set; }
    public bool IsActive { get; set; } = true;
}

// ─── Finished Goods DTOs ───────────────────────────────────

public class FinishedGoodsBatchDto
{
    public Guid Id { get; set; }
    public Guid RecipeId { get; set; }
    public string RecipeName { get; set; } = default!;
    public string BatchCode { get; set; } = default!;
    public string Barcode { get; set; } = default!;
    public int QuantityProduced { get; set; }
    public int QuantityAvailable { get; set; }
    public string ExpectedExpiry { get; set; } = default!;
    public Guid LocationId { get; set; }
    public string LocationName { get; set; } = default!;
    public string Status { get; set; } = default!;
    public string ProducedAt { get; set; } = default!;
}

// ─── Production Run DTOs ───────────────────────────────────

public class ProductionRunRequest
{
    public Guid RecipeId { get; set; }
    public int Quantity { get; set; }
    public string ExpectedExpiry { get; set; } = default!;
    public Guid LocationId { get; set; }
}

public class ComponentDeduction
{
    public Guid ProductId { get; set; }
    public int QuantityDeducted { get; set; }
}

public class ProductionRunResult
{
    public Guid BatchId { get; set; }
    public string BatchCode { get; set; } = default!;
    public string Barcode { get; set; } = default!;
    public int QuantityProduced { get; set; }
    public List<ComponentDeduction> ComponentsDeducted { get; set; } = new();
    public decimal TotalCost { get; set; }
}

// ─── On-Demand & Custom ────────────────────────────────────

public class OnDemandAssemblyRequest
{
    public Guid RecipeId { get; set; }
    public int Quantity { get; set; }
    public Guid LocationId { get; set; }
}

public class OnDemandAssemblyResult
{
    public bool Success { get; set; }
    public List<ComponentDeduction> ComponentsDeducted { get; set; } = new();
}

public class CustomBouquetComponent
{
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = default!;
    public int Quantity { get; set; }
    public decimal UnitCost { get; set; }
}

public class CustomBouquetRequest
{
    public List<CustomBouquetComponent> Components { get; set; } = new();
    public decimal SellingPrice { get; set; }
    public decimal? LaborCost { get; set; }
    public string? Image { get; set; }
}

public class CustomBouquetSaveRequest : CustomBouquetRequest
{
    public string Name { get; set; } = default!;
    public string? Category { get; set; }
}

// ─── Maintenance ───────────────────────────────────────────

public class MaintenanceReplacementDto
{
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = default!;
    public int QuantityReplaced { get; set; }
    public string Reason { get; set; } = default!;
}

public class MaintenanceLogDto
{
    public Guid Id { get; set; }
    public Guid FinishedBatchId { get; set; }
    public string BatchCode { get; set; } = default!;
    public List<MaintenanceReplacementDto> Replacements { get; set; } = new();
    public string PerformedAt { get; set; } = default!;
    public string? PerformedBy { get; set; }
    public string? Notes { get; set; }
}

public class MaintenanceRequest
{
    public Guid FinishedBatchId { get; set; }
    public List<MaintenanceReplacementDto> Replacements { get; set; } = new();
    public string? Notes { get; set; }
}

// ─── Wastage ───────────────────────────────────────────────

public class WastageLogDto
{
    public Guid Id { get; set; }
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = default!;
    public int Quantity { get; set; }
    public string Reason { get; set; } = default!;
    public Guid? RelatedFinishedBatchId { get; set; }
    public string? RelatedBatchCode { get; set; }
    public string CreatedAt { get; set; } = default!;
    public string? CreatedBy { get; set; }
}

public class CreateWastageRequest
{
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = default!;
    public int Quantity { get; set; }
    public string Reason { get; set; } = default!;
    public Guid? RelatedFinishedBatchId { get; set; }
    public string? RelatedBatchCode { get; set; }
}

// ─── Production Job DTOs ───────────────────────────────────

public class ProductionJobDto
{
    public Guid JobId { get; set; }
    public Guid OrderId { get; set; }
    public string? OrderNumber { get; set; }
    public string Description { get; set; } = default!;
    public string Status { get; set; } = default!;
    public string CreatedAtUtc { get; set; } = default!;
    public List<MaterialUsageDto>? MaterialUsages { get; set; }
}

public class CreateProductionJobRequest
{
    public Guid OrderId { get; set; }
    public string Description { get; set; } = default!;
}

public class MaterialUsageDto
{
    public Guid Id { get; set; }
    public string ProductName { get; set; } = default!;
    public int UnitsUsed { get; set; }
    public int AvailableUnits { get; set; }
}

public class AddMaterialUsageRequest
{
    public Guid JobId { get; set; }
    public Guid ProductId { get; set; }
    public int UnitsUsed { get; set; }
}

// ─── Inventory Product (simplified for production screen) ──

public class InventoryProductDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = default!;
    public string ProductType { get; set; } = default!;
    public int QuantityAvailable { get; set; }
    public decimal UnitCost { get; set; }
    public Guid LocationId { get; set; }
}

public class DeductBatchRequest
{
    public int Quantity { get; set; }
}
