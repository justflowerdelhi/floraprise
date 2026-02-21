using Sumpooj.Application.Common;
using Sumpooj.Application.Orders;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IOrderRepository
{
    Task<Order?> GetByIdAsync(Guid companyId, Guid id);
    Task<Order?> GetByOrderNumberAsync(Guid companyId, string orderNumber);
    Task<PagedResult<OrderListDto>> SearchAsync(Guid companyId, OrderSearchRequest request);
    Task<List<OrderListDto>> GetTodaysOrdersAsync(Guid companyId, Guid? locationId = null);
    Task<List<OrderListDto>> GetByDateAsync(Guid companyId, DateTime date);
    Task<List<OrderListDto>> GetByCustomerAsync(Guid companyId, Guid customerId);
    Task AddAsync(Order order);
    Task UpdateAsync(Order order);
    Task<string> GetNextOrderNumberAsync(Guid companyId);

    // Dashboard stats
    Task<int> GetTodaysOrderCountAsync(Guid companyId);
    Task<decimal> GetTodaysSalesAsync(Guid companyId);
    Task<int> GetPendingDeliveriesCountAsync(Guid companyId, DateTime date);
}
