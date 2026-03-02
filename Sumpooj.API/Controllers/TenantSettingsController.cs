using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Companies;
using Sumpooj.Application.Interfaces;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/tenant/settings")]
[Authorize(Policy = "CompanyAdmin")]
public class TenantSettingsController : ControllerBase
{
    private readonly ICompanyService _companyService;
    private readonly ITenantContext _tenantContext;

    public TenantSettingsController(ICompanyService companyService, ITenantContext tenantContext)
    {
        _companyService = companyService;
        _tenantContext = tenantContext;
    }

    private Guid CompanyId => _tenantContext.CompanyId
        ?? throw new UnauthorizedAccessException("Company context required");

    [HttpGet]
    public async Task<IActionResult> Get()
    {
        var company = await _companyService.GetByIdAsync(CompanyId);
        return company == null ? NotFound() : Ok(company);
    }

    [HttpPost]
    public async Task<IActionResult> Update([FromBody] UpdateCompanySettingsRequest request)
    {
        await _companyService.UpdateSettingsAsync(CompanyId, request);
        return NoContent();
    }
}
