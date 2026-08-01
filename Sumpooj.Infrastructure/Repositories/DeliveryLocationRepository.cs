using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class DeliveryLocationRepository : IDeliveryLocationRepository
{
    private readonly SumpoojDbContext _db;

    public DeliveryLocationRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public async Task<DeliveryLocation?> GetByIdAsync(Guid id)
    {
        return await _db.DeliveryLocations.FindAsync(id);
    }

    public async Task<List<DeliveryLocation>> GetByDeliveryIdAsync(Guid deliveryId)
    {
        return await _db.DeliveryLocations
            .Where(l => l.DeliveryId == deliveryId)
            .OrderByDescending(l => l.RecordedAt)
            .ToListAsync();
    }

    public async Task<List<DeliveryLocation>> GetByRouteIdAsync(Guid routeId)
    {
        return await _db.DeliveryLocations
            .Where(l => l.DeliveryRouteId == routeId)
            .OrderByDescending(l => l.RecordedAt)
            .ToListAsync();
    }

    public async Task<List<DeliveryLocation>> GetByDriverIdAsync(Guid driverId, DateTime? fromDate = null)
    {
        var query = _db.DeliveryLocations
            .Where(l => l.DriverId == driverId);

        if (fromDate.HasValue)
        {
            query = query.Where(l => l.RecordedAt >= fromDate.Value);
        }

        return await query
            .OrderByDescending(l => l.RecordedAt)
            .ToListAsync();
    }

    public async Task<DeliveryLocation?> GetLatestLocationAsync(Guid deliveryId)
    {
        return await _db.DeliveryLocations
            .Where(l => l.DeliveryId == deliveryId)
            .OrderByDescending(l => l.RecordedAt)
            .FirstOrDefaultAsync();
    }

    public async Task<DeliveryLocation?> GetLatestDriverLocationAsync(Guid driverId)
    {
        return await _db.DeliveryLocations
            .Where(l => l.DriverId == driverId)
            .OrderByDescending(l => l.RecordedAt)
            .FirstOrDefaultAsync();
    }

    public async Task AddAsync(DeliveryLocation location)
    {
        await _db.DeliveryLocations.AddAsync(location);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(DeliveryLocation location)
    {
        _db.DeliveryLocations.Update(location);
        await _db.SaveChangesAsync();
    }

    public async Task DeleteAsync(Guid id)
    {
        var location = await GetByIdAsync(id);
        if (location != null)
        {
            _db.DeliveryLocations.Remove(location);
            await _db.SaveChangesAsync();
        }
    }

    public async Task<List<DeliveryLocation>> GetRecentLocationsAsync(Guid deliveryId, int count = 10)
    {
        return await _db.DeliveryLocations
            .Where(l => l.DeliveryId == deliveryId)
            .OrderByDescending(l => l.RecordedAt)
            .Take(count)
            .ToListAsync();
    }
}
