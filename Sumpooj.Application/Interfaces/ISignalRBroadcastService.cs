namespace Sumpooj.Application.Interfaces;

public interface ISignalRBroadcastService
{
    Task BroadcastLocationUpdateAsync(Guid deliveryId, double latitude, double longitude, double speedKph);
    Task BroadcastStatusUpdateAsync(Guid deliveryId, string status, string? note = null);
    Task BroadcastProofUpdateAsync(Guid deliveryId, string photoUrl, string? recipientName = null);
    Task BroadcastHeartbeatAsync(Guid deliveryId, Guid? driverId = null);
    Task BroadcastToGroupAsync(string groupName, string method, object? data = null);
}
