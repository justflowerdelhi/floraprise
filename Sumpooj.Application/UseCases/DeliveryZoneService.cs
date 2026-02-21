using Sumpooj.Application.DeliveryZones;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.UseCases;

public class DeliveryZoneService
{
    private readonly IDeliveryZoneRepository _repository;

    public DeliveryZoneService(IDeliveryZoneRepository repository)
    {
        _repository = repository;
    }

    public async Task<List<DeliveryZoneDto>> GetAllAsync(Guid companyId, bool activeOnly = true)
    {
        return await _repository.GetAllAsync(companyId, activeOnly);
    }

    public async Task<DeliveryZoneDto?> GetByIdAsync(Guid companyId, Guid id)
    {
        var zone = await _repository.GetByIdAsync(companyId, id);
        return zone == null ? null : MapToDto(zone);
    }

    public async Task<DeliveryZoneDto> CreateAsync(Guid companyId, CreateDeliveryZoneRequest request)
    {
        var zone = new DeliveryZone(
            companyId,
            request.Name,
            request.Code,
            request.DeliveryFee,
            request.EstimatedMinutes);

        zone.Update(
            request.Name,
            request.Code,
            string.Join(",", request.MatchValues),
            null,
            request.DeliveryFee,
            request.FreeDeliveryThreshold,
            request.SameDayFee,
            request.ExpressFee,
            request.EstimatedMinutes,
            request.DistanceKm,
            request.Priority,
            request.Notes);

        await _repository.AddAsync(zone);
        return MapToDto(zone);
    }

    public async Task<DeliveryZoneDto?> UpdateAsync(Guid companyId, Guid id, UpdateDeliveryZoneRequest request)
    {
        var zone = await _repository.GetByIdAsync(companyId, id);
        if (zone == null) return null;

        zone.Update(
            request.Name,
            request.Code,
            string.Join(",", request.MatchValues),
            null,
            request.DeliveryFee,
            request.FreeDeliveryThreshold,
            request.SameDayFee,
            request.ExpressFee,
            request.EstimatedMinutes,
            request.DistanceKm,
            request.Priority,
            request.Notes);

        await _repository.UpdateAsync(zone);
        return MapToDto(zone);
    }

    public async Task<bool> DeleteAsync(Guid companyId, Guid id)
    {
        var zone = await _repository.GetByIdAsync(companyId, id);
        if (zone == null) return false;

        await _repository.DeleteAsync(zone);
        return true;
    }

    public async Task<bool> ActivateAsync(Guid companyId, Guid id)
    {
        var zone = await _repository.GetByIdAsync(companyId, id);
        if (zone == null) return false;

        zone.Activate();
        await _repository.UpdateAsync(zone);
        return true;
    }

    public async Task<bool> DeactivateAsync(Guid companyId, Guid id)
    {
        var zone = await _repository.GetByIdAsync(companyId, id);
        if (zone == null) return false;

        zone.Deactivate();
        await _repository.UpdateAsync(zone);
        return true;
    }

    public async Task<DeliveryFeeResult> CalculateFeeAsync(Guid companyId, CalculateDeliveryFeeRequest request)
    {
        DeliveryZone? zone = null;

        if (!string.IsNullOrWhiteSpace(request.ZipCode))
        {
            zone = await _repository.FindByZipCodeAsync(companyId, request.ZipCode);
        }

        if (zone == null && !string.IsNullOrWhiteSpace(request.City))
        {
            zone = await _repository.FindByCityAsync(companyId, request.City);
        }

        if (zone == null)
        {
            return new DeliveryFeeResult
            {
                IsServiceable = false,
                Message = "Delivery zone not found for the specified location."
            };
        }

        var baseFee = zone.DeliveryFee;
        var sameDayFee = request.IsSameDay ? zone.SameDayFee : 0;
        var expressFee = request.IsExpress ? zone.ExpressFee : 0;
        var totalFee = baseFee + sameDayFee + expressFee;

        var isFreeDelivery = zone.FreeDeliveryThreshold.HasValue && 
                            request.OrderAmount >= zone.FreeDeliveryThreshold.Value;

        if (isFreeDelivery)
        {
            totalFee = sameDayFee + expressFee;
        }

        return new DeliveryFeeResult
        {
            ZoneId = zone.Id,
            ZoneName = zone.Name,
            BaseFee = baseFee,
            SameDayFee = sameDayFee,
            ExpressFee = expressFee,
            TotalFee = totalFee,
            IsFreeDelivery = isFreeDelivery,
            IsServiceable = zone.IsActive,
            EstimatedMinutes = zone.EstimatedMinutes,
            Message = isFreeDelivery ? "Free delivery!" : null
        };
    }

    private static DeliveryZoneDto MapToDto(DeliveryZone zone)
    {
        var matchValues = zone.ZipCodes?.Split(',', StringSplitOptions.RemoveEmptyEntries).ToList() ?? new();
        return new DeliveryZoneDto
        {
            Id = zone.Id,
            Name = zone.Name,
            Code = zone.Code,
            MatchType = "ZIP",
            MatchValues = matchValues,
            ZipCodes = matchValues,
            Cities = zone.Cities?.Split(',', StringSplitOptions.RemoveEmptyEntries).ToList() ?? new(),
            FreeDeliveryThreshold = zone.FreeDeliveryThreshold,
            DeliveryFee = zone.DeliveryFee,
            SameDayFee = zone.SameDayFee,
            ExpressFee = zone.ExpressFee,
            EstimatedMinutes = zone.EstimatedMinutes,
            DistanceKm = zone.DistanceKm,
            Priority = zone.SortOrder,
            IsServiceable = zone.IsActive,
            IsActive = zone.IsActive,
            Notes = zone.Notes,
            CreatedAtUtc = zone.CreatedAtUtc
        };
    }
}
