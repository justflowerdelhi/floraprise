using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IDeliveryRepository
{
    Task<Delivery?> GetByIdAsync(Guid id);
    Task<Delivery?> GetBySalesOrderIdAsync(Guid salesOrderId);
    Task<IReadOnlyList<Delivery>> GetAllAsync();
    Task<IReadOnlyList<Delivery>> GetByDateAsync(DateTime date);
    Task<List<Delivery>> GetByIdsAsync(List<Guid> ids);
    Task AddAsync(Delivery delivery);
    Task UpdateAsync(Delivery delivery);

    // Staff performance
    Task<int> GetDeliveryCountByDriverAsync(Guid driverId, DateTime from, DateTime to);
    Task<int> GetCompletedDeliveryCountByDriverAsync(Guid driverId, DateTime from, DateTime to);
}
