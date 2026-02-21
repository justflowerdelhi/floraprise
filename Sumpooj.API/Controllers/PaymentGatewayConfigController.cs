using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Payments;

namespace Sumpooj.API.Controllers;

/// <summary>
/// Manage payment gateway configurations for the tenant
/// </summary>
[ApiController]
[Route("api/payment-gateways")]
[Authorize]
public class PaymentGatewayConfigController : ControllerBase
{
    private readonly PaymentGatewayConfigService _service;

    public PaymentGatewayConfigController(PaymentGatewayConfigService service)
    {
        _service = service;
    }

    /// <summary>
    /// Get all available payment gateway types with their info
    /// </summary>
    [HttpGet("available")]
    public ActionResult<IReadOnlyList<PaymentGatewayInfoDto>> GetAvailableGateways()
    {
        return Ok(_service.GetAvailableGateways());
    }

    /// <summary>
    /// Get all configured payment gateways for the company
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<PaymentGatewayConfigDto>>> GetAll()
    {
        var configs = await _service.GetAllAsync();
        return Ok(configs);
    }

    /// <summary>
    /// Get a specific payment gateway configuration
    /// </summary>
    [HttpGet("{id:guid}")]
    public async Task<ActionResult<PaymentGatewayConfigDto>> GetById(Guid id)
    {
        var config = await _service.GetByIdAsync(id);
        if (config == null) return NotFound();
        return Ok(config);
    }

    /// <summary>
    /// Get the default payment gateway for the company
    /// </summary>
    [HttpGet("default")]
    public async Task<ActionResult<PaymentGatewayConfigDto>> GetDefault()
    {
        var config = await _service.GetDefaultAsync();
        if (config == null) return NotFound(new { message = "No default payment gateway configured" });
        return Ok(config);
    }

    /// <summary>
    /// Create a new payment gateway configuration
    /// </summary>
    [HttpPost]
    public async Task<ActionResult<PaymentGatewayConfigDto>> Create([FromBody] PaymentGatewayConfigCreateDto dto)
    {
        try
        {
            var config = await _service.CreateAsync(dto);
            return CreatedAtAction(nameof(GetById), new { id = config.Id }, config);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Update a payment gateway configuration
    /// </summary>
    [HttpPut("{id:guid}")]
    public async Task<ActionResult<PaymentGatewayConfigDto>> Update(Guid id, [FromBody] PaymentGatewayConfigUpdateDto dto)
    {
        var config = await _service.UpdateAsync(id, dto);
        if (config == null) return NotFound();
        return Ok(config);
    }

    /// <summary>
    /// Delete a payment gateway configuration
    /// </summary>
    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var deleted = await _service.DeleteAsync(id);
        if (!deleted) return NotFound();
        return NoContent();
    }

    /// <summary>
    /// Test payment gateway connection
    /// </summary>
    [HttpPost("{id:guid}/test")]
    public async Task<ActionResult<PaymentGatewayTestResultDto>> TestConnection(Guid id)
    {
        var result = await _service.TestConnectionAsync(id);
        return Ok(result);
    }
}
