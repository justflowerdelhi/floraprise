namespace Sumpooj.Domain.Entities;

public class ProductBatch : BaseEntity
{
    private ProductBatch() { }

    public ProductBatch(
        Guid companyId,
        Guid productId,
        string batchNumber,
        int quantityReceived,
        decimal costPerUnit,
        DateTime receivedDate,
        DateTime? expiryDate,
        Guid? supplierId,
        Guid? locationId,
        string? storageLocation)
    {
        CompanyId = companyId;
        ProductId = productId;
        BatchNumber = batchNumber;
        QuantityReceived = quantityReceived;
        QuantityRemaining = quantityReceived;
        CostPerUnit = costPerUnit;
        ReceivedDate = receivedDate;
        ExpiryDate = expiryDate;
        SupplierId = supplierId;
        LocationId = locationId;
        StorageLocation = storageLocation;
        IsActive = true;
    }

    public Guid CompanyId { get; private set; }
    public Guid ProductId { get; private set; }
    public string BatchNumber { get; private set; }
    public int QuantityReceived { get; private set; }
    public int QuantityRemaining { get; private set; }
    public decimal CostPerUnit { get; private set; }
    public decimal SellingPricePerUnit { get; private set; }
    public DateTime ReceivedDate { get; private set; }
    public DateTime? ExpiryDate { get; private set; }
    public Guid? SupplierId { get; private set; }
    public Guid? LocationId { get; private set; }
    public string? StorageLocation { get; private set; }
    public Guid? PurchaseOrderId { get; private set; }
    public bool IsActive { get; private set; }

    public void SetSellingPrice(decimal price)
    {
        if (price < 0)
            throw new ArgumentException("Price cannot be negative");
        SellingPricePerUnit = price;
        MarkUpdated();
    }

    public void DeductQuantity(int quantity)
    {
        if (quantity > QuantityRemaining)
            throw new InvalidOperationException("Insufficient quantity in batch");

        QuantityRemaining -= quantity;
        MarkUpdated();
    }

    public void AddQuantity(int quantity)
    {
        QuantityRemaining += quantity;
        MarkUpdated();
    }

    public void UpdateStorageLocation(string? storageLocation)
    {
        StorageLocation = storageLocation;
        MarkUpdated();
    }

    public void LinkToPurchaseOrder(Guid purchaseOrderId)
    {
        PurchaseOrderId = purchaseOrderId;
        MarkUpdated();
    }

    public bool IsExpired() => ExpiryDate.HasValue && ExpiryDate.Value.Date <= DateTime.UtcNow.Date;

    public bool IsExpiringSoon(int daysThreshold)
    {
        if (!ExpiryDate.HasValue) return false;
        var threshold = DateTime.UtcNow.AddDays(daysThreshold).Date;
        return ExpiryDate.Value.Date <= threshold && !IsExpired();
    }

    public void Deactivate()
    {
        IsActive = false;
        MarkUpdated();
    }
}
