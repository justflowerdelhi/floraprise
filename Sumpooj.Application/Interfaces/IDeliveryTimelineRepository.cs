using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IDeliveryTimelineRepository
{
    Task<DeliveryTimeline?> GetByIdAsync(Guid id);
    Task<List<DeliveryTimeline>> GetByDeliveryIdAsync(Guid deliveryId);
    Task AddAsync(DeliveryTimeline timeline);
    Task UpdateAsync(DeliveryTimeline timeline);
    Task DeleteAsync(Guid id);
    Task<List<DeliveryTimeline>> GetRecentTimelineAsync(Guid deliveryId, int count = 20);
}
