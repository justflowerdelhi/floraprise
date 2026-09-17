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

    [HttpGet("{customerId:guid}/purchase-insights")]
    public async Task<IActionResult> GetPurchaseInsights(Guid customerId, CancellationToken cancellationToken)
    {
        try
        {
            var companyId = GetCompanyId();

            var customer = await _db.Customers
                .AsNoTracking()
                .FirstOrDefaultAsync(c => c.CompanyId == companyId && c.Id == customerId && c.IsActive, cancellationToken);
            if (customer == null) return NotFound();

            var query = from o in _db.Orders.AsNoTracking()
                        where o.CompanyId == companyId && o.CustomerId == customerId && o.IsActive
                        from oi in o.Items
                        join p in _db.Products.AsNoTracking() on oi.ProductId equals p.Id
                        select new
                        {
                            OrderId = o.Id,
                            OrderDate = o.OrderDate,
                            CategoryName = p.ProductCategoryRef != null ? p.ProductCategoryRef.Name : p.Category.ToString(),
                            Total = oi.TotalPrice
                        };

            var insights = await query
                .GroupBy(x => x.CategoryName)
                .Select(g => new
                {
                    CategoryName = g.Key ?? "Other",
                    OrderCount = g.Select(x => x.OrderId).Distinct().Count(),
                    TotalAmountSpentPaise = (long)(g.Sum(x => x.Total) * 100m),
                    LastPurchaseDate = g.Max(x => x.OrderDate)
                })
                .OrderByDescending(x => x.TotalAmountSpentPaise)
                .ToListAsync(cancellationToken);

            return Ok(insights);
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
