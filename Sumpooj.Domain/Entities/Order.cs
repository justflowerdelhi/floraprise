namespace Sumpooj.Domain.Entities;

public class Order : BaseEntity
{
    private readonly List<OrderItem> _items = new();
    private Order() { }

    public Order(
        Guid companyId,
        Guid customerId,
        DateTime deliveryDate,
        string? deliveryAddress,
        string? recipientName,
        string? recipientPhone)
    {
        CompanyId = companyId;
        CustomerId = customerId;
        OrderNumber = GenerateOrderNumber();
        OrderDate = DateTime.UtcNow;
        DeliveryDate = EnsureUtc(deliveryDate);
        DeliveryAddress = deliveryAddress;
        RecipientName = recipientName;
        RecipientPhone = recipientPhone;
        Status = OrderStatus.Pending;
        PaymentStatus = PaymentStatus.Unpaid;
        FulfillmentStatus = FulfillmentStatus.Draft;
        OrderSource = OrderSource.WalkIn;
        IsActive = true;
    }

    public Guid CompanyId { get; private set; }
    public Guid CustomerId { get; private set; }
    public Customer? Customer { get; private set; }
    public Guid LocationId { get; set; }
    public Location Location { get; set; } = null!;
    public string OrderNumber { get; private set; }
    public DateTime OrderDate { get; private set; }
    public DateTime DeliveryDate { get; private set; }
    public OrderStatus Status { get; private set; }
    public PaymentStatus PaymentStatus { get; private set; }
    public FulfillmentStatus FulfillmentStatus { get; private set; }
    public OrderSource OrderSource { get; private set; }
    public bool IsActive { get; private set; }
    public string? TimeSlot { get; private set; }

    // Delivery details
    public string? DeliveryAddress { get; private set; }
    public string? RecipientName { get; private set; }
    public string? RecipientPhone { get; private set; }
    public string? CardMessage { get; private set; }
    public DeliveryPriority DeliveryPriority { get; private set; }

    // Financial
    public decimal SubTotal { get; private set; }
    public decimal DeliveryFee { get; private set; }
    public decimal TaxAmount { get; private set; }
    public decimal DiscountAmount { get; private set; }
    public decimal TotalAmount { get; private set; }

    // Assignment
    public Guid? AssignedToUserId { get; private set; }
    public Guid? DeliveryPersonId { get; private set; }

    // Notes
    public string? InternalNotes { get; private set; }

    public IReadOnlyCollection<OrderItem> Items => _items.AsReadOnly();

    private static string GenerateOrderNumber()
    {
        return $"ORD-{DateTime.UtcNow:yyyyMMdd}-{Guid.NewGuid().ToString()[..8].ToUpper()}";
    }

    public void AddItem(Guid productId, string productName, int quantity, decimal unitPrice)
    {
        if (Status != OrderStatus.Pending && Status != OrderStatus.Confirmed)
            throw new InvalidOperationException("Cannot modify items for orders in current status");

        var item = new OrderItem(productId, productName, quantity, unitPrice);
        _items.Add(item);
        RecalculateTotals();
    }

    public void RemoveItem(Guid productId)
    {
        if (Status != OrderStatus.Pending && Status != OrderStatus.Confirmed)
            throw new InvalidOperationException("Cannot modify items for orders in current status");

        var item = _items.FirstOrDefault(i => i.ProductId == productId);
        if (item != null)
        {
            _items.Remove(item);
            RecalculateTotals();
        }
    }

    public void UpdateDeliveryDetails(
        DateTime deliveryDate,
        string? deliveryAddress,
        string? recipientName,
        string? recipientPhone)
    {
        DeliveryDate = deliveryDate;
        DeliveryAddress = deliveryAddress;
        RecipientName = recipientName;
        RecipientPhone = recipientPhone;
        MarkUpdated();
    }

    public void SetCardMessage(string? message)
    {
        CardMessage = message;
        MarkUpdated();
    }

    public void SetDeliveryPriority(DeliveryPriority priority)
    {
        DeliveryPriority = priority;
        MarkUpdated();
    }

    public void SetOrderSource(OrderSource source)
    {
        OrderSource = source;
        MarkUpdated();
    }

    public void SetFulfillmentStatus(FulfillmentStatus status)
    {
        FulfillmentStatus = status;
        MarkUpdated();
    }

    public void SetTimeSlot(string? timeSlot)
    {
        TimeSlot = timeSlot;
        MarkUpdated();
    }

    public void ApplyDiscount(decimal amount)
    {
        if (amount < 0)
            throw new ArgumentException("Discount cannot be negative");

        DiscountAmount = amount;
        RecalculateTotals();
    }

    public void SetDeliveryFee(decimal fee)
    {
        DeliveryFee = fee;
        RecalculateTotals();
    }

    public void SetTaxAmount(decimal tax)
    {
        TaxAmount = tax;
        RecalculateTotals();
    }

    private void RecalculateTotals()
    {
        SubTotal = _items.Sum(i => i.TotalPrice);
        TotalAmount = SubTotal + DeliveryFee + TaxAmount - DiscountAmount;
        MarkUpdated();
    }

    public void Confirm()
    {
        if (Status != OrderStatus.Pending)
            throw new InvalidOperationException("Only pending orders can be confirmed");

        Status = OrderStatus.Confirmed;
        MarkUpdated();
    }

    public void StartProcessing(Guid userId)
    {
        if (Status != OrderStatus.Confirmed)
            throw new InvalidOperationException("Only confirmed orders can be processed");

        Status = OrderStatus.Processing;
        AssignedToUserId = userId;
        MarkUpdated();
    }

    public void MarkReadyForDelivery()
    {
        if (Status != OrderStatus.Processing)
            throw new InvalidOperationException("Only processing orders can be marked ready");

        Status = OrderStatus.ReadyForDelivery;
        MarkUpdated();
    }

    public void AssignDeliveryPerson(Guid deliveryPersonId)
    {
        DeliveryPersonId = deliveryPersonId;
        MarkUpdated();
    }

    public void MarkOutForDelivery()
    {
        if (Status != OrderStatus.ReadyForDelivery)
            throw new InvalidOperationException("Order must be ready before delivery");

        Status = OrderStatus.OutForDelivery;
        MarkUpdated();
    }

    public void MarkDelivered()
    {
        if (Status != OrderStatus.OutForDelivery)
            throw new InvalidOperationException("Order must be out for delivery");

        Status = OrderStatus.Delivered;
        MarkUpdated();
    }

    /// <summary>
    /// Marks an order as delivered without requiring the full delivery pipeline.
    /// Used for walk-in / take-now orders where the customer takes items on the spot.
    /// </summary>
    public void MarkDeliveredDirect()
    {
        Status = OrderStatus.Delivered;
        MarkUpdated();
    }

    public void Cancel(string? reason)
    {
        if (Status == OrderStatus.Delivered || Status == OrderStatus.Cancelled)
            throw new InvalidOperationException("Cannot cancel delivered or already cancelled orders");

        Status = OrderStatus.Cancelled;
        InternalNotes = reason;
        MarkUpdated();
    }

    public void MarkPaid()
    {
        PaymentStatus = PaymentStatus.Paid;
        MarkUpdated();
    }

    public void MarkPartiallyPaid(decimal amountPaid)
    {
        PaymentStatus = PaymentStatus.PartiallyPaid;
        MarkUpdated();
    }

    public void AddInternalNote(string note)
    {
        InternalNotes = string.IsNullOrEmpty(InternalNotes)
            ? note
            : $"{InternalNotes}\n{note}";
        MarkUpdated();
    }

    public void Deactivate()
    {
        IsActive = false;
        MarkUpdated();
    }
}

public class OrderItem
{
    private OrderItem() { }

    public OrderItem(Guid productId, string productName, int quantity, decimal unitPrice)
    {
        Id = Guid.NewGuid();
        ProductId = productId;
        ProductName = productName;
        Quantity = quantity;
        UnitPrice = unitPrice;
        TotalPrice = quantity * unitPrice;
    }

    public Guid Id { get; private set; }
    public Guid ProductId { get; private set; }
    public string ProductName { get; private set; }
    public int Quantity { get; private set; }
    public decimal UnitPrice { get; private set; }
    public decimal TotalPrice { get; private set; }
    public string? SpecialInstructions { get; private set; }

    public void SetSpecialInstructions(string? instructions)
    {
        SpecialInstructions = instructions;
    }
}
