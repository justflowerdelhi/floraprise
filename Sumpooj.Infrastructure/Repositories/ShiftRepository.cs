using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class ShiftRepository : IShiftRepository
{
    private readonly SumpoojDbContext _db;

    public ShiftRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public async Task<Shift?> GetByIdAsync(Guid companyId, Guid id)
    {
        return await _db.Shifts
            .FirstOrDefaultAsync(s => s.CompanyId == companyId && s.Id == id);
    }

    public async Task<Shift?> GetActiveShiftAsync(Guid companyId, Guid locationId)
    {
        return await _db.Shifts
            .FirstOrDefaultAsync(s => s.CompanyId == companyId &&
                                      s.LocationId == locationId &&
                                      s.Status == ShiftStatus.Open);
    }

    public async Task<List<Shift>> GetHistoryAsync(Guid companyId, Guid locationId, int count = 20)
    {
        return await _db.Shifts
            .Where(s => s.CompanyId == companyId && s.LocationId == locationId)
            .OrderByDescending(s => s.OpenedAt)
            .Take(count)
            .ToListAsync();
    }

    public async Task AddAsync(Shift shift)
    {
        await _db.Shifts.AddAsync(shift);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(Shift shift)
    {
        _db.Shifts.Update(shift);
        await _db.SaveChangesAsync();
    }
}
