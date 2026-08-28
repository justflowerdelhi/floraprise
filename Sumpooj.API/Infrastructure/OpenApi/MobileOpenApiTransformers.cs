using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.OpenApi;
using Microsoft.OpenApi;

namespace Sumpooj.API.Infrastructure.OpenApi;

public sealed class JwtSecuritySchemeDocumentTransformer : IOpenApiDocumentTransformer
{
    public Task TransformAsync(OpenApiDocument document, OpenApiDocumentTransformerContext context, CancellationToken cancellationToken)
    {
        document.Components ??= new OpenApiComponents();
        document.Components.SecuritySchemes ??= new Dictionary<string, IOpenApiSecurityScheme>();

        document.Components.SecuritySchemes["Bearer"] = new OpenApiSecurityScheme
        {
            Type = SecuritySchemeType.Http,
            Scheme = "bearer",
            BearerFormat = "JWT",
            Name = "Authorization",
            In = ParameterLocation.Header,
            Description = "JWT Bearer token. Example: Bearer {token}"
        };

        return Task.CompletedTask;
    }
}

public sealed class MobileOpenApiOperationTransformer : IOpenApiOperationTransformer
{
    public Task TransformAsync(OpenApiOperation operation, OpenApiOperationTransformerContext context, CancellationToken cancellationToken)
    {
        operation.OperationId ??= BuildOperationId(context);

        if (string.IsNullOrWhiteSpace(operation.Summary))
        {
            operation.Summary = BuildFallbackSummary(context);
        }

        if (string.IsNullOrWhiteSpace(operation.Description))
        {
            operation.Description = BuildFallbackDescription(context);
        }

        operation.Responses ??= new OpenApiResponses();
        EnsureProblemResponse(operation, "400", "Bad request.");
        EnsureProblemResponse(operation, "401", "Unauthorized.");
        EnsureProblemResponse(operation, "403", "Forbidden.");
        EnsureProblemResponse(operation, "404", "Not found.");
        EnsureProblemResponse(operation, "409", "Conflict.");
        EnsureProblemResponse(operation, "500", "Server error.");

        AppendExampleHints(operation);

        return Task.CompletedTask;
    }

    private static void EnsureProblemResponse(OpenApiOperation operation, string statusCode, string description)
    {
        var responses = operation.Responses ??= new OpenApiResponses();

        if (responses.ContainsKey(statusCode))
            return;

        responses[statusCode] = new OpenApiResponse
        {
            Description = description,
            Content = new Dictionary<string, OpenApiMediaType>
            {
                ["application/problem+json"] = new()
            }
        };
    }

    private static string BuildOperationId(OpenApiOperationTransformerContext context)
    {
        var actionDescriptor = context.Description.ActionDescriptor;
        var controller = actionDescriptor.RouteValues.TryGetValue("controller", out var controllerValue)
            ? controllerValue
            : "Api";
        var action = actionDescriptor.RouteValues.TryGetValue("action", out var actionValue)
            ? actionValue
            : "Operation";

        return $"{controller}_{action}";
    }

    private static void AppendExampleHints(OpenApiOperation operation)
    {
        var operationId = operation.OperationId ?? string.Empty;
        var lines = new List<string>();

        if (operation.RequestBody?.Content is not null)
        {
            lines.Add("Request example: use this endpoint request schema with representative values.");
        }

        var responses = operation.Responses;
        if (responses is not null && responses.TryGetValue("200", out var okResponse) && okResponse.Content is not null)
        {
            lines.Add("Response example: use this endpoint response schema with representative values.");
        }

        if (operationId.Contains("Login", StringComparison.OrdinalIgnoreCase))
        {
            lines.Add("Mobile login example: { identifier, password, deviceId, platform, appVersion }. Existing clients may still include companyId.");
        }
        else if (operationId.Contains("Refresh", StringComparison.OrdinalIgnoreCase))
        {
            lines.Add("Token refresh example: { refreshToken }.");
        }
        else if (operationId.Contains("Heartbeat", StringComparison.OrdinalIgnoreCase))
        {
            lines.Add("Heartbeat example: { deviceId, appVersion, lastSyncUtc, ipAddress }.");
        }

        if (lines.Count > 0)
        {
            var suffix = string.Join(" ", lines);
            if (string.IsNullOrWhiteSpace(operation.Description))
            {
                operation.Description = suffix;
            }
            else if (!operation.Description.Contains("Request example:", StringComparison.OrdinalIgnoreCase))
            {
                operation.Description = $"{operation.Description} {suffix}";
            }
        }
    }

    private static string BuildFallbackSummary(OpenApiOperationTransformerContext context)
    {
        var method = context.Description.HttpMethod?.ToUpperInvariant() ?? "API";
        var path = context.Description.RelativePath ?? "/";
        return $"{method} {path}";
    }

    private static string BuildFallbackDescription(OpenApiOperationTransformerContext context)
    {
        var action = context.Description.ActionDescriptor.DisplayName ?? "endpoint";
        return $"Auto-generated documentation for {action}.";
    }
}
