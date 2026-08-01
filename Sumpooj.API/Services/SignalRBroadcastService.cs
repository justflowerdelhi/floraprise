using Microsoft.AspNetCore.SignalR;
using Sumpooj.API.Hubs;
using Sumpooj.Application.Interfaces;

namespace Sumpooj.API.Services;

public sealed class SignalRBroadcastService : ISignalRBroadcastService
{
    private readonly IHubContext<DeliveryTrackingHub> _hubContext;

    public SignalRBroadcastService(IHubContext<DeliveryTrackingHub> hubContext)
    {
        _hubContext = hubContext;
    }

    public async Task BroadcastLocationUpdateAsync(Guid deliveryId, double latitude, double longitude, double speedKph)
    {
        await _hubContext.Clients.Group($"delivery_{deliveryId}").SendAsync("message", new
        {
            @event = "LocationUpdated",
            payload = new { deliveryId, latitude, longitude, speedKph, timestamp = DateTime.UtcNow },
            deliveryId,
            timestamp = DateTime.UtcNow
        });
    }

    public async Task BroadcastStatusUpdateAsync(Guid deliveryId, string status, string? note = null)
    {
        await _hubContext.Clients.Group($"delivery_{deliveryId}").SendAsync("message", new
        {
            @event = "StatusChanged",
            payload = new { deliveryId, status, note, timestamp = DateTime.UtcNow },
            deliveryId,
            timestamp = DateTime.UtcNow
        });
    }

    public async Task BroadcastProofUpdateAsync(Guid deliveryId, string photoUrl, string? recipientName = null)
    {
        await _hubContext.Clients.Group($"delivery_{deliveryId}").SendAsync("message", new
        {
            @event = "ProofUpdated",
            payload = new { deliveryId, photoUrl, recipientName, timestamp = DateTime.UtcNow },
            deliveryId,
            timestamp = DateTime.UtcNow
        });
    }

    public async Task BroadcastHeartbeatAsync(Guid deliveryId, Guid? driverId = null)
    {
        await _hubContext.Clients.Group($"delivery_{deliveryId}").SendAsync("message", new
        {
            @event = "Heartbeat",
            payload = new { deliveryId, driverId, timestamp = DateTime.UtcNow },
            deliveryId,
            timestamp = DateTime.UtcNow
        });
    }

    public async Task BroadcastToGroupAsync(string groupName, string method, object? data = null)
    {
        await _hubContext.Clients.Group(groupName).SendAsync(method, data);
    }
}
