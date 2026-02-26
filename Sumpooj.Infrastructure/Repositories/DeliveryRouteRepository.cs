using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class DeliveryRouteRepository : IDeliveryRouteRepository
{
    private readonly SumpoojDbContext _db;

    public DeliveryRouteRepository(SumpoojDbContext db) => _db = db;

    public Task<DeliveryRoute?> GetByIdAsync(Guid id)
        => _db.DeliveryRoutes.FirstOrDefaultAsync(r => r.Id == id);

    public async Task<List<DeliveryRoute>> GetAllAsync()
        => await _db.DeliveryRoutes.AsNoTracking().OrderByDescending(r => r.RouteDate).ToListAsync();

    public async Task AddAsync(DeliveryRoute route)
    {
        _db.DeliveryRoutes.Add(route);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(DeliveryRoute route)
    {
        _db.DeliveryRoutes.Update(route);
        await _db.SaveChangesAsync();
    }
}
