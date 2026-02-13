using Microsoft.AspNetCore.Authorization;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Interfaces;

namespace Sumpooj.API.Authorization;

public class CompanyUserHandler
    : AuthorizationHandler<CompanyUserRequirement>
{
    private readonly ITenantContext _tenant;

    public CompanyUserHandler(ITenantContext tenant)
    {
        _tenant = tenant;
    }

    protected override Task HandleRequirementAsync(
        AuthorizationHandlerContext context,
        CompanyUserRequirement requirement)
    {
        if (_tenant.CompanyId.HasValue)
        {
            context.Succeed(requirement);
        }

        return Task.CompletedTask;
    }
}
