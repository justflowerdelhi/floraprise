namespace Sumpooj.Application.Orders;

public class OrderDto
{
    public Guid Id { get; set; }
    public string OrderNumber { get; set; } = default!;
    public Guid CustomerId { get; set; }
    public string CustomerName { get; set; } = default!;
    public DateTime OrderDate { get; set; }
    public DateTime DeliveryDate { get; set; }
    public string Status { get; set; } = default!;
    public string PaymentStatus { get; set; } = default!;
    public string FulfillmentStatus { get; set; } = default!;
    public string OrderSource { get; set; } = default!;
    public bool IsActive { get; set; }

    // Delivery Details
    public string? DeliveryAddress { get; set; }
    public string? RecipientName { get; set; }
    public string? RecipientPhone { get; set; }
    public string? CardMessage { get; set; }
    public string DeliveryPriority { get; set; } = default!;
    public string? TimeSlot { get; set; }

    // Financial
    public decimal SubTotal { get; set; }
    public decimal DeliveryFee { get; set; }
    public decimal TaxAmount { get; set; }
    public decimal DiscountAmount { get; set; }
    public decimal TotalAmount { get; set; }
    public decimal PaidAmount { get; set; }
    public decimal BalanceDue { get; set; }

    // Assignment
    public Guid? AssignedDesignerId { get; set; }
    public string? AssignedDesignerName { get; set; }
    public Guid? DeliveryPersonId { get; set; }
    public string? DeliveryPersonName { get; set; }

    public Guid LocationId { get; set; }
    public string? LocationName { get; set; }
    public string? InternalNotes { get; set; }
    public List<OrderItemDto> Items { get; set; } = new();
    public DateTime CreatedAtUtc { get; set; }
}

public class OrderItemDto
{
    public Guid Id { get; set; }
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = default!;
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal TotalPrice { get; set; }
    public decimal DiscountAmount { get; set; }
    public string? SpecialInstructions { get; set; }
}

public class OrderListDto
{
    public Guid Id { get; set; }
    public string OrderNumber { get; set; } = default!;
    public string CustomerName { get; set; } = default!;
    public DateTime OrderDate { get; set; }
    public DateTime DeliveryDate { get; set; }
    public string Status { get; set; } = default!;
    public string PaymentStatus { get; set; } = default!;
    public string FulfillmentStatus { get; set; } = default!;
    public string OrderSource { get; set; } = default!;
    public decimal TotalAmount { get; set; }
    public int ItemCount { get; set; }
    public string? RecipientName { get; set; }
    public string DeliveryPriority { get; set; } = default!;
}

public class CreateOrderRequest
{
    public Guid? CustomerId { get; set; }
    public Guid LocationId { get; set; }
    public DateTime? DeliveryDate { get; set; }
    public string? DeliveryAddress { get; set; }
    public string? RecipientName { get; set; }
    public string? RecipientPhone { get; set; }
    public string? CardMessage { get; set; }
    public string DeliveryPriority { get; set; } = "Standard";
    public string? TimeSlot { get; set; }
    public string OrderSource { get; set; } = "WalkIn";
    public string? OrderIntent { get; set; }
    public DateTime? PickupDate { get; set; }
    public string? PickupTimeSlot { get; set; }
    public decimal DeliveryFee { get; set; }
    public decimal DiscountAmount { get; set; }
    public string? InternalNotes { get; set; }
    public List<OrderItemRequest> Items { get; set; } = new();
    public List<OrderPaymentRequest> Payments { get; set; } = new();
}

public class OrderPaymentRequest
{
    public string Method { get; set; } = "Cash";
    public decimal Amount { get; set; }
}

public class OrderItemRequest
{
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = default!;
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public string? SpecialInstructions { get; set; }
}

public class OrderSearchRequest
{
    public string? Query { get; set; }
    public Guid? CustomerId { get; set; }
    public string? Status { get; set; }
    public string? PaymentStatus { get; set; }
    public string? FulfillmentStatus { get; set; }
    public string? OrderSource { get; set; }
    public DateTime? FromDate { get; set; }
    public DateTime? ToDate { get; set; }
    public DateTime? DeliveryDate { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}
