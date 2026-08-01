using Sumpooj.Application.Interfaces;

namespace Sumpooj.Application.DeliveryTracking;

public class SignalRBroadcastService : ISignalRBroadcastService
{
    public SignalRBroadcastService()
    {
    }

    public async Task BroadcastLocationUpdateAsync(Guid deliveryId, double latitude, double longitude, double speedKph)
    {
        await Task.CompletedTask;
    }

    public async Task BroadcastStatusUpdateAsync(Guid deliveryId, string status, string? note = null)
    {
        await Task.CompletedTask;
    }

    public async Task BroadcastProofUpdateAsync(Guid deliveryId, string photoUrl, string? recipientName = null)
    {
        await Task.CompletedTask;
    }

    public async Task BroadcastHeartbeatAsync(Guid deliveryId, Guid? driverId = null)
    {
        await Task.CompletedTask;
    }

    public async Task BroadcastToGroupAsync(string groupName, string method, object? data = null)
    {
        await Task.CompletedTask;
    }
}
