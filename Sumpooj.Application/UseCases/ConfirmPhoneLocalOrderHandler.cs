using Sumpooj.Application.Interfaces;
using Sumpooj.Application.SalesOrders;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.UseCases;

public class ConfirmPhoneLocalOrderHandler
{
    private readonly ISalesOrderRepository _salesOrderRepo;
    private readonly IProductRepository _productRepo;
    private readonly IProductBatchRepository _batchRepo;
    private readonly IInventoryReservationRepository _reservationRepo;

    public ConfirmPhoneLocalOrderHandler(
        ISalesOrderRepository salesOrderRepo,
        IProductRepository productRepo,
        IProductBatchRepository batchRepo,
        IInventoryReservationRepository reservationRepo)
    {
        _salesOrderRepo = salesOrderRepo;
        _productRepo = productRepo;
        _batchRepo = batchRepo;
        _reservationRepo = reservationRepo;
    }

    public async Task HandleAsync(ConfirmPhoneLocalOrderCommand command)
    {
        // 1. Load SalesOrder
        var order = await _salesOrderRepo.GetByIdAsync(command.SalesOrderId)
            ?? throw new InvalidOperationException($"SalesOrder '{command.SalesOrderId}' not found.");

        // 2. Ensure OrderType
        if (order.OrderType != OrderType.PhoneLocal)
            throw new InvalidOperationException("This handler only supports PhoneLocal orders.");

        // 3. Ensure Status == Draft (Confirm() also guards this, but fail-fast here)
        if (order.Status != SalesOrderStatus.Draft)
            throw new InvalidOperationException("Only Draft orders can be confirmed.");

        // 4. Confirm the order (Draft → Confirmed)
        order.Confirm();

        // 5. Reserve inventory for each item using FIFO split logic
        var reservations = new List<InventoryReservation>();
        var updatedBatches = new List<ProductBatch>();

        foreach (var item in order.Items)
        {
            // 5a. Load Product
            var product = await _productRepo.GetByIdAsync(item.ProductId)
                ?? throw new InvalidOperationException($"Product '{item.ProductId}' not found.");

            // 5b. Quantity represents consumption units
            int remainingUnitsToReserve = item.Quantity;

            // 5c. Load all active batches ordered by ReceivedDate ascending (FIFO)
            var batches = await _batchRepo.GetBatchesByProductIdAsync(item.ProductId);
            var activeBatches = batches
                .Where(b => b.IsActive && !b.IsExpired())
                .OrderBy(b => b.ReceivedDate)
                .ToList();

            // 5d. FIFO split reservation across batches
            foreach (var batch in activeBatches)
            {
                if (remainingUnitsToReserve <= 0)
                    break;

                int available = batch.GetAvailableForReservation(product);
                if (available <= 0)
                    continue;

                int unitsToReserve = Math.Min(available, remainingUnitsToReserve);

                // 5e. Enforce unique constraint: only one Active reservation per (SalesOrderId + ProductBatchId)
                var existingReservation = await _reservationRepo.GetActiveReservationAsync(order.Id, batch.Id);
                if (existingReservation != null)
                    throw new InvalidOperationException(
                        $"An active reservation already exists for SalesOrder '{order.Id}' and ProductBatch '{batch.Id}'.");

                // 5f. Reserve on batch aggregate
                batch.ReserveUnits(unitsToReserve, product);
                updatedBatches.Add(batch);

                // 5g. Create reservation tracking entity
                var reservation = new InventoryReservation(
                    salesOrderId: order.Id,
                    productBatchId: batch.Id,
                    productId: product.Id,
                    reservedUnits: unitsToReserve);

                reservations.Add(reservation);

                remainingUnitsToReserve -= unitsToReserve;
            }

            // 5h. Validate all units were reserved
            if (remainingUnitsToReserve > 0)
                throw new InvalidOperationException(
                    $"Insufficient stock for product '{product.Name}' (ID: {product.Id}). " +
                    $"Required: {item.Quantity}, Unable to reserve: {remainingUnitsToReserve}.");
        }

        // 6. Persist everything atomically
        await _salesOrderRepo.UpdateAsync(order);

        foreach (var batch in updatedBatches)
        {
            await _batchRepo.UpdateAsync(batch);
        }

        foreach (var reservation in reservations)
        {
            await _reservationRepo.AddAsync(reservation);
        }
    }
}
