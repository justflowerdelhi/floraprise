using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.DayClose;
using Sumpooj.Application.Interfaces;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class DayCloseRepository : IDayCloseRepository
{
    private readonly SumpoojDbContext _db;

    public DayCloseRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public async Task<Domain.Entities.DayClose?> GetByIdAsync(Guid companyId, Guid id)
    {
        return await _db.DayCloses
            .FirstOrDefaultAsync(d => d.CompanyId == companyId && d.Id == id);
    }

    public async Task<Domain.Entities.DayClose?> GetByDateAsync(Guid companyId, Guid locationId, DateTime date)
    {
        return await _db.DayCloses
            .FirstOrDefaultAsync(d => d.CompanyId == companyId && 
                                      d.LocationId == locationId && 
                                      d.BusinessDate.Date == date.Date);
    }

    public async Task<bool> IsDayClosedAsync(Guid companyId, Guid locationId, DateTime date)
    {
        return await _db.DayCloses
            .AnyAsync(d => d.CompanyId == companyId && 
                          d.LocationId == locationId && 
                          d.BusinessDate.Date == date.Date);
    }

    public async Task<List<DayCloseDto>> GetHistoryAsync(Guid companyId, Guid locationId, int days = 30)
    {
        var startDate = DateTime.UtcNow.AddDays(-days).Date;

        return await _db.DayCloses
            .Where(d => d.CompanyId == companyId && 
                       d.LocationId == locationId && 
                       d.BusinessDate >= startDate)
            .OrderByDescending(d => d.BusinessDate)
            .Select(d => new DayCloseDto
            {
                Id = d.Id,
                LocationId = d.LocationId,
                BusinessDate = d.BusinessDate,
                Status = d.Status.ToString(),
                ClosedAt = d.ClosedAt,
                ClosedByUserId = d.ClosedByUserId,
                TotalOrders = d.TotalOrders,
                TotalSales = d.TotalSales,
                TotalRefunds = d.TotalRefunds,
                NetSales = d.NetSales,
                CashTotal = d.CashTotal,
                CardTotal = d.CardTotal,
                UpiTotal = d.UpiTotal,
                GiftCardTotal = d.GiftCardTotal,
                OtherPaymentsTotal = d.OtherPaymentsTotal,
                ExpectedCash = d.ExpectedCash,
                ActualCash = d.ActualCash,
                CashVariance = d.CashVariance,
                Notes = d.Notes
            })
            .ToListAsync();
    }

    public async Task AddAsync(Domain.Entities.DayClose dayClose)
    {
        await _db.DayCloses.AddAsync(dayClose);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(Domain.Entities.DayClose dayClose)
    {
        _db.DayCloses.Update(dayClose);
        await _db.SaveChangesAsync();
    }
}
