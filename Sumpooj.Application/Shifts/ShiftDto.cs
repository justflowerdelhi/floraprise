namespace Sumpooj.Application.Shifts;

public class ShiftDto
{
    public Guid Id { get; set; }
    public Guid LocationId { get; set; }

    // Open
    public Guid OpenedByUserId { get; set; }
    public string OpenedByName { get; set; } = default!;
    public DateTime OpenedAt { get; set; }
    public decimal OpeningCash { get; set; }

    // Close
    public Guid? ClosedByUserId { get; set; }
    public string? ClosedByName { get; set; }
    public DateTime? ClosedAt { get; set; }
    public decimal? ClosingCashCount { get; set; }
    public decimal? CashDifference { get; set; }

    // Aggregates
    public decimal CashSales { get; set; }
    public decimal CardSales { get; set; }
    public decimal UpiSales { get; set; }
    public decimal GiftCardSales { get; set; }
    public decimal OtherSales { get; set; }
    public decimal TotalRefunds { get; set; }
    public decimal PaidOuts { get; set; }
    public int TransactionCount { get; set; }

    // Computed
    public decimal ExpectedCash { get; set; }

    public string Status { get; set; } = default!;
    public bool IsClosed { get; set; }
    public string? Notes { get; set; }
}

public class OpenShiftRequest
{
    public Guid LocationId { get; set; }
    public decimal OpeningCash { get; set; }
}

public class CloseShiftRequest
{
    public decimal ClosingCashCount { get; set; }
    public string? Notes { get; set; }
}
