using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IPurchaseOrderRepository
{
    Task<PurchaseOrder?> GetByIdAsync(Guid id);
    Task<PurchaseOrder?> GetByIdWithItemsAsync(Guid id);
    Task AddAsync(PurchaseOrder purchaseOrder);
    Task UpdateAsync(PurchaseOrder purchaseOrder);

    Task<(List<PurchaseOrder> Items, int TotalCount)> SearchAsync(
        string? query,
        Guid? supplierId,
        string? status,
        DateTime? fromDate,
        DateTime? toDate,
        int page,
        int pageSize);

    Task<List<PurchaseOrder>> GetPendingOrdersAsync();
}
