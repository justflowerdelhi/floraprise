using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class DeliveryTimelineRepository : IDeliveryTimelineRepository
{
    private readonly SumpoojDbContext _db;

    public DeliveryTimelineRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public async Task<DeliveryTimeline?> GetByIdAsync(Guid id)
    {
        return await _db.DeliveryTimelines.FindAsync(id);
    }

    public async Task<List<DeliveryTimeline>> GetByDeliveryIdAsync(Guid deliveryId)
    {
        return await _db.DeliveryTimelines
            .Where(t => t.DeliveryId == deliveryId)
            .OrderByDescending(t => t.RecordedAt)
            .ToListAsync();
    }

    public async Task AddAsync(DeliveryTimeline timeline)
    {
        await _db.DeliveryTimelines.AddAsync(timeline);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(DeliveryTimeline timeline)
    {
        _db.DeliveryTimelines.Update(timeline);
        await _db.SaveChangesAsync();
    }

    public async Task DeleteAsync(Guid id)
    {
        var timeline = await GetByIdAsync(id);
        if (timeline != null)
        {
            _db.DeliveryTimelines.Remove(timeline);
            await _db.SaveChangesAsync();
        }
    }

    public async Task<List<DeliveryTimeline>> GetRecentTimelineAsync(Guid deliveryId, int count = 20)
    {
        return await _db.DeliveryTimelines
            .Where(t => t.DeliveryId == deliveryId)
            .OrderByDescending(t => t.RecordedAt)
            .Take(count)
            .ToListAsync();
    }
}
