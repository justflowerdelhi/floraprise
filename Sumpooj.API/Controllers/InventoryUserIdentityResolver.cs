using System.Security.Claims;

namespace Sumpooj.API.Controllers;

public static class InventoryUserIdentityResolver
{
    public static Guid Resolve(ClaimsPrincipal user)
    {
        var identityUserId = user.FindFirst("identity_user_id")?.Value;
        if (Guid.TryParse(identityUserId, out var resolvedIdentityUserId))
            return resolvedIdentityUserId;

        var isMobileToken = user.HasClaim("client_type", "mobile") ||
            user.HasClaim(claim => claim.Type == "mobile_user_id");
        if (isMobileToken)
        {
            throw new UnauthorizedAccessException(
                "Your mobile session must be renewed before inventory changes can be saved.");
        }

        var userIdClaim = user.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (Guid.TryParse(userIdClaim, out var userId))
            return userId;

        throw new UnauthorizedAccessException("Identity user claim is missing.");
    }
}