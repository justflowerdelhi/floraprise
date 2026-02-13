namespace Sumpooj.Domain.Entities;

public class StockMovement : BaseEntity
{
    private StockMovement() { }

    public StockMovement(
        Guid companyId,
        Guid productId,
        StockMovementType movementType,
        int quantity,
        string? reason)
    {
        CompanyId = companyId;
        ProductId = productId;
        MovementType = movementType;
        Quantity = quantity;
        Reason = reason;
        MovementDate = DateTime.UtcNow;
    }

    public Guid CompanyId { get; private set; }
    public Guid ProductId { get; private set; }
    public StockMovementType MovementType { get; private set; }
    public int Quantity { get; private set; }
    public DateTime MovementDate { get; private set; }
    public string? Reason { get; private set; }

    // Reference to related entities
    public Guid? OrderId { get; private set; }
    public Guid? PurchaseOrderId { get; private set; }
    public Guid? UserId { get; private set; }

    public void LinkToOrder(Guid orderId)
    {
        OrderId = orderId;
        MarkUpdated();
    }

    public void LinkToPurchaseOrder(Guid purchaseOrderId)
    {
        PurchaseOrderId = purchaseOrderId;
        MarkUpdated();
    }

    public void RecordUser(Guid userId)
    {
        UserId = userId;
        MarkUpdated();
    }

    public void UpdateReason(string reason)
    {
        Reason = reason;
        MarkUpdated();
    }
}
