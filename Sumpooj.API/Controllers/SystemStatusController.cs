using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/v1/system")]
[Authorize(Policy = "PlatformSupport")]
public class SystemStatusController : ControllerBase
{
    private readonly SumpoojDbContext _db;
    private readonly IConfiguration _config;

    public SystemStatusController(SumpoojDbContext db, IConfiguration config)
    {
        _db = db;
        _config = config;
    }

    [HttpGet("status")]
    public async Task<IActionResult> GetSystemStatus()
    {
        // Check database connectivity
        bool dbHealthy = false;
        try
        {
            await _db.Database.CanConnectAsync();
            dbHealthy = true;
        }
        catch
        {
            dbHealthy = false;
        }

        // Get app version from config
        string appVersion = _config["App:Version"] ?? "1.0.0";

        // Check Razorpay status (simple check - in production this would verify API access)
        bool razorpayHealthy = !string.IsNullOrEmpty(_config["Razorpay:KeyId"]);

        // Get maintenance mode and kill switch from config or database
        bool maintenanceMode = _config.GetValue<bool>("MaintenanceMode", false);
        bool killSwitchActive = _config.GetValue<bool>("KillSwitch", false);

        return Ok(new SystemStatusDto
        {
            AppVersion = appVersion,
            ApiStatus = "Healthy",
            DatabaseStatus = dbHealthy ? "Connected" : "Disconnected",
            RazorpayStatus = razorpayHealthy ? "Operational" : "Not Configured",
            MaintenanceMode = maintenanceMode,
            KillSwitchActive = killSwitchActive,
            TimestampUtc = DateTime.UtcNow
        });
    }

    [HttpPost("maintenance")]
    public async Task<IActionResult> ToggleMaintenanceMode([FromBody] ToggleRequest request)
    {
        // In production, this would update a distributed cache or database flag
        // For now, we'll just acknowledge the request
        return Ok(new { success = true, maintenanceMode = request.Enabled });
    }

    [HttpPost("killswitch")]
    public async Task<IActionResult> ToggleKillSwitch([FromBody] ToggleRequest request)
    {
        // In production, this would update a distributed cache or database flag
        // For now, we'll just acknowledge the request
        return Ok(new { success = true, killSwitchActive = request.Enabled });
    }
}

public class SystemStatusDto
{
    public string AppVersion { get; set; } = string.Empty;
    public string ApiStatus { get; set; } = string.Empty;
    public string DatabaseStatus { get; set; } = string.Empty;
    public string RazorpayStatus { get; set; } = string.Empty;
    public bool MaintenanceMode { get; set; }
    public bool KillSwitchActive { get; set; }
    public DateTime TimestampUtc { get; set; }
}

public class ToggleRequest
{
    public bool Enabled { get; set; }
}
