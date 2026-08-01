using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.API.Services.Mobile;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Mobile;

namespace Sumpooj.API.Controllers.Mobile;

[Route("api/v1/mobile/bootstrap")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme, Policy = PolicyNames.CompanyOnly)]
public sealed class MobileBootstrapController : MobileApiControllerBase
{
    private readonly IMobileClientService _mobileClientService;

    public MobileBootstrapController(IMobileClientService mobileClientService, ITenantContext tenantContext)
        : base(tenantContext)
    {
        _mobileClientService = mobileClientService;
    }

    /// <summary>
    /// Returns bootstrap data required for mobile app startup.
    /// </summary>
    /// <remarks>
    /// Requires JWT Bearer auth with CompanyOnly policy.
    /// Response example includes company, user, plan, license, and feature flags.
    /// </remarks>
    [HttpGet(Name = "MobileBootstrap_Get")]
    [ProducesResponseType(typeof(MobileBootstrapResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> Get(CancellationToken cancellationToken)
    {
        try
        {
            var response = await _mobileClientService.GetBootstrapAsync(GetCompanyId(), GetMobileUserId(), GetDeviceId(), cancellationToken);
            return Ok(response);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }
}