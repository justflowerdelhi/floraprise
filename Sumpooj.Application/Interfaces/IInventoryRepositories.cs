using Sumpooj.Application.Inventory;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IProductBatchRepository
{
    Task<ProductBatch?> GetByIdAsync(Guid id);
    Task AddAsync(ProductBatch batch);
    Task UpdateAsync(ProductBatch batch);

    Task<(List<ProductBatch> Items, int TotalCount)> SearchAsync(
        string? query,
        Guid? productId,
        Guid? supplierId,
        Guid? locationId,
        bool? isActive,
        bool? expiringOnly,
        int? expiringWithinDays,
        int page,
        int pageSize);

    Task<List<ProductBatch>> GetBatchesByProductIdAsync(Guid productId);
    Task<List<ProductBatch>> GetExpiringBatchesAsync(int daysThreshold);
    Task<List<ProductBatch>> GetExpiredBatchesAsync();
    Task<string> GenerateBatchNumberAsync(Guid productId);
    Task<List<ExpiryAlertDto>> GetExpiryAlertsAsync(Guid companyId, int daysThreshold);
}

public interface IInventoryAdjustmentRepository
{
    Task<InventoryAdjustment?> GetByIdAsync(Guid id);
    Task AddAsync(InventoryAdjustment adjustment);

    Task<(List<InventoryAdjustment> Items, int TotalCount)> SearchAsync(
        Guid? productId,
        Guid? batchId,
        string? adjustmentType,
        DateTime? fromDate,
        DateTime? toDate,
        int page,
        int pageSize);

    Task<List<InventoryAdjustment>> GetRecentAdjustmentsAsync(int count);
}
