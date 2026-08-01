using Microsoft.AspNetCore.Mvc;

namespace Floraprise.Mobile.API.Controllers;

/// <summary>
/// Health endpoint for the Mobile infrastructure scaffold.
/// </summary>
[ApiController]
[Route("api/v1/[controller]")]
public sealed class HealthController : ControllerBase
{
    /// <summary>
    /// Returns the current health status for the Mobile API.
    /// </summary>
    /// <response code="200">The service is healthy.</response>
    [HttpGet]
    [ProducesResponseType(typeof(object), StatusCodes.Status200OK)]
    public IActionResult Get() => Ok(new { status = "ok" });
}
