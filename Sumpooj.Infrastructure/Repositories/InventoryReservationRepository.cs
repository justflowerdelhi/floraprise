using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class InventoryReservationRepository : IInventoryReservationRepository
{
    private readonly SumpoojDbContext _db;

    public InventoryReservationRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public Task<InventoryReservation?> GetByIdAsync(Guid id)
        => _db.InventoryReservations.FirstOrDefaultAsync(r => r.Id == id);

    public async Task AddAsync(InventoryReservation reservation)
    {
        _db.InventoryReservations.Add(reservation);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(InventoryReservation reservation)
    {
        _db.InventoryReservations.Update(reservation);
        await _db.SaveChangesAsync();
    }

    public Task<List<InventoryReservation>> GetBySalesOrderIdAsync(Guid salesOrderId)
        => _db.InventoryReservations
            .Where(r => r.SalesOrderId == salesOrderId)
            .OrderBy(r => r.CreatedAtUtc)
            .ToListAsync();

    public Task<InventoryReservation?> GetActiveReservationAsync(Guid salesOrderId, Guid productBatchId)
        => _db.InventoryReservations
            .FirstOrDefaultAsync(r =>
                r.SalesOrderId == salesOrderId
                && r.ProductBatchId == productBatchId
                && r.Status == ReservationStatus.Active);
}
