using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class DeliveryRepository : IDeliveryRepository
{
    private readonly SumpoojDbContext _db;

    public DeliveryRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public Task<Delivery?> GetByIdAsync(Guid id)
        => _db.Deliveries.FirstOrDefaultAsync(d => d.Id == id);

    public Task<Delivery?> GetBySalesOrderIdAsync(Guid salesOrderId)
        => _db.Deliveries.FirstOrDefaultAsync(d => d.SalesOrderId == salesOrderId);

    public async Task<IReadOnlyList<Delivery>> GetAllAsync()
        => await _db.Deliveries.AsNoTracking().ToListAsync();

    public async Task<IReadOnlyList<Delivery>> GetByDateAsync(DateTime date)
        => await _db.Deliveries
            .AsNoTracking()
            .Where(d => d.DeliveryDate.Date == date.Date)
            .OrderBy(d => d.DeliveryDate)
            .ThenBy(d => d.TimeSlot)
            .ToListAsync();

    public async Task AddAsync(Delivery delivery)
    {
        _db.Deliveries.Add(delivery);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(Delivery delivery)
    {
        _db.Deliveries.Update(delivery);
        await _db.SaveChangesAsync();
    }

    public async Task<List<Delivery>> GetByIdsAsync(List<Guid> ids)
    {
        return await _db.Deliveries
            .Where(d => ids.Contains(d.Id))
            .ToListAsync();
    }
}
