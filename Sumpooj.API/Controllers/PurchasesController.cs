using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Purchases;
using Sumpooj.Application.UseCases;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/purchases")]
[Authorize(Policy = PolicyNames.CompanyOnly)]
public class PurchasesController : ControllerBase
{
    private readonly PurchaseOrderService _service;

    public PurchasesController(PurchaseOrderService service)
    {
        _service = service;
    }

    [HttpGet("search")]
    public async Task<IActionResult> Search([FromQuery] PurchaseOrderSearchRequest request)
    {
        var result = await _service.SearchAsync(request);
        return Ok(result);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> Get(Guid id)
    {
        var purchaseOrder = await _service.GetAsync(id);
        return purchaseOrder == null ? NotFound() : Ok(purchaseOrder);
    }

    [HttpGet("{id:guid}/pdf")]
    public async Task<IActionResult> DownloadPdf(Guid id)
    {
        var (content, fileName) = await _service.GeneratePdfAsync(id);
        return File(content, "application/pdf", fileName);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreatePurchaseOrderRequest request)
    {
        var id = await _service.CreateAsync(request);
        return CreatedAtAction(nameof(Get), new { id }, new { id });
    }

    [HttpPost("{id:guid}/submit")]
    public async Task<ActionResult<PurchaseOrderSubmitResult>> Submit(Guid id)
    {
        var result = await _service.SubmitAsync(id);
        return Ok(result);
    }

    [HttpPost("{id:guid}/approve")]
    [Authorize(Policy = PolicyNames.CompanyAdmin)]
    public async Task<IActionResult> Approve(Guid id)
    {
        await _service.ApproveAsync(id);
        return NoContent();
    }

    [HttpPost("{id:guid}/receive")]
    public async Task<IActionResult> Receive(Guid id, [FromBody] ReceivePurchaseOrderRequest request)
    {
        await _service.ReceiveAsync(id, request);
        return NoContent();
    }

    [HttpPost("{id:guid}/cancel")]
    public async Task<IActionResult> Cancel(Guid id)
    {
        await _service.CancelAsync(id);
        return NoContent();
    }
}
