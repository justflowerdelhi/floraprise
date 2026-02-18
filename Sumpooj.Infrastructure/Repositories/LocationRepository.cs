using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class LocationRepository : ILocationRepository
{
    private readonly SumpoojDbContext _db;

    public LocationRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public Task<Location?> GetByIdAsync(Guid id)
        => _db.Locations.FirstOrDefaultAsync(l => l.Id == id);

    public async Task AddAsync(Location location)
    {
        _db.Locations.Add(location);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(Location location)
    {
        _db.Locations.Update(location);
        await _db.SaveChangesAsync();
    }

    public async Task<List<Location>> GetAllAsync()
    {
        return await _db.Locations
            .AsNoTracking()
            .OrderBy(l => l.Name)
            .ToListAsync();
    }

    public async Task<List<Location>> GetActiveLocationsAsync()
    {
        return await _db.Locations
            .AsNoTracking()
            .Where(l => l.IsActive)
            .OrderBy(l => l.Name)
            .ToListAsync();
    }

    public Task<Location?> GetDefaultLocationAsync()
    {
        return _db.Locations.FirstOrDefaultAsync(l => l.IsDefault && l.IsActive);
    }
}
