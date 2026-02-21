using Sumpooj.Application.Common;
using Sumpooj.Application.DeliveryZones;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IDeliveryZoneRepository
{
    Task<DeliveryZone?> GetByIdAsync(Guid companyId, Guid id);
    Task<DeliveryZone?> GetByCodeAsync(Guid companyId, string code);
    Task<List<DeliveryZoneDto>> GetAllAsync(Guid companyId, bool activeOnly = true);
    Task<DeliveryZone?> FindByZipCodeAsync(Guid companyId, string zipCode);
    Task<DeliveryZone?> FindByCityAsync(Guid companyId, string city);
    Task AddAsync(DeliveryZone zone);
    Task UpdateAsync(DeliveryZone zone);
    Task DeleteAsync(DeliveryZone zone);
}
