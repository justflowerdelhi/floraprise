using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.API.Services.Mobile;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Mobile;

namespace Sumpooj.API.Controllers.Mobile;

[Route("api/v1/mobile/license")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme, Policy = PolicyNames.CompanyOnly)]
public sealed class MobileLicenseController : MobileApiControllerBase
{
    private readonly IMobileClientService _mobileClientService;

    public MobileLicenseController(IMobileClientService mobileClientService, ITenantContext tenantContext)
        : base(tenantContext)
    {
        _mobileClientService = mobileClientService;
    }

    /// <summary>
    /// Validates device license access for the authenticated user.
    /// </summary>
    /// <remarks>
    /// Request example:
    /// { "deviceId": "android-emulator-001", "appVersion": "2.7.0", "lastSyncUtc": "2026-07-28T09:00:00Z" }
    /// </remarks>
    [HttpPost("validate", Name = "MobileLicense_Validate")]
    [ProducesResponseType(typeof(MobileLicenseStatusResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> Validate([FromBody] MobileLicenseValidateRequest request, CancellationToken cancellationToken)
    {
        try
        {
            if (!string.Equals(request.DeviceId, GetDeviceId(), StringComparison.Ordinal))
                return Problem(title: "Unauthorized", detail: "Device mismatch.", statusCode: StatusCodes.Status401Unauthorized);

            var response = await _mobileClientService.ValidateLicenseAsync(GetCompanyId(), GetMobileUserId(), request, cancellationToken);
            return Ok(response);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    /// <summary>
    /// Gets current online license status.
    /// </summary>
    [HttpGet("status", Name = "MobileLicense_Status")]
    [ProducesResponseType(typeof(MobileLicenseStatusResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> Status(CancellationToken cancellationToken)
    {
        try
        {
            var response = await _mobileClientService.GetLicenseStatusAsync(GetCompanyId(), GetMobileUserId(), GetDeviceId(), cancellationToken);
            return Ok(response);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    /// <summary>
    /// Gets offline validation status and remaining offline allowance.
    /// </summary>
    [HttpGet("offline-status", Name = "MobileLicense_OfflineStatus")]
    [ProducesResponseType(typeof(MobileOfflineValidationResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> OfflineStatus(CancellationToken cancellationToken)
    {
        try
        {
            var response = await _mobileClientService.GetOfflineValidationStatusAsync(GetCompanyId(), GetMobileUserId(), GetDeviceId(), cancellationToken);
            return Ok(response);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    /// <summary>
    /// Checks whether the requested device is authorized for current subscription.
    /// </summary>
    [HttpGet("authorize-device/{requestedDeviceId}", Name = "MobileLicense_AuthorizeDevice")]
    [ProducesResponseType(typeof(MobileDeviceAuthorizationResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> AuthorizeDevice([FromRoute] string requestedDeviceId, CancellationToken cancellationToken)
    {
        try
        {
            var response = await _mobileClientService.AuthorizeDeviceAsync(GetCompanyId(), GetMobileUserId(), GetDeviceId(), requestedDeviceId, cancellationToken);
            return Ok(response);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }
}