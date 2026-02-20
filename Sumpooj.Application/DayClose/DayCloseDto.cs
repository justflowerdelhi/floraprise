namespace Sumpooj.Application.DayClose;

public class DayCloseDto
{
    public Guid Id { get; set; }
    public Guid LocationId { get; set; }
    public DateTime BusinessDate { get; set; }
    public string Status { get; set; } = default!;
    public DateTime ClosedAt { get; set; }
    public Guid ClosedByUserId { get; set; }

    // Sales Summary
    public int TotalOrders { get; set; }
    public decimal TotalSales { get; set; }
    public decimal TotalRefunds { get; set; }
    public decimal NetSales { get; set; }

    // Payment Breakdown
    public decimal CashTotal { get; set; }
    public decimal CardTotal { get; set; }
    public decimal UpiTotal { get; set; }
    public decimal GiftCardTotal { get; set; }
    public decimal OtherPaymentsTotal { get; set; }

    // Cash Drawer
    public decimal ExpectedCash { get; set; }
    public decimal ActualCash { get; set; }
    public decimal CashVariance { get; set; }

    public string? Notes { get; set; }
}

public class DayCloseSummaryDto
{
    public DateTime BusinessDate { get; set; }
    public Guid LocationId { get; set; }
    public string LocationName { get; set; } = default!;

    // Sales Summary
    public int TotalOrders { get; set; }
    public decimal TotalSales { get; set; }
    public decimal TotalRefunds { get; set; }
    public decimal NetSales { get; set; }

    // Payment Breakdown
    public PaymentBreakdownDto Payments { get; set; } = new();

    // Orders breakdown by status
    public int CompletedOrders { get; set; }
    public int CancelledOrders { get; set; }
    public int PendingOrders { get; set; }

    public bool CanClose { get; set; }
}

public class PaymentBreakdownDto
{
    public decimal Cash { get; set; }
    public decimal Card { get; set; }
    public decimal Upi { get; set; }
    public decimal GiftCard { get; set; }
    public decimal Other { get; set; }
}

public class CloseDayRequest
{
    public Guid LocationId { get; set; }
    public DateTime BusinessDate { get; set; }
    public decimal ActualCash { get; set; }
    public string? Notes { get; set; }
}
