using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Interfaces;

namespace Sumpooj.API.Controllers.Mobile;

[ApiController]
[Produces("application/json")]
[ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
[ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
[ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
[ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
[ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status409Conflict)]
[ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status500InternalServerError)]
public abstract class MobileApiControllerBase : ControllerBase
{
    protected readonly ITenantContext TenantContext;

    protected MobileApiControllerBase(ITenantContext tenantContext)
    {
        TenantContext = tenantContext;
    }

    protected Guid GetCompanyId()
    {
        if (TenantContext.CompanyId.HasValue)
            return TenantContext.CompanyId.Value;

        var claim = User.FindFirstValue("company_id");
        if (Guid.TryParse(claim, out var companyId))
            return companyId;

        throw new UnauthorizedAccessException("Company context is required.");
    }

    protected Guid GetMobileUserId()
    {
        var claim = User.FindFirstValue("mobile_user_id")
                    ?? User.FindFirstValue(ClaimTypes.NameIdentifier)
                    ?? User.FindFirstValue(JwtRegisteredClaimNames.Sub);

        if (Guid.TryParse(claim, out var mobileUserId))
            return mobileUserId;

        throw new UnauthorizedAccessException("Mobile user claim is missing.");
    }

    protected string GetDeviceId()
    {
        var claim = User.FindFirstValue("device_id");
        if (!string.IsNullOrWhiteSpace(claim))
            return claim.Trim();

        throw new UnauthorizedAccessException("Device claim is missing.");
    }

    protected IActionResult ProblemFromException(Exception ex)
    {
        return ex switch
        {
            UnauthorizedAccessException => Problem(title: "Unauthorized", detail: ex.Message, statusCode: StatusCodes.Status401Unauthorized, extensions: new Dictionary<string, object?>()),
            KeyNotFoundException => Problem(title: "Not Found", detail: ex.Message, statusCode: StatusCodes.Status404NotFound, extensions: new Dictionary<string, object?>()),
            ArgumentException => Problem(title: "Invalid Request", detail: ex.Message, statusCode: StatusCodes.Status400BadRequest, extensions: new Dictionary<string, object?>()),
            InvalidOperationException => Problem(title: "Operation Failed", detail: ex.Message, statusCode: StatusCodes.Status409Conflict, extensions: new Dictionary<string, object?>()),
            _ => Problem(title: "Server Error", detail: ex.Message, statusCode: StatusCodes.Status500InternalServerError, extensions: new Dictionary<string, object?>())
        };
    }
}