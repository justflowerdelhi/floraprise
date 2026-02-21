namespace Sumpooj.Application.TaxRules;

/// <summary>
/// Fully computed tax summary for an order.
/// </summary>
public class TaxSummary
{
    /// <summary>Sum of line subtotals (excluding tax for exclusive rules, as-is for inclusive).</summary>
    public decimal Subtotal { get; set; }

    /// <summary>Total tax across all lines.</summary>
    public decimal TotalTax { get; set; }

    /// <summary>Subtotal + TotalTax (for exclusive) or Subtotal (for inclusive, tax already inside).</summary>
    public decimal GrandTotal { get; set; }

    /// <summary>Per-line tax detail.</summary>
    public List<LineTaxDetail> Lines { get; set; } = new();

    /// <summary>Aggregated breakdown grouped by TaxRule.</summary>
    public List<TaxBreakdownItem> TaxBreakdown { get; set; } = new();
}

/// <summary>
/// Tax calculation result for a single order line.
/// </summary>
public class LineTaxDetail
{
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = default!;
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }

    /// <summary>Quantity * UnitPrice (the original line amount before any tax adjustment).</summary>
    public decimal LineSubtotal { get; set; }

    public decimal TaxAmount { get; set; }
    public decimal LineTotal { get; set; }

    // Tax rule info applied
    public Guid? TaxRuleId { get; set; }
    public string? TaxRuleName { get; set; }
    public decimal TaxRate { get; set; }
    public bool IsInclusive { get; set; }
}

/// <summary>
/// Aggregated tax amount for a single TaxRule across all lines.
/// </summary>
public class TaxBreakdownItem
{
    public Guid TaxRuleId { get; set; }
    public string TaxRuleName { get; set; } = default!;
    public decimal Rate { get; set; }
    public bool IsInclusive { get; set; }
    public decimal TaxableAmount { get; set; }
    public decimal TaxAmount { get; set; }
}
