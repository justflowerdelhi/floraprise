namespace Sumpooj.Domain.Entities;

public class InventoryReservation : BaseEntity
{
    private InventoryReservation() { }

    public InventoryReservation(
        Guid salesOrderId,
        Guid productBatchId,
        Guid productId,
        int reservedUnits)
    {
        if (reservedUnits <= 0)
            throw new ArgumentException("ReservedUnits must be greater than zero.");

        SalesOrderId = salesOrderId;
        ProductBatchId = productBatchId;
        ProductId = productId;
        ReservedUnits = reservedUnits;
        Status = ReservationStatus.Active;
    }

    public Guid SalesOrderId { get; private set; }
    public Guid ProductBatchId { get; private set; }
    public Guid ProductId { get; private set; }
    public int ReservedUnits { get; private set; }
    public ReservationStatus Status { get; private set; }

    /// <summary>
    /// Release this reservation, returning units to the available pool.
    /// Only allowed when the reservation is currently Active.
    /// </summary>
    public void MarkReleased()
    {
        GuardActiveStatus(nameof(MarkReleased));
        Status = ReservationStatus.Released;
        MarkUpdated();
    }

    /// <summary>
    /// Mark this reservation as converted to actual usage.
    /// Only allowed when the reservation is currently Active.
    /// </summary>
    public void MarkConverted()
    {
        GuardActiveStatus(nameof(MarkConverted));
        Status = ReservationStatus.Converted;
        MarkUpdated();
    }

    private void GuardActiveStatus(string operation)
    {
        if (Status != ReservationStatus.Active)
            throw new InvalidOperationException(
                $"Cannot {operation} — reservation is already {Status}.");
    }
}
