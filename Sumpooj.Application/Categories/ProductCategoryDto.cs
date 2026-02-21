namespace Sumpooj.Application.Categories;

// ─── Response DTOs ───────────────────────────────────────────

public class ProductCategoryDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = default!;
    public bool IsPerishable { get; set; }
    public bool TrackBatchByDefault { get; set; }
    public bool IsActive { get; set; }
    public int ProductCount { get; set; }
    public DateTime CreatedAtUtc { get; set; }
    public DateTime? UpdatedAtUtc { get; set; }
}

// ─── Request DTOs ────────────────────────────────────────────

public class CreateProductCategoryRequest
{
    public string Name { get; set; } = default!;
    public bool IsPerishable { get; set; }
    public bool TrackBatchByDefault { get; set; }
}

public class UpdateProductCategoryRequest
{
    public string Name { get; set; } = default!;
    public bool IsPerishable { get; set; }
    public bool TrackBatchByDefault { get; set; }
}
