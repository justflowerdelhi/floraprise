using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.API.Services.Mobile;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Mobile;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.API.Controllers.Mobile;

[Route("api/v1/mobile/dashboard")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme, Policy = PolicyNames.CompanyOnly)]
public sealed class MobileDashboardController : MobileApiControllerBase
{
    private readonly SumpoojDbContext _db;

    public MobileDashboardController(SumpoojDbContext db, ITenantContext tenantContext)
        : base(tenantContext)
    {
        _db = db;
    }

    [HttpGet("summary")]
    public async Task<IActionResult> GetSummary(
        [FromQuery] DateTime? fromDate,
        [FromQuery] DateTime? toDate,
        CancellationToken cancellationToken)
    {
        try
        {
            var companyId = GetCompanyId();
            
            var businessFromDate = fromDate ?? PosSaleSyncService.GetServerLocalBusinessDate();
            var businessToDate = toDate ?? businessFromDate;
            
            var (utcFromStart, utcToEnd) = GetUtcRangeForBusinessDates(businessFromDate, businessToDate);
            
            if (utcToEnd < utcFromStart)
            {
                (utcFromStart, utcToEnd) = (utcToEnd, utcFromStart);
            }

            var orders = await _db.Orders
                .AsNoTracking()
                .Where(o =>
                    o.CompanyId == companyId &&
                    o.IsActive &&
                    o.OrderDate >= utcFromStart &&
                    o.OrderDate <= utcToEnd)
                .ToListAsync(cancellationToken);

            var orderIds = orders.Select(o => o.Id).ToList();
            var payments = orderIds.Count == 0
                ? new List<Payment>()
                : await _db.Payments
                    .AsNoTracking()
                    .Where(p =>
                        p.CompanyId == companyId &&
                        orderIds.Contains(p.OrderId) &&
                        p.Status == PaymentTransactionStatus.Approved)
                    .ToListAsync(cancellationToken);

            var expenses = await _db.Expenses
                .AsNoTracking()
                .Where(e =>
                    e.CompanyId == companyId &&
                    e.IsActive &&
                    e.ExpenseDate >= DateTime.SpecifyKind(businessFromDate.Date, DateTimeKind.Utc) &&
                    e.ExpenseDate <= DateTime.SpecifyKind(businessToDate.Date.AddDays(1), DateTimeKind.Utc))
                .ToListAsync(cancellationToken);

            var summary = new MobileDashboardSummaryDto(
                ToPaise(orders.Sum(o => o.TotalAmount)),
                orders.Count,
                ToPaise(payments.Where(p => p.Method == PaymentMethod.Cash).Sum(p => p.Amount)),
                ToPaise(payments.Where(p => p.Method == PaymentMethod.Upi).Sum(p => p.Amount)),
                ToPaise(payments.Where(p => p.Method == PaymentMethod.Card).Sum(p => p.Amount)),
                ToPaise(orders
                    .Where(o => o.PaymentStatus == PaymentStatus.Credit)
                    .Sum(o => o.TotalAmount)),
                orders.Count(o => o.Status is OrderStatus.Pending or OrderStatus.Confirmed),
                orders.Count(o => o.Status == OrderStatus.Processing),
                orders.Count(o => o.Status == OrderStatus.ReadyForDelivery),
                orders.Count(o => o.Status == OrderStatus.OutForDelivery),
                orders.Count(o => o.DeliveryAddress != null || o.DeliveryDate.Date > o.OrderDate.Date),
                orders.Count(o => o.DeliveryAddress == null && o.DeliveryDate.Date <= o.OrderDate.Date),
                ToPaise(expenses.Sum(e => e.Amount)));

            return Ok(summary);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    [HttpGet("profit-margin")]
    public async Task<IActionResult> GetProfitMargin(
        [FromQuery] DateTime? fromDate,
        [FromQuery] DateTime? toDate,
        CancellationToken cancellationToken)
    {
        try
        {
            var companyId = GetCompanyId();

            var businessFromDate = fromDate ?? PosSaleSyncService.GetServerLocalBusinessDate();
            var businessToDate = toDate ?? businessFromDate;

            var (utcFromStart, utcToEnd) = GetUtcRangeForBusinessDates(businessFromDate, businessToDate);

            if (utcToEnd < utcFromStart)
            {
                (utcFromStart, utcToEnd) = (utcToEnd, utcFromStart);
            }

            // Same inclusion rule as GetSummary (Cloud Sales Report): active orders in range.
            var orders = await _db.Orders
                .AsNoTracking()
                .Where(o =>
                    o.CompanyId == companyId &&
                    o.IsActive &&
                    o.OrderDate >= utcFromStart &&
                    o.OrderDate <= utcToEnd)
                .ToListAsync(cancellationToken);

            var orderIds = orders.Select(o => o.Id).ToList();
            var orderItems = orderIds.Count == 0
                ? new List<OrderItem>()
                : await _db.OrderItems
                    .AsNoTracking()
                    .Where(i => EF.Property<Guid?>(i, "OrderId") != null && orderIds.Contains(EF.Property<Guid?>(i, "OrderId")!.Value))
                    .ToListAsync(cancellationToken);

            var productIds = orderItems.Select(i => i.ProductId).Distinct().ToList();
            var productCosts = productIds.Count == 0
                ? new Dictionary<Guid, decimal>()
                : await _db.Products
                    .AsNoTracking()
                    .Where(p => p.CompanyId == companyId && productIds.Contains(p.Id))
                    .Select(p => new { p.Id, p.CostPrice })
                    .ToDictionaryAsync(p => p.Id, p => p.CostPrice, cancellationToken);

            var grossSales = orders.Sum(o => o.SubTotal);
            var discounts = orders.Sum(o => o.DiscountAmount);
            var netRevenue = grossSales - discounts;

            // COGS uses each product's current CostPrice, since OrderItem does not
            // store a per-sale historical cost snapshot. Products missing from the
            // catalog (e.g. deleted) contribute zero cost and are excluded from the estimate.
            var cogs = orderItems.Sum(i =>
                productCosts.TryGetValue(i.ProductId, out var costPrice) ? costPrice * i.Quantity : 0m);

            var grossProfit = netRevenue - cogs;
            var marginPercent = netRevenue > 0 ? Math.Round(grossProfit / netRevenue * 100m, 2) : 0m;

            var dto = new MobileProfitMarginDto(
                ToPaise(grossSales),
                ToPaise(discounts),
                ToPaise(netRevenue),
                ToPaise(cogs),
                ToPaise(grossProfit),
                marginPercent,
                orders.Count,
                CogsIsEstimate: true,
                CogsLimitationNote: "Cost of goods sold is calculated from each product's current cost price. " +
                    "The system does not store a historical cost snapshot per sale, so COGS for past orders " +
                    "may differ from the actual cost incurred at the time of sale if product costs changed since.");

            return Ok(dto);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    private static (DateTime utcStart, DateTime utcEnd) GetUtcRangeForBusinessDates(DateTime businessDateFrom, DateTime businessDateTo)
    {
        if (TimeZoneInfo.TryFindSystemTimeZoneById("Asia/Kolkata", out var tz) ||
            TimeZoneInfo.TryFindSystemTimeZoneById("India Standard Time", out tz))
        {
            var istFromMidnight = new DateTime(businessDateFrom.Year, businessDateFrom.Month, businessDateFrom.Day, 0, 0, 0);
            var istToMidnight = new DateTime(businessDateTo.Year, businessDateTo.Month, businessDateTo.Day, 23, 59, 59);
            
            var utcStart = TimeZoneInfo.ConvertTimeToUtc(istFromMidnight, tz);
            var utcEnd = TimeZoneInfo.ConvertTimeToUtc(istToMidnight, tz);
            
            return (utcStart, utcEnd);
        }
        
        return (
            DateTime.SpecifyKind(businessDateFrom.Date, DateTimeKind.Utc),
            DateTime.SpecifyKind(businessDateTo.Date.AddDays(1).AddTicks(-1), DateTimeKind.Utc)
        );
    }

    private static int ToPaise(decimal amount) =>
        (int)decimal.Round(amount * 100m, 0, MidpointRounding.AwayFromZero);
}
