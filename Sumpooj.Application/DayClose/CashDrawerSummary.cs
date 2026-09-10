namespace Sumpooj.Application.DayClose;

public sealed record CashDrawerSummary(
    decimal OpeningCash,
    decimal CashSales,
    decimal CashExpenses,
    decimal CashReceived = 0m,
    decimal CashPaid = 0m);