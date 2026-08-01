using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Interfaces;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/subscription")]
[Authorize(Roles = "CompanyAdmin,PlatformSuperAdmin,PlatformSupport")]
public class SubscriptionController : ControllerBase
{
    private readonly ITenantContext _tenantContext;

    public SubscriptionController(ITenantContext tenantContext)
    {
        _tenantContext = tenantContext;
    }

    private Guid? CompanyId => _tenantContext.CompanyId;

    [HttpPost("upgrade")]
    public IActionResult Upgrade([FromBody] UpgradePlanRequest request)
    {
        // Placeholder — integrate with payment provider (Stripe/Razorpay) when ready.
        // For now, acknowledge the request so the frontend flow completes.
        return Ok(new { companyId = CompanyId, plan = request.Plan, status = "pending" });
    }

    [HttpPost("cancel")]
    public IActionResult Cancel()
    {
        return Ok(new { companyId = CompanyId, status = "cancellation_scheduled" });
    }

    [HttpPost("resume")]
    public IActionResult Resume()
    {
        return Ok(new { companyId = CompanyId, status = "active" });
    }
}

public class UpgradePlanRequest
{
    public string Plan { get; set; } = default!;
}
