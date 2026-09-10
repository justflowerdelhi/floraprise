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
            var from = EnsureUtc(fromDate ?? PosSaleSyncService.GetServerLocalBusinessDate()).Date;
            var to = EnsureUtc(toDate ?? from).Date.AddDays(1).AddTicks(-1);
            if (to < from)
            {
                (from, to) = (to, from);
            }

            var orders = await _db.Orders
                .AsNoTracking()
                .Where(o =>
                    o.CompanyId == companyId &&
                    o.IsActive &&
                    o.OrderDate >= from &&
                    o.OrderDate <= to)
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
                    e.ExpenseDate >= from &&
                    e.ExpenseDate <= to)
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

    private static DateTime EnsureUtc(DateTime value) =>
        value.Kind == DateTimeKind.Utc ? value : DateTime.SpecifyKind(value, DateTimeKind.Utc);

    private static int ToPaise(decimal amount) =>
        (int)decimal.Round(amount * 100m, 0, MidpointRounding.AwayFromZero);
}
