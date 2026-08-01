namespace Sumpooj.Application.DeliveryTracking.DTOs;

public enum NotificationType
{
    DeliveryAssigned,
    DeliveryAccepted,
    DeliveryPickedUp,
    OutForDelivery,
    ArrivedNearby,
    Delivered,
    Failed,
    Delayed
}

public class NotificationRequest
{
    public Guid DeliveryId { get; set; }
    public NotificationType Type { get; set; }
    public string? CustomerPhone { get; set; }
    public string? CustomerEmail { get; set; }
    public string? FloristPhone { get; set; }
    public string? FloristEmail { get; set; }
    public Dictionary<string, object>? AdditionalData { get; set; }
}

public class NotificationResponse
{
    public bool CustomerSMS { get; set; }
    public bool CustomerEmail { get; set; }
    public bool FloristSMS { get; set; }
    public bool FloristEmail { get; set; }
    public DateTime SentAt { get; set; }
}
