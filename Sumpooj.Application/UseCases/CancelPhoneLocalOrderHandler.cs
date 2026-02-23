using Sumpooj.Application.Interfaces;
using Sumpooj.Application.SalesOrders;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.UseCases;

public class CancelPhoneLocalOrderHandler
{
    private readonly ISalesOrderRepository _salesOrderRepo;
    private readonly IInventoryReservationRepository _reservationRepo;
    private readonly IProductBatchRepository _batchRepo;

    public CancelPhoneLocalOrderHandler(
        ISalesOrderRepository salesOrderRepo,
        IInventoryReservationRepository reservationRepo,
        IProductBatchRepository batchRepo)
    {
        _salesOrderRepo = salesOrderRepo;
        _reservationRepo = reservationRepo;
        _batchRepo = batchRepo;
    }

    public async Task HandleAsync(CancelPhoneLocalOrderCommand command)
    {
        // 1. Load SalesOrder
        var order = await _salesOrderRepo.GetByIdAsync(command.SalesOrderId)
            ?? throw new InvalidOperationException($"SalesOrder '{command.SalesOrderId}' not found.");

        // 2. Ensure OrderType
        if (order.OrderType != OrderType.PhoneLocal)
            throw new InvalidOperationException("This handler only supports PhoneLocal orders.");

        // 3. Cancel the order (guards against Delivered and already-Cancelled)
        order.Cancel();

        // 4. Release all active reservations
        var reservations = await _reservationRepo.GetBySalesOrderIdAsync(order.Id);

        foreach (var reservation in reservations)
        {
            if (reservation.Status != ReservationStatus.Active)
                continue;

            // 4a. Load the corresponding batch
            var batch = await _batchRepo.GetByIdAsync(reservation.ProductBatchId)
                ?? throw new InvalidOperationException(
                    $"ProductBatch '{reservation.ProductBatchId}' not found for reservation '{reservation.Id}'.");

            // 4b. Release reserved units on the batch aggregate
            batch.ReleaseReservedUnits(reservation.ReservedUnits);
            await _batchRepo.UpdateAsync(batch);

            // 4c. Mark reservation as released
            reservation.MarkReleased();
            await _reservationRepo.UpdateAsync(reservation);
        }

        // 5. Persist the cancelled order
        await _salesOrderRepo.UpdateAsync(order);
    }
}
