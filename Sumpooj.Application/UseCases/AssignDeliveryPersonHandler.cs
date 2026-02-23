using Sumpooj.Application.Deliveries;
using Sumpooj.Application.Interfaces;

namespace Sumpooj.Application.UseCases;

public class AssignDeliveryPersonHandler
{
    private readonly IDeliveryRepository _deliveryRepo;
    private readonly ISalesOrderRepository _salesOrderRepo;
    private readonly IStaffRepository _staffRepo;

    public AssignDeliveryPersonHandler(
        IDeliveryRepository deliveryRepo,
        ISalesOrderRepository salesOrderRepo,
        IStaffRepository staffRepo)
    {
        _deliveryRepo = deliveryRepo;
        _salesOrderRepo = salesOrderRepo;
        _staffRepo = staffRepo;
    }

    public async Task HandleAsync(AssignDeliveryPersonCommand command)
    {
        // 1. Load Delivery
        var delivery = await _deliveryRepo.GetByIdAsync(command.DeliveryId)
            ?? throw new InvalidOperationException($"Delivery '{command.DeliveryId}' not found.");

        // 2. Validate status — cannot assign if already delivered or cancelled
        if (delivery.Status == Domain.Entities.DeliveryStatus.Delivered)
            throw new InvalidOperationException("Cannot assign a delivery person to a delivery that is already delivered.");

        if (delivery.Status == Domain.Entities.DeliveryStatus.Cancelled)
            throw new InvalidOperationException("Cannot assign a delivery person to a cancelled delivery.");

        // 3. Validate Staff exists (need CompanyId from the related SalesOrder)
        var order = await _salesOrderRepo.GetByIdAsync(delivery.SalesOrderId)
            ?? throw new InvalidOperationException($"SalesOrder '{delivery.SalesOrderId}' not found.");

        var staff = await _staffRepo.GetByIdAsync(order.CompanyId, command.StaffId)
            ?? throw new InvalidOperationException($"Staff '{command.StaffId}' not found.");

        // 4. Assign delivery person via domain method
        delivery.AssignDeliveryPerson(command.StaffId);

        // 5. Save changes
        await _deliveryRepo.UpdateAsync(delivery);
    }
}
