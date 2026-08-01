using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.API.Services.Mobile;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Mobile;

namespace Sumpooj.API.Controllers.Mobile;

[Route("api/v1/mobile/subscription")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme, Policy = PolicyNames.CompanyOnly)]
public sealed class MobileSubscriptionController : MobileApiControllerBase
{
    private readonly IMobileClientService _mobileClientService;

    public MobileSubscriptionController(IMobileClientService mobileClientService, ITenantContext tenantContext)
        : base(tenantContext)
    {
        _mobileClientService = mobileClientService;
    }

    /// <summary>
    /// Gets current subscription state for the authenticated mobile user.
    /// </summary>
    [HttpGet("current", Name = "MobileSubscription_Current")]
    [ProducesResponseType(typeof(MobileSubscriptionStateResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> Current(CancellationToken cancellationToken)
    {
        try
        {
            var response = await _mobileClientService.GetCurrentSubscriptionAsync(GetCompanyId(), GetMobileUserId(), cancellationToken);
            return Ok(response);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    /// <summary>
    /// Lists plans available for upgrade or downgrade.
    /// </summary>
    [HttpGet("plans", Name = "MobileSubscription_Plans")]
    [ProducesResponseType(typeof(MobileApiResponse<List<MobileSubscriptionPlanDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Plans(CancellationToken cancellationToken)
    {
        try
        {
            var plans = await _mobileClientService.GetAvailablePlansAsync(cancellationToken);
            var correlationId = HttpContext.TraceIdentifier;
            var response = new MobileApiResponse<List<MobileSubscriptionPlanDto>>(
                Success: true,
                Data: plans,
                Message: null,
                ErrorCode: null,
                CorrelationId: correlationId,
                TimestampUtc: DateTime.UtcNow);

            return Ok(response);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    /// <summary>
    /// Upgrades subscription plan and returns updated subscription state.
    /// </summary>
    [HttpPost("upgrade", Name = "MobileSubscription_Upgrade")]
    [ProducesResponseType(typeof(MobileSubscriptionActionResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> Upgrade([FromBody] MobilePlanChangeRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var response = await _mobileClientService.UpgradeAsync(GetCompanyId(), GetMobileUserId(), request, cancellationToken);
            return Ok(response);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    /// <summary>
    /// Downgrades subscription plan and returns updated subscription state.
    /// </summary>
    [HttpPost("downgrade", Name = "MobileSubscription_Downgrade")]
    [ProducesResponseType(typeof(MobileSubscriptionActionResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> Downgrade([FromBody] MobilePlanChangeRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var response = await _mobileClientService.DowngradeAsync(GetCompanyId(), GetMobileUserId(), request, cancellationToken);
            return Ok(response);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    /// <summary>
    /// Cancels auto-renewal and marks subscription for cancellation flow.
    /// </summary>
    [HttpPost("cancel", Name = "MobileSubscription_Cancel")]
    [ProducesResponseType(typeof(MobileSubscriptionActionResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> Cancel(CancellationToken cancellationToken)
    {
        try
        {
            var response = await _mobileClientService.CancelAsync(GetCompanyId(), GetMobileUserId(), cancellationToken);
            return Ok(response);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    /// <summary>
    /// Renews subscription for the selected billing cycle.
    /// </summary>
    [HttpPost("renew", Name = "MobileSubscription_Renew")]
    [ProducesResponseType(typeof(MobileSubscriptionActionResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> Renew([FromBody] MobileRenewRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var response = await _mobileClientService.RenewAsync(GetCompanyId(), GetMobileUserId(), request, cancellationToken);
            return Ok(response);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    /// <summary>
    /// Returns trial status and remaining trial days.
    /// </summary>
    [HttpGet("trial-status", Name = "MobileSubscription_TrialStatus")]
    [ProducesResponseType(typeof(MobileTrialStatusResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> TrialStatus(CancellationToken cancellationToken)
    {
        try
        {
            var response = await _mobileClientService.GetTrialStatusAsync(GetCompanyId(), GetMobileUserId(), cancellationToken);
            return Ok(response);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    /// <summary>
    /// Returns grace period status and remaining grace days.
    /// </summary>
    [HttpGet("grace-status", Name = "MobileSubscription_GraceStatus")]
    [ProducesResponseType(typeof(MobileGraceStatusResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> GraceStatus(CancellationToken cancellationToken)
    {
        try
        {
            var response = await _mobileClientService.GetGraceStatusAsync(GetCompanyId(), GetMobileUserId(), cancellationToken);
            return Ok(response);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }
}