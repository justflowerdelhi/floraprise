using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IInventoryReservationRepository
{
    Task<InventoryReservation?> GetByIdAsync(Guid id);
    Task AddAsync(InventoryReservation reservation);
    Task UpdateAsync(InventoryReservation reservation);
    Task<List<InventoryReservation>> GetBySalesOrderIdAsync(Guid salesOrderId);

    /// <summary>
    /// Returns the active reservation for a given (SalesOrderId, ProductBatchId) pair,
    /// or null if none exists. Only one Active reservation is allowed per pair.
    /// </summary>
    Task<InventoryReservation?> GetActiveReservationAsync(Guid salesOrderId, Guid productBatchId);
}
