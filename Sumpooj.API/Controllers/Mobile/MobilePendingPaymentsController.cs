using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Mobile;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.API.Controllers.Mobile;

[Route("api/v1/mobile/payments")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme, Policy = PolicyNames.CompanyOnly)]
public sealed class MobilePendingPaymentsController : MobileApiControllerBase
{
    private readonly SumpoojDbContext _db;

    public MobilePendingPaymentsController(SumpoojDbContext db, ITenantContext tenantContext)
        : base(tenantContext)
    {
        _db = db;
    }

    [HttpGet("pending")]
    public async Task<IActionResult> GetPendingPayments(CancellationToken cancellationToken)
    {
        try
        {
            var companyId = GetCompanyId();

            var orders = await _db.Orders
                .AsNoTracking()
                .Where(o =>
                    o.CompanyId == companyId &&
                    o.IsActive &&
                    o.PaymentStatus != PaymentStatus.Paid &&
                    o.Status != OrderStatus.Cancelled)
                .ToListAsync(cancellationToken);

            var orderIds = orders.Select(o => o.Id).ToList();
            var approvedPayments = orderIds.Count == 0
                ? new List<Payment>()
                : await _db.Payments
                    .AsNoTracking()
                    .Where(p =>
                        p.CompanyId == companyId &&
                        orderIds.Contains(p.OrderId) &&
                        p.Status == PaymentTransactionStatus.Approved)
                    .ToListAsync(cancellationToken);

            var paidByOrder = approvedPayments
                .GroupBy(p => p.OrderId)
                .ToDictionary(g => g.Key, g => g.Sum(p => p.Amount));

            var pendingOrders = orders
                .Select(o => new
                {
                    Order = o,
                    PendingAmount = Math.Max(0m, o.TotalAmount - paidByOrder.GetValueOrDefault(o.Id, 0m)),
                })
                .Where(x => x.PendingAmount > 0m)
                .ToList();

            var dto = new MobilePendingPaymentsDto(
                pendingOrders.Count,
                ToPaise(pendingOrders.Sum(x => x.PendingAmount)));

            return Ok(dto);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    private static int ToPaise(decimal amount) =>
        (int)decimal.Round(amount * 100m, 0, MidpointRounding.AwayFromZero);
}
