namespace Sumpooj.Domain.Entities;

public class VendorExecution : BaseEntity
{
    private VendorExecution() { }

    public VendorExecution(
        Guid salesOrderId,
        Guid vendorId,
        decimal vendorCost,
        decimal deliveryCharge)
    {
        if (vendorCost < 0)
            throw new ArgumentException("VendorCost cannot be negative.");
        if (deliveryCharge < 0)
            throw new ArgumentException("DeliveryCharge cannot be negative.");

        SalesOrderId = salesOrderId;
        VendorId = vendorId;
        VendorCost = vendorCost;
        DeliveryCharge = deliveryCharge;
        TotalVendorPayable = vendorCost + deliveryCharge;
        Status = VendorExecutionStatus.Pending;
    }

    public Guid SalesOrderId { get; private set; }
    public Guid VendorId { get; private set; }
    public decimal VendorCost { get; private set; }
    public decimal DeliveryCharge { get; private set; }
    public decimal TotalVendorPayable { get; private set; }
    public VendorExecutionStatus Status { get; private set; }

    /// <summary>
    /// Vendor has accepted the order. Pending → Accepted.
    /// </summary>
    public void MarkAccepted()
    {
        GuardTransition(VendorExecutionStatus.Pending, nameof(MarkAccepted));
        Status = VendorExecutionStatus.Accepted;
        MarkUpdated();
    }

    /// <summary>
    /// Vendor has delivered the order. Accepted → Delivered.
    /// </summary>
    public void MarkDelivered()
    {
        GuardTransition(VendorExecutionStatus.Accepted, nameof(MarkDelivered));
        Status = VendorExecutionStatus.Delivered;
        MarkUpdated();
    }

    /// <summary>
    /// Payment to vendor has been completed. Delivered → Paid.
    /// </summary>
    public void MarkPaid()
    {
        GuardTransition(VendorExecutionStatus.Delivered, nameof(MarkPaid));
        Status = VendorExecutionStatus.Paid;
        MarkUpdated();
    }

    private void GuardTransition(VendorExecutionStatus requiredStatus, string operation)
    {
        if (Status != requiredStatus)
            throw new InvalidOperationException(
                $"Cannot {operation} — current status is {Status}, expected {requiredStatus}.");
    }
}
