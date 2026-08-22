using Sumpooj.Application.Accounting;
using Sumpooj.Application.Common;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Orders;
using Sumpooj.Domain.Entities;
using System.Transactions;

namespace Sumpooj.Application.UseCases;

public class OrderService
{
    private readonly IOrderRepository _orderRepository;
    private readonly ICustomerRepository _customerRepository;
    private readonly IProductRepository _productRepository;
    private readonly ILocationRepository _locationRepository;
    private readonly IShiftRepository _shiftRepository;
    private readonly IPaymentRepository _paymentRepository;
    private readonly IInventoryLedgerRepository _inventoryLedgerRepository;
    private readonly IProductBatchRepository _productBatchRepository;
    private readonly IInventoryReservationRepository _reservationRepository;
    private readonly IFinishedGoodsBatchRepository _finishedGoodsBatchRepository;
    private readonly IJournalEntryRepository _journalEntryRepository;
    private readonly IDeliveryRepository _deliveryRepository;
    private readonly ICorporateRepository _corporateRepository;

    public OrderService(
        IOrderRepository orderRepository,
        ICustomerRepository customerRepository,
        IProductRepository productRepository,
        ILocationRepository locationRepository,
        IShiftRepository shiftRepository,
        IPaymentRepository paymentRepository,
        IInventoryLedgerRepository inventoryLedgerRepository,
        IProductBatchRepository productBatchRepository,
        IInventoryReservationRepository reservationRepository,
        IFinishedGoodsBatchRepository finishedGoodsBatchRepository,
        IJournalEntryRepository journalEntryRepository,
        IDeliveryRepository deliveryRepository,
        ICorporateRepository corporateRepository)
    {
        _orderRepository = orderRepository;
        _customerRepository = customerRepository;
        _productRepository = productRepository;
        _locationRepository = locationRepository;
        _shiftRepository = shiftRepository;
        _paymentRepository = paymentRepository;
        _inventoryLedgerRepository = inventoryLedgerRepository;
        _productBatchRepository = productBatchRepository;
        _reservationRepository = reservationRepository;
        _finishedGoodsBatchRepository = finishedGoodsBatchRepository;
        _journalEntryRepository = journalEntryRepository;
        _deliveryRepository = deliveryRepository;
        _corporateRepository = corporateRepository;
    }

    public async Task<OrderDto?> GetByIdAsync(Guid companyId, Guid id)
    {
        var order = await _orderRepository.GetByIdAsync(companyId, id);
        return order == null ? null : MapToDto(order);
    }

    public async Task<OrderDto?> GetByOrderNumberAsync(Guid companyId, string orderNumber)
    {
        var order = await _orderRepository.GetByOrderNumberAsync(companyId, orderNumber);
        return order == null ? null : MapToDto(order);
    }

    public async Task<PagedResult<OrderListDto>> SearchAsync(Guid companyId, OrderSearchRequest request)
    {
        return await _orderRepository.SearchAsync(companyId, request);
    }

    public async Task<List<OrderListDto>> GetTodaysOrdersAsync(Guid companyId, Guid? locationId = null)
    {
        return await _orderRepository.GetTodaysOrdersAsync(companyId, locationId);
    }

    public async Task<List<OrderListDto>> GetByDeliveryDateAsync(Guid companyId, DateTime date)
    {
        return await _orderRepository.GetByDateAsync(companyId, date);
    }

    public async Task<List<OrderListDto>> GetByCustomerAsync(Guid companyId, Guid customerId)
    {
        return await _orderRepository.GetByCustomerAsync(companyId, customerId);
    }

    public async Task<Guid> CreateAsync(Guid companyId, CreateOrderRequest request)
    {
        // Validate LocationId is provided
        if (!request.LocationId.HasValue || request.LocationId == Guid.Empty)
        {
            // Auto-assign default location if not provided
            var defaultLocation = await _locationRepository.GetDefaultAsync(companyId);
            if (defaultLocation != null)
                request.LocationId = defaultLocation.Id;
            else
                throw new InvalidOperationException("LocationId is required when creating an order.");
        }

        // Validate Location exists and belongs to the same company
        var location = await _locationRepository.GetByIdAsync(request.LocationId.Value)
            ?? throw new InvalidOperationException($"Location '{request.LocationId}' not found.");

        if (location.CompanyId != companyId)
            throw new InvalidOperationException("Location does not belong to this company.");

        if (!location.IsActive)
            throw new InvalidOperationException("Cannot create an order for an inactive location.");

        // Validate an active shift exists for this location
        var activeShift = await _shiftRepository.GetActiveShiftAsync(companyId, request.LocationId!.Value);
        if (activeShift == null)
            throw new InvalidOperationException("No active shift for this location. Please open a shift before creating orders.");

        // Resolve customer — use walk-in customer if not provided
        var customerId = request.CustomerId.GetValueOrDefault();
        if (customerId == Guid.Empty)
        {
            var matchedCustomer = await _customerRepository.FindByPhoneOrNameAsync(
                companyId,
                request.RecipientPhone,
                request.RecipientName);

            if (matchedCustomer != null)
            {
                customerId = matchedCustomer.Id;
            }
            else
            {
                var recipientName = request.RecipientName?.Trim();
                var recipientPhone = request.RecipientPhone?.Trim();

                if (!string.IsNullOrWhiteSpace(recipientName) || !string.IsNullOrWhiteSpace(recipientPhone))
                {
                    var customer = new Customer(
                        companyId,
                        recipientName ?? "POS Customer",
                        null,
                        recipientPhone);

                    await _customerRepository.AddAsync(customer);
                    customerId = customer.Id;
                }
                else
                {
                    var walkInCustomer = await _customerRepository.GetOrCreateWalkInCustomerAsync(companyId);
                    customerId = walkInCustomer.Id;
                }
            }
        }
        else
        {
            _ = await _customerRepository.GetByIdAsync(customerId)
                ?? throw new KeyNotFoundException("Customer not found");
        }

        // Default delivery date to now for walk-in / take-now orders
        var deliveryDate = request.DeliveryDate ?? DateTime.UtcNow;

        var order = new Order(
            companyId,
            customerId,
            deliveryDate,
            request.DeliveryAddress,
            request.DeliveryPincode,
            request.RecipientName,
            request.RecipientPhone);

        // Assign location
        order.LocationId = request.LocationId;

        // Set optional fields
        if (!string.IsNullOrEmpty(request.CardMessage))
            order.SetCardMessage(request.CardMessage);

        // Normalize frontend enum formats (WALK_IN → WalkIn, NORMAL → Standard)
        var priorityStr = NormalizeEnumString(request.DeliveryPriority);
        if (Enum.TryParse<DeliveryPriority>(priorityStr, true, out var priority))
            order.SetDeliveryPriority(priority);

        var sourceStr = NormalizeEnumString(request.OrderSource);
        if (Enum.TryParse<OrderSource>(sourceStr, true, out var source))
            order.SetOrderSource(source);

        if (!string.IsNullOrEmpty(request.TimeSlot))
            order.SetTimeSlot(request.TimeSlot);

        if (request.DeliveryFee > 0)
            order.SetDeliveryFee(request.DeliveryFee);

        if (request.DiscountAmount > 0)
            order.ApplyDiscount(request.DiscountAmount);

        if (!string.IsNullOrEmpty(request.InternalNotes))
            order.AddInternalNote(request.InternalNotes);

        // Add items
        foreach (var item in request.Items)
        {
            order.AddItem(item.ProductId, item.ProductName, item.Quantity, item.UnitPrice);
        }

        await _orderRepository.AddAsync(order);

        // ── Auto-schedule Delivery for DELIVERY orders ──
        var isDeliveryOrder = string.Equals(request.OrderIntent, "DELIVERY", StringComparison.OrdinalIgnoreCase);
        if (isDeliveryOrder
            && !string.IsNullOrWhiteSpace(request.DeliveryAddress)
            && !string.IsNullOrWhiteSpace(request.TimeSlot))
        {
            var existing = await _deliveryRepository.GetBySalesOrderIdAsync(order.Id);
            if (existing == null)
            {
                var delivery = new Delivery(companyId, order.Id, deliveryDate, request.TimeSlot, request.DeliveryAddress);
                if (!string.IsNullOrWhiteSpace(request.DeliveryPincode))
                    delivery.SetPostalCode(request.DeliveryPincode);
                await _deliveryRepository.AddAsync(delivery);
            }
        }

        // ── Save payments (if provided from POS checkout) ──
        if (request.Payments.Count > 0)
        {
            decimal totalPaid = 0;
            foreach (var p in request.Payments)
            {
                var methodStr = NormalizeEnumString(p.Method);
                if (!Enum.TryParse<PaymentMethod>(methodStr, true, out var method))
                    method = PaymentMethod.Cash;

                var payment = new Payment(companyId, order.Id, method, p.Amount);
                if (request.LocationId.HasValue)
                    payment.SetLocation(request.LocationId.Value);

                // POS payments are immediate — approve all methods
                // (card/UPI terminal has already confirmed at the POS)
                payment.Approve(null, null);

                await _paymentRepository.AddAsync(payment);
                totalPaid += p.Amount;
            }

            // Update order payment status
            if (totalPaid >= order.TotalAmount)
                order.MarkPaid();
            else if (totalPaid > 0)
                order.MarkPartiallyPaid(totalPaid);

            await _orderRepository.UpdateAsync(order);

            // ── Update shift sales totals ──
            if (request.LocationId.HasValue)
            {
                decimal cashTotal = 0, cardTotal = 0, upiTotal = 0, giftCardTotal = 0, otherTotal = 0;
                foreach (var p in request.Payments)
                {
                    var methodStr = NormalizeEnumString(p.Method);
                    if (!Enum.TryParse<PaymentMethod>(methodStr, true, out var m))
                        m = PaymentMethod.Cash;

                    switch (m)
                    {
                        case PaymentMethod.Cash: cashTotal += p.Amount; break;
                        case PaymentMethod.Card: cardTotal += p.Amount; break;
                        case PaymentMethod.Upi: upiTotal += p.Amount; break;
                        case PaymentMethod.GiftCard: giftCardTotal += p.Amount; break;
                        default: otherTotal += p.Amount; break;
                    }
                }

                var shift = await _shiftRepository.GetActiveShiftAsync(companyId, request.LocationId.Value);
                if (shift != null)
                {
                    shift.RecordSale(cashTotal, cardTotal, upiTotal, giftCardTotal, otherTotal);
                    await _shiftRepository.UpdateAsync(shift);
                }
            }
        }

        // Walk-in orders with full payment: auto-confirm + complete
        // Customer takes items on the spot — no delivery/design pipeline needed
        var isWalkIn = order.OrderSource == OrderSource.WalkIn;
        var isTakeNow = string.Equals(request.OrderIntent, "TAKE_NOW", StringComparison.OrdinalIgnoreCase);

        if (isWalkIn || isTakeNow)
        {
            if (order.Status == OrderStatus.Pending)
                order.Confirm();

            if (order.PaymentStatus == PaymentStatus.Paid)
            {
                order.SetFulfillmentStatus(FulfillmentStatus.Completed);
                order.MarkDeliveredDirect();
            }

            await _orderRepository.UpdateAsync(order);

            if (order.Status == OrderStatus.Delivered)
            {
                await ConsumeInventoryForOrderAsync(companyId, order);
            }
        }

        // ── Create accounting journal entries for payments ──
        if (request.Payments.Count > 0)
        {
            await CreateSaleJournalEntriesAsync(companyId, order, request);
        }

        // ── Update customer purchase stats ──
        await UpdateCustomerStatsAsync(customerId);

        return order.Id;
    }

    /// <summary>
    /// Converts SCREAMING_SNAKE_CASE to PascalCase for enum parsing.
    /// e.g. "WALK_IN" → "WalkIn", "SAME_DAY" → "SameDay", "NORMAL" → "Normal"
    /// </summary>
    private static string NormalizeEnumString(string? value)
    {
        if (string.IsNullOrWhiteSpace(value)) return string.Empty;

        // If it contains underscores, convert SCREAMING_SNAKE_CASE → PascalCase
        if (value.Contains('_'))
        {
            return string.Concat(
                value.Split('_')
                     .Where(s => s.Length > 0)
                     .Select(s => char.ToUpper(s[0]) + s[1..].ToLower()));
        }

        // Already PascalCase or single word — return as-is
        return value;
    }

    public async Task UpdateStatusAsync(Guid companyId, Guid id, string status)
    {
        var order = await _orderRepository.GetByIdAsync(companyId, id)
            ?? throw new KeyNotFoundException("Order not found");

        if (!Enum.TryParse<OrderStatus>(status, true, out var orderStatus))
            throw new ArgumentException($"Invalid status: {status}");

        switch (orderStatus)
        {
            case OrderStatus.Confirmed:
                order.Confirm();
                break;
            case OrderStatus.Cancelled:
                order.Cancel("Cancelled by user");
                break;
            case OrderStatus.ReadyForDelivery:
                order.MarkReadyForDelivery();
                break;
            case OrderStatus.OutForDelivery:
                order.MarkOutForDelivery();
                break;
            case OrderStatus.Delivered:
                order.MarkDelivered();
                break;
        }

        if (order.Status == OrderStatus.Delivered && !order.IsInventoryProcessed)
        {
            await ConsumeInventoryForOrderAsync(companyId, order);
        }

        await _orderRepository.UpdateAsync(order);

        await HandleCorporateFulfillmentPostingAsync(companyId, order);
    }

    public async Task UpdateFulfillmentStatusAsync(Guid companyId, Guid id, string status)
    {
        var order = await _orderRepository.GetByIdAsync(companyId, id)
            ?? throw new KeyNotFoundException("Order not found");

        if (Enum.TryParse<FulfillmentStatus>(status, true, out var fulfillmentStatus))
        {
            order.SetFulfillmentStatus(fulfillmentStatus);

            // When fulfillment is completed, also mark the order as delivered
            if (fulfillmentStatus == FulfillmentStatus.Completed
                && order.Status != OrderStatus.Delivered
                && order.Status != OrderStatus.Cancelled)
            {
                order.MarkDeliveredDirect();
            }

            if (order.Status == OrderStatus.Delivered && !order.IsInventoryProcessed)
            {
                await ConsumeInventoryForOrderAsync(companyId, order);
            }

            await _orderRepository.UpdateAsync(order);

            await HandleCorporateFulfillmentPostingAsync(companyId, order);
        }
    }

    public async Task AssignDesignerAsync(Guid companyId, Guid orderId, Guid designerId)
    {
        var order = await _orderRepository.GetByIdAsync(companyId, orderId)
            ?? throw new KeyNotFoundException("Order not found");

        order.StartProcessing(designerId);
        await _orderRepository.UpdateAsync(order);
    }

    public async Task AssignDriverAsync(Guid companyId, Guid orderId, Guid driverId)
    {
        var order = await _orderRepository.GetByIdAsync(companyId, orderId)
            ?? throw new KeyNotFoundException("Order not found");

        order.AssignDeliveryPerson(driverId);
        await _orderRepository.UpdateAsync(order);

        var delivery = await _deliveryRepository.GetBySalesOrderIdAsync(order.Id);
        var deliveryAddress = string.IsNullOrWhiteSpace(order.DeliveryAddress)
            ? "Address not specified"
            : order.DeliveryAddress;
        var timeSlot = string.IsNullOrWhiteSpace(order.TimeSlot)
            ? "Anytime"
            : order.TimeSlot;

        if (delivery == null)
        {
            delivery = new Delivery(
                companyId,
                order.Id,
                order.DeliveryDate,
                timeSlot,
                deliveryAddress);
            if (!string.IsNullOrWhiteSpace(order.DeliveryPincode))
                delivery.SetPostalCode(order.DeliveryPincode);
            delivery.SetCustomerContact(order.RecipientPhone, null);
            delivery.AssignDeliveryPerson(driverId);
            await _deliveryRepository.AddAsync(delivery);
            return;
        }

        if (!string.Equals(delivery.DeliveryAddress, deliveryAddress, StringComparison.Ordinal))
            delivery.UpdateAddress(deliveryAddress);
        if (!string.IsNullOrWhiteSpace(order.DeliveryPincode))
            delivery.SetPostalCode(order.DeliveryPincode);
        delivery.SetCustomerContact(order.RecipientPhone, null);
        delivery.AssignDeliveryPerson(driverId);
        await _deliveryRepository.UpdateAsync(delivery);
    }

    public async Task CancelAsync(Guid companyId, Guid id, string? reason)
    {
        var order = await _orderRepository.GetByIdAsync(companyId, id)
            ?? throw new KeyNotFoundException("Order not found");

        var reservations = await _reservationRepository.GetBySalesOrderIdAsync(order.Id);
        foreach (var reservation in reservations)
        {
            if (reservation.Status != ReservationStatus.Active)
                continue;

            var batch = await _productBatchRepository.GetByIdAsync(reservation.ProductBatchId)
                ?? throw new InvalidOperationException($"ProductBatch '{reservation.ProductBatchId}' not found for reservation '{reservation.Id}'.");

            batch.ReleaseReservedUnits(reservation.ReservedUnits);
            reservation.MarkReleased();

            await _productBatchRepository.UpdateAsync(batch);
            await _reservationRepository.UpdateAsync(reservation);
        }

        order.Cancel(reason);
        await _orderRepository.UpdateAsync(order);
    }

    /// <summary>
    /// Create an order from the Manual Sale Entry screen (offline/power-failure scenarios).
    /// Auto-resolves walk-in customer, auto-confirms, marks paid + delivered.
    /// </summary>
    public async Task<Guid> CreateManualSaleAsync(Guid companyId, ManualSaleRequest request)
    {
        // Resolve default location
        var defaultLocation = await _locationRepository.GetDefaultAsync(companyId);
        var locationId = defaultLocation?.Id ?? Guid.Empty;

        // Resolve walk-in customer
        var walkIn = await _customerRepository.GetOrCreateWalkInCustomerAsync(companyId);

        var saleDate = string.IsNullOrEmpty(request.SaleDate)
            ? DateTime.UtcNow
            : DateTime.Parse(request.SaleDate).ToUniversalTime();

        var order = new Order(companyId, walkIn.Id, saleDate, null, null, null, null);
        order.LocationId = locationId;
        order.SetOrderSource(OrderSource.WalkIn);
        order.AddInternalNote($"Manual sale — {request.Reason ?? "Offline"}");

        foreach (var item in request.Items)
        {
            // Attempt to parse productId as Guid; fall back to generating one
            var productId = Guid.TryParse(item.ProductId, out var pid) ? pid : Guid.NewGuid();
            order.AddItem(productId, item.Name, item.Qty, item.Price);
        }

        await _orderRepository.AddAsync(order);

        // Record payment
        var methodStr = NormalizeEnumString(request.PaymentMethod);
        if (!Enum.TryParse<PaymentMethod>(methodStr, true, out var method))
            method = PaymentMethod.Cash;

        var payment = new Payment(companyId, order.Id, method, order.TotalAmount);
        payment.SetLocation(locationId);
        if (method == PaymentMethod.Cash) payment.Approve(null, null);
        await _paymentRepository.AddAsync(payment);

        // Mark paid + delivered
        order.MarkPaid();
        order.Confirm();
        order.SetFulfillmentStatus(FulfillmentStatus.Completed);
        order.MarkDeliveredDirect();
        await _orderRepository.UpdateAsync(order);

        await ConsumeInventoryForOrderAsync(companyId, order);

        // Create accounting journal entries
        var cashAccountId = await _journalEntryRepository
            .GetOrCreateAccountIdAsync(companyId, "1000", "Cash", "Asset");

        var revenueAccountId = await _journalEntryRepository
            .GetOrCreateAccountIdAsync(companyId, "4000", "Sales Revenue", "Income");

        var manualEntries = new List<JournalEntry>
        {
            new JournalEntry(companyId, saleDate, order.OrderNumber, "SALE",
                $"Manual Sale {order.OrderNumber} — Cash payment",
                order.TotalAmount, 0, cashAccountId),
            new JournalEntry(companyId, saleDate, order.OrderNumber, "SALE",
                $"Manual Sale {order.OrderNumber} — Revenue",
                0, order.TotalAmount, revenueAccountId),
        };
        await _journalEntryRepository.AddRangeAsync(manualEntries);

        // Update customer stats
        await UpdateCustomerStatsAsync(walkIn.Id);

        return order.Id;
    }

    public async Task ConsumeInventoryForOrderAsync(Guid companyId, Order order)
    {
        if (order.IsInventoryProcessed)
            return;

        // Temporary migration safety for orders already processed in old flows.
        if (order.Status == OrderStatus.Delivered && order.IsInventoryProcessed)
            return;

        var reservations = await _reservationRepository.GetBySalesOrderIdAsync(order.Id);
        var activeReservations = reservations.Where(r => r.Status == ReservationStatus.Active).ToList();

        if (activeReservations.Count == 0)
        {
            throw new InvalidOperationException(
                "Inventory reservation required before delivery. Fallback deduction disabled.");
        }

        foreach (var reservation in activeReservations)
        {
            var batch = await _productBatchRepository.GetByIdAsync(reservation.ProductBatchId)
                ?? throw new InvalidOperationException($"Batch {reservation.ProductBatchId} not found");

            if (batch.QuantityRemaining < reservation.ReservedUnits)
                throw new InvalidOperationException("Insufficient batch quantity during consumption");

            batch.DeductQuantity(reservation.ReservedUnits);

            var product = await _productRepository.GetByIdAsync(reservation.ProductId)
                ?? throw new InvalidOperationException($"Product {reservation.ProductId} not found");

            if (product.TrackInventory)
            {
                product.AdjustStock(-reservation.ReservedUnits);
                await _productRepository.UpdateAsync(product);

                await _inventoryLedgerRepository.AddAsync(
                    new InventoryLedger(
                        companyId,
                        product.Id,
                        order.OrderNumber,
                        "SALE",
                        -reservation.ReservedUnits,
                        product.StockQuantity,
                        "Reserved stock consumed on delivery"
                    )
                );
            }

            reservation.MarkConverted();

            await _reservationRepository.UpdateAsync(reservation);
            await _productBatchRepository.UpdateAsync(batch);
        }

        order.MarkInventoryProcessed();
        await _orderRepository.UpdateAsync(order);

    }

    /// <summary>
    /// Legacy deduction path kept for reference and compatibility.
    /// New flows should call ConsumeInventoryForOrderAsync.
    /// </summary>
    private async Task DeductInventoryForOrderAsync(Guid companyId, Order order)
    {
        var finishedBatches = await _finishedGoodsBatchRepository.GetAllAsync(companyId);

        foreach (var item in order.Items)
        {
            // Always prefer consuming an active finished-goods batch when it matches
            // this sold item (batch id match or recipe-name + location match).
            var finishedBatch = ResolveFinishedGoodsBatch(order, item, finishedBatches);
            if (finishedBatch != null)
            {
                if (finishedBatch.QuantityAvailable < item.Quantity)
                    throw new Exception($"Not enough stock for finished goods batch {finishedBatch.BatchCode}");

                finishedBatch.Deduct(item.Quantity);
                await _finishedGoodsBatchRepository.UpdateAsync(finishedBatch);
                continue;
            }

            var product = await _productRepository.GetByIdAsync(item.ProductId);

            // Finished goods are sold from production batches (not Products table rows).
            if (product == null)
            {
                continue;
            }

            // Case 1: Batch-based inventory
            if (product.TrackBatch)
            {
                var batches = await _productBatchRepository.GetBatchesByProductIdAsync(product.Id);

                var remainingQty = item.Quantity;

                foreach (var batch in batches.OrderBy(b => b.ExpiryDate ?? DateTime.MaxValue))
                {
                    if (remainingQty <= 0) break;

                    var deduct = Math.Min(batch.QuantityRemaining, remainingQty);

                    batch.DeductQuantity(deduct);
                    await _productBatchRepository.UpdateAsync(batch);

                    remainingQty -= deduct;
                }

                if (remainingQty > 0)
                    throw new Exception($"Not enough stock for product {product.Name}");

                // Keep aggregate product stock synchronized with batch-level deductions.
                // This is used by inventory dropdowns and should match sum of active batches.
                product.AdjustStock(-item.Quantity);
                await _productRepository.UpdateAsync(product);

                await _inventoryLedgerRepository.AddAsync(
                    new InventoryLedger(
                        companyId,
                        product.Id,
                        order.OrderNumber,
                        "SALE",
                        -item.Quantity,
                        product.StockQuantity,
                        "POS Sale (Batch)"
                    )
                );

                continue;
            }

            // Case 2: Simple inventory
            if (product.TrackInventory)
            {
                // Some products may have received batches even when TrackBatch is false.
                // Consume those batches FIFO as well so batch dashboard stays aligned with stock.
                var batches = await _productBatchRepository.GetBatchesByProductIdAsync(product.Id);
                if (batches.Count > 0)
                {
                    var remainingQty = item.Quantity;

                    foreach (var batch in batches.OrderBy(b => b.ExpiryDate ?? DateTime.MaxValue))
                    {
                        if (remainingQty <= 0) break;

                        var deduct = Math.Min(batch.QuantityRemaining, remainingQty);
                        if (deduct <= 0) continue;

                        batch.DeductQuantity(deduct);
                        await _productBatchRepository.UpdateAsync(batch);

                        remainingQty -= deduct;
                    }

                    if (remainingQty > 0)
                        throw new Exception($"Not enough batch stock for product {product.Name}");
                }

                product.AdjustStock(-item.Quantity);
                await _productRepository.UpdateAsync(product);

                await _inventoryLedgerRepository.AddAsync(
                    new InventoryLedger(
                        companyId,
                        product.Id,
                        order.OrderNumber,
                        "SALE",
                        -item.Quantity,
                        product.StockQuantity,
                        "POS Sale"
                    )
                );

                continue;
            }
        }
    }

    private async Task HandleCorporateFulfillmentPostingAsync(Guid companyId, Order order)
    {
        if (order.CustomerType != CustomerType.Corporate)
            return;

        var meta = await _corporateRepository.GetOrderMetaByOrderIdAsync(companyId, order.Id);
        if (meta == null)
            return;

        var shouldPostInventory = order.Status == OrderStatus.Delivered || order.FulfillmentStatus == FulfillmentStatus.Completed;
        if (!shouldPostInventory || meta.IsInventoryPosted)
            return;

        await ConsumeInventoryForOrderAsync(companyId, order);
        await CreateCorporateCogsEntriesAsync(companyId, order);

        meta.MarkInventoryPosted();
        await _corporateRepository.UpdateOrderMetaAsync(meta);
    }

    private async Task CreateCorporateCogsEntriesAsync(Guid companyId, Order order)
    {
        try
        {
            var cogsAccountId = await _journalEntryRepository
                .GetOrCreateAccountIdAsync(companyId, "5000", "Cost of Goods Sold", "Expense");
            var inventoryAccountId = await _journalEntryRepository
                .GetOrCreateAccountIdAsync(companyId, "1200", "Inventory", "Asset");

            decimal totalCogs = 0m;
            var finishedBatches = await _finishedGoodsBatchRepository.GetAllAsync(companyId);

            foreach (var item in order.Items)
            {
                var finishedBatch = ResolveFinishedGoodsBatch(order, item, finishedBatches);
                if (finishedBatch != null)
                {
                    var unitCost = finishedBatch.QuantityProduced > 0
                        ? finishedBatch.TotalCost / finishedBatch.QuantityProduced
                        : 0m;
                    var finishedGoodsCogs = unitCost * item.Quantity;
                    if (finishedGoodsCogs > 0)
                        totalCogs += finishedGoodsCogs;
                    continue;
                }

                var product = await _productRepository.GetByIdAsync(companyId, item.ProductId);
                if (product != null && product.TrackInventory)
                {
                    var lineCogs = product.CostPrice * item.Quantity;
                    if (lineCogs > 0)
                        totalCogs += lineCogs;
                }
            }

            if (totalCogs <= 0)
                return;

            var now = DateTime.UtcNow;
            var entries = new List<JournalEntry>
            {
                new(companyId, now, order.OrderNumber, "CORPORATE_COGS",
                    $"Corporate order {order.OrderNumber} - COGS", totalCogs, 0, cogsAccountId),
                new(companyId, now, order.OrderNumber, "CORPORATE_COGS",
                    $"Corporate order {order.OrderNumber} - Inventory reduction", 0, totalCogs, inventoryAccountId)
            };

            if (order.LocationId.HasValue)
            {
                entries[0].SetLocation(order.LocationId.Value);
                entries[1].SetLocation(order.LocationId.Value);
            }

            await _journalEntryRepository.AddRangeAsync(entries);
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[OrderService] Corporate COGS posting failed: {ex.Message}");
        }
    }

    /// <summary>
    /// Creates double-entry journal entries for a POS sale.
    /// Dr Cash/Card/UPI → Cr Sales Revenue
    /// Dr Cost of Goods Sold → Cr Inventory
    /// </summary>
    private async Task CreateSaleJournalEntriesAsync(Guid companyId, Order order, CreateOrderRequest request)
    {
        try
        {
            // Look up (or auto-create) the Sales Revenue account
            var revenueAccountId = await _journalEntryRepository
                .GetOrCreateAccountIdAsync(companyId, "4000", "Sales Revenue", "Income");

            // Look up (or auto-create) COGS and Inventory accounts for stock-out posting.
            var cogsAccountId = await _journalEntryRepository
                .GetOrCreateAccountIdAsync(companyId, "5000", "Cost of Goods Sold", "Expense");
            var inventoryAccountId = await _journalEntryRepository
                .GetOrCreateAccountIdAsync(companyId, "1200", "Inventory", "Asset");

            var entries = new List<JournalEntry>();
            var now = DateTime.UtcNow;
            var orderRef = order.OrderNumber;

            foreach (var p in request.Payments)
            {
                var methodStr = NormalizeEnumString(p.Method);
                if (!Enum.TryParse<PaymentMethod>(methodStr, true, out var method))
                    method = PaymentMethod.Cash;

                // Determine the payment method account
                var (acctCode, acctName) = method switch
                {
                    PaymentMethod.Cash => ("1000", "Cash"),
                    PaymentMethod.Card => ("1010", "Card Receivables"),
                    PaymentMethod.Upi => ("1020", "UPI Receivables"),
                    PaymentMethod.GiftCard => ("1030", "Gift Card Receivables"),
                    PaymentMethod.BankTransfer => ("1100", "Bank Account"),
                    _ => ("1000", "Cash")
                };

                var paymentAccountId = await _journalEntryRepository
                    .GetOrCreateAccountIdAsync(companyId, acctCode, acctName, "Asset");

                var methodLabel = method switch
                {
                    PaymentMethod.Cash => "Cash",
                    PaymentMethod.Card => "Card",
                    PaymentMethod.Upi => "UPI",
                    PaymentMethod.GiftCard => "Gift Card",
                    PaymentMethod.BankTransfer => "Bank Transfer",
                    _ => method.ToString()
                };

                // Debit: Payment method account
                var debitEntry = new JournalEntry(
                    companyId, now, orderRef, "SALE",
                    $"POS Sale {orderRef} — {methodLabel} payment",
                    p.Amount, 0, paymentAccountId);
                if (order.LocationId.HasValue)
                    debitEntry.SetLocation(order.LocationId.Value);
                entries.Add(debitEntry);

                // Credit: Sales Revenue
                var creditEntry = new JournalEntry(
                    companyId, now, orderRef, "SALE",
                    $"POS Sale {orderRef} — Revenue",
                    0, p.Amount, revenueAccountId);
                if (order.LocationId.HasValue)
                    creditEntry.SetLocation(order.LocationId.Value);
                entries.Add(creditEntry);
            }

            // Post COGS for the sold products: Dr COGS / Cr Inventory.
            decimal totalCogs = 0m;
            var finishedBatches = await _finishedGoodsBatchRepository.GetAllAsync(companyId);
            foreach (var item in order.Items)
            {
                // Keep COGS source aligned with inventory deduction rule above.
                var finishedBatch = ResolveFinishedGoodsBatch(order, item, finishedBatches);
                if (finishedBatch != null)
                {
                    var unitCost = finishedBatch.QuantityProduced > 0
                        ? finishedBatch.TotalCost / finishedBatch.QuantityProduced
                        : 0m;
                    var finishedGoodsCogs = unitCost * item.Quantity;
                    if (finishedGoodsCogs > 0)
                        totalCogs += finishedGoodsCogs;
                    continue;
                }

                var product = await _productRepository.GetByIdAsync(companyId, item.ProductId);
                if (product != null)
                {
                    if (product.TrackInventory)
                    {
                        var lineCogs = product.CostPrice * item.Quantity;
                        if (lineCogs > 0)
                            totalCogs += lineCogs;
                        continue;
                    }
                }
            }

            if (totalCogs > 0)
            {
                var cogsDebit = new JournalEntry(
                    companyId, now, orderRef, "SALE",
                    $"POS Sale {orderRef} - COGS",
                    totalCogs, 0, cogsAccountId);
                if (order.LocationId.HasValue)
                    cogsDebit.SetLocation(order.LocationId.Value);
                entries.Add(cogsDebit);

                var inventoryCredit = new JournalEntry(
                    companyId, now, orderRef, "SALE",
                    $"POS Sale {orderRef} - Inventory reduction",
                    0, totalCogs, inventoryAccountId);
                if (order.LocationId.HasValue)
                    inventoryCredit.SetLocation(order.LocationId.Value);
                entries.Add(inventoryCredit);
            }

            if (entries.Count > 0)
                await _journalEntryRepository.AddRangeAsync(entries);
        }
        catch (Exception ex)
        {
            // Journal entry creation should not block order creation
            // Log and continue — the order itself is already saved
            System.Diagnostics.Debug.WriteLine($"[OrderService] Journal entry creation failed: {ex.Message}");
        }
    }

    private static FinishedGoodsBatch? ResolveFinishedGoodsBatch(Order order, OrderItem item, List<FinishedGoodsBatch> finishedBatches)
    {
        var activeBatches = finishedBatches
            .Where(b => b.Status == FinishedBatchStatus.Active && b.QuantityAvailable > 0)
            .ToList();

        if (activeBatches.Count == 0)
            return null;

        // Preferred match: exact batch id.
        var byId = activeBatches.FirstOrDefault(b => b.Id == item.ProductId);
        if (byId != null)
            return byId;

        var normalizedName = (item.ProductName ?? string.Empty).Trim();
        if (normalizedName.Length == 0)
            return null;

        IEnumerable<FinishedGoodsBatch> candidates = activeBatches.Where(
            b => string.Equals(b.RecipeName, normalizedName, StringComparison.OrdinalIgnoreCase));

        if (order.LocationId.HasValue)
        {
            var scoped = candidates.Where(b => b.LocationId == order.LocationId.Value).ToList();
            if (scoped.Count > 0)
                candidates = scoped;
        }

        // FEFO style: consume the earliest-expiring produced batch first.
        return candidates
            .OrderBy(b => b.ExpectedExpiry)
            .ThenBy(b => b.ProducedAt)
            .FirstOrDefault();
    }

    /// <summary>
    /// Increments the customer's order count after a sale.
    /// </summary>
    private async Task UpdateCustomerStatsAsync(Guid customerId)
    {
        var customer = await _customerRepository.GetByIdAsync(customerId);
        if (customer != null)
        {
            customer.IncrementOrderCount();
            await _customerRepository.UpdateAsync(customer);
        }
    }

    private static OrderDto MapToDto(Order order) => new()
    {
        Id = order.Id,
        OrderNumber = order.OrderNumber,
        CustomerId = order.CustomerId,
        CustomerName = order.Customer?.Name ?? "Unknown",
        OrderDate = order.OrderDate,
        DeliveryDate = order.DeliveryDate,
        Status = order.Status.ToString(),
        PaymentStatus = order.PaymentStatus.ToString(),
        FulfillmentStatus = order.FulfillmentStatus.ToString(),
        OrderSource = order.OrderSource.ToString(),
        IsActive = order.IsActive,
        DeliveryAddress = order.DeliveryAddress,
        DeliveryPincode = order.DeliveryPincode,
        RecipientName = order.RecipientName,
        RecipientPhone = order.RecipientPhone,
        CardMessage = order.CardMessage,
        DeliveryPriority = order.DeliveryPriority.ToString(),
        TimeSlot = order.TimeSlot,
        SubTotal = order.SubTotal,
        DeliveryFee = order.DeliveryFee,
        TaxAmount = order.TaxAmount,
        DiscountAmount = order.DiscountAmount,
        TotalAmount = order.TotalAmount,
        AssignedDesignerId = order.AssignedToUserId,
        DeliveryPersonId = order.DeliveryPersonId,
        LocationId = order.LocationId,
        LocationName = order.Location?.Name,
        InternalNotes = order.InternalNotes,
        Items = order.Items.Select(i => new OrderItemDto
        {
            Id = i.Id,
            ProductId = i.ProductId,
            ProductName = i.ProductName,
            Quantity = i.Quantity,
            UnitPrice = i.UnitPrice,
            TotalPrice = i.TotalPrice
        }).ToList(),
        CreatedAtUtc = order.CreatedAtUtc
    };
}
