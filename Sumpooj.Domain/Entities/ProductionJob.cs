namespace Sumpooj.Domain.Entities;

/// <summary>
/// Represents a production job tied to an order
/// </summary>
public class ProductionJob : BaseEntity
{
    private ProductionJob() { }

    public ProductionJob(
        Guid companyId,
        Guid orderId,
        string description)
    {
        CompanyId = companyId;
        OrderId = orderId;
        Description = description;
        Status = ProductionStatus.Pending;
    }

    public Guid CompanyId { get; private set; }
    public Guid OrderId { get; private set; }
    public string Description { get; private set; } = default!;
    public ProductionStatus Status { get; private set; }

    public List<ProductionMaterialUsage> MaterialUsages { get; private set; } = new();

    public void Start()
    {
        Status = ProductionStatus.InProgress;
        MarkUpdated();
    }

    public void Complete()
    {
        Status = ProductionStatus.Completed;
        MarkUpdated();
    }
}

public enum ProductionStatus
{
    Pending,
    InProgress,
    Completed
}

/// <summary>
/// Tracks materials consumed by a production job
/// </summary>
public class ProductionMaterialUsage : BaseEntity
{
    private ProductionMaterialUsage() { }

    public ProductionMaterialUsage(Guid jobId, Guid productId, string productName, int unitsUsed)
    {
        JobId = jobId;
        ProductId = productId;
        ProductName = productName;
        UnitsUsed = unitsUsed;
    }

    public Guid JobId { get; private set; }
    public Guid ProductId { get; private set; }
    public string ProductName { get; private set; } = default!;
    public int UnitsUsed { get; private set; }
}
