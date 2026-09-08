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

[Route("api/v1/mobile/customers")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme, Policy = PolicyNames.CompanyOnly)]
public sealed class MobileCustomersController : MobileApiControllerBase
{
    private readonly SumpoojDbContext _db;

    public MobileCustomersController(SumpoojDbContext db, ITenantContext tenantContext)
        : base(tenantContext)
    {
        _db = db;
    }

    [HttpGet("{customerId:guid}/statistics")]
    public async Task<IActionResult> GetStatistics(Guid customerId, CancellationToken cancellationToken)
    {
        try
        {
            var companyId = GetCompanyId();

            var customer = await _db.Customers
                .AsNoTracking()
                .FirstOrDefaultAsync(
                    c => c.CompanyId == companyId && c.Id == customerId && c.IsActive,
                    cancellationToken);
            if (customer == null) return NotFound();

            var orders = await _db.Orders
                .AsNoTracking()
                .Where(o => o.CompanyId == companyId && o.CustomerId == customerId && o.IsActive)
                .ToListAsync(cancellationToken);

            var orderIds = orders.Select(o => o.Id).ToList();
            var paidByOrder = orderIds.Count == 0
                ? new Dictionary<Guid, decimal>()
                : await _db.Payments
                    .AsNoTracking()
                    .Where(p => p.CompanyId == companyId &&
                                orderIds.Contains(p.OrderId) &&
                                p.Status == PaymentTransactionStatus.Approved)
                    .GroupBy(p => p.OrderId)
                    .Select(g => new { OrderId = g.Key, Paid = g.Sum(p => p.Amount) })
                    .ToDictionaryAsync(x => x.OrderId, x => x.Paid, cancellationToken);

            var stats = new MobileCustomerStatisticsDto(
                customer.Id,
                orders.Count,
                orders.Count == 0 ? null : orders.Max(o => o.OrderDate),
                ToPaise(orders.Sum(o => o.TotalAmount)),
                ToPaise(orders.Sum(o => Math.Max(0m, o.TotalAmount - paidByOrder.GetValueOrDefault(o.Id, 0m)))));

            return Ok(stats);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    private static int ToPaise(decimal amount) =>
        decimal.Round(amount * 100m, 0, MidpointRounding.AwayFromZero) is var rounded
            ? (int)rounded
            : 0;
}
