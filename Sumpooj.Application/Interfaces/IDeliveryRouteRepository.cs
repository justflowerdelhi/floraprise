using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IDeliveryRouteRepository
{
    Task<DeliveryRoute?> GetByIdAsync(Guid id);
    Task<List<DeliveryRoute>> GetAllAsync();
    Task AddAsync(DeliveryRoute route);
    Task UpdateAsync(DeliveryRoute route);
}
