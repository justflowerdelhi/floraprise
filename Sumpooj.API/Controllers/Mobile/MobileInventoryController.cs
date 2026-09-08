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

[Route("api/v1/mobile/inventory")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme, Policy = PolicyNames.CompanyOnly)]
public sealed class MobileInventoryController : MobileApiControllerBase
{
    private readonly SumpoojDbContext _db;

    public MobileInventoryController(SumpoojDbContext db, ITenantContext tenantContext)
        : base(tenantContext)
    {
        _db = db;
    }

    [HttpGet("low-stock")]
    public async Task<IActionResult> GetLowStock(CancellationToken cancellationToken)
    {
        try
        {
            var companyId = GetCompanyId();
            var products = await _db.Products
                .AsNoTracking()
                .Where(p => p.CompanyId == companyId &&
                            p.IsActive &&
                            p.TrackInventory &&
                            (p.StockQuantity <= 0 || p.StockQuantity <= p.MinimumStockLevel))
                .ToListAsync(cancellationToken);

            var items = products
                .Select(p => new MobileLowStockProductDto(
                    p.Id,
                    p.Name,
                    p.Sku,
                    p.StockQuantity,
                    p.MinimumStockLevel,
                    p.StockQuantity <= 0 ? "outOfStock" : "lowStock"))
                .OrderBy(p => p.Status)
                .ThenBy(p => p.Name)
                .ToList();

            return Ok(items);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }
}
