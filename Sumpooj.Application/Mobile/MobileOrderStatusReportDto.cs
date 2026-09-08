namespace Sumpooj.Application.Mobile;

public sealed record MobileOrderStatusReportDto(
    int Pending,
    int InProgress,
    int Ready,
    int Completed,
    int Cancelled,
    int Total,
    MobileOrderFulfillmentCountsDto Fulfillment,
    DateTime? FromDate = null,
    DateTime? ToDate = null);

public sealed record MobileOrderFulfillmentCountsDto(
    int Delivery,
    int Pickup,
    int TakeAway);
