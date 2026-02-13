using System.Security.Claims;
using Sumpooj.Application.Interfaces;

namespace Sumpooj.API.Infrastructure;

public class HttpTenantContext : ITenantContext
{
    public Guid? CompanyId { get; }
    public string? Region { get; }
    public bool IsPlatformUser { get; }

    public HttpTenantContext(IHttpContextAccessor accessor)
    {
        var user = accessor.HttpContext?.User;

        if (user == null || !user.Identity?.IsAuthenticated == true)
        {
            IsPlatformUser = true;
            return;
        }

        var companyClaim = user.FindFirst("company_id")?.Value;
        var regionClaim = user.FindFirst("region")?.Value;

        Region = regionClaim;

        if (Guid.TryParse(companyClaim, out var companyId))
        {
            CompanyId = companyId;
            IsPlatformUser = false;
        }
        else
        {
            IsPlatformUser = true;
        }
    }
}
