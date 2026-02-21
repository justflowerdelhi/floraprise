namespace Sumpooj.Domain.Entities;

/// <summary>
/// Represents a POS cash-drawer shift.
/// A shift must be open before POS transactions are allowed.
/// Tracks opening cash, payment method totals, and closing count.
/// </summary>
public class Shift : BaseEntity
{
    private Shift() { }

    public Shift(
        Guid companyId,
        Guid locationId,
        Guid openedByUserId,
        string openedByName,
        decimal openingCash)
    {
        CompanyId = companyId;
        LocationId = locationId;
        OpenedByUserId = openedByUserId;
        OpenedByName = openedByName;
        OpeningCash = openingCash;
        OpenedAt = DateTime.UtcNow;
        Status = ShiftStatus.Open;
    }

    public Guid CompanyId { get; private set; }
    public Guid LocationId { get; private set; }

    // Open
    public Guid OpenedByUserId { get; private set; }
    public string OpenedByName { get; private set; } = default!;
    public DateTime OpenedAt { get; private set; }
    public decimal OpeningCash { get; private set; }

    // Close (nullable until shift is closed)
    public Guid? ClosedByUserId { get; private set; }
    public string? ClosedByName { get; private set; }
    public DateTime? ClosedAt { get; private set; }
    public decimal? ClosingCashCount { get; private set; }
    public decimal? CashDifference { get; private set; }

    // Payment aggregates (updated as sales happen)
    public decimal CashSales { get; private set; }
    public decimal CardSales { get; private set; }
    public decimal UpiSales { get; private set; }
    public decimal GiftCardSales { get; private set; }
    public decimal OtherSales { get; private set; }
    public decimal TotalRefunds { get; private set; }
    public decimal PaidOuts { get; private set; }
    public int TransactionCount { get; private set; }

    // Status
    public ShiftStatus Status { get; private set; }

    // Notes
    public string? Notes { get; private set; }

    // ─── Computed ───────────────────────────────────────

    /// <summary>
    /// Expected cash = opening + cash sales − refunds − paid-outs
    /// </summary>
    public decimal ExpectedCash => OpeningCash + CashSales - TotalRefunds - PaidOuts;

    public bool IsClosed => Status == ShiftStatus.Closed;

    // ─── Behaviors ──────────────────────────────────────

    public void RecordSale(decimal cash, decimal card, decimal upi, decimal giftCard, decimal other)
    {
        if (IsClosed) throw new InvalidOperationException("Cannot record sale on a closed shift");
        CashSales += cash;
        CardSales += card;
        UpiSales += upi;
        GiftCardSales += giftCard;
        OtherSales += other;
        TransactionCount++;
        MarkUpdated();
    }

    public void RecordRefund(decimal amount)
    {
        if (IsClosed) throw new InvalidOperationException("Cannot record refund on a closed shift");
        TotalRefunds += amount;
        MarkUpdated();
    }

    public void RecordPaidOut(decimal amount)
    {
        if (IsClosed) throw new InvalidOperationException("Cannot record paid-out on a closed shift");
        PaidOuts += amount;
        MarkUpdated();
    }

    public void Close(Guid closedByUserId, string closedByName, decimal closingCashCount, string? notes = null)
    {
        if (IsClosed) throw new InvalidOperationException("Shift is already closed");

        ClosedByUserId = closedByUserId;
        ClosedByName = closedByName;
        ClosedAt = DateTime.UtcNow;
        ClosingCashCount = closingCashCount;
        CashDifference = closingCashCount - ExpectedCash;
        Status = ShiftStatus.Closed;
        Notes = notes;
        MarkUpdated();
    }
}
