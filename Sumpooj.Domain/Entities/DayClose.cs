namespace Sumpooj.Domain.Entities;

public class DayClose : BaseEntity
{
    private DayClose() { }

    public DayClose(
        Guid companyId,
        Guid locationId,
        DateTime businessDate,
        Guid closedByUserId)
    {
        CompanyId = companyId;
        LocationId = locationId;
        BusinessDate = businessDate;
        ClosedByUserId = closedByUserId;
        ClosedAt = DateTime.UtcNow;
        Status = DayCloseStatus.Completed;
    }

    public Guid CompanyId { get; private set; }
    public Guid LocationId { get; private set; }
    public DateTime BusinessDate { get; private set; }
    public DayCloseStatus Status { get; private set; }
    public DateTime ClosedAt { get; private set; }
    public Guid ClosedByUserId { get; private set; }

    // Sales Summary
    public int TotalOrders { get; private set; }
    public decimal TotalSales { get; private set; }
    public decimal TotalRefunds { get; private set; }
    public decimal NetSales { get; private set; }

    // Payment Breakdown
    public decimal CashTotal { get; private set; }
    public decimal CardTotal { get; private set; }
    public decimal UpiTotal { get; private set; }
    public decimal GiftCardTotal { get; private set; }
    public decimal OtherPaymentsTotal { get; private set; }

    // Cash Drawer
    public decimal ExpectedCash { get; private set; }
    public decimal ActualCash { get; private set; }
    public decimal CashVariance { get; private set; }

    // Notes
    public string? Notes { get; private set; }

    public void SetSalesSummary(int totalOrders, decimal totalSales, decimal totalRefunds)
    {
        TotalOrders = totalOrders;
        TotalSales = totalSales;
        TotalRefunds = totalRefunds;
        NetSales = totalSales - totalRefunds;
        MarkUpdated();
    }

    public void SetPaymentBreakdown(decimal cash, decimal card, decimal upi, decimal giftCard, decimal other)
    {
        CashTotal = cash;
        CardTotal = card;
        UpiTotal = upi;
        GiftCardTotal = giftCard;
        OtherPaymentsTotal = other;
        ExpectedCash = cash;
        MarkUpdated();
    }

    public void SetCashCount(decimal actualCash)
    {
        ActualCash = actualCash;
        CashVariance = actualCash - ExpectedCash;
        MarkUpdated();
    }

    public void AddNotes(string notes)
    {
        Notes = string.IsNullOrEmpty(Notes) ? notes : $"{Notes}\n{notes}";
        MarkUpdated();
    }
}
