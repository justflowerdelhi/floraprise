using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.Extensions.Logging;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Mobile;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Identity;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.API.Services.Mobile;

public sealed class MobileClientService : IMobileClientService
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly IConfiguration _configuration;
    private readonly SumpoojDbContext _db;
    private readonly IMobileSubscriptionService _mobileSubscriptionService;
    private readonly IMobileUserRepository _mobileUsers;
    private readonly IMobileDeviceRepository _mobileDevices;
    private readonly IMobileSubscriptionRepository _mobileSubscriptions;
    private readonly IMobileLicenseRepository _mobileLicenses;
    private readonly ISubscriptionPlanRepository _subscriptionPlans;
    private readonly IMobilePaymentTransactionRepository _mobilePayments;
    private readonly IDeviceSessionRepository _deviceSessions;
    private readonly IMobileUnitOfWork _uow;
    private readonly ISubscriptionPaymentGatewayFactory _paymentGatewayFactory;
    private readonly ILogger<MobileClientService> _logger;

    public MobileClientService(
        UserManager<ApplicationUser> userManager,
        IConfiguration configuration,
        SumpoojDbContext db,
        IMobileSubscriptionService mobileSubscriptionService,
        IMobileUserRepository mobileUsers,
        IMobileDeviceRepository mobileDevices,
        IMobileSubscriptionRepository mobileSubscriptions,
        IMobileLicenseRepository mobileLicenses,
        ISubscriptionPlanRepository subscriptionPlans,
        IMobilePaymentTransactionRepository mobilePayments,
        IDeviceSessionRepository deviceSessions,
        IMobileUnitOfWork uow,
        ISubscriptionPaymentGatewayFactory paymentGatewayFactory,
        ILogger<MobileClientService> logger)
    {
        _userManager = userManager;
        _configuration = configuration;
        _db = db;
        _mobileSubscriptionService = mobileSubscriptionService;
        _mobileUsers = mobileUsers;
        _mobileDevices = mobileDevices;
        _mobileSubscriptions = mobileSubscriptions;
        _mobileLicenses = mobileLicenses;
        _subscriptionPlans = subscriptionPlans;
        _mobilePayments = mobilePayments;
        _deviceSessions = deviceSessions;
        _uow = uow;
        _paymentGatewayFactory = paymentGatewayFactory;
        _logger = logger;
    }

    public Task<MobileAuthTokenResponse> LoginAsync(MobileApiLoginRequest request, CancellationToken cancellationToken = default)
    {
        return LoginInternalAsync(request, registrationRequest: null, cancellationToken);
    }

    public Task<MobileAuthTokenResponse> LoginAsync(MobileApiLoginRequest request, RegisterMobileCustomerRequest registrationRequest, CancellationToken cancellationToken = default)
    {
        return LoginInternalAsync(request, registrationRequest, cancellationToken);
    }

    private async Task<MobileAuthTokenResponse> LoginInternalAsync(MobileApiLoginRequest request, RegisterMobileCustomerRequest? registrationRequest, CancellationToken cancellationToken)
    {
        _logger.LogInformation("[Mobile Login] Starting login for companyId: {CompanyId}, identifier: {Identifier}, deviceId: {DeviceId}", request.CompanyId, request.Identifier, request.DeviceId);

        MobileValidators.Validate(new MobileAuthLoginRequest(
            request.CompanyId,
            request.Identifier,
            request.Password,
            request.DeviceId,
            request.Platform,
            request.Manufacturer,
            request.Model,
            request.OsVersion,
            request.AppVersion,
            request.PushToken,
            request.IpAddress));

        var identifier = request.Identifier.Trim();
        _logger.LogInformation("[Mobile Login] Looking up identity user for identifier: {Identifier}, companyId: {CompanyId}", identifier, request.CompanyId);
        var identityUser = await _userManager.Users
            .Where(x => x.CompanyId == request.CompanyId)
            .Where(x => x.Email == identifier || x.UserName == identifier || x.PhoneNumber == identifier)
            .FirstOrDefaultAsync(cancellationToken);

        if (identityUser == null || !identityUser.IsActive)
        {
            _logger.LogWarning("[Mobile Login] Identity user not found or inactive for identifier: {Identifier}, companyId: {CompanyId}", identifier, request.CompanyId);
            throw new UnauthorizedAccessException("Invalid credentials.");
        }
        _logger.LogInformation("[Mobile Login] Identity user found: {UserId}", identityUser.Id);

        _logger.LogInformation("[Mobile Login] Validating password for user: {UserId}", identityUser.Id);
        var validPassword = await _userManager.CheckPasswordAsync(identityUser, request.Password);
        if (!validPassword)
        {
            _logger.LogWarning("[Mobile Login] Invalid password for user: {UserId}", identityUser.Id);
            throw new UnauthorizedAccessException("Invalid credentials.");
        }

        _logger.LogInformation("[Mobile Login] Loading company: {CompanyId}", request.CompanyId);
        var company = await _db.Companies.FirstOrDefaultAsync(x => x.Id == request.CompanyId, cancellationToken)
            ?? throw new KeyNotFoundException("Company not found.");

        var mobile = ResolveMobile(identityUser, request.Identifier);
        _logger.LogInformation("[Mobile Login] Resolved mobile number: {Mobile}", mobile);

        _logger.LogInformation("[Mobile Login] Calling RegisterOrStartTrialAsync for companyId: {CompanyId}, deviceId: {DeviceId}", request.CompanyId, request.DeviceId);
        var registration = await _mobileSubscriptionService.RegisterOrStartTrialAsync(
            registrationRequest ?? new RegisterMobileCustomerRequest(
                CompanyId: request.CompanyId,
                BusinessName: company.Name,
                OwnerName: identityUser.UserName ?? company.Name,
                Mobile: mobile,
                Email: identityUser.Email,
                City: null,
                State: null,
                Country: company.Region,
                FullName: identityUser.UserName ?? company.Name,
                DeviceId: request.DeviceId,
                Platform: request.Platform,
                Manufacturer: request.Manufacturer,
                Model: request.Model,
                OsVersion: request.OsVersion,
                AppVersion: request.AppVersion,
                PushToken: request.PushToken,
                IpAddress: request.IpAddress,
                IdentityUserId: identityUser.Id,
                ActorUserId: identityUser.Id),
            cancellationToken);
        _logger.LogInformation("[Mobile Login] RegisterOrStartTrialAsync completed. MobileUserId: {MobileUserId}, MobileDeviceId: {MobileDeviceId}", registration.MobileUserId, registration.MobileDeviceId);

        _logger.LogInformation("[Mobile Login] Managing device sessions for device: {MobileDeviceId}", registration.MobileDeviceId);
        var activeSessions = await _deviceSessions.GetActiveByDeviceAsync(request.CompanyId, registration.MobileDeviceId);
        foreach (var session in activeSessions)
            session.Logout(identityUser.Id);

        _logger.LogInformation("[Mobile Login] Creating new device session");
        var refreshToken = MobileSecurityTokens.NewToken();
        var newSession = new DeviceSession(
            companyId: request.CompanyId,
            mobileDeviceId: registration.MobileDeviceId,
            refreshToken: refreshToken,
            expiresAtUtc: DateTime.UtcNow.AddDays(30));
        newSession.SetCreatedBy(identityUser.Id);
        await _deviceSessions.AddAsync(newSession);
        await _uow.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("[Mobile Login] Generating access token");
        var expiresAtUtc = DateTime.UtcNow.AddMinutes(GetAccessTokenExpiryMinutes());
        var accessToken = GenerateAccessToken(request.CompanyId, registration.MobileUserId, request.DeviceId, expiresAtUtc);
        
        _logger.LogInformation("[Mobile Login] Loading bootstrap data");
        var bootstrap = await GetBootstrapAsync(request.CompanyId, registration.MobileUserId, request.DeviceId, cancellationToken);

        _logger.LogInformation("[Mobile Login] Login completed successfully for user: {UserId}", identityUser.Id);
        return new MobileAuthTokenResponse(
            accessToken,
            refreshToken,
            expiresAtUtc,
            request.CompanyId,
            registration.MobileUserId,
            registration.MobileDeviceId,
            bootstrap);
    }

    public async Task<MobileAuthTokenResponse> RefreshAsync(MobileApiRefreshRequest request, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.RefreshToken))
            throw new ArgumentException("Refresh token is required.", nameof(request.RefreshToken));

        var existing = await _deviceSessions.GetByRefreshTokenAsync(request.RefreshToken)
            ?? throw new UnauthorizedAccessException("Invalid refresh token.");

        if (!existing.IsActive(DateTime.UtcNow))
            throw new UnauthorizedAccessException("Refresh token expired or revoked.");

        var device = await _mobileDevices.GetByIdAsync(existing.CompanyId, existing.MobileDeviceId)
            ?? throw new UnauthorizedAccessException("Device session is invalid.");

        existing.Logout(null);

        var newRefreshToken = MobileSecurityTokens.NewToken();
        var newSession = new DeviceSession(
            companyId: existing.CompanyId,
            mobileDeviceId: existing.MobileDeviceId,
            refreshToken: newRefreshToken,
            expiresAtUtc: DateTime.UtcNow.AddDays(30));
        await _deviceSessions.AddAsync(newSession);

        await _uow.SaveChangesAsync(cancellationToken);

        var expiresAtUtc = DateTime.UtcNow.AddMinutes(GetAccessTokenExpiryMinutes());
        var accessToken = GenerateAccessToken(existing.CompanyId, device.MobileUserId, device.DeviceId, expiresAtUtc);
        var bootstrap = await GetBootstrapAsync(existing.CompanyId, device.MobileUserId, device.DeviceId, cancellationToken);

        return new MobileAuthTokenResponse(
            accessToken,
            newRefreshToken,
            expiresAtUtc,
            existing.CompanyId,
            device.MobileUserId,
            device.Id,
            bootstrap);
    }

    public async Task LogoutAsync(Guid companyId, Guid mobileUserId, string deviceId, MobileApiLogoutRequest request, CancellationToken cancellationToken = default)
    {
        if (!string.IsNullOrWhiteSpace(request.RefreshToken))
        {
            var session = await _deviceSessions.GetByRefreshTokenAsync(request.RefreshToken);
            if (session != null && session.CompanyId == companyId)
            {
                session.Logout(mobileUserId);
                await _uow.SaveChangesAsync(cancellationToken);
            }

            return;
        }

        var device = await _mobileDevices.GetByDeviceIdAsync(companyId, mobileUserId, deviceId)
            ?? throw new KeyNotFoundException("Device not found.");

        var sessions = await _deviceSessions.GetActiveByDeviceAsync(companyId, device.Id);
        foreach (var session in sessions)
            session.Logout(mobileUserId);

        await _uow.SaveChangesAsync(cancellationToken);
    }

    public Task<MobileOtpStatusResponse> RequestOtpAsync(MobileOtpRequest request, CancellationToken cancellationToken = default)
    {
        return Task.FromResult(new MobileOtpStatusResponse(false, "OTP authentication is currently disabled. SMS integration is not configured."));
    }

    public Task<MobileOtpStatusResponse> VerifyOtpAsync(MobileOtpVerifyRequest request, CancellationToken cancellationToken = default)
    {
        return Task.FromResult(new MobileOtpStatusResponse(false, "OTP verification is currently disabled. SMS integration is not configured."));
    }

    public async Task<MobileDeviceResponse> RegisterDeviceAsync(Guid companyId, Guid mobileUserId, MobileDeviceRegisterRequest request, CancellationToken cancellationToken = default)
    {
        var user = await _mobileUsers.GetByIdAsync(companyId, mobileUserId)
            ?? throw new KeyNotFoundException("Mobile user not found.");

        var customer = await _db.MobileCustomers
            .FirstOrDefaultAsync(x => x.Id == user.MobileCustomerId && x.CompanyId == companyId, cancellationToken)
            ?? throw new KeyNotFoundException("Mobile customer not found.");

        var identityUserId = await _userManager.Users
            .Where(x => x.CompanyId == companyId)
            .Where(x =>
                (!string.IsNullOrWhiteSpace(user.Email) && x.Email == user.Email) ||
                x.PhoneNumber == user.Mobile)
            .Select(x => x.Id)
            .FirstOrDefaultAsync(cancellationToken);
        if (identityUserId == Guid.Empty)
            throw new KeyNotFoundException("Identity user not found for mobile device registration.");

        var registration = await _mobileSubscriptionService.RegisterOrStartTrialAsync(
            new RegisterMobileCustomerRequest(
                companyId,
                customer.BusinessName,
                customer.OwnerName,
                user.Mobile,
                user.Email,
                customer.City,
                customer.State,
                customer.Country,
                user.FullName,
                request.DeviceId,
                request.Platform,
                request.Manufacturer,
                request.Model,
                request.OsVersion,
                request.AppVersion,
                request.PushToken,
                request.IpAddress,
                identityUserId,
                identityUserId),
            cancellationToken);

        var device = await _mobileDevices.GetByIdAsync(companyId, registration.MobileDeviceId)
            ?? throw new KeyNotFoundException("Device could not be loaded.");

        return ToDeviceResponse(device, request.DeviceId);
    }

    public Task<MobileLicenseCheckResult> HeartbeatAsync(Guid companyId, Guid mobileUserId, MobileDeviceHeartbeatRequest request, CancellationToken cancellationToken = default)
    {
        return _mobileSubscriptionService.HeartbeatAsync(
            new MobileHeartbeatRequest(
                CompanyId: companyId,
                MobileUserId: mobileUserId,
                DeviceId: request.DeviceId,
                AppVersion: request.AppVersion,
                IpAddress: request.IpAddress,
                LastSyncUtc: request.LastSyncUtc,
                ActorUserId: mobileUserId),
            cancellationToken);
    }

    public async Task<MobileBootstrapResponse> GetBootstrapAsync(Guid companyId, Guid mobileUserId, string deviceId, CancellationToken cancellationToken = default)
    {
        var company = await _db.Companies.AsNoTracking().FirstOrDefaultAsync(x => x.Id == companyId, cancellationToken)
            ?? throw new KeyNotFoundException("Company not found.");

        var user = await _db.MobileUsers
            .AsNoTracking()
            .Include(x => x.Subscription)
                .ThenInclude(x => x!.SubscriptionPlan)
            .Include(x => x.Subscription)
                .ThenInclude(x => x!.FeatureEntitlements)
            .FirstOrDefaultAsync(x => x.CompanyId == companyId && x.Id == mobileUserId && !x.IsDeleted, cancellationToken)
            ?? throw new KeyNotFoundException("Mobile user not found.");

        var device = await _mobileDevices.GetByDeviceIdAsync(companyId, mobileUserId, deviceId)
            ?? throw new KeyNotFoundException("Device not found.");

        var license = await _mobileLicenses.GetByDeviceIdAsync(companyId, device.Id)
            ?? throw new KeyNotFoundException("License not found.");

        var subscription = user.Subscription
            ?? throw new KeyNotFoundException("Subscription not found.");

        var licenseState = await _mobileSubscriptionService.CheckLicenseAsync(
            new MobileLicenseCheckRequest(
                CompanyId: companyId,
                MobileUserId: mobileUserId,
                DeviceId: deviceId,
                AppVersion: device.AppVersion,
                IpAddress: device.LastIpAddress,
                LastSyncUtc: device.LastSyncAtUtc,
                ActorUserId: mobileUserId),
            cancellationToken);

        var branches = await _db.Locations
            .AsNoTracking()
            .Where(x => x.CompanyId == companyId && x.IsActive)
            .OrderByDescending(x => x.IsDefault)
            .ThenBy(x => x.Name)
            .Select(x => new MobileBootstrapBranchDto(Id: x.Id, Name: x.Name, Code: x.Code, IsDefault: x.IsDefault))
            .ToListAsync(cancellationToken);

        var permissions = ParsePermissions(subscription.SubscriptionPlan?.IncludedModulesJson);
        var featureFlags = subscription.FeatureEntitlements
            .Select(x => new MobileFeatureFlagDto(Key: x.FeatureKey, Enabled: x.IsEnabled))
            .ToList();

        if (featureFlags.Count == 0)
        {
            featureFlags = permissions.Select(x => new MobileFeatureFlagDto(Key: x, Enabled: true)).ToList();
        }

        var latestVersion = _configuration["MobileClient:LatestAppVersion"] ?? device.AppVersion;
        var minimumSupported = _configuration["MobileClient:MinimumSupportedVersion"] ?? device.AppVersion;
        var forceUpdate = bool.TryParse(_configuration["MobileClient:ForceUpdate"], out var force) && force;

        var printer = new MobileBootstrapPrinterSettingsDto(
            AutoPrintInvoice: bool.TryParse(_configuration["MobileClient:Printer:AutoPrintInvoice"], out var autoInvoice) && autoInvoice,
            AutoPrintKot: bool.TryParse(_configuration["MobileClient:Printer:AutoPrintKot"], out var autoKot) && autoKot,
            Copies: int.TryParse(_configuration["MobileClient:Printer:Copies"], out var copies) ? Math.Max(1, copies) : 1,
            PaperSize: _configuration["MobileClient:Printer:PaperSize"] ?? "80mm",
            PreferredPrinter: _configuration["MobileClient:Printer:PreferredPrinter"]);

        var trialRemaining = subscription.Status == MobileSubscriptionStatus.Trial
            ? Math.Max(0, (int)Math.Ceiling((subscription.TrialEndUtc - DateTime.UtcNow).TotalDays))
            : 0;

        var bootstrapPayload = new MobileBootstrapResponse(
            Company: new MobileBootstrapCompanyDto(
                Id: company.Id,
                Name: company.Name,
                Currency: company.CurrencyCode,
                Region: company.Region,
                TimeZone: company.TimeZone,
                TaxIdentifier: company.TaxIdentifier),
            User: new MobileBootstrapUserDto(
                Id: user.Id,
                FullName: user.FullName,
                Mobile: user.Mobile,
                Email: user.Email,
                Status: user.Status),
            Branches: branches,
            Subscription: new MobileBootstrapSubscriptionDto(
                Id: subscription.Id,
                PlanCode: subscription.SubscriptionPlan?.Code ?? "MOBILE_TRIAL",
                PlanName: subscription.SubscriptionPlan?.Name ?? "Mobile Trial",
                Status: subscription.Status,
                AutoRenew: subscription.AutoRenew,
                StartUtc: subscription.StartUtc,
                EndUtc: subscription.EndUtc,
                GraceEndUtc: subscription.GraceEndUtc,
                RemainingDays: licenseState.RemainingDays,
                OfflineValidationDays: subscription.SubscriptionPlan?.OfflineDays ?? 0,
                GraceDays: subscription.SubscriptionPlan?.GraceDays ?? 0),
            License: new MobileBootstrapLicenseDto(
                Id: license.Id,
                Status: licenseState.LicenseStatus,
                IssuedAtUtc: license.IssuedAtUtc,
                ExpiryUtc: licenseState.ExpiryUtc,
                AllowsAccess: licenseState.AllowsAccess,
                DeviceId: device.DeviceId),
            Trial: new MobileBootstrapTrialDto(
                IsTrial: subscription.Status == MobileSubscriptionStatus.Trial,
                TrialStartUtc: subscription.Status == MobileSubscriptionStatus.Trial ? subscription.TrialStartUtc : null,
                TrialEndUtc: subscription.Status == MobileSubscriptionStatus.Trial ? subscription.TrialEndUtc : null,
                RemainingDays: trialRemaining,
                IsExpired: subscription.Status == MobileSubscriptionStatus.Trial && trialRemaining == 0),
            TaxSettings: new MobileBootstrapTaxSettingsDto(
                TaxSystem: string.IsNullOrWhiteSpace(company.TaxIdentifier) ? "NONE" : "GST",
                TaxIdentifier: company.TaxIdentifier,
                TaxEnabled: !string.IsNullOrWhiteSpace(company.TaxIdentifier)),
            PrinterSettings: printer,
            Permissions: permissions,
            Language: user.PreferredLanguage,
            Theme: user.PreferredTheme,
            AppVersion: latestVersion,
            MinimumSupportedVersion: minimumSupported,
            ForceUpdate: forceUpdate || IsVersionLower(device.AppVersion, minimumSupported),
            FeatureFlags: featureFlags,
            GeneratedAtUtc: DateTime.UtcNow);

        return bootstrapPayload;
    }

    public async Task<MobileSubscriptionStateResponse> GetCurrentSubscriptionAsync(Guid companyId, Guid mobileUserId, CancellationToken cancellationToken = default)
    {
        var subscription = await GetSubscriptionEntityAsync(companyId, mobileUserId, cancellationToken);
        return ToSubscriptionState(subscription);
    }

    public Task<List<MobileSubscriptionPlanDto>> GetAvailablePlansAsync(CancellationToken cancellationToken = default)
        => _mobileSubscriptionService.GetActivePlansAsync(cancellationToken);

    public Task<MobileSubscriptionActionResponse> UpgradeAsync(Guid companyId, Guid mobileUserId, MobilePlanChangeRequest request, CancellationToken cancellationToken = default)
        => ChangePlanInternalAsync(companyId, mobileUserId, request, "upgrade", cancellationToken);

    public Task<MobileSubscriptionActionResponse> DowngradeAsync(Guid companyId, Guid mobileUserId, MobilePlanChangeRequest request, CancellationToken cancellationToken = default)
        => ChangePlanInternalAsync(companyId, mobileUserId, request, "downgrade", cancellationToken);

    public async Task<MobileSubscriptionActionResponse> CancelAsync(Guid companyId, Guid mobileUserId, CancellationToken cancellationToken = default)
    {
        var subscription = await GetSubscriptionEntityAsync(companyId, mobileUserId, cancellationToken);
        subscription.Cancel(mobileUserId);
        await _uow.SaveChangesAsync(cancellationToken);
        return new MobileSubscriptionActionResponse(Action: "cancel", Subscription: ToSubscriptionState(subscription));
    }

    public async Task<MobileSubscriptionActionResponse> RenewAsync(Guid companyId, Guid mobileUserId, MobileRenewRequest request, CancellationToken cancellationToken = default)
    {
        var subscription = await GetSubscriptionEntityAsync(companyId, mobileUserId, cancellationToken);

        if (subscription.AutoRenew != request.AutoRenew && subscription.EndUtc.HasValue)
        {
            var start = subscription.StartUtc ?? DateTime.UtcNow;
            subscription.Activate(start, subscription.EndUtc.Value, request.AutoRenew, mobileUserId);
        }

        await _uow.SaveChangesAsync(cancellationToken);
        return new MobileSubscriptionActionResponse(Action: "renew", Subscription: ToSubscriptionState(subscription));
    }

    public async Task<MobileTrialStatusResponse> GetTrialStatusAsync(Guid companyId, Guid mobileUserId, CancellationToken cancellationToken = default)
    {
        var subscription = await GetSubscriptionEntityAsync(companyId, mobileUserId, cancellationToken);
        var isTrial = subscription.Status == MobileSubscriptionStatus.Trial;
        var remaining = isTrial ? Math.Max(0, (int)Math.Ceiling((subscription.TrialEndUtc - DateTime.UtcNow).TotalDays)) : 0;
        return new MobileTrialStatusResponse(
            IsTrial: isTrial,
            IsExpired: isTrial && remaining == 0,
            TrialEndUtc: isTrial ? subscription.TrialEndUtc : null,
            RemainingDays: remaining);
    }

    public async Task<MobileGraceStatusResponse> GetGraceStatusAsync(Guid companyId, Guid mobileUserId, CancellationToken cancellationToken = default)
    {
        var subscription = await GetSubscriptionEntityAsync(companyId, mobileUserId, cancellationToken);
        var inGrace = subscription.Status == MobileSubscriptionStatus.Grace && subscription.GraceEndUtc.HasValue;
        var days = inGrace
            ? Math.Max(0, (int)Math.Ceiling((subscription.GraceEndUtc!.Value - DateTime.UtcNow).TotalDays))
            : 0;
        return new MobileGraceStatusResponse(
            InGrace: inGrace,
            GraceEndUtc: subscription.GraceEndUtc,
            RemainingGraceDays: days);
    }

    public async Task<MobileDeviceResponse> GetCurrentDeviceAsync(Guid companyId, Guid mobileUserId, string deviceId, CancellationToken cancellationToken = default)
    {
        var device = await _mobileDevices.GetByDeviceIdAsync(companyId, mobileUserId, deviceId)
            ?? throw new KeyNotFoundException("Device not found.");
        return ToDeviceResponse(device, deviceId);
    }

    public async Task<List<MobileDeviceResponse>> GetDevicesAsync(Guid companyId, Guid mobileUserId, string currentDeviceId, CancellationToken cancellationToken = default)
    {
        var devices = await _db.MobileDevices
            .AsNoTracking()
            .Where(x => x.CompanyId == companyId && x.MobileUserId == mobileUserId && !x.IsDeleted)
            .OrderByDescending(x => x.LastLoginAtUtc)
            .ToListAsync(cancellationToken);

        return devices.Select(x => ToDeviceResponse(x, currentDeviceId)).ToList();
    }

    public async Task<MobileDeviceResponse> UpdateLastSyncAsync(Guid companyId, Guid mobileUserId, string deviceId, MobileDeviceLastSyncRequest request, CancellationToken cancellationToken = default)
    {
        var device = await _mobileDevices.GetByDeviceIdAsync(companyId, mobileUserId, deviceId)
            ?? throw new KeyNotFoundException("Device not found.");

        device.UpdateHeartbeat(device.AppVersion, request.IpAddress, request.LastSyncUtc, mobileUserId);
        await _uow.SaveChangesAsync(cancellationToken);
        return ToDeviceResponse(device, deviceId);
    }

    public async Task<MobileDeviceResponse> UpdatePushTokenAsync(Guid companyId, Guid mobileUserId, string deviceId, MobileDevicePushTokenRequest request, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.PushToken))
            throw new ArgumentException("Push token is required.", nameof(request.PushToken));

        var device = await _mobileDevices.GetByDeviceIdAsync(companyId, mobileUserId, deviceId)
            ?? throw new KeyNotFoundException("Device not found.");

        if (!string.IsNullOrWhiteSpace(request.AppVersion))
        {
            device.UpdateHeartbeat(request.AppVersion!, device.LastIpAddress, device.LastSyncAtUtc, mobileUserId);
        }
        device.UpdatePushToken(request.PushToken, mobileUserId);

        await _uow.SaveChangesAsync(cancellationToken);
        return ToDeviceResponse(device, deviceId);
    }

    public async Task<MobileLicenseStatusResponse> ValidateLicenseAsync(Guid companyId, Guid mobileUserId, MobileLicenseValidateRequest request, CancellationToken cancellationToken = default)
    {
        var result = await _mobileSubscriptionService.CheckLicenseAsync(
            new MobileLicenseCheckRequest(
                CompanyId: companyId,
                MobileUserId: mobileUserId,
                DeviceId: request.DeviceId,
                AppVersion: request.AppVersion,
                IpAddress: request.IpAddress,
                LastSyncUtc: request.LastSyncUtc,
                ActorUserId: mobileUserId),
            cancellationToken);

        return ToLicenseStatusResponse(result, request.LastSyncUtc);
    }

    public async Task<MobileLicenseStatusResponse> GetLicenseStatusAsync(Guid companyId, Guid mobileUserId, string deviceId, CancellationToken cancellationToken = default)
    {
        var device = await _mobileDevices.GetByDeviceIdAsync(companyId, mobileUserId, deviceId)
            ?? throw new KeyNotFoundException("Device not found.");

        var result = await _mobileSubscriptionService.CheckLicenseAsync(
            new MobileLicenseCheckRequest(
                CompanyId: companyId,
                MobileUserId: mobileUserId,
                DeviceId: deviceId,
                AppVersion: device.AppVersion,
                IpAddress: device.LastIpAddress,
                LastSyncUtc: device.LastSyncAtUtc,
                ActorUserId: mobileUserId),
            cancellationToken);

        return ToLicenseStatusResponse(result, device.LastSyncAtUtc);
    }

    public async Task<MobileOfflineValidationResponse> GetOfflineValidationStatusAsync(Guid companyId, Guid mobileUserId, string deviceId, CancellationToken cancellationToken = default)
    {
        var subscription = await GetSubscriptionEntityAsync(companyId, mobileUserId, cancellationToken);
        var device = await _mobileDevices.GetByDeviceIdAsync(companyId, mobileUserId, deviceId)
            ?? throw new KeyNotFoundException("Device not found.");

        var allowedDays = subscription.SubscriptionPlan?.OfflineDays ?? 0;
        var lastSync = device.LastSyncAtUtc;
        var since = lastSync.HasValue
            ? Math.Max(0, (int)Math.Floor((DateTime.UtcNow - lastSync.Value).TotalDays))
            : int.MaxValue;
        var valid = lastSync.HasValue && since <= allowedDays;

        return new MobileOfflineValidationResponse(valid, lastSync, allowedDays, since == int.MaxValue ? allowedDays + 1 : since);
    }

    public async Task<MobileDeviceAuthorizationResponse> AuthorizeDeviceAsync(Guid companyId, Guid mobileUserId, string deviceId, string requestedDeviceId, CancellationToken cancellationToken = default)
    {
        if (!string.Equals(deviceId, requestedDeviceId, StringComparison.Ordinal))
        {
            return new MobileDeviceAuthorizationResponse(requestedDeviceId, false, "Device ID does not match authenticated device.");
        }

        var device = await _mobileDevices.GetByDeviceIdAsync(companyId, mobileUserId, requestedDeviceId);
        if (device == null)
            return new MobileDeviceAuthorizationResponse(requestedDeviceId, false, "Device is not registered.");

        if (device.Status != MobileDeviceStatus.Active)
            return new MobileDeviceAuthorizationResponse(requestedDeviceId, false, $"Device is {device.Status}.");

        var license = await _mobileLicenses.GetByDeviceIdAsync(companyId, device.Id);
        if (license == null || license.Status != MobileLicenseStatus.Active)
            return new MobileDeviceAuthorizationResponse(requestedDeviceId, false, "License is not active for this device.");

        return new MobileDeviceAuthorizationResponse(requestedDeviceId, true, "Authorized");
    }

    public async Task<CreateSubscriptionOrderResponse> CreateSubscriptionOrderAsync(Guid companyId, Guid mobileUserId, CreateSubscriptionOrderRequest request, CancellationToken cancellationToken = default)
    {
        var subscription = await GetSubscriptionEntityAsync(companyId, mobileUserId, cancellationToken);
        if (subscription.Id != request.SubscriptionId)
            throw new UnauthorizedAccessException("Subscription does not belong to the authenticated user.");

        var targetPlanCode = string.IsNullOrWhiteSpace(request.PlanCode)
            ? subscription.SubscriptionPlan?.Code ?? string.Empty
            : request.PlanCode.Trim().ToUpperInvariant();
        var targetPlan = await _subscriptionPlans.GetByCodeAsync(targetPlanCode)
            ?? throw new KeyNotFoundException($"Subscription plan '{targetPlanCode}' not found.");

        if (!targetPlan.IsActive || targetPlan.IsDeleted)
            throw new InvalidOperationException("Selected subscription plan is not active.");

        var serverAmount = ResolvePlanAmount(targetPlan, request.BillingCycle);
        var serverRequest = request with
        {
            Amount = serverAmount,
            PlanCode = targetPlan.Code,
            Currency = string.IsNullOrWhiteSpace(request.Currency) ? "INR" : request.Currency.Trim().ToUpperInvariant()
        };

        var gateway = _paymentGatewayFactory.Resolve(serverRequest.Gateway);
        var (gatewayOrderId, clientPayload) = await gateway.CreateOrderAsync(serverRequest, cancellationToken);

        var txRef = $"MOB-{DateTime.UtcNow:yyyyMMddHHmmss}-{Random.Shared.Next(1000, 9999)}";
        var paymentType = subscription.Status is MobileSubscriptionStatus.Active or MobileSubscriptionStatus.Grace
            ? (string.Equals(subscription.SubscriptionPlan?.Code, request.PlanCode, StringComparison.OrdinalIgnoreCase)
                ? MobilePaymentType.Renewal
                : MobilePaymentType.Upgrade)
            : MobilePaymentType.Purchase;

        var tx = new MobilePaymentTransaction(
            companyId: companyId,
            mobileSubscriptionId: subscription.Id,
            paymentType: paymentType,
            transactionRef: txRef,
            amount: serverRequest.Amount,
            currency: serverRequest.Currency);
        tx.SetGatewayOrder(gatewayOrderId, mobileUserId);
        tx.SetCreatedBy(mobileUserId);

        await _mobilePayments.AddAsync(tx);
        await _uow.SaveChangesAsync(cancellationToken);

        var orderPayload = new Dictionary<string, string>(clientPayload)
        {
            ["transactionId"] = tx.Id.ToString(),
            ["transactionRef"] = tx.TransactionRef,
            ["gateway"] = serverRequest.Gateway.ToString().ToLowerInvariant(),
            ["paymentStatus"] = tx.PaymentStatus.ToString(),
            ["orderId"] = gatewayOrderId,
            ["amount"] = tx.Amount.ToString("0.00"),
            ["currency"] = tx.Currency,
            ["gatewayOrderId"] = gatewayOrderId
        };

        return new CreateSubscriptionOrderResponse(
            TransactionId: tx.Id,
            TransactionRef: tx.TransactionRef,
            Gateway: serverRequest.Gateway,
            GatewayOrderId: gatewayOrderId,
            PaymentStatus: tx.PaymentStatus.ToString(),
            Amount: tx.Amount,
            Currency: tx.Currency,
            ClientPayload: orderPayload);
    }

    public async Task<PaymentCallbackResponse> PaymentCallbackAsync(Guid companyId, Guid mobileUserId, PaymentCallbackRequest request, CancellationToken cancellationToken = default)
    {
        var tx = await _db.MobilePaymentTransactions
            .FirstOrDefaultAsync(
                x => (companyId == Guid.Empty || x.CompanyId == companyId) && !x.IsDeleted &&
                (
                    x.TransactionRef == request.TransactionRef ||
                    (!string.IsNullOrWhiteSpace(request.GatewayOrderId) && x.GatewayOrderId == request.GatewayOrderId)
                ),
                cancellationToken)
            ?? throw new KeyNotFoundException("Transaction not found.");

        var effectiveCompanyId = companyId == Guid.Empty ? tx.CompanyId : companyId;

        var gateway = _paymentGatewayFactory.Resolve(request.Gateway);
        var normalized = await gateway.NormalizeCallbackStatusAsync(request, cancellationToken);
        var wasAlreadyPaid = tx.PaymentStatus == MobilePaymentStatus.Paid;
        if (wasAlreadyPaid && string.Equals(normalized, "paid", StringComparison.OrdinalIgnoreCase))
            return new PaymentCallbackResponse(tx.TransactionRef, tx.PaymentStatus.ToString(), false, "Already Processed");

        ApplyPaymentStatus(tx, normalized, request.GatewayOrderId, request.GatewayPaymentId, mobileUserId);
        if (string.Equals(normalized, "paid", StringComparison.OrdinalIgnoreCase) && !wasAlreadyPaid)
        {
            await ApplyVerifiedSubscriptionChangeAsync(
                effectiveCompanyId,
                mobileUserId,
                tx,
                new PaymentVerificationRequest(
                    request.Gateway,
                    tx.TransactionRef,
                    request.GatewayOrderId,
                    request.GatewayPaymentId ?? string.Empty,
                    request.Signature,
                    request.PlanCode,
                    request.BillingCycle),
                cancellationToken);
        }
        await _uow.SaveChangesAsync(cancellationToken);

        return new PaymentCallbackResponse(tx.TransactionRef, tx.PaymentStatus.ToString(), true);
    }

    public async Task<PaymentVerificationResponse> VerifyPaymentAsync(Guid companyId, Guid mobileUserId, PaymentVerificationRequest request, CancellationToken cancellationToken = default)
    {
        var tx = await _db.MobilePaymentTransactions
            .FirstOrDefaultAsync(x => x.CompanyId == companyId && x.TransactionRef == request.TransactionRef && !x.IsDeleted, cancellationToken)
            ?? throw new KeyNotFoundException("Transaction not found.");

        if (tx.PaymentStatus == MobilePaymentStatus.Paid)
            return new PaymentVerificationResponse(tx.TransactionRef, true, tx.PaymentStatus.ToString().ToLowerInvariant(), "Already Processed");

        var gateway = _paymentGatewayFactory.Resolve(request.Gateway);
        var verified = await gateway.VerifyPaymentAsync(request, cancellationToken);

        if (verified)
        {
            var wasAlreadyPaid = tx.PaymentStatus == MobilePaymentStatus.Paid;
            if (!wasAlreadyPaid)
            {
                tx.MarkPaid(request.GatewayOrderId, request.GatewayPaymentId, mobileUserId);
                await ApplyVerifiedSubscriptionChangeAsync(companyId, mobileUserId, tx, request, cancellationToken);
            }
        }
        else
        {
            tx.MarkFailed("Payment verification failed.", mobileUserId);
        }

        await _uow.SaveChangesAsync(cancellationToken);
        return new PaymentVerificationResponse(tx.TransactionRef, verified, tx.PaymentStatus.ToString().ToLowerInvariant());
    }

    private async Task ApplyVerifiedSubscriptionChangeAsync(
        Guid companyId,
        Guid mobileUserId,
        MobilePaymentTransaction tx,
        PaymentVerificationRequest request,
        CancellationToken cancellationToken)
    {
        var subscription = await _db.MobileSubscriptions
            .Include(x => x.SubscriptionPlan)
            .FirstOrDefaultAsync(x => x.CompanyId == companyId && x.Id == tx.MobileSubscriptionId && !x.IsDeleted, cancellationToken)
            ?? throw new KeyNotFoundException("Subscription not found for payment transaction.");

        var requestedPlanCode = string.IsNullOrWhiteSpace(request.PlanCode)
            ? subscription.SubscriptionPlan?.Code ?? "ANNUAL"
            : request.PlanCode.Trim().ToUpperInvariant();

        var targetPlan = await _subscriptionPlans.GetByCodeAsync(requestedPlanCode)
            ?? throw new KeyNotFoundException($"Subscription plan '{requestedPlanCode}' not found.");

        if (!targetPlan.IsActive || targetPlan.IsDeleted)
            throw new InvalidOperationException("Selected subscription plan is not active.");

        if (!PaymentMatchesPlanPrice(targetPlan, request.BillingCycle, tx.Amount))
            throw new InvalidOperationException("Payment amount does not match the selected subscription plan.");

        if (subscription.SubscriptionPlanId != targetPlan.Id)
            subscription.ChangePlan(targetPlan.Id, mobileUserId);

        var months = BillingCycleToMonths(request.BillingCycle ?? "annual");
        var start = subscription.EndUtc.HasValue && subscription.EndUtc > DateTime.UtcNow
            ? subscription.EndUtc.Value
            : DateTime.UtcNow;
        var end = start.AddMonths(months);

        subscription.Activate(start, end, true, mobileUserId);
        subscription.MarkValidated(DateTime.UtcNow, mobileUserId);

        var licenses = await _db.MobileLicenses
            .Where(x => x.CompanyId == companyId && x.MobileSubscriptionId == subscription.Id && !x.IsDeleted)
            .ToListAsync(cancellationToken);

        foreach (var license in licenses)
        {
            license.Activate(mobileUserId);
            license.SetExpiry(end, mobileUserId);
        }
    }

    private static bool PaymentMatchesPlanPrice(SubscriptionPlan plan, string? billingCycle, decimal amount)
    {
        var expected = ResolvePlanAmount(plan, billingCycle);
        return decimal.Round(expected, 2) == decimal.Round(amount, 2);
    }

    private static decimal ResolvePlanAmount(SubscriptionPlan plan, string? billingCycle)
    {
        var normalizedCycle = (billingCycle ?? string.Empty).Trim().ToLowerInvariant();
        if (normalizedCycle is "quarterly" or "half-yearly" or "halfyearly" or "annual" or "yearly")
        {
            return plan.AnnualPrice;
        }

        return plan.MonthlyPrice > 0 ? plan.MonthlyPrice : plan.AnnualPrice;
    }

    public async Task<List<MobilePaymentHistoryItem>> GetPaymentHistoryAsync(Guid companyId, Guid mobileUserId, CancellationToken cancellationToken = default)
    {
        var subscription = await GetSubscriptionEntityAsync(companyId, mobileUserId, cancellationToken);
        var items = await _mobilePayments.GetBySubscriptionAsync(companyId, subscription.Id);
        return items.Select(x => new MobilePaymentHistoryItem(
            Id: x.Id,
            TransactionRef: x.TransactionRef,
            PaymentType: x.PaymentType,
            PaymentStatus: x.PaymentStatus,
            Amount: x.Amount,
            Currency: x.Currency,
            CreatedAtUtc: x.CreatedAtUtc,
            PaidAtUtc: x.PaidAtUtc,
            GatewayOrderId: x.GatewayOrderId,
            GatewayPaymentId: x.GatewayPaymentId,
            FailureReason: x.FailureReason)).ToList();
    }

    private async Task<MobileSubscriptionActionResponse> ChangePlanInternalAsync(Guid companyId, Guid mobileUserId, MobilePlanChangeRequest request, string action, CancellationToken cancellationToken)
    {
        var subscription = await GetSubscriptionEntityAsync(companyId, mobileUserId, cancellationToken);
        var targetPlan = await _subscriptionPlans.GetByIdAsync(request.PlanId)
            ?? throw new KeyNotFoundException("Subscription plan not found.");

        if (!targetPlan.IsActive || targetPlan.IsDeleted)
            throw new InvalidOperationException("Subscription plan is not active.");

        subscription.ChangePlan(targetPlan.Id, mobileUserId);

        var months = BillingCycleToMonths(request.BillingCycle);
        var start = subscription.EndUtc.HasValue && subscription.EndUtc > DateTime.UtcNow
            ? subscription.EndUtc.Value
            : DateTime.UtcNow;
        var end = start.AddMonths(months);
        subscription.Activate(start, end, true, mobileUserId);

        await _uow.SaveChangesAsync(cancellationToken);
        return new MobileSubscriptionActionResponse(Action: action, Subscription: ToSubscriptionState(subscription));
    }

    private async Task<MobileSubscription> GetSubscriptionEntityAsync(Guid companyId, Guid mobileUserId, CancellationToken cancellationToken)
    {
        var subscription = await _db.MobileSubscriptions
            .Include(x => x.SubscriptionPlan)
            .FirstOrDefaultAsync(x => x.CompanyId == companyId && x.MobileUserId == mobileUserId && !x.IsDeleted, cancellationToken)
            ?? await CreateTrialSubscriptionAsync(companyId, mobileUserId, cancellationToken);

        return subscription;
    }

    private async Task<MobileSubscription> CreateTrialSubscriptionAsync(Guid companyId, Guid mobileUserId, CancellationToken cancellationToken)
    {
        var user = await _mobileUsers.GetByIdAsync(companyId, mobileUserId)
            ?? throw new KeyNotFoundException("Mobile user not found.");

        var trialPlan = await _subscriptionPlans.GetByCodeAsync("MOBILE_TRIAL")
            ?? throw new KeyNotFoundException("Trial subscription plan not found.");

        var now = DateTime.UtcNow;
        var trialEnd = now.AddDays(Math.Max(1, trialPlan.TrialDays));

        var subscription = new MobileSubscription(
            companyId: companyId,
            mobileUserId: mobileUserId,
            subscriptionPlanId: trialPlan.Id,
            trialStartUtc: now,
            trialEndUtc: trialEnd);
        subscription.SetCreatedBy(user.Id);

        await _mobileSubscriptions.AddAsync(subscription);
        await _uow.SaveChangesAsync(cancellationToken);

        return subscription;
    }

    private static MobileSubscriptionStateResponse ToSubscriptionState(MobileSubscription subscription)
    {
        var expiry = subscription.Status == MobileSubscriptionStatus.Trial
            ? subscription.TrialEndUtc
            : subscription.EndUtc;

        var remaining = expiry.HasValue
            ? Math.Max(0, (int)Math.Ceiling((expiry.Value - DateTime.UtcNow).TotalDays))
            : 0;

        // Determine the correct status based on expiry date
        var correctStatus = subscription.Status;
        if (expiry.HasValue)
        {
            if (expiry.Value <= DateTime.UtcNow)
            {
                // Subscription has expired
                correctStatus = MobileSubscriptionStatus.Expired;
            }
            else if (subscription.Status == MobileSubscriptionStatus.Expired)
            {
                // Status is Expired but expiry is in the future - should be Active
                correctStatus = MobileSubscriptionStatus.Active;
            }
        }

        return new MobileSubscriptionStateResponse(
            SubscriptionId: subscription.Id,
            PlanCode: subscription.SubscriptionPlan?.Code ?? "MOBILE_TRIAL",
            PlanName: subscription.SubscriptionPlan?.Name ?? "Mobile Trial",
            Status: correctStatus,
            IsTrial: subscription.Status == MobileSubscriptionStatus.Trial,
            TrialEndUtc: subscription.Status == MobileSubscriptionStatus.Trial ? subscription.TrialEndUtc : null,
            EndUtc: subscription.EndUtc,
            GraceEndUtc: subscription.GraceEndUtc,
            RemainingDays: remaining,
            OfflineValidationDays: subscription.SubscriptionPlan?.OfflineDays ?? 0,
            GraceDays: subscription.SubscriptionPlan?.GraceDays ?? 0,
            AutoRenew: subscription.AutoRenew);
    }

    private static MobileDeviceResponse ToDeviceResponse(MobileDevice device, string currentDeviceId)
    {
        return new MobileDeviceResponse(
            Id: device.Id,
            DeviceId: device.DeviceId,
            Platform: device.Platform,
            Manufacturer: device.Manufacturer,
            Model: device.Model,
            OsVersion: device.OsVersion,
            AppVersion: device.AppVersion,
            PushToken: device.PushToken,
            Status: device.Status,
            device.LastLoginAtUtc,
            device.LastHeartbeatAtUtc,
            device.LastSyncAtUtc,
            device.LastIpAddress,
            string.Equals(device.DeviceId, currentDeviceId, StringComparison.Ordinal));
    }

    private static MobileLicenseStatusResponse ToLicenseStatusResponse(MobileLicenseCheckResult result, DateTime? lastSyncUtc)
    {
        var since = lastSyncUtc.HasValue
            ? Math.Max(0, (int)Math.Floor((DateTime.UtcNow - lastSyncUtc.Value).TotalDays))
            : int.MaxValue;

        var offlineValid = lastSyncUtc.HasValue && since <= result.OfflineValidationDays;

        return new MobileLicenseStatusResponse(
            LicenseStatus: result.LicenseStatus,
            SubscriptionStatus: result.SubscriptionStatus,
            PlanCode: result.PlanCode,
            ExpiryUtc: result.ExpiryUtc,
            RemainingDays: result.RemainingDays,
            OfflineValid: offlineValid,
            OfflineValidationDays: result.OfflineValidationDays,
            GraceDays: result.GraceDays,
            AllowsAccess: result.AllowsAccess);
    }

    private string GenerateAccessToken(Guid companyId, Guid mobileUserId, string deviceId, DateTime expiresAtUtc)
    {
        var jwtKey = _configuration["Jwt:Key"] ?? throw new InvalidOperationException("JWT Key is missing.");
        var jwtIssuer = _configuration["Jwt:Issuer"] ?? throw new InvalidOperationException("JWT Issuer is missing.");

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, mobileUserId.ToString()),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString("N")),
            new("company_id", companyId.ToString()),
            new("mobile_user_id", mobileUserId.ToString()),
            new("device_id", deviceId),
            new("client_type", "mobile")
        };

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: jwtIssuer,
            audience: jwtIssuer,
            claims: claims,
            expires: expiresAtUtc,
            signingCredentials: credentials);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    private int GetAccessTokenExpiryMinutes()
    {
        if (int.TryParse(_configuration["Jwt:MobileAccessTokenMinutes"], out var minutes) && minutes > 0)
            return minutes;

        return 30;
    }

    private static List<string> ParsePermissions(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
            return new List<string>();

        try
        {
            var parsed = System.Text.Json.JsonSerializer.Deserialize<List<string>>(json);
            return parsed?.Where(x => !string.IsNullOrWhiteSpace(x)).Select(x => x.Trim()).Distinct(StringComparer.OrdinalIgnoreCase).ToList()
                   ?? new List<string>();
        }
        catch
        {
            return new List<string>();
        }
    }

    private static string ResolveMobile(ApplicationUser user, string identifier)
    {
        var value = user.PhoneNumber;
        if (!string.IsNullOrWhiteSpace(value))
            return value.Trim();

        if (!identifier.Contains('@'))
            return identifier.Trim();

        throw new InvalidOperationException("Mobile number is required for mobile API access.");
    }

    private static int BillingCycleToMonths(string billingCycle)
    {
        return billingCycle.Trim().ToLowerInvariant() switch
        {
            "monthly" => 1,
            "quarterly" => 3,
            "half-yearly" => 6,
            "halfyearly" => 6,
            "yearly" => 12,
            "annual" => 12,
            _ => throw new ArgumentException("Unsupported billing cycle.", nameof(billingCycle))
        };
    }

    private static bool IsVersionLower(string currentVersion, string minimumSupported)
    {
        if (!Version.TryParse(NormalizeVersion(currentVersion), out var current))
            return false;
        if (!Version.TryParse(NormalizeVersion(minimumSupported), out var minimum))
            return false;

        return current < minimum;
    }

    private static string NormalizeVersion(string value)
    {
        var trimmed = value.Trim();
        var parts = trimmed.Split('.', StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length >= 3)
            return trimmed;
        if (parts.Length == 2)
            return trimmed + ".0";
        if (parts.Length == 1)
            return trimmed + ".0.0";
        return "0.0.0";
    }

    private static void ApplyPaymentStatus(MobilePaymentTransaction tx, string normalizedStatus, string gatewayOrderId, string? gatewayPaymentId, Guid actorUserId)
    {
        switch (normalizedStatus)
        {
            case "paid":
                if (tx.PaymentStatus != MobilePaymentStatus.Paid)
                    tx.MarkPaid(gatewayOrderId, gatewayPaymentId ?? gatewayOrderId, actorUserId);
                break;
            case "failed":
                tx.MarkFailed("Payment failed by gateway callback.", actorUserId);
                break;
            case "refunded":
                tx.MarkRefunded(actorUserId);
                break;
            default:
                tx.SetGatewayOrder(gatewayOrderId, actorUserId);
                break;
        }
    }
}