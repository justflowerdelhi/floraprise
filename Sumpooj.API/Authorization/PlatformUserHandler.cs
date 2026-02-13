using Microsoft.AspNetCore.Authorization;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Interfaces;

namespace Sumpooj.API.Authorization;

public class PlatformUserHandler
    : AuthorizationHandler<PlatformUserRequirement>
{
    private readonly ITenantContext _tenant;

    public PlatformUserHandler(ITenantContext tenant)
    {
        _tenant = tenant;
    }

    protected override Task HandleRequirementAsync(
        AuthorizationHandlerContext context,
        PlatformUserRequirement requirement)
    {
        if (_tenant.IsPlatformUser)
        {
            context.Succeed(requirement);
        }

        return Task.CompletedTask;
    }
}
