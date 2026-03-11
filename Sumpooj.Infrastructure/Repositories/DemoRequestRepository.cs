using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class DemoRequestRepository : IDemoRequestRepository
{
    private readonly SumpoojDbContext _db;

    public DemoRequestRepository(SumpoojDbContext db) => _db = db;

    public async Task AddAsync(DemoRequest request)
    {
        _db.DemoRequests.Add(request);
        await _db.SaveChangesAsync();
    }

    public async Task<List<DemoRequest>> GetAllAsync()
    {
        return await _db.DemoRequests
            .OrderByDescending(d => d.CreatedAtUtc)
            .ToListAsync();
    }

    public async Task<DemoRequest?> GetByIdAsync(Guid id)
    {
        return await _db.DemoRequests.FindAsync(id);
    }

    public async Task UpdateAsync(DemoRequest request)
    {
        _db.DemoRequests.Update(request);
        await _db.SaveChangesAsync();
    }
}
