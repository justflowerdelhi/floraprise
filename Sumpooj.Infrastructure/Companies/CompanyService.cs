using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Companies;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Companies;

public class CompanyService : ICompanyService
{
    private readonly SumpoojDbContext _db;
    private readonly ILocationRepository _locationRepository;

    public CompanyService(SumpoojDbContext db, ILocationRepository locationRepository)
    {
        _db = db;
        _locationRepository = locationRepository;
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

        // Company + its default Location must be created atomically.
        var strategy = _db.Database.CreateExecutionStrategy();
        await strategy.ExecuteAsync(async () =>
        {
            await using var transaction = await _db.Database.BeginTransactionAsync();
            _db.Companies.Add(company);
            await _db.SaveChangesAsync();
            await CreateDefaultLocationAsync(company.Id);
            await transaction.CommitAsync();
        });

        return company.Id;
    }

    public async Task CreateDefaultLocationAsync(Guid companyId)
    {
        var existingDefault = await _locationRepository.GetDefaultAsync(companyId);
        if (existingDefault != null)
            return;

        var location = new Location(companyId, "Main Store", "MAIN-01", LocationType.Store, null);
        location.SetAsDefault();
        await _locationRepository.AddAsync(location);
    }

    public async Task<CompanyDto?> FindByEmailOrPhoneAsync(string email, string phone)
    {
        var normalizedEmail = email.Trim();
        var normalizedPhone = phone.Trim();

        return await _db.Companies
            .Where(c => c.Email == normalizedEmail || c.Phone == normalizedPhone)
            .Select(c => MapToDto(c))
            .FirstOrDefaultAsync();
    }

    public async Task<IReadOnlyList<CompanyDto>> GetAllAsync()
    {
        return await _db.Companies
            .OrderBy(c => c.Name)
            .Select(c => MapToDto(c))
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
            .Select(c => MapToDto(c))
            .FirstOrDefaultAsync();
    }

    public async Task UpdateSettingsAsync(Guid companyId, UpdateCompanySettingsRequest request)
    {
        var company = await _db.Companies.FindAsync(companyId)
            ?? throw new InvalidOperationException("Company not found");

        if (request.Name != null || request.Phone != null || request.Email != null || request.Address != null || request.ShortDescription != null)
        {
            var name = request.Name ?? company.Name;
            if (string.IsNullOrWhiteSpace(name))
                throw new ArgumentException("Company name cannot be empty.");

            company.UpdateProfile(
                name: name,
                phone: request.Phone ?? company.Phone,
                email: request.Email ?? company.Email,
                address: request.Address ?? company.Address,
                shortDescription: request.ShortDescription ?? company.ShortDescription);
        }

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

        if (request.LogoPath != null)
        {
            company.UpdateBranding(string.IsNullOrWhiteSpace(request.LogoPath) ? null : request.LogoPath.Trim());
        }

        if (request.OwnerName != null || request.City != null || request.State != null || request.PinCode != null)
        {
            var customer = await _db.MobileCustomers.FirstOrDefaultAsync(x => x.CompanyId == companyId && !x.IsDeleted);
            if (customer != null)
            {
                if (request.OwnerName != null && !string.IsNullOrWhiteSpace(request.OwnerName))
                {
                    customer.UpdateOwnerName(request.OwnerName.Trim());
                }

                var city = request.City != null ? (string.IsNullOrWhiteSpace(request.City) ? null : request.City.Trim()) : customer.City;
                var state = request.State != null ? (string.IsNullOrWhiteSpace(request.State) ? null : request.State.Trim()) : customer.State;
                var pinCode = request.PinCode != null ? (string.IsNullOrWhiteSpace(request.PinCode) ? null : request.PinCode.Trim()) : customer.Country;
                customer.UpdateProfile(customer.Email, city, state, pinCode, null);
            }
            else
            {
                var newCustomer = new MobileCustomer(
                    companyId: companyId,
                    businessName: company.Name,
                    ownerName: string.IsNullOrWhiteSpace(request.OwnerName) ? "Owner" : request.OwnerName.Trim(),
                    mobile: company.Phone ?? "0000000000");
                newCustomer.UpdateProfile(
                    company.Email,
                    string.IsNullOrWhiteSpace(request.City) ? null : request.City.Trim(),
                    string.IsNullOrWhiteSpace(request.State) ? null : request.State.Trim(),
                    string.IsNullOrWhiteSpace(request.PinCode) ? null : request.PinCode.Trim(),
                    null);
                _db.MobileCustomers.Add(newCustomer);
            }

            if (request.OwnerName != null && !string.IsNullOrWhiteSpace(request.OwnerName))
            {
                var users = await _db.MobileUsers.Where(x => x.CompanyId == companyId && !x.IsDeleted).ToListAsync();
                foreach (var user in users)
                {
                    user.UpdateFullName(request.OwnerName.Trim());
                }
            }
        }

        await _db.SaveChangesAsync();
    }

    private static CompanyDto MapToDto(Company c) => new()
    {
        Id = c.Id,
        Name = c.Name,
        Region = c.Region,
        IsActive = c.IsActive,
        Email = c.Email,
        Phone = c.Phone,
        Address = c.Address,
        ShortDescription = c.ShortDescription,
        TimeZone = c.TimeZone,
        CurrencyCode = c.CurrencyCode,
        TaxIdentifier = c.TaxIdentifier,
        CreatedAt = c.CreatedAtUtc,
    };
}
