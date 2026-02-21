using Sumpooj.Application.Common;
using Sumpooj.Application.WireOrders;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IWireOrderRepository
{
    Task<WireOrder?> GetByIdAsync(Guid companyId, Guid id);
    Task<WireOrder?> GetByWireOrderNumberAsync(Guid companyId, string wireOrderNumber);
    Task<PagedResult<WireOrderDto>> SearchAsync(Guid companyId, WireOrderSearchRequest request);
    Task<List<WireOrderDto>> GetTodaysOrdersAsync(Guid companyId);
    Task<List<WireOrderDto>> GetPendingOrdersAsync(Guid companyId);
    Task<WireOrderSummaryDto> GetSummaryAsync(Guid companyId, DateTime fromDate, DateTime toDate);
    Task AddAsync(WireOrder order);
    Task UpdateAsync(WireOrder order);
}
