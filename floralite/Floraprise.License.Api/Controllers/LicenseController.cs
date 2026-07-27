using Floraprise.License.Api.DTOs;
using Floraprise.License.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace Floraprise.License.Api.Controllers;

[ApiController]
[Route("api/license")]
public sealed class LicenseController : ControllerBase
{
    private readonly ILicenseService _licenseService;
    private readonly ILogger<LicenseController> _logger;

    public LicenseController(
        ILicenseService licenseService,
        ILogger<LicenseController> logger)
    {
        _licenseService = licenseService;
        _logger = logger;
    }

    [HttpPost("register")]
    [ProducesResponseType(typeof(LicenseRegistrationResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ValidationProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<LicenseRegistrationResponse>> Register(
        [FromBody] RegisterLicenseRequest request,
        CancellationToken cancellationToken)
    {
        var response = await _licenseService.RegisterAsync(request, cancellationToken);
        _logger.LogInformation(
            "License registration checked for mobile {Mobile} and customer {CustomerId}.",
            request.Mobile,
            response.CustomerId);
        return Ok(response);
    }

    [HttpGet("check")]
    [ProducesResponseType(typeof(LicenseCheckResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<LicenseCheckResponse>> Check(
        [FromQuery] Guid customerId,
        [FromQuery] string deviceId,
        CancellationToken cancellationToken)
    {
        var response = await _licenseService.CheckAsync(
            customerId,
            deviceId,
            cancellationToken);

        return response is null
            ? NotFound(new ProblemDetails
            {
                Title = "License not found",
                Detail = "The customer or device is not registered.",
                Status = StatusCodes.Status404NotFound
            })
            : Ok(response);
    }

    [HttpPost("heartbeat")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Heartbeat(
        [FromBody] LicenseHeartbeatRequest request,
        CancellationToken cancellationToken)
    {
        var updated = await _licenseService.HeartbeatAsync(request, cancellationToken);
        return updated
            ? NoContent()
            : NotFound(new ProblemDetails
            {
                Title = "Device not found",
                Detail = "The customer device is not registered.",
                Status = StatusCodes.Status404NotFound
            });
    }
}