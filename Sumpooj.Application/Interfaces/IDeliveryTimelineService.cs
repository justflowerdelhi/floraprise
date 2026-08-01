using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IDeliveryTimelineService
{
    Task<DeliveryTimeline> AddTimelineEventAsync(Guid deliveryId, string status, string? note = null, Guid? userId = null, string? userName = null);
    Task<List<DeliveryTimeline>> GetDeliveryTimelineAsync(Guid deliveryId);
    Task<List<DeliveryTimeline>> GetRecentTimelineAsync(Guid deliveryId, int count = 20);
}
