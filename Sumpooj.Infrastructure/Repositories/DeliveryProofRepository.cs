using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class DeliveryProofRepository : IDeliveryProofRepository
{
    private readonly SumpoojDbContext _db;

    public DeliveryProofRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public async Task<DeliveryProof?> GetByIdAsync(Guid id)
    {
        return await _db.DeliveryProofs.FindAsync(id);
    }

    public async Task<DeliveryProof?> GetByDeliveryIdAsync(Guid deliveryId)
    {
        return await _db.DeliveryProofs
            .Where(p => p.DeliveryId == deliveryId)
            .OrderByDescending(p => p.RecordedAt)
            .FirstOrDefaultAsync();
    }

    public async Task AddAsync(DeliveryProof proof)
    {
        await _db.DeliveryProofs.AddAsync(proof);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(DeliveryProof proof)
    {
        _db.DeliveryProofs.Update(proof);
        await _db.SaveChangesAsync();
    }

    public async Task DeleteAsync(Guid id)
    {
        var proof = await GetByIdAsync(id);
        if (proof != null)
        {
            _db.DeliveryProofs.Remove(proof);
            await _db.SaveChangesAsync();
        }
    }
}
