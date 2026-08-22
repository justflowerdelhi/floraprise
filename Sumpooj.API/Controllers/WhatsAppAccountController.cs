using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.WhatsApp;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/whatsapp/account")]
public class WhatsAppAccountController : ControllerBase
{
    private readonly IWhatsAppAccountService _service;
    private readonly ILogger<WhatsAppAccountController> _logger;

    public WhatsAppAccountController(IWhatsAppAccountService service, ILogger<WhatsAppAccountController> logger)
    {
        _service = service;
        _logger = logger;
    }

    [HttpPost]
    public async Task<ActionResult<WhatsAppAccountResponse>> CreateAccount([FromBody] CreateWhatsAppAccountRequest request)
    {
        try
        {
            var result = await _service.CreateAccountAsync(request);
            return CreatedAtAction(nameof(GetAccountById), new { id = result.Id }, result);
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Failed to create WhatsApp account");
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<WhatsAppAccountResponse>> GetAccountById(Guid id)
    {
        var result = await _service.GetAccountByIdAsync(id);
        if (result == null)
        {
            return NotFound();
        }
        return Ok(result);
    }

    [HttpGet("by-phone-number-id/{phoneNumberId}")]
    public async Task<ActionResult<WhatsAppAccountResponse>> GetAccountByPhoneNumberId(string phoneNumberId)
    {
        var result = await _service.GetAccountByPhoneNumberIdAsync(phoneNumberId);
        if (result == null)
        {
            return NotFound();
        }
        return Ok(result);
    }

    [HttpGet("by-member-id/{memberId}")]
    public async Task<ActionResult<WhatsAppAccountResponse>> GetAccountByMemberId(int memberId)
    {
        var result = await _service.GetAccountByMemberIdAsync(memberId);
        if (result == null)
        {
            return NotFound();
        }
        return Ok(result);
    }

    [HttpPut("{id}")]
    public async Task<ActionResult<WhatsAppAccountResponse>> UpdateAccount(Guid id, [FromBody] UpdateWhatsAppAccountRequest request)
    {
        var result = await _service.UpdateAccountAsync(id, request);
        if (result == null)
        {
            return NotFound();
        }
        return Ok(result);
    }

    [HttpPatch("{id}/deactivate")]
    public async Task<ActionResult> DeactivateAccount(Guid id)
    {
        var result = await _service.DeactivateAccountAsync(id);
        if (!result)
        {
            return NotFound();
        }
        return NoContent();
    }

    [HttpPatch("{id}/activate")]
    public async Task<ActionResult> ActivateAccount(Guid id)
    {
        var result = await _service.ActivateAccountAsync(id);
        if (!result)
        {
            return NotFound();
        }
        return NoContent();
    }
}
