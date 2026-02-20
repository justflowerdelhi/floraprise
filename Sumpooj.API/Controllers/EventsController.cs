using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Events;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.UseCases;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = "CompanyOnly")]
public class EventsController : ControllerBase
{
    private readonly EventService _eventService;
    private readonly ITenantContext _tenantContext;

    public EventsController(EventService eventService, ITenantContext tenantContext)
    {
        _eventService = eventService;
        _tenantContext = tenantContext;
    }

    private Guid CompanyId => _tenantContext.CompanyId 
        ?? throw new UnauthorizedAccessException("Company context required");

    [HttpGet("search")]
    public async Task<IActionResult> Search([FromQuery] EventSearchRequest request)
    {
        var result = await _eventService.SearchAsync(CompanyId, request);
        return Ok(result);
    }

    [HttpGet("upcoming")]
    public async Task<IActionResult> GetUpcoming([FromQuery] int days = 30)
    {
        var events = await _eventService.GetUpcomingAsync(CompanyId, days);
        return Ok(events);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var evt = await _eventService.GetByIdAsync(CompanyId, id);
        return evt == null ? NotFound() : Ok(evt);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateEventRequest request)
    {
        var id = await _eventService.CreateAsync(CompanyId, request);
        return CreatedAtAction(nameof(GetById), new { id }, new { id });
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateEventRequest request)
    {
        await _eventService.UpdateAsync(CompanyId, id, request);
        return NoContent();
    }
}
