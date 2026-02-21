using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.TaxRules;
using Sumpooj.Application.UseCases;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/taxrules")]
[Authorize(Policy = PolicyNames.CompanyOnly)]
public class TaxRulesController : ControllerBase
{
    private readonly TaxRuleService _service;
    private readonly ITenantContext _tenantContext;

    public TaxRulesController(TaxRuleService service, ITenantContext tenantContext)
    {
        _service = service;
        _tenantContext = tenantContext;
    }

    private Guid CompanyId =>
        _tenantContext.CompanyId ?? throw new UnauthorizedAccessException("Company context required");

    /// <summary>
    /// GET /api/taxrules?country=XX
    /// Returns tax rules filtered by country code, or all if country is omitted.
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<List<TaxRuleDto>>> Get([FromQuery] string? country, [FromQuery] bool activeOnly = true)
    {
        if (!string.IsNullOrWhiteSpace(country))
        {
            var rules = await _service.GetByCountryAsync(CompanyId, country.ToUpperInvariant(), activeOnly);
            return Ok(rules);
        }

        var all = await _service.GetAllAsync(CompanyId, activeOnly);
        return Ok(all);
    }

    /// <summary>
    /// GET /api/taxrules/{id}
    /// </summary>
    [HttpGet("{id:guid}")]
    public async Task<ActionResult<TaxRuleDto>> GetById(Guid id)
    {
        var rule = await _service.GetByIdAsync(CompanyId, id);
        return rule == null ? NotFound() : Ok(rule);
    }

    /// <summary>
    /// POST /api/taxrules
    /// </summary>
    [HttpPost]
    [Authorize(Policy = PolicyNames.CompanyAdmin)]
    public async Task<ActionResult<TaxRuleDto>> Create([FromBody] CreateTaxRuleRequest request)
    {
        var rule = await _service.CreateAsync(CompanyId, request);
        return CreatedAtAction(nameof(GetById), new { id = rule.Id }, rule);
    }

    /// <summary>
    /// PUT /api/taxrules/{id}
    /// </summary>
    [HttpPut("{id:guid}")]
    [Authorize(Policy = PolicyNames.CompanyAdmin)]
    public async Task<ActionResult<TaxRuleDto>> Update(Guid id, [FromBody] UpdateTaxRuleRequest request)
    {
        var result = await _service.UpdateAsync(CompanyId, id, request);
        return result == null ? NotFound() : Ok(result);
    }

    /// <summary>
    /// DELETE /api/taxrules/{id} — Soft-delete (deactivate).
    /// </summary>
    [HttpDelete("{id:guid}")]
    [Authorize(Policy = PolicyNames.CompanyAdmin)]
    public async Task<ActionResult> Deactivate(Guid id)
    {
        var success = await _service.DeactivateAsync(CompanyId, id);
        return success ? NoContent() : NotFound();
    }

    /// <summary>
    /// POST /api/taxrules/{id}/activate — Re-activate a deactivated rule.
    /// </summary>
    [HttpPost("{id:guid}/activate")]
    [Authorize(Policy = PolicyNames.CompanyAdmin)]
    public async Task<ActionResult> Activate(Guid id)
    {
        var success = await _service.ActivateAsync(CompanyId, id);
        return success ? NoContent() : NotFound();
    }
}
