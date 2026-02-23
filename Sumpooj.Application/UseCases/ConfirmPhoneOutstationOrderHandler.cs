using Sumpooj.Application.Interfaces;
using Sumpooj.Application.SalesOrders;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.UseCases;

public class ConfirmPhoneOutstationOrderHandler
{
    private readonly ISalesOrderRepository _salesOrderRepo;
    private readonly IVendorExecutionRepository _vendorExecutionRepo;

    public ConfirmPhoneOutstationOrderHandler(
        ISalesOrderRepository salesOrderRepo,
        IVendorExecutionRepository vendorExecutionRepo)
    {
        _salesOrderRepo = salesOrderRepo;
        _vendorExecutionRepo = vendorExecutionRepo;
    }

    public async Task HandleAsync(ConfirmPhoneOutstationOrderCommand command)
    {
        // 1. Validate VendorId is provided
        if (command.VendorId == Guid.Empty)
            throw new ArgumentException("VendorId is required for outstation order confirmation.");

        // 2. Load SalesOrder
        var order = await _salesOrderRepo.GetByIdAsync(command.SalesOrderId)
            ?? throw new InvalidOperationException($"SalesOrder '{command.SalesOrderId}' not found.");

        // 3. Ensure OrderType
        if (order.OrderType != OrderType.PhoneOutstation)
            throw new InvalidOperationException("This handler only supports PhoneOutstation orders.");

        // 4. Ensure Status == Draft (Confirm() also guards this)
        if (order.Status != SalesOrderStatus.Draft)
            throw new InvalidOperationException("Only Draft orders can be confirmed.");

        // 5. Confirm the order (Draft → Confirmed)
        order.Confirm();

        // 6. Create VendorExecution entity
        var vendorExecution = new VendorExecution(
            salesOrderId: order.Id,
            vendorId: command.VendorId,
            vendorCost: command.VendorCost,
            deliveryCharge: command.DeliveryCharge);

        // 7. Persist everything
        await _salesOrderRepo.UpdateAsync(order);
        await _vendorExecutionRepo.AddAsync(vendorExecution);
    }
}
