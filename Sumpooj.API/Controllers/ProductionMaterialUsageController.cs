using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Production;
using Sumpooj.Application.UseCases;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/production-material-usage")]
[Authorize(Policy = PolicyNames.CompanyOnly)]
public class ProductionMaterialUsageController : ControllerBase
{
    private readonly ProductionService _service;
    private readonly ITenantContext _tenant;

    public ProductionMaterialUsageController(ProductionService service, ITenantContext tenant)
    {
        _service = service;
        _tenant = tenant;
    }

    private Guid CompanyId =>
        _tenant.CompanyId ?? throw new UnauthorizedAccessException("Company context required");

    /// <summary>
    /// POST /api/production-material-usage
    /// </summary>
    [HttpPost]
    public async Task<ActionResult> Add([FromBody] AddMaterialUsageRequest request)
    {
        var success = await _service.AddMaterialUsageAsync(CompanyId, request);
        return success ? Ok(new { success = true }) : NotFound();
    }
}
