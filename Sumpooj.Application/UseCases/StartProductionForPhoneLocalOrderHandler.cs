using Sumpooj.Application.Interfaces;
using Sumpooj.Application.SalesOrders;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.UseCases;

public class StartProductionForPhoneLocalOrderHandler
{
    private readonly ISalesOrderRepository _salesOrderRepo;
    private readonly IInventoryReservationRepository _reservationRepo;
    private readonly IProductBatchRepository _batchRepo;
    private readonly IProductRepository _productRepo;

    public StartProductionForPhoneLocalOrderHandler(
        ISalesOrderRepository salesOrderRepo,
        IInventoryReservationRepository reservationRepo,
        IProductBatchRepository batchRepo,
        IProductRepository productRepo)
    {
        _salesOrderRepo = salesOrderRepo;
        _reservationRepo = reservationRepo;
        _batchRepo = batchRepo;
        _productRepo = productRepo;
    }

    public async Task HandleAsync(StartProductionForPhoneLocalOrderCommand command)
    {
        // 1. Load SalesOrder
        var order = await _salesOrderRepo.GetByIdAsync(command.SalesOrderId)
            ?? throw new InvalidOperationException($"SalesOrder '{command.SalesOrderId}' not found.");

        // 2. Ensure OrderType
        if (order.OrderType != OrderType.PhoneLocal)
            throw new InvalidOperationException("This handler only supports PhoneLocal orders.");

        // 3. Ensure Status == Confirmed (MarkInProduction also guards this)
        if (order.Status != SalesOrderStatus.Confirmed)
            throw new InvalidOperationException("Only Confirmed orders can be moved to InProduction.");

        // 4. Load all reservations for this order
        var reservations = await _reservationRepo.GetBySalesOrderIdAsync(order.Id);
        var activeReservations = reservations
            .Where(r => r.Status == ReservationStatus.Active)
            .ToList();

        if (activeReservations.Count == 0)
            throw new InvalidOperationException(
                $"No active reservations found for SalesOrder '{order.Id}'. Cannot start production without reserved inventory.");

        // 5. Transition order status (Confirmed → InProduction)
        order.MarkInProduction();

        // 6. Convert each active reservation to usage
        foreach (var reservation in activeReservations)
        {
            // 6a. Load the product (needed for multi-unit calculation)
            var product = await _productRepo.GetByIdAsync(reservation.ProductId)
                ?? throw new InvalidOperationException(
                    $"Product '{reservation.ProductId}' not found for reservation '{reservation.Id}'.");

            // 6b. Load the corresponding batch
            var batch = await _batchRepo.GetByIdAsync(reservation.ProductBatchId)
                ?? throw new InvalidOperationException(
                    $"ProductBatch '{reservation.ProductBatchId}' not found for reservation '{reservation.Id}'.");

            // 6c. Convert reservation to usage (decreases ReservedUnits, increases UsedUnits)
            batch.ConvertReservationToUsage(reservation.ReservedUnits, product);
            await _batchRepo.UpdateAsync(batch);

            // 6d. Mark reservation as converted
            reservation.MarkConverted();
            await _reservationRepo.UpdateAsync(reservation);
        }

        // 7. Persist the updated order
        await _salesOrderRepo.UpdateAsync(order);
    }
}
