using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace Sumpooj.API.Hubs;

[Authorize]
public class DeliveryTrackingHub : Hub
{
    private readonly ILogger<DeliveryTrackingHub> _logger;
    private readonly IHubContext<DeliveryTrackingHub> _hubContext;

    public DeliveryTrackingHub(ILogger<DeliveryTrackingHub> logger, IHubContext<DeliveryTrackingHub> hubContext)
    {
        _logger = logger;
        _hubContext = hubContext;
    }

    public async Task SubscribeToDelivery(Guid deliveryId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"delivery_{deliveryId}");
        _logger.LogInformation("Connection {ConnectionId} subscribed to delivery {DeliveryId}", Context.ConnectionId, deliveryId);
    }

    public async Task UnsubscribeFromDelivery(Guid deliveryId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"delivery_{deliveryId}");
        _logger.LogInformation("Connection {ConnectionId} unsubscribed from delivery {DeliveryId}", Context.ConnectionId, deliveryId);
    }

    public async Task SubscribeToDriver(Guid driverId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"driver_{driverId}");
        _logger.LogInformation("Connection {ConnectionId} subscribed to driver {DriverId}", Context.ConnectionId, driverId);
    }

    public async Task UnsubscribeFromDriver(Guid driverId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"driver_{driverId}");
        _logger.LogInformation("Connection {ConnectionId} unsubscribed from driver {DriverId}", Context.ConnectionId, driverId);
    }

    public override async Task OnConnectedAsync()
    {
        _logger.LogInformation("Client connected: {ConnectionId}", Context.ConnectionId);
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        _logger.LogInformation("Client disconnected: {ConnectionId}", Context.ConnectionId);
        await base.OnDisconnectedAsync(exception);
    }

    // Broadcast methods called from controllers/services
    public static async Task BroadcastLocationUpdate(IHubContext<DeliveryTrackingHub> hubContext, Guid deliveryId, object locationData)
    {
        var payload = new { @event = "LocationUpdated", payload = locationData, deliveryId, timestamp = DateTime.UtcNow };
        await hubContext.Clients.Group($"delivery_{deliveryId}").SendAsync("message", payload);
        await hubContext.Clients.Group("dispatchers").SendAsync("message", new { @event = "DriverLocationUpdated", payload = new { deliveryId, locationData }, deliveryId, timestamp = DateTime.UtcNow });
    }

    public static async Task BroadcastStatusChange(IHubContext<DeliveryTrackingHub> hubContext, Guid deliveryId, string status, object? additionalData = null)
    {
        var payload = new { @event = "StatusChanged", payload = new { deliveryId, status, additionalData }, deliveryId, timestamp = DateTime.UtcNow };
        await hubContext.Clients.Group($"delivery_{deliveryId}").SendAsync("message", payload);
        await hubContext.Clients.Group("dispatchers").SendAsync("message", new { @event = "DeliveryStatusChanged", payload = new { deliveryId, status, additionalData }, deliveryId, timestamp = DateTime.UtcNow });
    }

    public static async Task BroadcastETAUpdate(IHubContext<DeliveryTrackingHub> hubContext, Guid deliveryId, DateTime eta, double? remainingDistance)
    {
        var payload = new { @event = "ETAUpdated", payload = new { deliveryId, eta, remainingDistance }, deliveryId, timestamp = DateTime.UtcNow };
        await hubContext.Clients.Group($"delivery_{deliveryId}").SendAsync("message", payload);
    }
}
