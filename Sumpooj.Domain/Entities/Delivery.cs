namespace Sumpooj.Domain.Entities;

public class Delivery : BaseEntity
{
    private Delivery() { }

    public Delivery(
        Guid companyId,
        Guid orderId,
        DateTime scheduledDateTime,
        string deliveryAddress,
        string? recipientName,
        string? recipientPhone)
    {
        CompanyId = companyId;
        OrderId = orderId;
        ScheduledDateTime = scheduledDateTime;
        DeliveryAddress = deliveryAddress;
        RecipientName = recipientName;
        RecipientPhone = recipientPhone;
        Status = DeliveryStatus.Scheduled;
        IsActive = true;
    }

    public Guid CompanyId { get; private set; }
    public Guid OrderId { get; private set; }
    public Guid? DeliveryPersonId { get; private set; }
    public DateTime ScheduledDateTime { get; private set; }
    public DateTime? ActualDeliveryDateTime { get; private set; }
    public DeliveryStatus Status { get; private set; }
    public bool IsActive { get; private set; }

    public string DeliveryAddress { get; private set; }
    public string? RecipientName { get; private set; }
    public string? RecipientPhone { get; private set; }

    // Delivery tracking
    public string? DeliveryProofPhotoPath { get; private set; }
    public string? RecipientSignature { get; private set; }
    public string? DeliveryNotes { get; private set; }

    // Geolocation
    public double? DeliveryLatitude { get; private set; }
    public double? DeliveryLongitude { get; private set; }

    public void AssignDeliveryPerson(Guid deliveryPersonId)
    {
        if (Status != DeliveryStatus.Scheduled)
            throw new InvalidOperationException("Can only assign delivery person to scheduled deliveries");

        DeliveryPersonId = deliveryPersonId;
        MarkUpdated();
    }

    public void StartDelivery()
    {
        if (Status != DeliveryStatus.Scheduled)
            throw new InvalidOperationException("Can only start scheduled deliveries");

        if (!DeliveryPersonId.HasValue)
            throw new InvalidOperationException("Cannot start delivery without assigned delivery person");

        Status = DeliveryStatus.InProgress;
        MarkUpdated();
    }

    public void CompleteDelivery(
        string? proofPhotoPath,
        string? recipientSignature,
        double? latitude,
        double? longitude,
        string? notes)
    {
        if (Status != DeliveryStatus.InProgress)
            throw new InvalidOperationException("Can only complete deliveries in progress");

        Status = DeliveryStatus.Completed;
        ActualDeliveryDateTime = DateTime.UtcNow;
        DeliveryProofPhotoPath = proofPhotoPath;
        RecipientSignature = recipientSignature;
        DeliveryLatitude = latitude;
        DeliveryLongitude = longitude;
        DeliveryNotes = notes;
        MarkUpdated();
    }

    public void MarkFailed(string reason)
    {
        if (Status == DeliveryStatus.Completed)
            throw new InvalidOperationException("Cannot mark completed delivery as failed");

        Status = DeliveryStatus.Failed;
        DeliveryNotes = reason;
        MarkUpdated();
    }

    public void Reschedule(DateTime newDateTime, string? reason)
    {
        if (Status == DeliveryStatus.Completed)
            throw new InvalidOperationException("Cannot reschedule completed delivery");

        ScheduledDateTime = newDateTime;
        Status = DeliveryStatus.Rescheduled;
        
        if (!string.IsNullOrEmpty(reason))
        {
            DeliveryNotes = string.IsNullOrEmpty(DeliveryNotes)
                ? $"Rescheduled: {reason}"
                : $"{DeliveryNotes}\nRescheduled: {reason}";
        }
        
        MarkUpdated();
    }

    public void UpdateDeliveryAddress(string newAddress)
    {
        if (Status == DeliveryStatus.Completed)
            throw new InvalidOperationException("Cannot update address for completed delivery");

        DeliveryAddress = newAddress;
        MarkUpdated();
    }

    public void AddNote(string note)
    {
        DeliveryNotes = string.IsNullOrEmpty(DeliveryNotes)
            ? note
            : $"{DeliveryNotes}\n{note}";
        MarkUpdated();
    }

    public void Deactivate()
    {
        IsActive = false;
        MarkUpdated();
    }
}
