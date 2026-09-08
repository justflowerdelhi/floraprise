namespace Sumpooj.Application.Mobile;

public sealed class MobileOrderWorkspaceRequest
{
    public string? Query { get; set; }
    public string? Status { get; set; }
    public string? PaymentStatus { get; set; }
    public string? FulfilmentType { get; set; }
    public DateTime? FromDate { get; set; }
    public DateTime? ToDate { get; set; }
    public DateTime? DeliveryDate { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 50;
}

public sealed record MobileOrderWorkspaceResponse(
    IReadOnlyList<MobileOrderListItemDto> Items,
    int TotalCount,
    int Page,
    int PageSize);

public sealed record MobileOrderListItemDto(
    Guid Id,
    string OrderNumber,
    string CustomerName,
    string? CustomerPhone,
    string? RecipientName,
    string? RecipientPhone,
    string FulfilmentType,
    string Status,
    string PaymentStatus,
    decimal TotalAmount,
    decimal PaidAmount,
    decimal BalanceDue,
    DateTime OrderDate,
    DateTime DeliveryDate,
    string? DesignerName,
    string? DeliveryPersonName);

public sealed record MobileOrderDetailDto(
    Guid Id,
    string OrderNumber,
    Guid CustomerId,
    string CustomerName,
    string? CustomerPhone,
    string? RecipientName,
    string? RecipientPhone,
    string FulfilmentType,
    string Status,
    string PaymentStatus,
    string FulfillmentStatus,
    string OrderSource,
    decimal SubTotal,
    decimal DeliveryFee,
    decimal TaxAmount,
    decimal DiscountAmount,
    decimal TotalAmount,
    decimal PaidAmount,
    decimal BalanceDue,
    int RewardPointsEarned,
    int RewardPointsRedeemed,
    Guid? AssignedDesignerId,
    Guid? AssignedDesignerStaffId,
    string? AssignedDesignerName,
    Guid? DeliveryPersonId,
    string? DeliveryPersonName,
    Guid? LocationId,
    string? LocationName,
    DateTime OrderDate,
    DateTime DeliveryDate,
    string? DeliveryAddress,
    string? DeliveryPincode,
    string? CardMessage,
    string? TimeSlot,
    string? InternalNotes,
    IReadOnlyList<MobileOrderItemDto> Items,
    IReadOnlyList<MobileOrderPaymentDto> Payments,
    MobileOrderDeliverySummaryDto? DeliverySummary,
    IReadOnlyList<MobileOrderTimelineItemDto> Timeline,
    DateTime CreatedAtUtc);

public sealed record MobileOrderItemDto(
    Guid Id,
    Guid ProductId,
    string ProductName,
    int Quantity,
    decimal UnitPrice,
    decimal TotalPrice,
    decimal DiscountAmount,
    decimal? TaxRatePercent,
    decimal? LineSubtotal,
    decimal? LineTaxAmount,
    decimal LineTotal,
    string? SpecialInstructions,
    string? ClientOrderLineId);

public sealed record MobileOrderPaymentDto(
    Guid Id,
    Guid OrderId,
    Guid? LocationId,
    string Method,
    decimal Amount,
    string Status,
    string? Reference,
    string? ClientPaymentId,
    string? TransactionId,
    DateTime CreatedAtUtc);

public sealed record MobileOrderDeliverySummaryDto(
    Guid Id,
    string Status,
    DateTime DeliveryDate,
    string TimeSlot,
    string DeliveryAddress,
    string? PostalCode,
    Guid? DeliveryPersonId,
    string? DeliveryPersonName,
    DateTime? StartedAtUtc,
    DateTime? CompletedAtUtc,
    DateTime? LastLocationUtc);

public sealed record MobileOrderTimelineItemDto(
    string Source,
    string Status,
    string? Notes,
    DateTime CreatedAtUtc);

public sealed record MobileCustomerStatisticsDto(
    Guid CustomerId,
    int TotalOrders,
    DateTime? LastOrderAt,
    int LifetimePurchasePaise,
    int PendingPaymentPaise);