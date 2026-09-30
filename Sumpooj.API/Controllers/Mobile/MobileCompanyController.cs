using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
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
    private readonly IWebHostEnvironment _environment;

    public MobileCompanyController(
        IMobileClientService mobileClientService,
        ICompanyService companyService,
        ITenantContext tenantContext,
        IWebHostEnvironment environment)
        : base(tenantContext)
    {
        _mobileClientService = mobileClientService;
        _companyService = companyService;
        _environment = environment;
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

    /// <summary>
    /// Uploads a shop logo image for the authenticated company.
    /// Saves the file to wwwroot/uploads/logos/ and updates Company.LogoPath.
    /// </summary>
    [HttpPost("logo", Name = "MobileCompany_UploadLogo")]
    [Authorize(Policy = PolicyNames.CompanyAdmin)]
    [ProducesResponseType(typeof(MobileCompanyProfileDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> UploadLogo(IFormFile? file, CancellationToken cancellationToken)
    {
        try
        {
            if (file == null || file.Length == 0)
            {
                return BadRequest(new { message = "Logo image file is required." });
            }

            if (file.Length > 5 * 1024 * 1024)
            {
                return BadRequest(new { message = "Logo image must be smaller than 5 MB." });
            }

            var allowedExtensions = new[] { ".png", ".jpg", ".jpeg", ".webp", ".svg" };
            var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
            if (string.IsNullOrEmpty(extension) || !allowedExtensions.Contains(extension))
            {
                return BadRequest(new { message = "Only PNG, JPG, JPEG, WEBP, and SVG image files are supported." });
            }

            var companyId = GetCompanyId();
            var webRoot = _environment.WebRootPath;
            if (string.IsNullOrEmpty(webRoot))
            {
                webRoot = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
            }

            var logosDir = Path.Combine(webRoot, "uploads", "logos");
            if (!Directory.Exists(logosDir))
            {
                Directory.CreateDirectory(logosDir);
            }

            var fileName = $"logo_{companyId}_{DateTime.UtcNow.Ticks}{extension}";
            var filePath = Path.Combine(logosDir, fileName);

            await using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(stream, cancellationToken);
            }

            var relativePath = $"/uploads/logos/{fileName}";
            await _companyService.UpdateSettingsAsync(companyId, new UpdateCompanySettingsRequest
            {
                LogoPath = relativePath
            });

            var response = await _mobileClientService.GetCompanyProfileAsync(companyId, cancellationToken);
            return Ok(response);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    /// <summary>
    /// Deletes the shop logo image for the authenticated company.
    /// </summary>
    [HttpDelete("logo", Name = "MobileCompany_DeleteLogo")]
    [Authorize(Policy = PolicyNames.CompanyAdmin)]
    [ProducesResponseType(typeof(MobileCompanyProfileDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> DeleteLogo(CancellationToken cancellationToken)
    {
        try
        {
            var companyId = GetCompanyId();
            await _companyService.UpdateSettingsAsync(companyId, new UpdateCompanySettingsRequest
            {
                LogoPath = ""
            });

            var response = await _mobileClientService.GetCompanyProfileAsync(companyId, cancellationToken);
            return Ok(response);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }
}

