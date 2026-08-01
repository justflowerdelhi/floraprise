using System.ComponentModel.DataAnnotations.Schema;

namespace Sumpooj.Domain.Entities;

public class Delivery : BaseEntity
{
    private Delivery() { }

    public Delivery(
        Guid companyId,
        Guid salesOrderId,
        DateTime deliveryDate,
        string timeSlot,
        string deliveryAddress)
    {
        if (companyId == Guid.Empty)
            throw new ArgumentException("CompanyId is required.", nameof(companyId));
        if (salesOrderId == Guid.Empty)
            throw new ArgumentException("SalesOrderId is required.", nameof(salesOrderId));
        if (string.IsNullOrWhiteSpace(timeSlot))
            throw new ArgumentException("TimeSlot is required.", nameof(timeSlot));
        if (string.IsNullOrWhiteSpace(deliveryAddress))
            throw new ArgumentException("DeliveryAddress is required.", nameof(deliveryAddress));

        CompanyId = companyId;
        SalesOrderId = salesOrderId;
        DeliveryDate = EnsureUtc(deliveryDate);
        TimeSlot = timeSlot;
        DeliveryAddress = deliveryAddress;
        Status = DeliveryStatus.Created;
    }

    public Guid CompanyId { get; private set; }

    public Guid SalesOrderId { get; private set; }
    public DateTime DeliveryDate { get; private set; }
    public string TimeSlot { get; private set; } = string.Empty;
    public string DeliveryAddress { get; private set; } = string.Empty;
    public string? PostalCode { get; private set; }
    public Guid? DeliveryPersonId { get; private set; }
    public DeliveryStatus Status { get; private set; }
    
    // Secure tracking token for anonymous driver/customer access
    public string? TrackingToken { get; private set; }
    
    // GPS coordinates for delivery address
    public double? DeliveryAddressLatitude { get; private set; }
    public double? DeliveryAddressLongitude { get; private set; }
    
    // Customer contact info for notifications
    public string? CustomerPhone { get; private set; }
    public string? CustomerEmail { get; private set; }

    public void SetTrackingToken(string? token)
    {
        TrackingToken = token;
        MarkUpdated();
    }

    public void SetPostalCode(string? code)
    {
        PostalCode = code;
        MarkUpdated();
    }

    public void SetDeliveryAddressCoordinates(double? latitude, double? longitude)
    {
        DeliveryAddressLatitude = latitude;
        DeliveryAddressLongitude = longitude;
        MarkUpdated();
    }

    public void SetCustomerContact(string? phone, string? email)
    {
        CustomerPhone = phone;
        CustomerEmail = email;
        MarkUpdated();
    }

    // Route assignment
    public Guid? DeliveryRouteId { get; private set; }
    public int? StopOrder { get; private set; }
    // ── Domain Methods ───────────────────────────────────────────────────

    /// <summary>
    /// Confirm the delivery (order confirmed)
    /// </summary>
    public void Confirm()
    {
        if (Status != DeliveryStatus.Created)
            throw new InvalidOperationException("Only Created deliveries can be confirmed.");

        Status = DeliveryStatus.Confirmed;
        MarkUpdated();
    }

    /// <summary>
    /// Mark delivery as in production
    /// </summary>
    public void MarkInProduction()
    {
        if (Status != DeliveryStatus.Confirmed)
            throw new InvalidOperationException("Only Confirmed deliveries can be marked InProduction.");

        Status = DeliveryStatus.InProduction;
        MarkUpdated();
    }

    /// <summary>
    /// Mark delivery as ready for pickup
    /// </summary>
    public void MarkReady()
    {
        if (Status != DeliveryStatus.InProduction)
            throw new InvalidOperationException("Only InProduction deliveries can be marked Ready.");

        Status = DeliveryStatus.Ready;
        MarkUpdated();
    }

    /// <summary>
    /// Schedule the delivery for a specific date/time
    /// </summary>
    public void Schedule(DateTime deliveryDate, string timeSlot)
    {
        if (Status != DeliveryStatus.Ready)
            throw new InvalidOperationException("Only Ready deliveries can be scheduled.");

        if (string.IsNullOrWhiteSpace(timeSlot))
            throw new ArgumentException("TimeSlot is required.", nameof(timeSlot));

        DeliveryDate = EnsureUtc(deliveryDate);
        TimeSlot = timeSlot;
        Status = DeliveryStatus.Scheduled;
        MarkUpdated();
    }

    /// <summary>
    /// Assign delivery to a route
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
        Status = DeliveryStatus.Assigned;
        MarkUpdated();
    }

    /// <summary>
    /// Remove delivery from route
    /// </summary>
    public void RemoveFromRoute()
    {
        DeliveryRouteId = null;
        StopOrder = null;
        if (Status == DeliveryStatus.Assigned)
        {
            Status = DeliveryStatus.Scheduled;
        }
        MarkUpdated();
    }

    /// <summary>
    /// Driver accepted the delivery
    /// </summary>
    public void MarkAccepted(Guid driverId)
    {
        if (Status != DeliveryStatus.Assigned)
            throw new InvalidOperationException("Only Assigned deliveries can be accepted.");

        DeliveryPersonId = driverId;
        Status = DeliveryStatus.Accepted;
        MarkUpdated();
    }

    /// <summary>
    /// Driver picked up the delivery
    /// </summary>
    public void MarkPickedUp()
    {
        if (Status != DeliveryStatus.Accepted)
            throw new InvalidOperationException("Only Accepted deliveries can be picked up.");

        Status = DeliveryStatus.PickedUp;
        MarkUpdated();
    }

    /// <summary>
    /// Mark delivery as out for delivery
    /// </summary>
    public void MarkOutForDelivery()
    {
        if (Status != DeliveryStatus.PickedUp)
            throw new InvalidOperationException("Only PickedUp deliveries can be marked OutForDelivery.");

        Status = DeliveryStatus.OutForDelivery;
        MarkUpdated();
    }

    /// <summary>
    /// Mark delivery as arrived nearby
    /// </summary>
    public void MarkArrivedNearby()
    {
        if (Status != DeliveryStatus.OutForDelivery)
            throw new InvalidOperationException("Only OutForDelivery deliveries can be marked ArrivedNearby.");

        Status = DeliveryStatus.ArrivedNearby;
        MarkUpdated();
    }

    /// <summary>
    /// Mark the delivery as successfully completed
    /// </summary>
    public void MarkDelivered()
    {
        if (Status != DeliveryStatus.ArrivedNearby && Status != DeliveryStatus.OutForDelivery)
            throw new InvalidOperationException("Only ArrivedNearby or OutForDelivery deliveries can be marked Delivered.");

        Status = DeliveryStatus.Delivered;
        MarkUpdated();
    }

    /// <summary>
    /// Mark the delivery as failed (e.g., customer not available)
    /// </summary>
    public void MarkFailed()
    {
        if (Status != DeliveryStatus.ArrivedNearby && Status != DeliveryStatus.OutForDelivery)
            throw new InvalidOperationException("Only ArrivedNearby or OutForDelivery deliveries can be marked Failed.");

        Status = DeliveryStatus.Failed;
        MarkUpdated();
    }

    /// <summary>
    /// Mark the delivery as returned
    /// </summary>
    public void MarkReturned()
    {
        if (Status != DeliveryStatus.Failed)
            throw new InvalidOperationException("Only Failed deliveries can be marked Returned.");

        Status = DeliveryStatus.Returned;
        MarkUpdated();
    }

    /// <summary>
    /// Mark settlement as completed
    /// </summary>
    public void MarkSettlementCompleted()
    {
        if (Status != DeliveryStatus.Delivered && Status != DeliveryStatus.Returned)
            throw new InvalidOperationException("Only Delivered or Returned deliveries can have settlement completed.");

        Status = DeliveryStatus.SettlementCompleted;
        MarkUpdated();
    }

    /// <summary>
    /// Cancel the delivery. Only allowed if not already delivered or cancelled.
    /// </summary>
    public void Cancel()
    {
        if (Status == DeliveryStatus.Delivered || Status == DeliveryStatus.SettlementCompleted)
            throw new InvalidOperationException("Cannot cancel a delivery that has already been delivered.");
        if (Status == DeliveryStatus.Cancelled)
            throw new InvalidOperationException("Delivery is already cancelled.");

        Status = DeliveryStatus.Cancelled;
        MarkUpdated();
    }

    /// <summary>
    /// Reschedule a failed or scheduled delivery
    /// </summary>
    public void Reschedule(DateTime newDeliveryDate, string newTimeSlot)
    {
        if (Status != DeliveryStatus.Scheduled && Status != DeliveryStatus.Failed && Status != DeliveryStatus.Returned)
            throw new InvalidOperationException("Only Scheduled, Failed, or Returned deliveries can be rescheduled.");

        if (string.IsNullOrWhiteSpace(newTimeSlot))
            throw new ArgumentException("TimeSlot is required.", nameof(newTimeSlot));

        DeliveryDate = newDeliveryDate;
        TimeSlot = newTimeSlot;
        Status = DeliveryStatus.Scheduled;
        MarkUpdated();
    }

    /// <summary>
    /// Update delivery address
    /// </summary>
    public void UpdateAddress(string newAddress)
    {
        if (Status == DeliveryStatus.Delivered || Status == DeliveryStatus.Cancelled || Status == DeliveryStatus.SettlementCompleted)
            throw new InvalidOperationException("Cannot update address for completed, cancelled, or settled deliveries.");

        if (string.IsNullOrWhiteSpace(newAddress))
            throw new ArgumentException("DeliveryAddress is required.", nameof(newAddress));

        DeliveryAddress = newAddress;
        MarkUpdated();
    }

    /// <summary>
    /// Assign or change delivery person
    /// </summary>
    public void AssignDeliveryPerson(Guid deliveryPersonId)
    {
        if (Status == DeliveryStatus.Delivered || Status == DeliveryStatus.Cancelled || Status == DeliveryStatus.SettlementCompleted)
            throw new InvalidOperationException("Cannot assign delivery person to completed, cancelled, or settled deliveries.");

        DeliveryPersonId = deliveryPersonId;

        // Direct assignment flow (without route planning) should make the
        // delivery actionable in driver workspace.
        if (Status == DeliveryStatus.Created || Status == DeliveryStatus.Scheduled)
            Status = DeliveryStatus.Assigned;

        MarkUpdated();
    }
}
