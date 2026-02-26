using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using Sumpooj.Application.UseCases;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Identity;
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

    public AuthController(
        UserManager<ApplicationUser> userManager,
        IConfiguration config,
        ILogger<AuthController> logger,
        AuditLogService auditLogService)
    {
        _userManager = userManager;
        _config = config;
        _logger = logger;
        _auditLogService = auditLogService;
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

                // Audit: login failed — unknown user
                var unknownIp = HttpContext.Connection.RemoteIpAddress?.ToString();
                _ = _auditLogService.LogAsync(
                    Guid.Empty, null, request.Email, null,
                    AuditActions.LoginFailed, "User", null, request.Email,
                    description: $"Login attempt for unknown email: {request.Email}",
                    ipAddress: unknownIp, requestPath: "/api/auth/login", httpMethod: "POST",
                    isSuccess: false, errorMessage: "User not found");

                return Unauthorized(new { message = "Invalid email or password" });
            }

            if (!user.IsActive)
            {
                _logger.LogWarning("User is inactive: {Email}", request.Email);

                // Audit: login failed — inactive account
                var inactiveIp = HttpContext.Connection.RemoteIpAddress?.ToString();
                _ = _auditLogService.LogAsync(
                    user.CompanyId ?? Guid.Empty, user.Id, user.Email, null,
                    AuditActions.LoginFailed, "User", user.Id, user.Email,
                    description: $"Login attempt for inactive account: {user.Email}",
                    ipAddress: inactiveIp, requestPath: "/api/auth/login", httpMethod: "POST",
                    isSuccess: false, errorMessage: "Account disabled");

                return Unauthorized(new { message = "Account is disabled" });
            }

            if (!await _userManager.CheckPasswordAsync(user, request.Password))
            {
                _logger.LogWarning("Invalid password for: {Email}", request.Email);

                // Audit: failed login
                var failIp = HttpContext.Connection.RemoteIpAddress?.ToString();
                _ = _auditLogService.LogAsync(
                    user.CompanyId ?? Guid.Empty,
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

                return Unauthorized(new { message = "Invalid email or password" });
            }

            var roles = await _userManager.GetRolesAsync(user);
            var primaryRole = roles.FirstOrDefault() ?? "Staff";
            _logger.LogInformation("User {Email} has roles: {Roles}", request.Email, string.Join(", ", roles));

            var claims = new List<Claim>
            {
                new(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
                new(JwtRegisteredClaimNames.Email, user.Email!),
                new("company_id", user.CompanyId?.ToString() ?? ""),
            };

            foreach (var role in roles)
                claims.Add(new Claim(ClaimTypes.Role, role));

            var jwtKey = _config["Jwt:Key"];
            if (string.IsNullOrEmpty(jwtKey))
            {
                _logger.LogError("JWT Key is not configured!");
                return StatusCode(500, new { message = "Server configuration error" });
            }

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));

            var token = new JwtSecurityToken(
                issuer: _config["Jwt:Issuer"],
                audience: _config["Jwt:Issuer"],
                claims: claims,
                expires: DateTime.UtcNow.AddHours(8),
                signingCredentials: new SigningCredentials(key, SecurityAlgorithms.HmacSha256)
            );

            var accessToken = new JwtSecurityTokenHandler().WriteToken(token);
            _logger.LogInformation("Login successful for: {Email}", request.Email);

            // Audit: successful login
            var ip = HttpContext.Connection.RemoteIpAddress?.ToString();
            await _auditLogService.LogAsync(
                user.CompanyId ?? Guid.Empty,
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

            // Return token + user + tenant in single response
            return Ok(new
            {
                access_token = accessToken,
                user = new
                {
                    id = user.Id.ToString(),
                    name = user.UserName,
                    email = user.Email,
                    role = primaryRole.ToUpperInvariant(),
                    primaryLocationId = (string?)null,
                    assignedLocationIds = Array.Empty<string>()
                },
                tenant = user.CompanyId.HasValue ? new
                {
                    id = user.CompanyId.Value.ToString(),
                    name = "Company",
                    slug = "company",
                    plan = "PRO",
                    subscriptionStatus = "ACTIVE",
                    country = "IN",
                    currency = "INR",
                    taxSystem = "GST",
                    dateFormat = "DD/MM/YYYY",
                    timeFormat = "12H",
                    locale = "en-IN",
                    isActive = true,
                    createdAt = DateTime.UtcNow.ToString("o")
                } : null
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Login failed for: {Email}", request.Email);
            return StatusCode(500, new { message = "An error occurred during login" });
        }
    }

    /// <summary>
    /// Get current user info from token. Used for session refresh/validation.
    /// </summary>
    [HttpGet("me")]
    [Microsoft.AspNetCore.Authorization.Authorize]
    public async Task<IActionResult> GetMe()
    {
        var userId = User.FindFirstValue(JwtRegisteredClaimNames.Sub);
        if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var userGuid))
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
            user = new
            {
                id = user.Id.ToString(),
                name = user.UserName,
                email = user.Email,
                role = primaryRole.ToUpperInvariant(),
                primaryLocationId = (string?)null,
                assignedLocationIds = Array.Empty<string>()
            },
            tenant = user.CompanyId.HasValue ? new
            {
                id = user.CompanyId.Value.ToString(),
                name = "Company",
                slug = "company",
                plan = "PRO",
                subscriptionStatus = "ACTIVE",
                country = "IN",
                currency = "INR",
                taxSystem = "GST",
                dateFormat = "DD/MM/YYYY",
                timeFormat = "12H",
                locale = "en-IN",
                isActive = true,
                createdAt = DateTime.UtcNow.ToString("o")
            } : null
        });
    }
}

public record LoginRequest(string Email, string Password);
