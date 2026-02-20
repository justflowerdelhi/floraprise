using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Locations;
using Sumpooj.Application.UseCases;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/locations")]
[Authorize(Policy = PolicyNames.CompanyOnly)]
public class LocationsController : ControllerBase
{
    private readonly LocationService _service;

    public LocationsController(LocationService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var locations = await _service.GetActiveLocationsAsync();
        return Ok(locations);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> Get(Guid id)
    {
        var location = await _service.GetAsync(id);
        return location == null ? NotFound() : Ok(location);
    }

    [HttpPost]
    [Authorize(Policy = PolicyNames.CompanyAdmin)]
    public async Task<IActionResult> Create([FromBody] CreateLocationRequest request)
    {
        var id = await _service.CreateAsync(request);
        return CreatedAtAction(nameof(Get), new { id }, new { id });
    }

    [HttpPut("{id:guid}")]
    [Authorize(Policy = PolicyNames.CompanyAdmin)]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateLocationRequest request)
    {
        await _service.UpdateAsync(id, request);
        return NoContent();
    }

    [HttpPut("{id:guid}/deactivate")]
    [Authorize(Policy = PolicyNames.CompanyAdmin)]
    public async Task<IActionResult> Deactivate(Guid id)
    {
        await _service.DeactivateAsync(id);
        return NoContent();
    }
}
