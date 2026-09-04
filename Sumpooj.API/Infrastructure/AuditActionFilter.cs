using System.Diagnostics;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.UseCases;
using Sumpooj.Domain.Entities;

namespace Sumpooj.API.Infrastructure;

/// <summary>
/// Automatically logs audit entries for every mutating API action (POST, PUT, PATCH, DELETE).
/// Read-only actions (GET, HEAD, OPTIONS) are skipped.
/// </summary>
public class AuditActionFilter : IAsyncActionFilter
{
    private readonly AuditLogService _auditLogService;
    private readonly ITenantContext _tenantContext;
    private readonly ILogger<AuditActionFilter> _logger;

    public AuditActionFilter(
        AuditLogService auditLogService,
        ITenantContext tenantContext,
        ILogger<AuditActionFilter> logger)
    {
        _auditLogService = auditLogService;
        _tenantContext = tenantContext;
        _logger = logger;
    }

    public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
    {
        var httpMethod = context.HttpContext.Request.Method;

        // Skip read-only requests
        if (httpMethod is "GET" or "HEAD" or "OPTIONS")
        {
            await next();
            return;
        }

        var sw = Stopwatch.StartNew();
        var executedContext = await next();
        sw.Stop();

        // Fire-and-forget audit logging — don't let it break the response
        try
        {
            var companyId = _tenantContext.CompanyId;
            if (!companyId.HasValue || companyId.Value == Guid.Empty)
            {
                // Skip audit for requests without a valid company context (e.g. login, platform endpoints)
                // Login audit is handled explicitly in AuthController
                return;
            }

            var user = context.HttpContext.User;
            var userId = GetUserId(user);
            var userName = user.FindFirstValue(JwtRegisteredClaimNames.Email)
                           ?? user.FindFirstValue(ClaimTypes.Email)
                           ?? user.Identity?.Name;
            var userRole = user.FindFirstValue(ClaimTypes.Role);

            var requestPath = context.HttpContext.Request.Path.Value;
            var ipAddress = context.HttpContext.Connection.RemoteIpAddress?.ToString();
            var userAgent = context.HttpContext.Request.Headers.UserAgent.ToString();

            // Derive action and entity type from the route
            var (action, entityType, entityId, entityName) = DeriveAuditInfo(context, executedContext, httpMethod);

            var isSuccess = executedContext.Exception == null &&
                            executedContext.Result is not ObjectResult { StatusCode: >= 400 };
            var errorMessage = executedContext.Exception?.Message;

            await _auditLogService.LogAsync(
                companyId.Value,
                userId,
                userName,
                userRole,
                action,
                entityType,
                entityId,
                entityName,
                oldValue: null,
                newValue: null,
                description: $"{httpMethod} {requestPath}",
                ipAddress: ipAddress,
                userAgent: userAgent,
                requestPath: requestPath,
                httpMethod: httpMethod,
                isSuccess: isSuccess,
                errorMessage: errorMessage);
        }
        catch (Exception ex)
        {
            // Never let audit logging break a request
            _logger.LogWarning(ex, "Audit logging failed for {Method} {Path}",
                httpMethod, context.HttpContext.Request.Path);
        }
    }

    private static Guid? GetUserId(ClaimsPrincipal user)
    {
        var identityUserId = user.FindFirstValue("identity_user_id");
        if (Guid.TryParse(identityUserId, out var resolvedIdentityUserId))
            return resolvedIdentityUserId;

        if (user.HasClaim("client_type", "mobile") || user.HasClaim(claim => claim.Type == "mobile_user_id"))
            return null;

        var legacyUserId = user.FindFirstValue(JwtRegisteredClaimNames.Sub)
            ?? user.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.TryParse(legacyUserId, out var resolvedLegacyUserId) ? resolvedLegacyUserId : null;
    }

    /// <summary>
    /// Derives the audit action, entity type, and optional entity ID from the route/result.
    /// </summary>
    private static (string Action, string EntityType, Guid? EntityId, string? EntityName)
        DeriveAuditInfo(ActionExecutingContext context, ActionExecutedContext executedContext, string httpMethod)
    {
        // Derive entity type from the controller name (e.g., "OrdersController" → "Order")
        var controllerName = context.Controller.GetType().Name
            .Replace("Controller", "");
        var entityType = controllerName;

        // Derive action from HTTP method + route template
        var actionName = context.ActionDescriptor.RouteValues.TryGetValue("action", out var act) ? act ?? "" : "";
        var action = httpMethod switch
        {
            "POST" => ResolvePostAction(actionName),
            "PUT" => AuditActions.Update,
            "PATCH" => AuditActions.Update,
            "DELETE" => AuditActions.Delete,
            _ => httpMethod
        };

        // Try to extract entity ID from route values
        Guid? entityId = null;
        if (context.ActionArguments.TryGetValue("id", out var idObj) && idObj is Guid guid)
        {
            entityId = guid;
        }

        // Try to extract entity name/ID from the result (for creates)
        string? entityName = null;
        if (executedContext.Result is CreatedAtActionResult created && created.Value != null)
        {
            // Attempt to read an "id" property from the response body
            var idProp = created.Value.GetType().GetProperty("id") ??
                         created.Value.GetType().GetProperty("Id");
            if (idProp?.GetValue(created.Value) is Guid createdId)
            {
                entityId = createdId;
            }
        }

        return (action, entityType, entityId, entityName);
    }

    private static string ResolvePostAction(string actionName)
    {
        var lower = actionName.ToLowerInvariant();
        return lower switch
        {
            "login" => AuditActions.Login,
            "logout" => AuditActions.Logout,
            "start" => AuditActions.Update,
            "complete" => AuditActions.Update,
            "activate" => AuditActions.Update,
            "deactivate" => AuditActions.Update,
            "approve" => AuditActions.Update,
            "void" => AuditActions.PaymentVoided,
            "close" => AuditActions.DayClosed,
            "assign" or "assigndesigner" or "assigndriver" => AuditActions.Update,
            _ => AuditActions.Create,
        };
    }
}
