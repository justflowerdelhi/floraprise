using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Persistence.Repositories;

public class DriverLocationRepository : IDriverLocationRepository
{
    private readonly SumpoojDbContext _context;

    public DriverLocationRepository(SumpoojDbContext context)
    {
        _context = context;
    }

    public async Task<DriverLocation?> GetLatestLocationAsync(Guid driverId, Guid deliveryId)
    {
        return await _context.DriverLocations
            .Where(dl => dl.DriverId == driverId && dl.DeliveryId == deliveryId)
            .OrderByDescending(dl => dl.RecordedAt)
            .FirstOrDefaultAsync();
    }

    public async Task<DriverLocation?> GetLatestLocationByDriverAsync(Guid driverId)
    {
        return await _context.DriverLocations
            .Where(dl => dl.DriverId == driverId)
            .OrderByDescending(dl => dl.RecordedAt)
            .FirstOrDefaultAsync();
    }

    public async Task<IEnumerable<DriverLocation>> GetLocationsByDeliveryAsync(Guid deliveryId, int limit = 100)
    {
        return await _context.DriverLocations
            .Where(dl => dl.DeliveryId == deliveryId)
            .OrderByDescending(dl => dl.RecordedAt)
            .Take(limit)
            .ToListAsync();
    }

    public async Task<IEnumerable<DriverLocation>> GetLocationsByDriverAsync(Guid driverId, DateTime since)
    {
        return await _context.DriverLocations
            .Where(dl => dl.DriverId == driverId && dl.RecordedAt >= since)
            .OrderBy(dl => dl.RecordedAt)
            .ToListAsync();
    }

    public async Task AddLocationAsync(DriverLocation location)
    {
        await _context.DriverLocations.AddAsync(location);
        await _context.SaveChangesAsync();
    }

    public async Task AddRangeAsync(IEnumerable<DriverLocation> locations)
    {
        await _context.DriverLocations.AddRangeAsync(locations);
        await _context.SaveChangesAsync();
    }

    public async Task CleanupOldLocationsAsync(int retentionDays)
    {
        var cutoffDate = DateTime.UtcNow.AddDays(-retentionDays);
        var oldLocations = await _context.DriverLocations
            .Where(dl => dl.RecordedAt < cutoffDate)
            .ToListAsync();
        
        if (oldLocations.Any())
        {
            _context.DriverLocations.RemoveRange(oldLocations);
            await _context.SaveChangesAsync();
        }
    }
}
