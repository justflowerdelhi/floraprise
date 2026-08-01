using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("api")]
public class PingController : ControllerBase
{
    [HttpGet("ping")]
    public IActionResult Get()
    {
        return Ok(new
        {
            status = "ok",
            version = "2026-07-31-build"
        });
    }
}
