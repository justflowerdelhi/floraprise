using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Companies;
using Sumpooj.Infrastructure;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/platform/companies")]
[Authorize(Policy = PolicyNames.PlatformSupport)]
public class CompaniesController : ControllerBase
{
    private readonly ICompanyService _service;
    private readonly SumpoojDbContext _db;

    public CompaniesController(ICompanyService service, SumpoojDbContext db)
    {
        _service = service;
        _db = db;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var companies = await _service.GetAllAsync();
        return Ok(companies);
    }

    [HttpGet("{companyId:guid}")]
    public async Task<IActionResult> GetById(Guid companyId)
    {
        var company = await _service.GetByIdAsync(companyId);
        return company == null ? NotFound() : Ok(company);
    }

    [HttpPost]
    public async Task<IActionResult> Create(CreateCompanyRequest request)
    {
        var companyId = await _service.CreateAsync(request);
        return CreatedAtAction(nameof(GetById), new { companyId }, companyId);
    }

    [HttpPut("{companyId:guid}")]
    public async Task<IActionResult> Update(Guid companyId, CreateCompanyRequest request)
    {
        // Reuse CreateCompanyRequest for update (same fields)
        var existing = await _service.GetByIdAsync(companyId);
        if (existing == null) return NotFound();

        await _service.UpdateSettingsAsync(companyId, new UpdateCompanySettingsRequest
        {
            TimeZone = request.TimeZone,
            CurrencyCode = request.CurrencyCode,
            TaxIdentifier = request.TaxIdentifier,
        });
        return NoContent();
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

    /// <summary>
    /// Populate ~5 demo records per major table for a company.
    /// Platform Super Admin only. Skips tables that already have data.
    /// </summary>
    [HttpPost("{companyId:guid}/seed-demo-data")]
    [Authorize(Policy = PolicyNames.PlatformOnly)]
    public async Task<IActionResult> SeedDemoData(Guid companyId)
    {
        var result = await CompanyDemoDataSeeder.SeedAsync(_db, companyId);
        return Ok(result);
    }

    /// <summary>
    /// Remove ALL company data from every major table (for going live).
    /// The Company record itself is preserved — only its data is wiped.
    /// Platform Super Admin only.
    /// </summary>
    [HttpPost("{companyId:guid}/purge-demo-data")]
    [Authorize(Policy = PolicyNames.PlatformOnly)]
    public async Task<IActionResult> PurgeDemoData(Guid companyId)
    {
        var result = await CompanyDemoDataSeeder.PurgeAsync(_db, companyId);
        return Ok(result);
    }
}
