using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.API.Services.Mobile;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Companies;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Mobile;
using Microsoft.AspNetCore.Identity;
using Sumpooj.Infrastructure.Identity;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.API.Controllers.Mobile;

[Route("api/v1/mobile/auth")]
public sealed class MobileAuthController : MobileApiControllerBase
{
    private readonly IMobileClientService _mobileClientService;
    private readonly ICompanyService _companyService;
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly SumpoojDbContext _db;
    private readonly ILogger<MobileAuthController> _logger;

    public MobileAuthController(
        IMobileClientService mobileClientService,
        ITenantContext tenantContext,
        ICompanyService companyService,
        UserManager<ApplicationUser> userManager,
        SumpoojDbContext db,
        ILogger<MobileAuthController> logger)
        : base(tenantContext)
    {
        _mobileClientService = mobileClientService;
        _companyService = companyService;
        _userManager = userManager;
        _db = db;
        _logger = logger;
    }

    [AllowAnonymous]
    [HttpPost("register", Name = "MobileAuth_Register")]
    [ProducesResponseType(typeof(MobileAuthTokenResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> Register([FromBody] MobileApiRegisterRequest request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("[Mobile Register] Starting registration for email: {Email}, mobile: {Mobile}", request.Email, request.Mobile);

            if (string.IsNullOrWhiteSpace(request.CompanyName) ||
                string.IsNullOrWhiteSpace(request.OwnerName) ||
                string.IsNullOrWhiteSpace(request.Mobile) ||
                string.IsNullOrWhiteSpace(request.Email) ||
                string.IsNullOrWhiteSpace(request.Password))
            {
                throw new ArgumentException("Company name, owner name, mobile, email, and password are required.");
            }

            var email = request.Email.Trim();
            var mobile = request.Mobile.Trim();

            if (await IsDuplicateCompanyRegistrationAsync(request.CompanyName, mobile, cancellationToken))
            {
                const string message = "This company is already registered with Floraprise.";
                return Conflict(new
                {
                    error = new
                    {
                        code = "DUPLICATE_COMPANY",
                        message
                    },
                    title = "Company already registered",
                    detail = $"DUPLICATE_COMPANY: {message}",
                    errorCode = "DUPLICATE_COMPANY",
                    message
                });
            }

            if (await IsDuplicatePhoneRegistrationAsync(mobile, cancellationToken))
            {
                const string message = "Phone number already in use. Please use a different phone number.";
                return Conflict(new
                {
                    error = new
                    {
                        code = "PHONE_ALREADY_IN_USE",
                        message
                    },
                    title = "Phone number already in use",
                    detail = $"PHONE_ALREADY_IN_USE: {message}",
                    errorCode = "PHONE_ALREADY_IN_USE",
                    message
                });
            }

            if (await IsDuplicateEmailRegistrationAsync(email, cancellationToken))
            {
                const string message = "This email is already registered. Please use a different email or log in.";
                return Conflict(new
                {
                    error = new
                    {
                        code = "EMAIL_ALREADY_IN_USE",
                        message
                    },
                    title = "Email already registered",
                    detail = $"EMAIL_ALREADY_IN_USE: {message}",
                    errorCode = "EMAIL_ALREADY_IN_USE",
                    message
                });
            }

            _logger.LogInformation("[Mobile Register] Creating new company for: {CompanyName}", request.CompanyName);
            var company = new Domain.Entities.Company(
                name: request.CompanyName.Trim(),
                region: "IN",
                email: email,
                phone: mobile,
                address: string.IsNullOrWhiteSpace(request.Address) ? null : request.Address.Trim(),
                shortDescription: "Registered from mobile onboarding",
                logoPath: null,
                timeZone: "Asia/Kolkata",
                currencyCode: "INR",
                taxIdentifier: null
            );

            company.Deactivate();

            // Company + its default Location must be created atomically.
            var companyCreationStrategy = _db.Database.CreateExecutionStrategy();
            await companyCreationStrategy.ExecuteAsync(async () =>
            {
                await using var transaction = await _db.Database.BeginTransactionAsync(cancellationToken);
                _db.Companies.Add(company);
                await _db.SaveChangesAsync(cancellationToken);
                await _companyService.CreateDefaultLocationAsync(company.Id);
                await transaction.CommitAsync(cancellationToken);
            });
            var companyId = company.Id;
            _logger.LogInformation("[Mobile Register] New company created with ID: {CompanyId}", companyId);

            _logger.LogInformation("[Mobile Register] Creating ApplicationUser for email: {Email}", email);
            var user = new ApplicationUser
            {
                UserName = email,
                Email = email,
                PhoneNumber = mobile,
                CompanyId = companyId,
                EmailConfirmed = true,
                PhoneNumberConfirmed = true,
                IsActive = true,
            };

            _logger.LogInformation("[Mobile Register] Calling UserManager.CreateAsync for user: {Email}", email);
            var createResult = await _userManager.CreateAsync(user, request.Password);
            if (!createResult.Succeeded)
            {
                var errors = string.Join(", ", createResult.Errors.Select(x => x.Description));
                _logger.LogError("[Mobile Register] UserManager.CreateAsync failed for {Email}. Errors: {Errors}", email, errors);
                throw new InvalidOperationException($"User creation failed: {errors}");
            }
            _logger.LogInformation("[Mobile Register] ApplicationUser created successfully with ID: {UserId}", user.Id);

            _logger.LogInformation("[Mobile Register] Adding user to CompanyAdmin role");
            var roleResult = await _userManager.AddToRoleAsync(user, "CompanyAdmin");
            if (!roleResult.Succeeded)
            {
                var errors = string.Join(", ", roleResult.Errors.Select(x => x.Description));
                _logger.LogError("[Mobile Register] AddToRoleAsync failed for {Email}. Errors: {Errors}", email, errors);
                throw new InvalidOperationException($"Failed to add user to role: {errors}");
            }

            _logger.LogInformation("[Mobile Register] Creating MobileCustomer and MobileUser in PendingOnboarding state for: {Email}", email);
            var customer = new Domain.Entities.MobileCustomer(
                companyId: companyId,
                businessName: request.CompanyName.Trim(),
                ownerName: request.OwnerName.Trim(),
                mobile: mobile);
            customer.UpdateProfile(email, string.IsNullOrWhiteSpace(request.City) ? null : request.City.Trim(), null, "IN", user.Id);
            customer.SetCreatedBy(user.Id);
            _db.MobileCustomers.Add(customer);
            await _db.SaveChangesAsync(cancellationToken);

            var mobileUser = new Domain.Entities.MobileUser(
                companyId: companyId,
                mobileCustomerId: customer.Id,
                fullName: request.OwnerName.Trim(),
                mobile: mobile,
                email: email);
            mobileUser.SetPendingOnboarding(user.Id);
            mobileUser.SetCreatedBy(user.Id);
            _db.MobileUsers.Add(mobileUser);
            await _db.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("[Mobile Register] Registration completed in PendingOnboarding state for email: {Email}, mobileUserId: {MobileUserId}", email, mobileUser.Id);

            return Ok(new MobileApiRegisterResponse(
                Status: "PendingOnboarding",
                CompanyId: companyId,
                MobileUserId: mobileUser.Id,
                BusinessName: company.Name,
                OwnerName: request.OwnerName.Trim(),
                Mobile: mobile,
                Email: email,
                Message: "Registration submitted successfully. Your Floraprise account is awaiting activation by Central Admin."));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[Mobile Register] Registration failed for email: {Email}. Exception: {Exception}", request.Email, ex.ToString());
            return ProblemFromException(ex);
        }
    }

    private async Task<bool> IsDuplicateCompanyRegistrationAsync(
        string companyName,
        string businessPhone,
        CancellationToken cancellationToken)
    {
        var normalizedName = NormalizeCompanyName(companyName);
        var normalizedPhone = NormalizeIndianBusinessPhone(businessPhone);
        if (string.IsNullOrWhiteSpace(normalizedName) || string.IsNullOrWhiteSpace(normalizedPhone))
            return false;

        var candidates = await _db.Companies
            .AsNoTracking()
            .Where(c => c.Phone != null)
            .Select(c => new { c.Name, c.Phone })
            .ToListAsync(cancellationToken);

        return candidates.Any(c =>
            NormalizeCompanyName(c.Name) == normalizedName &&
            NormalizeIndianBusinessPhone(c.Phone) == normalizedPhone);
    }

    private async Task<bool> IsDuplicatePhoneRegistrationAsync(
        string businessPhone,
        CancellationToken cancellationToken)
    {
        var rawPhone = (businessPhone ?? string.Empty).Trim();
        var normalizedPhone = NormalizeIndianBusinessPhone(businessPhone);
        if (string.IsNullOrWhiteSpace(rawPhone) && string.IsNullOrWhiteSpace(normalizedPhone))
            return false;

        var users = await _userManager.Users
            .AsNoTracking()
            .Where(u => u.PhoneNumber != null || u.UserName != null)
            .Select(u => new { u.PhoneNumber, u.UserName })
            .ToListAsync(cancellationToken);

        return users.Any(u =>
            (!string.IsNullOrWhiteSpace(u.PhoneNumber) && (u.PhoneNumber == rawPhone || NormalizeIndianBusinessPhone(u.PhoneNumber) == normalizedPhone)) ||
            (!string.IsNullOrWhiteSpace(u.UserName) && (u.UserName == rawPhone || NormalizeIndianBusinessPhone(u.UserName) == normalizedPhone)));
    }

    private async Task<bool> IsDuplicateEmailRegistrationAsync(
        string email,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(email))
            return false;

        var normalizedEmail = email.Trim().ToLowerInvariant();
        var user = await _userManager.FindByEmailAsync(normalizedEmail);
        return user != null;
    }

    private static string NormalizeCompanyName(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
            return string.Empty;

        return new string(value
            .Trim()
            .ToLowerInvariant()
            .Where(char.IsLetterOrDigit)
            .ToArray());
    }

    private static string NormalizeIndianBusinessPhone(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
            return string.Empty;

        var digits = new string(value.Where(char.IsDigit).ToArray());
        if (digits.Length == 12 && digits.StartsWith("91", StringComparison.Ordinal))
            return digits[2..];
        if (digits.Length == 11 && digits.StartsWith("0", StringComparison.Ordinal))
            return digits[1..];

        return digits;
    }

    [AllowAnonymous]
    [HttpPost("~/api/mobile/auth/register")]
    [ProducesResponseType(typeof(MobileAuthTokenResponse), StatusCodes.Status200OK)]
    public Task<IActionResult> RegisterLegacy([FromBody] MobileApiRegisterRequest request, CancellationToken cancellationToken)
        => Register(request, cancellationToken);

    /// <summary>
    /// Authenticates a mobile user and returns access tokens plus bootstrap payload.
    /// </summary>
    /// <remarks>
    /// Request example:
    /// { "identifier": "+919876543210", "password": "StrongPassword@123", "deviceId": "android-emulator-001", "platform": "android", "appVersion": "2.7.0" }
    /// Response example:
    /// { "accessToken": "jwt", "refreshToken": "token", "expiresAtUtc": "2026-07-28T10:30:00Z" }
    /// </remarks>
    [AllowAnonymous]
    [HttpPost("login", Name = "MobileAuth_Login")]
    [ProducesResponseType(typeof(MobileAuthTokenResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> Login([FromBody] MobileApiLoginRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var response = await _mobileClientService.LoginAsync(request, cancellationToken);
            return Ok(response);
        }
        catch (UnauthorizedAccessException uex) when (uex.Message.Contains("ACCOUNT_PENDING_ACTIVATION"))
        {
            return StatusCode(StatusCodes.Status403Forbidden, new
            {
                errorCode = "ACCOUNT_PENDING_ACTIVATION",
                code = "ACCOUNT_PENDING_ACTIVATION",
                title = "Account awaiting activation",
                detail = "Your Floraprise account is awaiting activation.",
                message = "Your Floraprise account is awaiting activation."
            });
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    /// <summary>
    /// Refreshes a mobile access token using a valid refresh token.
    /// </summary>
    /// <remarks>
    /// Request example:
    /// { "refreshToken": "refresh_token_value" }
    /// Response example:
    /// { "accessToken": "jwt", "refreshToken": "token", "expiresAtUtc": "2026-07-28T10:30:00Z" }
    /// </remarks>
    [AllowAnonymous]
    [HttpPost("refresh", Name = "MobileAuth_Refresh")]
    [ProducesResponseType(typeof(MobileAuthTokenResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> Refresh([FromBody] MobileApiRefreshRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var response = await _mobileClientService.RefreshAsync(request, cancellationToken);
            return Ok(response);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    /// <summary>
    /// Revokes the active mobile session refresh token.
    /// </summary>
    /// <remarks>
    /// Requires JWT Bearer auth with CompanyOnly policy.
    /// Request example:
    /// { "refreshToken": "refresh_token_value" }
    /// </remarks>
    [Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme, Policy = PolicyNames.CompanyOnly)]
    [HttpPost("logout", Name = "MobileAuth_Logout")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Logout([FromBody] MobileApiLogoutRequest request, CancellationToken cancellationToken)
    {
        try
        {
            await _mobileClientService.LogoutAsync(GetCompanyId(), GetMobileUserId(), GetDeviceId(), request, cancellationToken);
            return NoContent();
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    /// <summary>
    /// Registers or updates the authenticated mobile device metadata.
    /// </summary>
    /// <remarks>
    /// Requires JWT Bearer auth with CompanyOnly policy.
    /// Request example:
    /// { "deviceId": "android-emulator-001", "platform": "android", "appVersion": "2.7.0" }
    /// </remarks>
    [Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme, Policy = PolicyNames.CompanyOnly)]
    [HttpPost("register-device", Name = "MobileAuth_RegisterDevice")]
    [ProducesResponseType(typeof(MobileDeviceResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> RegisterDevice([FromBody] MobileDeviceRegisterRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var response = await _mobileClientService.RegisterDeviceAsync(GetCompanyId(), GetMobileUserId(), request, cancellationToken);
            return Ok(response);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    /// <summary>
    /// Sends a heartbeat to keep the session active and validate license state.
    /// </summary>
    /// <remarks>
    /// Requires JWT Bearer auth with CompanyOnly policy.
    /// Request example:
    /// { "deviceId": "android-emulator-001", "appVersion": "2.7.0", "lastSyncUtc": "2026-07-28T09:00:00Z" }
    /// </remarks>
    [Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme, Policy = PolicyNames.CompanyOnly)]
    [HttpPost("heartbeat", Name = "MobileAuth_Heartbeat")]
    [ProducesResponseType(typeof(MobileLicenseCheckResult), StatusCodes.Status200OK)]
    public async Task<IActionResult> Heartbeat([FromBody] MobileDeviceHeartbeatRequest request, CancellationToken cancellationToken)
    {
        try
        {
            if (!string.Equals(request.DeviceId, GetDeviceId(), StringComparison.Ordinal))
                return Problem(title: "Unauthorized", detail: "Device mismatch.", statusCode: StatusCodes.Status401Unauthorized);

            var response = await _mobileClientService.HeartbeatAsync(GetCompanyId(), GetMobileUserId(), request, cancellationToken);
            return Ok(response);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    /// <summary>
    /// Requests OTP for mobile login fallback authentication.
    /// </summary>
    /// <remarks>
    /// Request example:
    /// { "mobileOrEmail": "+919876543210" }
    /// </remarks>
    [AllowAnonymous]
    [HttpPost("otp/request", Name = "MobileAuth_RequestOtp")]
    [ProducesResponseType(typeof(MobileOtpStatusResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> RequestOtp([FromBody] MobileOtpRequest request, CancellationToken cancellationToken)
    {
        var response = await _mobileClientService.RequestOtpAsync(request, cancellationToken);
        return Ok(response);
    }

    /// <summary>
    /// Verifies OTP and confirms whether login can proceed.
    /// </summary>
    /// <remarks>
    /// Request example:
    /// { "mobileOrEmail": "+919876543210", "otp": "123456" }
    /// </remarks>
    [AllowAnonymous]
    [HttpPost("otp/verify", Name = "MobileAuth_VerifyOtp")]
    [ProducesResponseType(typeof(MobileOtpStatusResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> VerifyOtp([FromBody] MobileOtpVerifyRequest request, CancellationToken cancellationToken)
    {
        var response = await _mobileClientService.VerifyOtpAsync(request, cancellationToken);
        return Ok(response);
    }
}