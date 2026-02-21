using Microsoft.Extensions.Logging;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.TaxRules;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.UseCases;

/// <summary>
/// Input line supplied by the caller (from order items + loaded products).
/// </summary>
public class TaxableLineItem
{
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = default!;
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }

    /// <summary>
    /// The TaxRule associated with the product (Product.TaxRule navigation).
    /// Null means the product is tax-exempt.
    /// </summary>
    public TaxRule? TaxRule { get; set; }
}

/// <summary>
/// Calculates tax for a set of order lines using TaxRule-based logic.
/// Supports both inclusive and exclusive tax modes.
/// </summary>
public class TaxCalculationService
{
    private readonly ITenantContext _tenant;
    private readonly ILogger<TaxCalculationService> _logger;

    public TaxCalculationService(ITenantContext tenant, ILogger<TaxCalculationService> logger)
    {
        _tenant = tenant;
        _logger = logger;
    }

    /// <summary>
    /// Calculate tax for a collection of line items.
    /// Uses the tenant's Region as the country code to filter applicable rules.
    /// </summary>
    public TaxSummary Calculate(IEnumerable<TaxableLineItem> lineItems)
    {
        var countryCode = _tenant.Region?.ToUpperInvariant();

        var summary = new TaxSummary();
        var breakdownMap = new Dictionary<Guid, TaxBreakdownItem>();

        foreach (var line in lineItems)
        {
            var lineSubtotal = line.Quantity * line.UnitPrice;
            var detail = new LineTaxDetail
            {
                ProductId = line.ProductId,
                ProductName = line.ProductName,
                Quantity = line.Quantity,
                UnitPrice = line.UnitPrice,
                LineSubtotal = lineSubtotal
            };

            var rule = line.TaxRule;

            // Only apply a rule if it's active and matches the tenant's country
            if (rule != null
                && rule.IsActive
                && (string.IsNullOrEmpty(countryCode)
                    || rule.CountryCode.Equals(countryCode, StringComparison.OrdinalIgnoreCase)))
            {
                detail.TaxRuleId = rule.Id;
                detail.TaxRuleName = rule.Name;
                detail.TaxRate = rule.Rate;
                detail.IsInclusive = rule.IsInclusive;

                if (rule.IsInclusive)
                {
                    // Price already contains tax
                    // taxAmount = lineSubtotal - (lineSubtotal / (1 + rate))
                    var taxAmount = lineSubtotal - (lineSubtotal / (1m + rule.Rate));
                    detail.TaxAmount = Math.Round(taxAmount, 2, MidpointRounding.AwayFromZero);
                    detail.LineTotal = lineSubtotal; // total stays as-is
                }
                else
                {
                    // Tax added on top
                    var taxAmount = lineSubtotal * rule.Rate;
                    detail.TaxAmount = Math.Round(taxAmount, 2, MidpointRounding.AwayFromZero);
                    detail.LineTotal = lineSubtotal + detail.TaxAmount;
                }

                // Aggregate into breakdown
                if (!breakdownMap.TryGetValue(rule.Id, out var bucket))
                {
                    bucket = new TaxBreakdownItem
                    {
                        TaxRuleId = rule.Id,
                        TaxRuleName = rule.Name,
                        Rate = rule.Rate,
                        IsInclusive = rule.IsInclusive
                    };
                    breakdownMap[rule.Id] = bucket;
                }

                bucket.TaxableAmount += lineSubtotal;
                bucket.TaxAmount += detail.TaxAmount;
            }
            else
            {
                // No applicable tax rule — tax-exempt line
                detail.TaxAmount = 0m;
                detail.LineTotal = lineSubtotal;

                if (rule != null && rule.IsActive)
                {
                    _logger.LogDebug(
                        "TaxRule {RuleId} ({RuleCountry}) skipped for product {ProductId}: tenant country is {TenantCountry}",
                        rule.Id, rule.CountryCode, line.ProductId, countryCode ?? "(none)");
                }
            }

            summary.Lines.Add(detail);
        }

        // Aggregate totals
        summary.Subtotal = summary.Lines.Sum(l => l.LineSubtotal);
        summary.TotalTax = summary.Lines.Sum(l => l.TaxAmount);

        // GrandTotal: for exclusive lines, tax is added on top; for inclusive, it's already in the subtotal.
        // Since a mix of inclusive/exclusive is possible, compute from individual line totals.
        summary.GrandTotal = summary.Lines.Sum(l => l.LineTotal);

        summary.TaxBreakdown = breakdownMap.Values
            .OrderBy(b => b.TaxRuleName)
            .ToList();

        return summary;
    }

    /// <summary>
    /// Convenience overload that builds TaxableLineItems from OrderItems + their loaded Products.
    /// Each Product must have TaxRule navigation loaded.
    /// </summary>
    public TaxSummary CalculateForOrder(IEnumerable<OrderItem> orderItems, IDictionary<Guid, Product> productMap)
    {
        var lines = orderItems.Select(oi =>
        {
            productMap.TryGetValue(oi.ProductId, out var product);
            return new TaxableLineItem
            {
                ProductId = oi.ProductId,
                ProductName = oi.ProductName,
                Quantity = oi.Quantity,
                UnitPrice = oi.UnitPrice,
                TaxRule = product?.TaxRule
            };
        });

        return Calculate(lines);
    }
}
