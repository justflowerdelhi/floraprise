using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IDeliveryTrackingService
{
    Task<DeliveryTrackingSnapshot> GetTrackingByOrderIdAsync(Guid orderId);
    Task<DeliveryTrackingSnapshot> GetTrackingByDeliveryIdAsync(Guid deliveryId);
    Task<DeliveryTrackingSnapshot> GetTrackingByRouteIdAsync(Guid routeId);
    Task<List<DeliveryWorkspaceRecord>> GetActiveDeliveriesAsync();
    Task<List<DeliveryWorkspaceRecord>> GetDeliveriesByStatusAsync(string status);
    Task RecordHeartbeatAsync(Guid deliveryId, Guid? driverId = null);
}

public class DeliveryTrackingSnapshot
{
    public Guid AssignmentId { get; set; }
    public Guid OrderId { get; set; }
    public string TrackingId { get; set; } = string.Empty;
    public string TrackingLink { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime? Eta { get; set; }
    public DeliveryDriverInfo? Driver { get; set; }
    public List<DeliveryLocationPoint> Route { get; set; } = new();
    public List<DeliveryTimelineEvent> Timeline { get; set; } = new();
    public DeliveryProofInfo? Proof { get; set; }
    public DeliveryLocationPoint? LastLocation { get; set; }
}

public class DeliveryDriverInfo
{
    public string Name { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string? Vehicle { get; set; }
}

public class DeliveryLocationPoint
{
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public DateTime RecordedAt { get; set; }
    public double SpeedKph { get; set; }
}

public class DeliveryTimelineEvent
{
    public string Status { get; set; } = string.Empty;
    public DateTime RecordedAt { get; set; }
    public string? Note { get; set; }
}

public class DeliveryProofInfo
{
    public string PhotoUrl { get; set; } = string.Empty;
    public string? Note { get; set; }
    public string? RecipientName { get; set; }
    public DateTime? RecordedAt { get; set; }
}

public class DeliveryWorkspaceRecord
{
    public string AssignmentId { get; set; } = string.Empty;
    public Guid OrderId { get; set; }
    public string OrderNo { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;
    public string RecipientName { get; set; } = string.Empty;
    public string DeliveryAddress { get; set; } = string.Empty;
    public string DeliveryArea { get; set; } = string.Empty;
    public string? CustomerPhone { get; set; }
    public string DeliveryTime { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string TrackingLink { get; set; } = string.Empty;
    public DateTime? Eta { get; set; }
    public DateTime UpdatedAt { get; set; }
    public DeliveryDriverInfo? Driver { get; set; }
}
