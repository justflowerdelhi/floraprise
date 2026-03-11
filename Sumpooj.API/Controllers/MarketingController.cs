using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.API.Infrastructure;
using Sumpooj.Application.Marketing;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/marketing")]
[AllowAnonymous]
[WebsiteApiKey]
public class MarketingController : ControllerBase
{
    private readonly DemoRequestService _service;

    public MarketingController(DemoRequestService service) => _service = service;

    [HttpPost("demo-request")]
    public async Task<IActionResult> SubmitDemoRequest([FromBody] DemoRequestDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.FullName))
            return BadRequest(new { message = "Full name is required" });

        if (string.IsNullOrWhiteSpace(dto.BusinessEmail))
            return BadRequest(new { message = "Business email is required" });

        await _service.SubmitAsync(dto);

        return Ok(new { success = true, message = "Demo request submitted successfully" });
    }
}
