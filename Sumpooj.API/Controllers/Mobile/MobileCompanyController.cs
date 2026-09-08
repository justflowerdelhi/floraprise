using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.API.Services.Mobile;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Companies;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Mobile;

namespace Sumpooj.API.Controllers.Mobile;

[Route("api/v1/mobile/company")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme, Policy = PolicyNames.CompanyOnly)]
public sealed class MobileCompanyController : MobileApiControllerBase
{
    private readonly IMobileClientService _mobileClientService;
    private readonly ICompanyService _companyService;

    public MobileCompanyController(IMobileClientService mobileClientService, ICompanyService companyService, ITenantContext tenantContext)
        : base(tenantContext)
    {
        _mobileClientService = mobileClientService;
        _companyService = companyService;
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

    /// <summary>
    /// Updates the authenticated company's profile.
    /// Used by Cloud Store to edit company details in Settings → Shop Details.
    /// </summary>
    /// <remarks>
    /// Requires JWT Bearer auth with the CompanyAdmin role.
    /// The company_id is extracted from the JWT claim; it is never accepted from the request body.
    /// </remarks>
    [HttpPut("profile", Name = "MobileCompany_UpdateProfile")]
    [Authorize(Policy = PolicyNames.CompanyAdmin)]
    [ProducesResponseType(typeof(MobileCompanyProfileDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateCompanySettingsRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var companyId = GetCompanyId();
            await _companyService.UpdateSettingsAsync(companyId, request);
            var response = await _mobileClientService.GetCompanyProfileAsync(companyId, cancellationToken);
            return Ok(response);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }
}

