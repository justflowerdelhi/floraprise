using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace Sumpooj.API.Infrastructure;

/// <summary>
/// Validates the "X-Website-Key" header against a configured secret.
/// Use on public endpoints that bypass JWT authentication.
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public class WebsiteApiKeyAttribute : Attribute, IAsyncAuthorizationFilter
{
    private const string HeaderName = "X-Website-Key";

    public async Task OnAuthorizationAsync(AuthorizationFilterContext context)
    {
        await Task.CompletedTask;

        var configuration = context.HttpContext.RequestServices
            .GetRequiredService<IConfiguration>();

        var expectedKey = configuration["WebsiteApiKey"];

        if (string.IsNullOrEmpty(expectedKey))
        {
            context.Result = new ObjectResult(new { message = "Server configuration error" })
            {
                StatusCode = StatusCodes.Status500InternalServerError
            };
            return;
        }

        if (!context.HttpContext.Request.Headers.TryGetValue(HeaderName, out var providedKey)
            || !string.Equals(providedKey, expectedKey, StringComparison.Ordinal))
        {
            context.Result = new UnauthorizedObjectResult(new { message = "Invalid or missing API key" });
        }
    }
}
