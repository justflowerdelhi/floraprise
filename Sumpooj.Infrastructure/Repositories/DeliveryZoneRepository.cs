using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.DeliveryZones;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class DeliveryZoneRepository : IDeliveryZoneRepository
{
    private readonly SumpoojDbContext _db;

    public DeliveryZoneRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public async Task<DeliveryZone?> GetByIdAsync(Guid companyId, Guid id)
    {
        return await _db.DeliveryZones
            .FirstOrDefaultAsync(z => z.CompanyId == companyId && z.Id == id);
    }

    public async Task<DeliveryZone?> GetByCodeAsync(Guid companyId, string code)
    {
        return await _db.DeliveryZones
            .FirstOrDefaultAsync(z => z.CompanyId == companyId && z.Code == code);
    }

    public async Task<List<DeliveryZoneDto>> GetAllAsync(Guid companyId, bool activeOnly = true)
    {
        var query = _db.DeliveryZones
            .Where(z => z.CompanyId == companyId);

        if (activeOnly)
        {
            query = query.Where(z => z.IsActive);
        }

        var zones = await query
            .OrderBy(z => z.SortOrder)
            .ThenBy(z => z.Name)
            .ToListAsync();

        return zones.Select(z => new DeliveryZoneDto
        {
            Id = z.Id,
            Name = z.Name,
            Code = z.Code,
            MatchType = "ZIP",
            MatchValues = z.ZipCodes?.Split(',', StringSplitOptions.RemoveEmptyEntries).ToList() ?? new(),
            ZipCodes = z.ZipCodes?.Split(',', StringSplitOptions.RemoveEmptyEntries).ToList() ?? new(),
            Cities = z.Cities?.Split(',', StringSplitOptions.RemoveEmptyEntries).ToList() ?? new(),
            FreeDeliveryThreshold = z.FreeDeliveryThreshold,
            DeliveryFee = z.DeliveryFee,
            SameDayFee = z.SameDayFee,
            ExpressFee = z.ExpressFee,
            EstimatedMinutes = z.EstimatedMinutes,
            DistanceKm = z.DistanceKm,
            Priority = z.SortOrder,
            IsServiceable = z.IsActive,
            IsActive = z.IsActive,
            Notes = z.Notes,
            CreatedAtUtc = z.CreatedAtUtc
        }).ToList();
    }

    public async Task<DeliveryZone?> FindByZipCodeAsync(Guid companyId, string zipCode)
    {
        return await _db.DeliveryZones
            .Where(z => z.CompanyId == companyId && z.IsActive)
            .Where(z => z.ZipCodes != null && z.ZipCodes.Contains(zipCode))
            .OrderBy(z => z.SortOrder)
            .FirstOrDefaultAsync();
    }

    public async Task<DeliveryZone?> FindByCityAsync(Guid companyId, string city)
    {
        var cityLower = city.ToLower();
        return await _db.DeliveryZones
            .Where(z => z.CompanyId == companyId && z.IsActive)
            .Where(z => z.Cities != null && z.Cities.ToLower().Contains(cityLower))
            .OrderBy(z => z.SortOrder)
            .FirstOrDefaultAsync();
    }

    public async Task AddAsync(DeliveryZone zone)
    {
        await _db.DeliveryZones.AddAsync(zone);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(DeliveryZone zone)
    {
        _db.DeliveryZones.Update(zone);
        await _db.SaveChangesAsync();
    }

    public async Task DeleteAsync(DeliveryZone zone)
    {
        _db.DeliveryZones.Remove(zone);
        await _db.SaveChangesAsync();
    }
}
