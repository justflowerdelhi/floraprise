using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.TaxRules;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class TaxRuleRepository : ITaxRuleRepository
{
    private readonly SumpoojDbContext _db;

    public TaxRuleRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public async Task<TaxRule?> GetByIdAsync(Guid companyId, Guid id)
    {
        return await _db.TaxRules
            .FirstOrDefaultAsync(t => t.CompanyId == companyId && t.Id == id);
    }

    public async Task<List<TaxRuleDto>> GetByCountryAsync(Guid companyId, string countryCode, bool activeOnly = true)
    {
        var query = _db.TaxRules
            .Where(t => t.CompanyId == companyId && t.CountryCode == countryCode);

        if (activeOnly)
            query = query.Where(t => t.IsActive);

        return await query
            .OrderBy(t => t.Name)
            .Select(t => new TaxRuleDto
            {
                Id = t.Id,
                CountryCode = t.CountryCode,
                Name = t.Name,
                Rate = t.Rate,
                IsInclusive = t.IsInclusive,
                IsActive = t.IsActive,
                CreatedAtUtc = t.CreatedAtUtc,
                UpdatedAtUtc = t.UpdatedAtUtc
            })
            .ToListAsync();
    }

    public async Task<List<TaxRuleDto>> GetAllAsync(Guid companyId, bool activeOnly = true)
    {
        var query = _db.TaxRules
            .Where(t => t.CompanyId == companyId);

        if (activeOnly)
            query = query.Where(t => t.IsActive);

        return await query
            .OrderBy(t => t.CountryCode)
            .ThenBy(t => t.Name)
            .Select(t => new TaxRuleDto
            {
                Id = t.Id,
                CountryCode = t.CountryCode,
                Name = t.Name,
                Rate = t.Rate,
                IsInclusive = t.IsInclusive,
                IsActive = t.IsActive,
                CreatedAtUtc = t.CreatedAtUtc,
                UpdatedAtUtc = t.UpdatedAtUtc
            })
            .ToListAsync();
    }

    public async Task AddAsync(TaxRule taxRule)
    {
        await _db.TaxRules.AddAsync(taxRule);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(TaxRule taxRule)
    {
        _db.TaxRules.Update(taxRule);
        await _db.SaveChangesAsync();
    }
}
