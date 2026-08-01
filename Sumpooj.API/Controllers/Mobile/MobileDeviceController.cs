using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.API.Services.Mobile;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Mobile;

namespace Sumpooj.API.Controllers.Mobile;

[Route("api/v1/mobile/device")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme, Policy = PolicyNames.CompanyOnly)]
public sealed class MobileDeviceController : MobileApiControllerBase
{
    private readonly IMobileClientService _mobileClientService;

    public MobileDeviceController(IMobileClientService mobileClientService, ITenantContext tenantContext)
        : base(tenantContext)
    {
        _mobileClientService = mobileClientService;
    }

    /// <summary>
    /// Registers or updates a mobile device for the authenticated user.
    /// </summary>
    /// <remarks>
    /// Request example:
    /// { "deviceId": "android-emulator-001", "platform": "android", "appVersion": "2.7.0" }
    /// </remarks>
    [HttpPost("register", Name = "MobileDevice_Register")]
    [ProducesResponseType(typeof(MobileDeviceResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> Register([FromBody] MobileDeviceRegisterRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var response = await _mobileClientService.RegisterDeviceAsync(GetCompanyId(), GetMobileUserId(), request, cancellationToken);
            return Ok(response);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    /// <summary>
    /// Gets details of the current authenticated device.
    /// </summary>
    [HttpGet("current", Name = "MobileDevice_Current")]
    [ProducesResponseType(typeof(MobileDeviceResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> Current(CancellationToken cancellationToken)
    {
        try
        {
            var response = await _mobileClientService.GetCurrentDeviceAsync(GetCompanyId(), GetMobileUserId(), GetDeviceId(), cancellationToken);
            return Ok(response);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    /// <summary>
    /// Lists all devices associated with the authenticated user.
    /// </summary>
    [HttpGet("list", Name = "MobileDevice_List")]
    [ProducesResponseType(typeof(List<MobileDeviceResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> List(CancellationToken cancellationToken)
    {
        try
        {
            var response = await _mobileClientService.GetDevicesAsync(GetCompanyId(), GetMobileUserId(), GetDeviceId(), cancellationToken);
            return Ok(response);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    /// <summary>
    /// Sends periodic heartbeat for the current device.
    /// </summary>
    /// <remarks>
    /// Request example:
    /// { "deviceId": "android-emulator-001", "appVersion": "2.7.0", "lastSyncUtc": "2026-07-28T09:00:00Z" }
    /// </remarks>
    [HttpPost("heartbeat", Name = "MobileDevice_Heartbeat")]
    [ProducesResponseType(typeof(MobileLicenseCheckResult), StatusCodes.Status200OK)]
    public async Task<IActionResult> Heartbeat([FromBody] MobileDeviceHeartbeatRequest request, CancellationToken cancellationToken)
    {
        try
        {
            if (!string.Equals(request.DeviceId, GetDeviceId(), StringComparison.Ordinal))
                return Problem(title: "Unauthorized", detail: "Device mismatch.", statusCode: StatusCodes.Status401Unauthorized);

            var response = await _mobileClientService.HeartbeatAsync(GetCompanyId(), GetMobileUserId(), request, cancellationToken);
            return Ok(response);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    /// <summary>
    /// Updates the device last synchronization timestamp.
    /// </summary>
    /// <remarks>
    /// Request example:
    /// { "lastSyncUtc": "2026-07-28T09:05:00Z", "ipAddress": "10.0.2.15" }
    /// </remarks>
    [HttpPost("last-sync", Name = "MobileDevice_LastSync")]
    [ProducesResponseType(typeof(MobileDeviceResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> LastSync([FromBody] MobileDeviceLastSyncRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var response = await _mobileClientService.UpdateLastSyncAsync(GetCompanyId(), GetMobileUserId(), GetDeviceId(), request, cancellationToken);
            return Ok(response);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    /// <summary>
    /// Updates the push notification token for the current device.
    /// </summary>
    /// <remarks>
    /// Request example:
    /// { "pushToken": "fcm-token-value", "appVersion": "2.7.0" }
    /// </remarks>
    [HttpPost("push-token", Name = "MobileDevice_PushToken")]
    [ProducesResponseType(typeof(MobileDeviceResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> PushToken([FromBody] MobileDevicePushTokenRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var response = await _mobileClientService.UpdatePushTokenAsync(GetCompanyId(), GetMobileUserId(), GetDeviceId(), request, cancellationToken);
            return Ok(response);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }
}