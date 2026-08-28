using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.API.Services.Mobile;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Mobile;

namespace Sumpooj.API.Controllers.Mobile;

[Route("api/v1/mobile/company")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme, Policy = PolicyNames.CompanyOnly)]
public sealed class MobileCompanyController : MobileApiControllerBase
{
    private readonly IMobileClientService _mobileClientService;

    public MobileCompanyController(IMobileClientService mobileClientService, ITenantContext tenantContext)
        : base(tenantContext)
    {
        _mobileClientService = mobileClientService;
    }

    /// <summary>
    /// Returns the authenticated company's profile.
    /// Used by Cloud Store to display company details in Settings → Shop Details.
    /// </summary>
    /// <remarks>
    /// Requires JWT Bearer auth with CompanyOnly policy.
    /// The company_id is extracted from the JWT claim, ensuring users can only access their own company.
    /// </remarks>
    [HttpGet("profile", Name = "MobileCompany_GetProfile")]
    [ProducesResponseType(typeof(MobileCompanyProfileDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetProfile(CancellationToken cancellationToken)
    {
        try
        {
            var response = await _mobileClientService.GetCompanyProfileAsync(GetCompanyId(), cancellationToken);
            return Ok(response);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }
}
