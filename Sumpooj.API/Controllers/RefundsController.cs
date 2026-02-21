using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Refunds;
using Sumpooj.Application.UseCases;
using System.Security.Claims;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = "CompanyOnly")]
public class RefundsController : ControllerBase
{
    private readonly RefundService _refundService;
    private readonly ITenantContext _tenantContext;

    public RefundsController(RefundService refundService, ITenantContext tenantContext)
    {
        _refundService = refundService;
        _tenantContext = tenantContext;
    }

    private Guid CompanyId => _tenantContext.CompanyId 
        ?? throw new UnauthorizedAccessException("Company context required");

    private Guid UserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier) 
        ?? throw new UnauthorizedAccessException("User not found"));

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var refund = await _refundService.GetByIdAsync(CompanyId, id);
        return refund == null ? NotFound() : Ok(refund);
    }

    [HttpGet("by-order/{orderId:guid}")]
    public async Task<IActionResult> GetByOrderId(Guid orderId)
    {
        var refunds = await _refundService.GetByOrderIdAsync(orderId);
        return Ok(refunds);
    }

    [HttpPost]
    [Authorize(Policy = "StaffAccess")]
    public async Task<IActionResult> Create([FromBody] CreateRefundRequest request)
    {
        var refund = await _refundService.CreateAsync(CompanyId, request, UserId);
        return CreatedAtAction(nameof(GetById), new { id = refund.Id }, refund);
    }
}
