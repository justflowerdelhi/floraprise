using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Companies;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Companies;

public class CompanyService : ICompanyService
{
    private readonly SumpoojDbContext _db;

    public CompanyService(SumpoojDbContext db)
    {
        _db = db;
    }

    public async Task<Guid> CreateAsync(CreateCompanyRequest request)
    {
        var company = new Company(
            name: request.Name,
            region: request.Region,
            email: request.Email,
            phone: request.Phone,
            address: request.Address,
            shortDescription: request.ShortDescription,
            logoPath: null,
            timeZone: request.TimeZone,
            currencyCode: request.CurrencyCode,
            taxIdentifier: request.TaxIdentifier
        );

        _db.Companies.Add(company);
        await _db.SaveChangesAsync();

        return company.Id;
    }

    public async Task<IReadOnlyList<CompanyDto>> GetAllAsync()
    {
        return await _db.Companies
            .OrderBy(c => c.Name)
            .Select(c => new CompanyDto
            {
                Id = c.Id,
                Name = c.Name,
                Region = c.Region,
                IsActive = c.IsActive
            })
            .ToListAsync();
    }

    public async Task SetActiveAsync(Guid companyId, bool isActive)
    {
        var company = await _db.Companies.FindAsync(companyId)
            ?? throw new InvalidOperationException("Company not found");

        if (isActive)
            company.Activate();
        else
            company.Deactivate();

        await _db.SaveChangesAsync();
    }

    public async Task<CompanyDto?> GetByIdAsync(Guid companyId)
    {
        return await _db.Companies
            .Where(c => c.Id == companyId)
            .Select(c => new CompanyDto
            {
                Id = c.Id,
                Name = c.Name,
                Region = c.Region,
                IsActive = c.IsActive
            })
            .FirstOrDefaultAsync();
    }

    public async Task UpdateSettingsAsync(Guid companyId, UpdateCompanySettingsRequest request)
    {
        var company = await _db.Companies.FindAsync(companyId)
            ?? throw new InvalidOperationException("Company not found");

        if (request.TimeZone != null || request.CurrencyCode != null)
        {
            company.UpdateLocalization(
                request.TimeZone ?? company.TimeZone,
                request.CurrencyCode ?? company.CurrencyCode);
        }

        if (request.TaxIdentifier != null)
        {
            company.UpdateTax(request.TaxIdentifier);
        }

        await _db.SaveChangesAsync();
    }
}
