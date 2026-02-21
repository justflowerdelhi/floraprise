using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.DeliveryZones;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.UseCases;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/delivery-zones")]
[Authorize(Policy = PolicyNames.CompanyOnly)]
public class DeliveryZonesController : ControllerBase
{
    private readonly DeliveryZoneService _service;
    private readonly ITenantContext _tenant;

    public DeliveryZonesController(DeliveryZoneService service, ITenantContext tenant)
    {
        _service = service;
        _tenant = tenant;
    }

    /// <summary>
    /// Get all delivery zones
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<List<DeliveryZoneDto>>> GetAll([FromQuery] bool activeOnly = true)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var zones = await _service.GetAllAsync(companyId, activeOnly);
        return Ok(zones);
    }

    /// <summary>
    /// Get delivery zone by ID
    /// </summary>
    [HttpGet("{id:guid}")]
    public async Task<ActionResult<DeliveryZoneDto>> GetById(Guid id)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var zone = await _service.GetByIdAsync(companyId, id);
        return zone == null ? NotFound() : Ok(zone);
    }

    /// <summary>
    /// Create a new delivery zone
    /// </summary>
    [HttpPost]
    [Authorize(Policy = PolicyNames.CompanyAdmin)]
    public async Task<ActionResult<DeliveryZoneDto>> Create([FromBody] CreateDeliveryZoneRequest request)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var zone = await _service.CreateAsync(companyId, request);
        return CreatedAtAction(nameof(GetById), new { id = zone.Id }, zone);
    }

    /// <summary>
    /// Update a delivery zone
    /// </summary>
    [HttpPut("{id:guid}")]
    [Authorize(Policy = PolicyNames.CompanyAdmin)]
    public async Task<ActionResult<DeliveryZoneDto>> Update(Guid id, [FromBody] UpdateDeliveryZoneRequest request)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var zone = await _service.UpdateAsync(companyId, id, request);
        return zone == null ? NotFound() : Ok(zone);
    }

    /// <summary>
    /// Delete a delivery zone
    /// </summary>
    [HttpDelete("{id:guid}")]
    [Authorize(Policy = PolicyNames.CompanyAdmin)]
    public async Task<ActionResult> Delete(Guid id)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var success = await _service.DeleteAsync(companyId, id);
        return success ? NoContent() : NotFound();
    }

    /// <summary>
    /// Activate a delivery zone
    /// </summary>
    [HttpPost("{id:guid}/activate")]
    [Authorize(Policy = PolicyNames.CompanyAdmin)]
    public async Task<ActionResult> Activate(Guid id)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var success = await _service.ActivateAsync(companyId, id);
        return success ? Ok() : NotFound();
    }

    /// <summary>
    /// Deactivate a delivery zone
    /// </summary>
    [HttpPost("{id:guid}/deactivate")]
    [Authorize(Policy = PolicyNames.CompanyAdmin)]
    public async Task<ActionResult> Deactivate(Guid id)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var success = await _service.DeactivateAsync(companyId, id);
        return success ? Ok() : NotFound();
    }

    /// <summary>
    /// Calculate delivery fee for a location
    /// </summary>
    [HttpPost("calculate-fee")]
    public async Task<ActionResult<DeliveryFeeResult>> CalculateFee([FromBody] CalculateDeliveryFeeRequest request)
    {
        var companyId = _tenant.CompanyId ?? throw new UnauthorizedAccessException();
        var result = await _service.CalculateFeeAsync(companyId, request);
        return Ok(result);
    }
}
