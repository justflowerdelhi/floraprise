namespace Sumpooj.Domain.Entities;

public class Delivery : BaseEntity
{
    private Delivery() { }

    public Delivery(
        Guid salesOrderId,
        DateTime deliveryDate,
        string timeSlot,
        string deliveryAddress)
    {
        if (salesOrderId == Guid.Empty)
            throw new ArgumentException("SalesOrderId is required.", nameof(salesOrderId));
        if (string.IsNullOrWhiteSpace(timeSlot))
            throw new ArgumentException("TimeSlot is required.", nameof(timeSlot));
        if (string.IsNullOrWhiteSpace(deliveryAddress))
            throw new ArgumentException("DeliveryAddress is required.", nameof(deliveryAddress));

        SalesOrderId = salesOrderId;
        DeliveryDate = EnsureUtc(deliveryDate);
        TimeSlot = timeSlot;
        DeliveryAddress = deliveryAddress;
        Status = DeliveryStatus.Scheduled;
    }

    public Guid SalesOrderId { get; private set; }
    public DateTime DeliveryDate { get; private set; }
    public string TimeSlot { get; private set; } = string.Empty;
    public string DeliveryAddress { get; private set; } = string.Empty;
    public string? PostalCode { get; private set; }
    public Guid? DeliveryPersonId { get; private set; }
    public DeliveryStatus Status { get; private set; }

    // Route assignment
    public Guid? DeliveryRouteId { get; private set; }
    public int? StopOrder { get; private set; }
    /// <summary>
    /// Assign this delivery to a route and stop order.
    /// </summary>
    public void AssignToRoute(Guid routeId, int stopOrder)
    {
        if (Status != DeliveryStatus.Scheduled)
            throw new InvalidOperationException("Only Scheduled deliveries can be assigned to a route.");
        if (DeliveryRouteId.HasValue)
            throw new InvalidOperationException("Delivery is already assigned to a route.");
        if (Status == DeliveryStatus.Delivered || Status == DeliveryStatus.Cancelled)
            throw new InvalidOperationException("Cannot assign route for delivered or cancelled deliveries.");
        DeliveryRouteId = routeId;
        StopOrder = stopOrder;
        MarkUpdated();
    }

    /// <summary>
    /// Remove this delivery from its route assignment.
    /// </summary>
    public void RemoveFromRoute()
    {
        DeliveryRouteId = null;
        StopOrder = null;
        MarkUpdated();
    }

    // ── Domain Methods ───────────────────────────────────────────────────

    /// <summary>
    /// Assign a delivery person and mark out for delivery.
    /// </summary>
    public void MarkOutForDelivery(Guid? deliveryPersonId = null)
    {
        if (Status != DeliveryStatus.Scheduled)
            throw new InvalidOperationException("Only Scheduled deliveries can be marked OutForDelivery.");

        if (deliveryPersonId.HasValue)
            DeliveryPersonId = deliveryPersonId;

        Status = DeliveryStatus.OutForDelivery;
        MarkUpdated();
    }

    /// <summary>
    /// Mark the delivery as successfully completed.
    /// </summary>
    public void MarkDelivered()
    {
        if (Status != DeliveryStatus.OutForDelivery)
            throw new InvalidOperationException("Only OutForDelivery deliveries can be marked Delivered.");

        Status = DeliveryStatus.Delivered;
        MarkUpdated();
    }

    /// <summary>
    /// Mark the delivery as failed (e.g., customer not available).
    /// </summary>
    public void MarkFailed()
    {
        if (Status != DeliveryStatus.OutForDelivery)
            throw new InvalidOperationException("Only OutForDelivery deliveries can be marked Failed.");

        Status = DeliveryStatus.Failed;
        MarkUpdated();
    }

    /// <summary>
    /// Cancel the delivery. Only allowed if not already delivered or cancelled.
    /// </summary>
    public void Cancel()
    {
        if (Status == DeliveryStatus.Delivered)
            throw new InvalidOperationException("Cannot cancel a delivery that has already been delivered.");
        if (Status == DeliveryStatus.Cancelled)
            throw new InvalidOperationException("Delivery is already cancelled.");

        Status = DeliveryStatus.Cancelled;
        MarkUpdated();
    }

    /// <summary>
    /// Reschedule a failed or scheduled delivery.
    /// </summary>
    public void Reschedule(DateTime newDeliveryDate, string newTimeSlot)
    {
        if (Status != DeliveryStatus.Scheduled && Status != DeliveryStatus.Failed)
            throw new InvalidOperationException("Only Scheduled or Failed deliveries can be rescheduled.");

        if (string.IsNullOrWhiteSpace(newTimeSlot))
            throw new ArgumentException("TimeSlot is required.", nameof(newTimeSlot));

        DeliveryDate = newDeliveryDate;
        TimeSlot = newTimeSlot;
        Status = DeliveryStatus.Scheduled;
        MarkUpdated();
    }

    /// <summary>
    /// Update delivery address.
    /// </summary>
    public void UpdateAddress(string newAddress)
    {
        if (Status == DeliveryStatus.Delivered || Status == DeliveryStatus.Cancelled)
            throw new InvalidOperationException("Cannot update address for completed or cancelled deliveries.");

        if (string.IsNullOrWhiteSpace(newAddress))
            throw new ArgumentException("DeliveryAddress is required.", nameof(newAddress));

        DeliveryAddress = newAddress;
        MarkUpdated();
    }

    /// <summary>
    /// Assign or change delivery person.
    /// </summary>
    public void AssignDeliveryPerson(Guid deliveryPersonId)
    {
        if (Status == DeliveryStatus.Delivered || Status == DeliveryStatus.Cancelled)
            throw new InvalidOperationException("Cannot assign delivery person to completed or cancelled deliveries.");

        DeliveryPersonId = deliveryPersonId;
        MarkUpdated();
    }
}
