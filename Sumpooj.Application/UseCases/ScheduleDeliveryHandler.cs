using Sumpooj.Application.Deliveries;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.UseCases;

public class ScheduleDeliveryHandler
{
    private readonly ISalesOrderRepository _salesOrderRepo;
    private readonly IDeliveryRepository _deliveryRepo;

    public ScheduleDeliveryHandler(
        ISalesOrderRepository salesOrderRepo,
        IDeliveryRepository deliveryRepo)
    {
        _salesOrderRepo = salesOrderRepo;
        _deliveryRepo = deliveryRepo;
    }

    public async Task HandleAsync(ScheduleDeliveryCommand command)
    {
        // 1. Load SalesOrder
        var order = await _salesOrderRepo.GetByIdAsync(command.SalesOrderId)
            ?? throw new InvalidOperationException($"SalesOrder '{command.SalesOrderId}' not found.");

        // 2. Validate OrderType == PhoneLocal
        if (order.OrderType != OrderType.PhoneLocal)
            throw new InvalidOperationException("Deliveries can only be scheduled for PhoneLocal orders.");

        // 3. Validate not Cancelled or Delivered
        if (order.Status == SalesOrderStatus.Cancelled)
            throw new InvalidOperationException("Cannot schedule delivery for a cancelled order.");
        if (order.Status == SalesOrderStatus.Delivered)
            throw new InvalidOperationException("Cannot schedule delivery for an already delivered order.");

        // 4. Create Delivery entity
        var delivery = new Delivery(
            salesOrderId: command.SalesOrderId,
            deliveryDate: command.DeliveryDate,
            timeSlot: command.TimeSlot,
            deliveryAddress: command.Address);

        // 5. Save via IDeliveryRepository
        await _deliveryRepo.AddAsync(delivery);
    }
}
