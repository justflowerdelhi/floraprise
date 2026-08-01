using Microsoft.AspNetCore.Mvc;

namespace Floraprise.Mobile.API.Controllers;

/// <summary>
/// Placeholder documentation endpoint for the Mobile API.
/// </summary>
[ApiController]
[Route("api/v1/[controller]")]
public sealed class DocsController : ControllerBase
{
    /// <summary>
    /// Returns a placeholder payload for the OpenAPI documentation endpoint.
    /// </summary>
    /// <response code="200">OpenAPI metadata placeholder.</response>
    [HttpGet("openapi")]
    [ProducesResponseType(typeof(object), StatusCodes.Status200OK)]
    public IActionResult GetOpenApi() => Ok(new { message = "OpenAPI placeholder" });
}
