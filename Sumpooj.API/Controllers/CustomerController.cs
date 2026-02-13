using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
//using Sumpooj.API.Models;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Customers;
using Sumpooj.Application.UseCases;


namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/customers")]
[Authorize(Policy = PolicyNames.CompanyOnly)]
public class CustomersController : ControllerBase
{
    private readonly CustomerService _service;

    public CustomersController(CustomerService service)
    {
        _service = service;
    }

    [HttpGet("search")]
    public async Task<IActionResult> Search([FromQuery] CustomerSearchRequest request)
    {
        var result = await _service.SearchAsync(request);
        return Ok(result);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> Get(Guid id)
    {
        var customer = await _service.GetAsync(id);
        return customer == null ? NotFound() : Ok(customer);
    }

    [HttpPost]
    public async Task<IActionResult> Create(CreateCustomerRequest request)
    {
        var id = await _service.CreateAsync(request);
        return CreatedAtAction(nameof(Get), new { id }, null);
    }

    [HttpPut("{id:guid}/contact")]
    public async Task<IActionResult> UpdateContact(
        Guid id,
        UpdateCustomerRequest request)
    {
        await _service.UpdateContactAsync(id, request);
        return NoContent();
    }

    [HttpPut("{id:guid}/card-message")]
    public async Task<IActionResult> UpdateCardMessage(
        Guid id,
        [FromBody] string? message)
    {
        await _service.UpdateCardMessageAsync(id, message);
        return NoContent();
    }

    [HttpPut("{id:guid}/deactivate")]
    public async Task<IActionResult> Deactivate(Guid id)
    {
        await _service.DeactivateAsync(id);
        return NoContent();
    }

    [HttpPut("{id:guid}/reactivate")]
    public async Task<IActionResult> Reactivate(Guid id)
    {
        await _service.ReactivateAsync(id);
        return NoContent();
    }
}
