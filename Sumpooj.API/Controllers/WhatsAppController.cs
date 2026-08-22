using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.WhatsApp;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/whatsapp")]
public class WhatsAppController : ControllerBase
{
    private readonly IWhatsAppAccountService _service;
    private readonly ILogger<WhatsAppController> _logger;

    public WhatsAppController(IWhatsAppAccountService service, ILogger<WhatsAppController> logger)
    {
        _service = service;
        _logger = logger;
    }

    [HttpGet("resolve/{phoneNumberId}")]
    public async Task<IActionResult> ResolveCompany(string phoneNumberId)
    {
        var result = await _service.ResolveCompanyAsync(phoneNumberId);

        if (result == null)
        {
            _logger.LogInformation("Unknown WhatsApp Phone Number ID: {PhoneNumberId}", phoneNumberId);
            return NotFound();
        }

        return Ok(result);
    }
}
