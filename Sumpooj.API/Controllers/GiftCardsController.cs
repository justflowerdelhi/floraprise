using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.GiftCards;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.UseCases;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/gift-cards")]
[Authorize(Policy = "CompanyOnly")]
public class GiftCardsController : ControllerBase
{
    private readonly GiftCardService _giftCardService;
    private readonly ITenantContext _tenantContext;

    public GiftCardsController(GiftCardService giftCardService, ITenantContext tenantContext)
    {
        _giftCardService = giftCardService;
        _tenantContext = tenantContext;
    }

    private Guid CompanyId => _tenantContext.CompanyId 
        ?? throw new UnauthorizedAccessException("Company context required");

    [HttpGet("search")]
    public async Task<IActionResult> Search([FromQuery] GiftCardSearchRequest request)
    {
        var result = await _giftCardService.SearchAsync(CompanyId, request);
        return Ok(result);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var card = await _giftCardService.GetByIdAsync(CompanyId, id);
        return card == null ? NotFound() : Ok(card);
    }

    [HttpGet("check-balance/{code}")]
    public async Task<IActionResult> CheckBalance(string code)
    {
        var result = await _giftCardService.CheckBalanceAsync(CompanyId, code);
        return Ok(result);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateGiftCardRequest request)
    {
        var card = await _giftCardService.CreateAsync(CompanyId, request);
        return CreatedAtAction(nameof(GetById), new { id = card.Id }, card);
    }

    [HttpPost("redeem")]
    public async Task<IActionResult> Redeem([FromBody] RedeemGiftCardRequest request)
    {
        var result = await _giftCardService.RedeemAsync(CompanyId, request);
        return Ok(result);
    }

    [HttpPost("{id:guid}/add-balance")]
    [Authorize(Policy = "CompanyAdmin")]
    public async Task<IActionResult> AddBalance(Guid id, [FromBody] AddBalanceRequest request)
    {
        await _giftCardService.AddBalanceAsync(CompanyId, id, request.Amount);
        return NoContent();
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Policy = "CompanyAdmin")]
    public async Task<IActionResult> Deactivate(Guid id)
    {
        await _giftCardService.DeactivateAsync(CompanyId, id);
        return NoContent();
    }
}

public class AddBalanceRequest
{
    public decimal Amount { get; set; }
}
