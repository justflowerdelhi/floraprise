using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Companies;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/platform/companies")]
[Authorize(Policy = PolicyNames.PlatformSupport)]
public class CompaniesController : ControllerBase
{
    private readonly ICompanyService _service;

    public CompaniesController(ICompanyService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var companies = await _service.GetAllAsync();
        return Ok(companies);
    }

    [HttpPost]
    public async Task<IActionResult> Create(CreateCompanyRequest request)
    {
        var companyId = await _service.CreateAsync(request);
        return CreatedAtAction(nameof(GetAll), new { id = companyId }, companyId);
    }

    [HttpPatch("{companyId:guid}/activate")]
    public async Task<IActionResult> Activate(Guid companyId)
    {
        await _service.SetActiveAsync(companyId, true);
        return NoContent();
    }

    [HttpPatch("{companyId:guid}/deactivate")]
    public async Task<IActionResult> Deactivate(Guid companyId)
    {
        await _service.SetActiveAsync(companyId, false);
        return NoContent();
    }
}
