namespace Sumpooj.Application.Mobile;

public sealed record MobileDashboardSummaryDto(
    int TotalSalesPaise,
    int OrderCount,
    int CashPaise,
    int UpiPaise,
    int CardPaise,
    int CreditPaise,
    int PendingOrderCount,
    int PreparingOrderCount,
    int ReadyOrderCount,
    int OutForDeliveryCount,
    int DeliveryCount,
    int PickupCount,
    int ExpensePaise);
