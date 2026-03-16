using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Sumpooj.Application.UseCases;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Identity;
using Sumpooj.Infrastructure.Persistence;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly IConfiguration _config;
    private readonly ILogger<AuthController> _logger;
    private readonly AuditLogService _auditLogService;
    private readonly SumpoojDbContext _db;

    public AuthController(
        UserManager<ApplicationUser> userManager,
        IConfiguration config,
        ILogger<AuthController> logger,
        AuditLogService auditLogService,
        SumpoojDbContext db)
    {
        _userManager = userManager;
        _config = config;
        _logger = logger;
        _auditLogService = auditLogService;
        _db = db;
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        try
        {
            _logger.LogInformation("Login attempt for: {Email}", request.Email);

            var user = await _userManager.FindByEmailAsync(request.Email);
            if (user == null)
            {
                _logger.LogWarning("User not found: {Email}", request.Email);
                return Unauthorized(new { message = "Invalid email or password" });
            }

            if (!user.IsActive)
            {
                _logger.LogWarning("User is inactive: {Email}", request.Email);

                if (user.CompanyId.HasValue)
                {
                    var inactiveIp = HttpContext.Connection.RemoteIpAddress?.ToString();
                    _ = _auditLogService.LogAsync(
                        user.CompanyId.Value, user.Id, user.Email, null,
                        AuditActions.LoginFailed, "User", user.Id, user.Email,
                        description: $"Login attempt for inactive account: {user.Email}",
                        ipAddress: inactiveIp, requestPath: "/api/auth/login", httpMethod: "POST",
                        isSuccess: false, errorMessage: "Account disabled");
                }

                return Unauthorized(new { message = "Account is disabled" });
            }

            if (!await _userManager.CheckPasswordAsync(user, request.Password))
            {
                _logger.LogWarning("Invalid password for: {Email}", request.Email);

                if (user.CompanyId.HasValue)
                {
                    var failIp = HttpContext.Connection.RemoteIpAddress?.ToString();
                    _ = _auditLogService.LogAsync(
                        user.CompanyId.Value,
                        user.Id,
                        user.Email,
                        null,
                        AuditActions.LoginFailed,
                        "User",
                        user.Id,
                        user.Email,
                        description: $"Failed login attempt for {user.Email} — invalid password",
                        ipAddress: failIp,
                        requestPath: "/api/auth/login",
                        httpMethod: "POST",
                        isSuccess: false,
                        errorMessage: "Invalid password");
                }

                return Unauthorized(new { message = "Invalid email or password" });
            }

            var roles = await _userManager.GetRolesAsync(user);
            var primaryRole = roles.FirstOrDefault() ?? "Staff";
            _logger.LogInformation("User {Email} has roles: {Roles}", request.Email, string.Join(", ", roles));

            var accessToken = GenerateAccessToken(user, roles);

            // Generate refresh token
            var refreshToken = new RefreshToken(user.Id, expiryDays: 7);
            _db.RefreshTokens.Add(refreshToken);
            await _db.SaveChangesAsync();

            _logger.LogInformation("Login successful for: {Email}", request.Email);

            // Audit: successful login
            if (user.CompanyId.HasValue)
            {
                var ip = HttpContext.Connection.RemoteIpAddress?.ToString();
                await _auditLogService.LogAsync(
                    user.CompanyId.Value,
                    user.Id,
                    user.Email,
                    primaryRole,
                    AuditActions.Login,
                    "User",
                    user.Id,
                    user.Email,
                    description: $"User {user.Email} logged in successfully",
                    ipAddress: ip,
                    requestPath: "/api/auth/login",
                    httpMethod: "POST");
            }

            return Ok(new
            {
                access_token = accessToken,
                refresh_token = refreshToken.Token,
                user = BuildUserResponse(user, primaryRole),
                tenant = await BuildTenantResponseAsync(user)
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Login failed for: {Email}", request.Email);
            return StatusCode(500, new { message = "An error occurred during login" });
        }
    }

    /// <summary>
    /// Exchange a valid refresh token for a new access token + refresh token pair.
    /// The old refresh token is revoked (rotation).
    /// </summary>
    [HttpPost("refresh")]
    public async Task<IActionResult> Refresh([FromBody] RefreshRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.RefreshToken))
            return BadRequest(new { message = "Refresh token is required" });

        var existing = await _db.RefreshTokens
            .FirstOrDefaultAsync(r => r.Token == request.RefreshToken);

        if (existing == null)
            return Unauthorized(new { message = "Invalid refresh token" });

        if (!existing.IsActive)
        {
            // Possible token reuse attack — revoke entire family
            if (existing.IsRevoked && !string.IsNullOrEmpty(existing.ReplacedByToken))
            {
                _logger.LogWarning("Refresh token reuse detected for user {UserId}", existing.UserId);
                await RevokeTokenFamilyAsync(existing.UserId);
            }
            return Unauthorized(new { message = "Refresh token expired or revoked" });
        }

        var user = await _userManager.FindByIdAsync(existing.UserId.ToString());
        if (user == null || !user.IsActive)
            return Unauthorized(new { message = "User not found or inactive" });

        var roles = await _userManager.GetRolesAsync(user);
        var primaryRole = roles.FirstOrDefault() ?? "Staff";

        // Generate new tokens (rotation)
        var newRefreshToken = new RefreshToken(user.Id, expiryDays: 7);
        existing.Revoke(replacedByToken: newRefreshToken.Token);
        _db.RefreshTokens.Add(newRefreshToken);
        await _db.SaveChangesAsync();

        var accessToken = GenerateAccessToken(user, roles);

        return Ok(new
        {
            access_token = accessToken,
            refresh_token = newRefreshToken.Token,
            user = BuildUserResponse(user, primaryRole),
            tenant = await BuildTenantResponseAsync(user)
        });
    }

    /// <summary>
    /// Revoke a refresh token (used on logout).
    /// </summary>
    [HttpPost("revoke")]
    public async Task<IActionResult> Revoke([FromBody] RefreshRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.RefreshToken))
            return BadRequest(new { message = "Refresh token is required" });

        var existing = await _db.RefreshTokens
            .FirstOrDefaultAsync(r => r.Token == request.RefreshToken);

        if (existing == null || !existing.IsActive)
            return Ok(new { message = "Token already revoked or invalid" });

        existing.Revoke();
        await _db.SaveChangesAsync();

        return Ok(new { message = "Token revoked" });
    }

    /// <summary>
    /// Get current user info from token. Used for session refresh/validation.
    /// </summary>
    [HttpGet("me")]
    [Microsoft.AspNetCore.Authorization.Authorize]
    public async Task<IActionResult> GetMe()
    {
        var userId = User.FindFirstValue(JwtRegisteredClaimNames.Sub);
        if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out _))
        {
            return Unauthorized(new { message = "Invalid token" });
        }

        var user = await _userManager.FindByIdAsync(userId);
        if (user == null)
        {
            return Unauthorized(new { message = "User not found" });
        }

        var roles = await _userManager.GetRolesAsync(user);
        var primaryRole = roles.FirstOrDefault() ?? "Staff";

        return Ok(new
        {
            user = BuildUserResponse(user, primaryRole),
            tenant = await BuildTenantResponseAsync(user)
        });
    }

    // ── Private helpers ──────────────────────────────────────────

    private string GenerateAccessToken(ApplicationUser user, IList<string> roles)
    {
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new(JwtRegisteredClaimNames.Email, user.Email!),
            new("company_id", user.CompanyId?.ToString() ?? ""),
        };

        foreach (var role in roles)
            claims.Add(new Claim(ClaimTypes.Role, role));

        var jwtKey = _config["Jwt:Key"]
            ?? throw new InvalidOperationException("JWT Key is not configured");

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));

        var token = new JwtSecurityToken(
            issuer: _config["Jwt:Issuer"],
            audience: _config["Jwt:Issuer"],
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(30),
            signingCredentials: new SigningCredentials(key, SecurityAlgorithms.HmacSha256)
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    private static object BuildUserResponse(ApplicationUser user, string role) => new
    {
        id = user.Id.ToString(),
        name = user.UserName,
        email = user.Email,
        role = role.ToUpperInvariant(),
        primaryLocationId = (string?)null,
        assignedLocationIds = Array.Empty<string>()
    };

    private async Task<object?> BuildTenantResponseAsync(ApplicationUser user)
    {
        if (!user.CompanyId.HasValue) return null;

        var company = await _db.Companies.FindAsync(user.CompanyId.Value);

        return new
        {
            id = user.CompanyId.Value.ToString(),
            name = company?.Name ?? "Company",
            slug = (company?.Name ?? "company").ToLower().Replace(" ", "-"),
            plan = "PRO",
            subscriptionStatus = "ACTIVE",
            country = company?.Region ?? "IN",
            currency = company?.CurrencyCode ?? "USD",
            taxSystem = !string.IsNullOrEmpty(company?.TaxIdentifier) ? "GST" : "NONE",
            dateFormat = "DD/MM/YYYY",
            timeFormat = "12H",
            locale = (company?.CurrencyCode) switch
            {
                "INR" => "en-IN",
                "AED" => "en-AE",
                "GBP" => "en-GB",
                "EUR" => "en-DE",
                "CAD" => "en-CA",
                "AUD" => "en-AU",
                _ => "en-US"
            },
            isActive = company?.IsActive ?? true,
            createdAt = company?.CreatedAtUtc.ToString("o") ?? DateTime.UtcNow.ToString("o")
        };
    }

    /// <summary>
    /// Revoke all active refresh tokens for a user (token reuse detection).
    /// </summary>
    private async Task RevokeTokenFamilyAsync(Guid userId)
    {
        var activeTokens = await _db.RefreshTokens
            .Where(r => r.UserId == userId && !r.IsRevoked)
            .ToListAsync();

        foreach (var token in activeTokens)
            token.Revoke();

        await _db.SaveChangesAsync();
    }

    /// <summary>
    /// Verify the current user's password. Used for sensitive actions (e.g. currency change).
    /// </summary>
    [HttpPost("verify-password")]
    [Microsoft.AspNetCore.Authorization.Authorize]
    public async Task<IActionResult> VerifyPassword([FromBody] VerifyPasswordRequest request)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return Unauthorized();

        var user = await _userManager.FindByIdAsync(userId);
        if (user == null) return Unauthorized();

        var valid = await _userManager.CheckPasswordAsync(user, request.Password);
        return Ok(new { verified = valid });
    }

    /// <summary>
    /// Change the current user's own password. Requires current password.
    /// Available to any authenticated user.
    /// </summary>
    [HttpPost("change-password")]
    [Microsoft.AspNetCore.Authorization.Authorize]
    public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return Unauthorized();

        var user = await _userManager.FindByIdAsync(userId);
        if (user == null) return Unauthorized();

        var result = await _userManager.ChangePasswordAsync(user, request.CurrentPassword, request.NewPassword);
        if (!result.Succeeded)
        {
            var errors = string.Join(", ", result.Errors.Select(e => e.Description));
            return BadRequest(new { message = errors });
        }

        return Ok(new { message = "Password changed successfully." });
    }

    /// <summary>
    /// Reset another user's password (admin action).
    /// - PlatformSuperAdmin / PlatformSupport: can reset any user
    /// - CompanyAdmin: can only reset users within their company
    /// </summary>
    [HttpPost("admin-reset-password")]
    [Microsoft.AspNetCore.Authorization.Authorize]
    public async Task<IActionResult> AdminResetPassword([FromBody] AdminResetPasswordRequest request)
    {
        var callerUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (callerUserId == null) return Unauthorized();

        var caller = await _userManager.FindByIdAsync(callerUserId);
        if (caller == null) return Unauthorized();

        var callerRoles = await _userManager.GetRolesAsync(caller);
        var isPlatformAdmin = callerRoles.Any(r =>
            r == "PlatformSuperAdmin" || r == "PlatformSupport");
        var isCompanyAdmin = callerRoles.Any(r => r == "CompanyAdmin");

        if (!isPlatformAdmin && !isCompanyAdmin)
            return Forbid();

        var targetUser = await _userManager.FindByIdAsync(request.UserId);
        if (targetUser == null)
            return NotFound(new { message = "User not found." });

        // CompanyAdmin can only reset passwords for users in the same company
        if (isCompanyAdmin && !isPlatformAdmin)
        {
            if (caller.CompanyId == null || targetUser.CompanyId != caller.CompanyId)
                return Forbid();
        }

        var resetToken = await _userManager.GeneratePasswordResetTokenAsync(targetUser);
        var result = await _userManager.ResetPasswordAsync(targetUser, resetToken, request.NewPassword);

        if (!result.Succeeded)
        {
            var errors = string.Join(", ", result.Errors.Select(e => e.Description));
            return BadRequest(new { message = errors });
        }

        return Ok(new { message = "Password reset successfully." });
    }

    /// <summary>
    /// List users that the current admin can manage passwords for.
    /// - PlatformSuperAdmin / PlatformSupport: all users
    /// - CompanyAdmin: users in their company only
    /// </summary>
    [HttpGet("manageable-users")]
    [Microsoft.AspNetCore.Authorization.Authorize]
    public async Task<IActionResult> GetManageableUsers()
    {
        var callerUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (callerUserId == null) return Unauthorized();

        var caller = await _userManager.FindByIdAsync(callerUserId);
        if (caller == null) return Unauthorized();

        var callerRoles = await _userManager.GetRolesAsync(caller);
        var isPlatformAdmin = callerRoles.Any(r =>
            r == "PlatformSuperAdmin" || r == "PlatformSupport");
        var isCompanyAdmin = callerRoles.Any(r => r == "CompanyAdmin");

        if (!isPlatformAdmin && !isCompanyAdmin)
            return Ok(Array.Empty<object>());

        IQueryable<ApplicationUser> query = _userManager.Users;

        if (isCompanyAdmin && !isPlatformAdmin && caller.CompanyId.HasValue)
            query = query.Where(u => u.CompanyId == caller.CompanyId);

        var users = await query
            .Where(u => u.Id != Guid.Parse(callerUserId)) // exclude self
            .OrderBy(u => u.Email)
            .Select(u => new { id = u.Id.ToString(), email = u.Email, companyId = u.CompanyId })
            .ToListAsync();

        return Ok(users);
    }
}

public record LoginRequest(string Email, string Password);
public record RefreshRequest(string RefreshToken);
public class VerifyPasswordRequest
{
    public string Password { get; set; } = default!;
}

public class ChangePasswordRequest
{
    public string CurrentPassword { get; set; } = default!;
    public string NewPassword { get; set; } = default!;
}

public class AdminResetPasswordRequest
{
    public string UserId { get; set; } = default!;
    public string NewPassword { get; set; } = default!;
}
