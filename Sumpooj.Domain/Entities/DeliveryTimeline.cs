namespace Sumpooj.Domain.Entities;

public class DeliveryTimeline : BaseEntity
{
    private DeliveryTimeline() { }

    public DeliveryTimeline(
        Guid deliveryId,
        string status,
        string? note = null)
    {
        if (deliveryId == Guid.Empty)
            throw new ArgumentException("DeliveryId is required.", nameof(deliveryId));
        if (string.IsNullOrWhiteSpace(status))
            throw new ArgumentException("Status is required.", nameof(status));

        DeliveryId = deliveryId;
        Status = status;
        Note = note;
        RecordedAt = DateTime.UtcNow;
    }

    public Guid DeliveryId { get; private set; }
    public string Status { get; private set; }
    public string? Note { get; private set; }
    public DateTime RecordedAt { get; private set; }

    // Optional: Who made this change
    public Guid? ChangedByUserId { get; private set; }
    public string? ChangedByUserName { get; private set; }

    public void SetChangeContext(Guid? userId, string? userName)
    {
        ChangedByUserId = userId;
        ChangedByUserName = userName;
        MarkUpdated();
    }
}
