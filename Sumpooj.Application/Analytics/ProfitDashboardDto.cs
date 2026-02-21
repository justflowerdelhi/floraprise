namespace Sumpooj.Application.Analytics;

public class ProfitDashboardDto
{
    public ExecutiveSummaryDto Summary { get; set; } = new();
    public List<ChannelProfitDto> ChannelProfit { get; set; } = new();
    public List<ProductProfitDto> ProductProfit { get; set; } = new();
    public List<PlatformCommissionDto> PlatformCommission { get; set; } = new();
    public InventoryImpactDto? InventoryImpact { get; set; }
    public PaymentAnalysisSummaryDto? PaymentAnalysis { get; set; }
}

public class ExecutiveSummaryDto
{
    public decimal GrossRevenue { get; set; }
    public decimal ExternalCommissionPaid { get; set; }
    public decimal RefundsIssued { get; set; }
    public decimal TotalCOGS { get; set; }
    public decimal WastageValue { get; set; }
    public decimal NetProfit { get; set; }
    public decimal ProfitMarginPercent { get; set; }
    public decimal PaymentProcessingCost { get; set; }
    public int OrderCount { get; set; }
    public decimal AvgOrderValue { get; set; }
    public string PeriodLabel { get; set; } = default!;
}

public class ChannelProfitDto
{
    public string Channel { get; set; } = default!;
    public decimal GrossRevenue { get; set; }
    public decimal Commission { get; set; }
    public decimal NetRevenue { get; set; }
    public decimal Cogs { get; set; }
    public decimal EstimatedProfit { get; set; }
    public decimal ProfitPercent { get; set; }
    public int OrderCount { get; set; }
    public decimal AvgOrderValue { get; set; }
}

public class ProductProfitDto
{
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = default!;
    public string Sku { get; set; } = default!;
    public string Category { get; set; } = default!;
    public int QuantitySold { get; set; }
    public decimal GrossRevenue { get; set; }
    public decimal Cogs { get; set; }
    public decimal WastageImpact { get; set; }
    public Dictionary<string, decimal> ChannelBreakdown { get; set; } = new();
    public decimal NetProfit { get; set; }
    public decimal NetProfitPercent { get; set; }
    public decimal EffectiveMarginPercent { get; set; }
}

public class PlatformCommissionDto
{
    public string Platform { get; set; } = default!;
    public decimal GrossRevenue { get; set; }
    public decimal CommissionRate { get; set; }
    public decimal CommissionAmount { get; set; }
    public decimal PlatformFees { get; set; }
    public decimal NetPayout { get; set; }
    public decimal Cogs { get; set; }
    public decimal Profit { get; set; }
    public decimal ProfitPercent { get; set; }
    public int OrderCount { get; set; }
}

public class InventoryImpactDto
{
    public decimal TotalSalesValue { get; set; }
    public decimal TotalCOGS { get; set; }
    public decimal TotalWastageValue { get; set; }
    public int TotalWastageUnits { get; set; }
    public decimal ShrinkagePercent { get; set; }
    public decimal AdjustedGrossProfit { get; set; }
    public decimal AdjustedProfitMargin { get; set; }
    public List<WastageByCategoryDto> WastageByCategory { get; set; } = new();
}

public class WastageByCategoryDto
{
    public string Category { get; set; } = default!;
    public decimal WastageValue { get; set; }
    public int WastageUnits { get; set; }
    public decimal WastagePercent { get; set; }
}

public class PaymentAnalysisSummaryDto
{
    public int TotalTransactions { get; set; }
    public decimal TotalRevenue { get; set; }
    public decimal TotalProcessingCost { get; set; }
    public decimal NetRevenueAfterProcessing { get; set; }
    public List<PaymentMethodAnalysisDto> MethodBreakdown { get; set; } = new();
}

public class PaymentMethodAnalysisDto
{
    public string Method { get; set; } = default!;
    public int TransactionCount { get; set; }
    public decimal TotalAmount { get; set; }
    public decimal PercentOfTotal { get; set; }
    public decimal EstimatedProcessingRate { get; set; }
    public decimal EstimatedProcessingCost { get; set; }
    public decimal NetRevenue { get; set; }
}

public class ProfitDashboardRequest
{
    public DateTime? FromDate { get; set; }
    public DateTime? ToDate { get; set; }
    public Guid? LocationId { get; set; }
    public string? DateRangePreset { get; set; }
}
