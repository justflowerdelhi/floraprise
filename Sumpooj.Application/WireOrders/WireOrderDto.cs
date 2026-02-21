using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.WireOrders;

public class WireOrderDto
{
    public Guid Id { get; set; }
    public string ExternalOrderId { get; set; } = default!;
    public string Platform { get; set; } = default!;
    public WireServiceType WireService { get; set; }
    public string WireOrderNumber { get; set; } = default!;
    public DateTime ReceivedDate { get; set; }
    public DateTime DeliveryDate { get; set; }
    public string? TimeSlot { get; set; }
    public WireOrderStatus Status { get; set; }
    public string StatusName => Status.ToString();
    
    public string? SenderName { get; set; }
    public string? SenderPhone { get; set; }
    public string? SenderEmail { get; set; }
    
    public string RecipientName { get; set; } = default!;
    public string RecipientPhone { get; set; } = default!;
    public string DeliveryAddress { get; set; } = default!;
    public string? DeliveryCity { get; set; }
    public string? DeliveryZipCode { get; set; }
    public string? DeliveryInstructions { get; set; }
    
    public string? CardMessage { get; set; }
    
    public decimal GrossAmount { get; set; }
    public decimal Commission { get; set; }
    public decimal Fees { get; set; }
    public decimal NetPayout { get; set; }
    public decimal? FulfillmentCost { get; set; }
    public decimal? Profit => FulfillmentCost.HasValue ? NetPayout - FulfillmentCost.Value : null;
    public bool IsExternallyPaid { get; set; } = true;
    
    public string? ProductDescription { get; set; }
    public string? WireProductCode { get; set; }
    public string? SubstitutionNotes { get; set; }
    public List<WireOrderItemDto> Items { get; set; } = new();
    
    public Guid? LinkedOrderId { get; set; }
    public Guid? AssignedToUserId { get; set; }
    public string? AssignedToUserName { get; set; }
    
    public string? InternalNotes { get; set; }
    public string? ConfirmationCode { get; set; }
    public DateTime? FulfilledAt { get; set; }
    public string? RejectionReason { get; set; }
    
    public DateTime CreatedAtUtc { get; set; }
}

public class WireOrderItemDto
{
    public string ProductName { get; set; } = default!;
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
}

public class CreateWireOrderRequest
{
    public WireServiceType WireService { get; set; }
    public string WireOrderNumber { get; set; } = default!;
    public DateTime ReceivedDate { get; set; }
    public DateTime DeliveryDate { get; set; }
    public string? TimeSlot { get; set; }
    
    public string? SenderName { get; set; }
    public string? SenderPhone { get; set; }
    public string? SenderEmail { get; set; }
    
    public string RecipientName { get; set; } = default!;
    public string RecipientPhone { get; set; } = default!;
    public string DeliveryAddress { get; set; } = default!;
    public string? DeliveryCity { get; set; }
    public string? DeliveryZipCode { get; set; }
    public string? DeliveryInstructions { get; set; }
    
    public string? CardMessage { get; set; }
    
    public decimal GrossAmount { get; set; }
    public decimal Commission { get; set; }
    public decimal Fees { get; set; }
    
    public string? ProductDescription { get; set; }
    public string? WireProductCode { get; set; }
    
    public List<WireOrderItemDto> Items { get; set; } = new();
}

public class WireOrderSearchRequest
{
    public WireServiceType? WireService { get; set; }
    public WireOrderStatus? Status { get; set; }
    public DateTime? FromDate { get; set; }
    public DateTime? ToDate { get; set; }
    public string? Query { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}

public class WireOrderSummaryDto
{
    public int TotalOrders { get; set; }
    public int PendingOrders { get; set; }
    public int AcceptedOrders { get; set; }
    public int FulfilledOrders { get; set; }
    public int RejectedOrders { get; set; }
    public decimal TotalGrossAmount { get; set; }
    public decimal TotalCommission { get; set; }
    public decimal TotalFees { get; set; }
    public decimal TotalNetPayout { get; set; }
    public decimal TotalFulfillmentCost { get; set; }
    public decimal TotalProfit { get; set; }
    public Dictionary<string, int> ByPlatform { get; set; } = new();
    public Dictionary<string, int> ByStatus { get; set; } = new();
}
