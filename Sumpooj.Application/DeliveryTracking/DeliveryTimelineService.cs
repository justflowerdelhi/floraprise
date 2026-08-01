using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.DeliveryTracking;

public class DeliveryTimelineService : IDeliveryTimelineService
{
    private readonly IDeliveryTimelineRepository _timelineRepo;

    public DeliveryTimelineService(IDeliveryTimelineRepository timelineRepo)
    {
        _timelineRepo = timelineRepo;
    }

    public async Task<DeliveryTimeline> AddTimelineEventAsync(Guid deliveryId, string status, string? note = null, Guid? userId = null, string? userName = null)
    {
        var timeline = new DeliveryTimeline(deliveryId, status, note);
        
        if (userId.HasValue || !string.IsNullOrWhiteSpace(userName))
        {
            timeline.SetChangeContext(userId, userName);
        }

        await _timelineRepo.AddAsync(timeline);
        return timeline;
    }

    public async Task<List<DeliveryTimeline>> GetDeliveryTimelineAsync(Guid deliveryId)
    {
        return await _timelineRepo.GetByDeliveryIdAsync(deliveryId);
    }

    public async Task<List<DeliveryTimeline>> GetRecentTimelineAsync(Guid deliveryId, int count = 20)
    {
        return await _timelineRepo.GetRecentTimelineAsync(deliveryId, count);
    }
}
