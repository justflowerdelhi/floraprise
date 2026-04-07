using Sumpooj.Application.Interfaces;
using Sumpooj.Application.SalesOrders;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.UseCases;

public class StartProductionForPhoneLocalOrderHandler
{
    private readonly ISalesOrderRepository _salesOrderRepo;
    private readonly IInventoryReservationRepository _reservationRepo;

    public StartProductionForPhoneLocalOrderHandler(
        ISalesOrderRepository salesOrderRepo,
        IInventoryReservationRepository reservationRepo)
    {
        _salesOrderRepo = salesOrderRepo;
        _reservationRepo = reservationRepo;
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

        // 6. Persist the updated order (inventory consumption happens only on delivery)
        await _salesOrderRepo.UpdateAsync(order);
    }
}
