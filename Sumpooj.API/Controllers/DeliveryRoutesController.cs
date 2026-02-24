using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Deliveries;
using System;
using System.Threading.Tasks;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/delivery-routes")]
public class DeliveryRoutesController : ControllerBase
{
    private readonly AssignDriverToRouteHandler _assignDriverHandler;
    private readonly CompleteRouteHandler _completeRouteHandler;
    // Assume StartRouteHandler exists and is injected
    private readonly StartRouteHandler _startRouteHandler;

    public DeliveryRoutesController(
        AssignDriverToRouteHandler assignDriverHandler,
        CompleteRouteHandler completeRouteHandler,
        StartRouteHandler startRouteHandler)
    {
        _assignDriverHandler = assignDriverHandler;
        _completeRouteHandler = completeRouteHandler;
        _startRouteHandler = startRouteHandler;
    }

    [HttpPut("{id}/assign-driver")]
    public async Task<IActionResult> AssignDriver(Guid id, [FromBody] AssignDriverRequest request)
    {
        try
        {
            var cmd = new AssignDriverToRouteCommand(id, request.DriverId);
            await _assignDriverHandler.Handle(cmd);
            return Ok();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpPut("{id}/start")]
    public async Task<IActionResult> StartRoute(Guid id)
    {
        try
        {
            await _startRouteHandler.Handle(id);
            return Ok();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpPut("{id}/complete")]
    public async Task<IActionResult> CompleteRoute(Guid id)
    {
        try
        {
            await _completeRouteHandler.Handle(id);
            return Ok();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }
}

public class AssignDriverRequest
{
    public Guid DriverId { get; set; }
}
