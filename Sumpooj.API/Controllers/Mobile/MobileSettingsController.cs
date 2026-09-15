using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Mobile;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.API.Controllers.Mobile;

[Route("api/v1/mobile/company/settings")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme, Policy = PolicyNames.CompanyOnly)]
public sealed class MobileSettingsController : MobileApiControllerBase
{
    private static readonly HashSet<string> ValidWatermarkSizes = new(StringComparer.OrdinalIgnoreCase)
    {
        "small", "medium", "large"
    };

    private static readonly HashSet<string> ValidWatermarkPositions = new(StringComparer.OrdinalIgnoreCase)
    {
        "topLeft", "topCenter", "topRight", "bottomLeft", "bottomCenter", "bottomRight"
    };

    private readonly SumpoojDbContext _db;

    public MobileSettingsController(SumpoojDbContext db, ITenantContext tenantContext)
        : base(tenantContext)
    {
        _db = db;
    }

    [HttpGet("share-branding", Name = "MobileSettings_GetShareBranding")]
    [ProducesResponseType(typeof(ShareBrandingSettingsDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetShareBranding(CancellationToken cancellationToken)
    {
        try
        {
            var companyId = GetCompanyId();
            var settings = await _db.ShareBrandingSettings
                .AsNoTracking()
                .FirstOrDefaultAsync(s => s.CompanyId == companyId, cancellationToken);

            if (settings == null)
            {
                // Default settings for company that hasn't saved custom values yet
                return Ok(new ShareBrandingSettingsDto(
                    Guid.Empty,
                    companyId,
                    ShowPrice: true,
                    ShowShopName: true,
                    ShowPhoneNumber: true,
                    ShowWebsite: true,
                    ShowLogo: false,
                    ShowWatermark: true,
                    ShowWatermarkBusinessName: true,
                    ShowWatermarkCity: true,
                    WatermarkOpacity: 0.72,
                    WatermarkSize: "medium",
                    WatermarkPosition: "bottomCenter",
                    FooterColorArgb: 0xCC1B5E20,
                    DateTime.UtcNow,
                    null));
            }

            return Ok(ToShareBrandingDto(settings));
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    [HttpPut("share-branding", Name = "MobileSettings_UpdateShareBranding")]
    [Authorize(Policy = PolicyNames.CompanyAdmin)]
    [ProducesResponseType(typeof(ShareBrandingSettingsDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> UpdateShareBranding(
        [FromBody] UpdateShareBrandingSettingsRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var validationError = ValidateShareBrandingRequest(request);
            if (validationError != null)
                return BadRequest(new ProblemDetails { Title = "Invalid Request", Detail = validationError, Status = StatusCodes.Status400BadRequest });

            var companyId = GetCompanyId();
            var settings = await _db.ShareBrandingSettings
                .FirstOrDefaultAsync(s => s.CompanyId == companyId, cancellationToken);

            if (settings == null)
            {
                settings = new ShareBrandingSettings(
                    companyId,
                    request.ShowPrice,
                    request.ShowShopName,
                    request.ShowPhoneNumber,
                    request.ShowWebsite,
                    request.ShowLogo,
                    request.ShowWatermark,
                    request.ShowWatermarkBusinessName,
                    request.ShowWatermarkCity,
                    request.WatermarkOpacity,
                    NormalizeWatermarkSize(request.WatermarkSize),
                    NormalizeWatermarkPosition(request.WatermarkPosition),
                    request.FooterColorArgb);
                _db.ShareBrandingSettings.Add(settings);
            }
            else
            {
                settings.Update(
                    request.ShowPrice,
                    request.ShowShopName,
                    request.ShowPhoneNumber,
                    request.ShowWebsite,
                    request.ShowLogo,
                    request.ShowWatermark,
                    request.ShowWatermarkBusinessName,
                    request.ShowWatermarkCity,
                    request.WatermarkOpacity,
                    NormalizeWatermarkSize(request.WatermarkSize),
                    NormalizeWatermarkPosition(request.WatermarkPosition),
                    request.FooterColorArgb);
            }

            await _db.SaveChangesAsync(cancellationToken);
            return Ok(ToShareBrandingDto(settings));
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    [HttpGet("rewards", Name = "MobileSettings_GetRewards")]
    [ProducesResponseType(typeof(RewardsSettingsDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetRewards(CancellationToken cancellationToken)
    {
        try
        {
            var companyId = GetCompanyId();
            var settings = await _db.RewardsSettings
                .AsNoTracking()
                .FirstOrDefaultAsync(s => s.CompanyId == companyId, cancellationToken);

            if (settings == null)
            {
                // Default settings for company that hasn't saved custom values yet
                return Ok(new RewardsSettingsDto(
                    Guid.Empty,
                    companyId,
                    Enabled: true,
                    EarnSpendPaisePerPoint: 10000,
                    MinimumBillPaise: 30000,
                    PointValuePaise: 100,
                    MaximumRedemptionPercent: 20,
                    ExpiryDays: 365,
                    DateTime.UtcNow,
                    null));
            }

            return Ok(ToRewardsDto(settings));
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    [HttpPut("rewards", Name = "MobileSettings_UpdateRewards")]
    [Authorize(Policy = PolicyNames.CompanyAdmin)]
    [ProducesResponseType(typeof(RewardsSettingsDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> UpdateRewards(
        [FromBody] UpdateRewardsSettingsRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var validationError = ValidateRewardsRequest(request);
            if (validationError != null)
                return BadRequest(new ProblemDetails { Title = "Invalid Request", Detail = validationError, Status = StatusCodes.Status400BadRequest });

            var companyId = GetCompanyId();
            var settings = await _db.RewardsSettings
                .FirstOrDefaultAsync(s => s.CompanyId == companyId, cancellationToken);

            if (settings == null)
            {
                settings = new RewardsSettings(
                    companyId,
                    request.Enabled,
                    request.EarnSpendPaisePerPoint,
                    request.MinimumBillPaise,
                    request.PointValuePaise,
                    request.MaximumRedemptionPercent,
                    request.ExpiryDays);
                _db.RewardsSettings.Add(settings);
            }
            else
            {
                settings.Update(
                    request.Enabled,
                    request.EarnSpendPaisePerPoint,
                    request.MinimumBillPaise,
                    request.PointValuePaise,
                    request.MaximumRedemptionPercent,
                    request.ExpiryDays);
            }

            await _db.SaveChangesAsync(cancellationToken);
            return Ok(ToRewardsDto(settings));
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    private static string? ValidateShareBrandingRequest(UpdateShareBrandingSettingsRequest r)
    {
        if (r.WatermarkOpacity < 0.2 || r.WatermarkOpacity > 1.0)
            return "watermarkOpacity must be between 0.2 and 1.0.";

        if (string.IsNullOrWhiteSpace(r.WatermarkSize) || !ValidWatermarkSizes.Contains(r.WatermarkSize.Trim()))
            return "watermarkSize must be one of: small, medium, large.";

        if (string.IsNullOrWhiteSpace(r.WatermarkPosition) || !ValidWatermarkPositions.Contains(r.WatermarkPosition.Trim()))
            return "watermarkPosition must be one of: topLeft, topCenter, topRight, bottomLeft, bottomCenter, bottomRight.";

        if (r.FooterColorArgb < 0 || r.FooterColorArgb > 0xFFFFFFFFL)
            return "footerColorArgb must represent a valid 32-bit ARGB color value.";

        return null;
    }

    private static string? ValidateRewardsRequest(UpdateRewardsSettingsRequest r)
    {
        if (r.EarnSpendPaisePerPoint <= 0)
            return "earnSpendPaisePerPoint must be greater than 0.";

        if (r.MinimumBillPaise < 0)
            return "minimumBillPaise cannot be negative.";

        if (r.PointValuePaise <= 0)
            return "pointValuePaise must be greater than 0.";

        if (r.MaximumRedemptionPercent < 0 || r.MaximumRedemptionPercent > 100)
            return "maximumRedemptionPercent must be between 0 and 100.";

        if (r.ExpiryDays <= 0)
            return "expiryDays must be greater than 0.";

        return null;
    }

    private static string NormalizeWatermarkSize(string raw)
    {
        var trimmed = raw.Trim();
        if (string.Equals(trimmed, "small", StringComparison.OrdinalIgnoreCase)) return "small";
        if (string.Equals(trimmed, "large", StringComparison.OrdinalIgnoreCase)) return "large";
        return "medium";
    }

    private static string NormalizeWatermarkPosition(string raw)
    {
        var trimmed = raw.Trim();
        foreach (var pos in ValidWatermarkPositions)
        {
            if (string.Equals(trimmed, pos, StringComparison.OrdinalIgnoreCase)) return pos;
        }
        return "bottomCenter";
    }

    private static ShareBrandingSettingsDto ToShareBrandingDto(ShareBrandingSettings s) => new(
        s.Id,
        s.CompanyId,
        s.ShowPrice,
        s.ShowShopName,
        s.ShowPhoneNumber,
        s.ShowWebsite,
        s.ShowLogo,
        s.ShowWatermark,
        s.ShowWatermarkBusinessName,
        s.ShowWatermarkCity,
        s.WatermarkOpacity,
        s.WatermarkSize,
        s.WatermarkPosition,
        s.FooterColorArgb,
        s.CreatedAtUtc,
        s.UpdatedAtUtc);

    private static RewardsSettingsDto ToRewardsDto(RewardsSettings s) => new(
        s.Id,
        s.CompanyId,
        s.Enabled,
        s.EarnSpendPaisePerPoint,
        s.MinimumBillPaise,
        s.PointValuePaise,
        s.MaximumRedemptionPercent,
        s.ExpiryDays,
        s.CreatedAtUtc,
        s.UpdatedAtUtc);
}
