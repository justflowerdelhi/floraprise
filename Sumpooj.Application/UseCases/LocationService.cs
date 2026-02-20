using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Locations;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.UseCases;

public class LocationService
{
    private readonly ILocationRepository _repo;
    private readonly ITenantContext _tenant;

    public LocationService(ILocationRepository repo, ITenantContext tenant)
    {
        _repo = repo;
        _tenant = tenant;
    }

    public async Task<List<LocationDto>> GetAllAsync()
    {
        var locations = await _repo.GetAllAsync();
        return locations.Select(ToDto).ToList();
    }

    public async Task<List<LocationDto>> GetActiveLocationsAsync()
    {
        var locations = await _repo.GetActiveLocationsAsync();
        return locations.Select(ToDto).ToList();
    }

    public async Task<LocationDto?> GetAsync(Guid id)
    {
        var location = await _repo.GetByIdAsync(id);
        return location == null ? null : ToDto(location);
    }

    public async Task<Guid> CreateAsync(CreateLocationRequest request)
    {
        if (_tenant.CompanyId == null)
            throw new InvalidOperationException("Company context required");

        var locationType = Enum.TryParse<LocationType>(request.LocationType, true, out var lt)
            ? lt
            : LocationType.Store;

        var location = new Location(
            companyId: _tenant.CompanyId.Value,
            name: request.Name,
            code: request.Code,
            locationType: locationType,
            address: request.Address);

        if (request.IsDefault)
        {
            // Clear other defaults first
            var currentDefault = await _repo.GetDefaultLocationAsync();
            if (currentDefault != null)
            {
                currentDefault.ClearDefault();
                await _repo.UpdateAsync(currentDefault);
            }
            location.SetAsDefault();
        }

        await _repo.AddAsync(location);
        return location.Id;
    }

    public async Task UpdateAsync(Guid id, UpdateLocationRequest request)
    {
        var location = await _repo.GetByIdAsync(id)
            ?? throw new KeyNotFoundException("Location not found");

        if (request.Name != null || request.Address != null)
        {
            location.UpdateDetails(
                request.Name ?? location.Name,
                request.Address ?? location.Address);
        }

        if (request.IsDefault == true && !location.IsDefault)
        {
            var currentDefault = await _repo.GetDefaultLocationAsync();
            if (currentDefault != null && currentDefault.Id != location.Id)
            {
                currentDefault.ClearDefault();
                await _repo.UpdateAsync(currentDefault);
            }
            location.SetAsDefault();
        }

        await _repo.UpdateAsync(location);
    }

    public async Task DeactivateAsync(Guid id)
    {
        var location = await _repo.GetByIdAsync(id)
            ?? throw new KeyNotFoundException("Location not found");

        location.Deactivate();
        await _repo.UpdateAsync(location);
    }

    private static LocationDto ToDto(Location l) => new()
    {
        Id = l.Id,
        Name = l.Name,
        Code = l.Code,
        LocationType = l.LocationType.ToString(),
        Address = l.Address,
        IsActive = l.IsActive,
        IsDefault = l.IsDefault
    };
}
