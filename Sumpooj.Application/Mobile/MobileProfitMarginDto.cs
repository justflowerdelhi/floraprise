namespace Sumpooj.Application.Mobile;

/// <summary>
/// Cloud Profit/Margin summary. CogsPaise uses each product's current CostPrice
/// (no per-sale historical cost snapshot exists in the data model), so CogsIsEstimate
/// is always true and callers should surface that limitation to users.
/// </summary>
public sealed record MobileProfitMarginDto(
    int GrossSalesPaise,
    int DiscountsPaise,
    int NetRevenuePaise,
    int CogsPaise,
    int GrossProfitPaise,
    decimal MarginPercent,
    int OrderCount,
    bool CogsIsEstimate,
    string CogsLimitationNote);
