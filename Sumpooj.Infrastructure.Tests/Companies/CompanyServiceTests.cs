using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Sumpooj.Application.Companies;
using Sumpooj.Application.DayClose;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.UseCases;
using Sumpooj.Infrastructure.Companies;
using Sumpooj.Infrastructure.Persistence;
using Sumpooj.Infrastructure.Repositories;

namespace Sumpooj.Infrastructure.Tests.Companies;

public class CompanyServiceTests : IDisposable
{
    private readonly SumpoojDbContext _db;
    private readonly LocationRepository _locationRepository;
    private readonly CompanyService _companyService;

    public CompanyServiceTests()
    {
        var options = new DbContextOptionsBuilder<SumpoojDbContext>()
            .UseInMemoryDatabase($"CompanyService_{Guid.NewGuid():N}")
            .ConfigureWarnings(warnings => warnings.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options;

        // Platform-scoped context: no tenant filter applied, matching how company creation runs today.
        _db = new SumpoojDbContext(options, new TestTenantContext(null));
        _locationRepository = new LocationRepository(_db);
        _companyService = new CompanyService(_db, _locationRepository);
    }

    public void Dispose() => _db.Dispose();

    [Fact]
    public async Task CreateAsync_CreatesOneActiveDefaultLocation_ForNewCompany()
    {
        var companyId = await _companyService.CreateAsync(new CreateCompanyRequest
        {
            Name = "Platform Onboarded Florist",
            Region = "IN",
            Email = "platform@example.com",
            TimeZone = "Asia/Kolkata",
            CurrencyCode = "INR",
        });

        var locations = await _db.Locations.Where(l => l.CompanyId == companyId).ToListAsync();

        var location = Assert.Single(locations);
        Assert.True(location.IsActive);
        Assert.True(location.IsDefault);
    }

    [Fact]
    public async Task CreateDefaultLocationAsync_IsIdempotent_WhenDefaultAlreadyExists()
    {
        var companyId = await _companyService.CreateAsync(new CreateCompanyRequest
        {
            Name = "Idempotent Florist",
            Region = "IN",
            TimeZone = "Asia/Kolkata",
            CurrencyCode = "INR",
        });

        await _companyService.CreateDefaultLocationAsync(companyId);

        var locations = await _db.Locations.Where(l => l.CompanyId == companyId).ToListAsync();
        Assert.Single(locations);
    }

    [Fact]
    public async Task DayClose_CanResolveAndCloseUsing_TheDefaultLocation()
    {
        var companyId = await _companyService.CreateAsync(new CreateCompanyRequest
        {
            Name = "Day Close Florist",
            Region = "IN",
            TimeZone = "Asia/Kolkata",
            CurrencyCode = "INR",
        });

        var activeLocations = await _locationRepository.GetActiveLocationsAsync();
        var defaultLocation = Assert.Single(activeLocations, l => l.CompanyId == companyId);

        var dayCloseRepository = new DayCloseRepository(_db);
        var dayCloseService = new DayCloseService(
            dayCloseRepository,
            new OrderRepository(_db),
            new PaymentRepository(_db),
            _locationRepository,
            dayCloseRepository);

        var businessDate = DateTime.UtcNow.Date;
        var dayCloseId = await dayCloseService.CloseAsync(
            companyId,
            new CloseDayRequest
            {
                LocationId = defaultLocation.Id,
                BusinessDate = businessDate,
                ActualCash = 0m,
            },
            userId: Guid.NewGuid());

        Assert.NotEqual(Guid.Empty, dayCloseId);
    }

    [Fact]
    public async Task UpdateSettingsAsync_UpdatesProfileFields_AndLeavesOtherCompanyUntouched()
    {
        var companyId = await _companyService.CreateAsync(new CreateCompanyRequest
        {
            Name = "Original Name",
            Region = "IN",
            Email = "original@example.com",
            Phone = "1111111111",
            TimeZone = "UTC",
            CurrencyCode = "USD",
        });
        var otherCompanyId = await _companyService.CreateAsync(new CreateCompanyRequest
        {
            Name = "Other Company",
            Region = "IN",
            Email = "other@example.com",
            Phone = "2222222222",
            TimeZone = "UTC",
            CurrencyCode = "USD",
        });

        await _companyService.UpdateSettingsAsync(companyId, new UpdateCompanySettingsRequest
        {
            Name = "Jai Bajrang Bali",
            Phone = "9876543210",
            Email = "shop@example.com",
            Address = "Main Bazaar",
            ShortDescription = "Flower shop",
            TaxIdentifier = "GSTIN123",
            TimeZone = "Asia/Kolkata",
            CurrencyCode = "INR",
        });

        var updated = await _companyService.GetByIdAsync(companyId);
        Assert.NotNull(updated);
        Assert.Equal("Jai Bajrang Bali", updated!.Name);
        Assert.Equal("9876543210", updated.Phone);
        Assert.Equal("shop@example.com", updated.Email);
        Assert.Equal("Main Bazaar", updated.Address);
        Assert.Equal("Flower shop", updated.ShortDescription);
        Assert.Equal("GSTIN123", updated.TaxIdentifier);
        Assert.Equal("Asia/Kolkata", updated.TimeZone);
        Assert.Equal("INR", updated.CurrencyCode);

        // CompanyId isolation: the other company's row must be unaffected.
        var untouched = await _companyService.GetByIdAsync(otherCompanyId);
        Assert.NotNull(untouched);
        Assert.Equal("Other Company", untouched!.Name);
        Assert.Equal("2222222222", untouched.Phone);
        Assert.Equal("other@example.com", untouched.Email);
    }

    [Fact]
    public async Task UpdateSettingsAsync_PartialUpdate_LeavesUnspecifiedFieldsUnchanged()
    {
        var companyId = await _companyService.CreateAsync(new CreateCompanyRequest
        {
            Name = "Keep My Name",
            Region = "IN",
            Email = "keep@example.com",
            Phone = "3333333333",
            TimeZone = "UTC",
            CurrencyCode = "USD",
        });

        await _companyService.UpdateSettingsAsync(companyId, new UpdateCompanySettingsRequest
        {
            Phone = "4444444444",
        });

        var updated = await _companyService.GetByIdAsync(companyId);
        Assert.NotNull(updated);
        Assert.Equal("Keep My Name", updated!.Name);
        Assert.Equal("4444444444", updated.Phone);
        Assert.Equal("keep@example.com", updated.Email);
    }

    [Fact]
    public async Task UpdateSettingsAsync_RejectsBlankName()
    {
        var companyId = await _companyService.CreateAsync(new CreateCompanyRequest
        {
            Name = "Valid Name",
            Region = "IN",
            TimeZone = "UTC",
            CurrencyCode = "USD",
        });

        await Assert.ThrowsAsync<ArgumentException>(() => _companyService.UpdateSettingsAsync(
            companyId,
            new UpdateCompanySettingsRequest { Name = "   " }));
    }

    private sealed class TestTenantContext(Guid? companyId) : ITenantContext
    {
        public Guid? CompanyId => companyId;
        public bool IsPlatformUser => companyId == null;
        public string? Region => null;
    }
}
