namespace Sumpooj.Application.Mobile;

public sealed record MobilePendingPaymentsDto(
    int PendingOrderCount,
    int PendingPaymentPaise);
