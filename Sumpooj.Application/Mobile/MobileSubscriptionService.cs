using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Mobile;

public sealed class MobileSubscriptionService : IMobileSubscriptionService
{
    private const string TrialPlanCode = "MOBILE_TRIAL";

    private readonly IMobileCustomerRepository _customers;
    private readonly IMobileUserRepository _users;
    private readonly IMobileDeviceRepository _devices;
    private readonly ISubscriptionPlanRepository _plans;
    private readonly IMobileSubscriptionRepository _subscriptions;
    private readonly IMobileLicenseRepository _licenses;
    private readonly IMobileUnitOfWork _uow;
    private readonly IConfiguration _configuration;
    private readonly ILogger<MobileSubscriptionService> _logger;

    public MobileSubscriptionService(
        IMobileCustomerRepository customers,
        IMobileUserRepository users,
        IMobileDeviceRepository devices,
        ISubscriptionPlanRepository plans,
        IMobileSubscriptionRepository subscriptions,
        IMobileLicenseRepository licenses,
        IMobileUnitOfWork uow,
        IConfiguration configuration,
        ILogger<MobileSubscriptionService> logger)
    {
        _customers = customers;
        _users = users;
        _devices = devices;
        _plans = plans;
        _subscriptions = subscriptions;
        _licenses = licenses;
        _uow = uow;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task<RegisterMobileCustomerResult> RegisterOrStartTrialAsync(RegisterMobileCustomerRequest request, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("[MobileSubscription] Starting RegisterOrStartTrialAsync for companyId: {CompanyId}, mobile: {Mobile}, deviceId: {DeviceId}", request.CompanyId, request.Mobile, request.DeviceId);
        
        MobileValidators.Validate(request);

        var now = DateTime.UtcNow;

        _logger.LogInformation("[MobileSubscription] Getting/creating MobileCustomer for mobile: {Mobile}", request.Mobile);
        var customer = await _customers.GetByMobileAsync(request.CompanyId, request.Mobile);
        if (customer == null)
        {
            _logger.LogInformation("[MobileSubscription] Creating new MobileCustomer for mobile: {Mobile}", request.Mobile);
            customer = new MobileCustomer(
                companyId: request.CompanyId,
                businessName: request.BusinessName,
                ownerName: request.OwnerName,
                mobile: request.Mobile);
            customer.UpdateProfile(request.Email, request.City, request.State, request.Country, request.ActorUserId);
            customer.SetCreatedBy(request.ActorUserId);
            await _customers.AddAsync(customer);
            _logger.LogInformation("[MobileSubscription] MobileCustomer created with ID: {CustomerId}", customer.Id);
        }
        else
        {
            _logger.LogInformation("[MobileSubscription] MobileCustomer found with ID: {CustomerId}, updating profile", customer.Id);
            customer.UpdateProfile(request.Email, request.City, request.State, request.Country, request.ActorUserId);
        }

        _logger.LogInformation("[MobileSubscription] Getting/creating MobileUser for mobile: {Mobile}", request.Mobile);
        var user = await _users.GetByMobileAsync(request.CompanyId, request.Mobile);
        if (user == null)
        {
            _logger.LogInformation("[MobileSubscription] Creating new MobileUser for mobile: {Mobile}, customerId: {CustomerId}", request.Mobile, customer.Id);
            user = new MobileUser(
                companyId: request.CompanyId,
                mobileCustomerId: customer.Id,
                fullName: request.FullName,
                mobile: request.Mobile,
                email: request.Email);
            user.SetCreatedBy(request.ActorUserId);
            await _users.AddAsync(user);
            _logger.LogInformation("[MobileSubscription] MobileUser created with ID: {UserId}", user.Id);
        }
        else if (user.Status != MobileUserStatus.Active)
        {
            _logger.LogInformation("[MobileSubscription] Activating existing MobileUser: {UserId}", user.Id);
            user.Activate(request.ActorUserId);
        }
        else
        {
            _logger.LogInformation("[MobileSubscription] MobileUser already active: {UserId}", user.Id);
        }

        _logger.LogInformation("[MobileSubscription] Getting/creating MobileDevice for userId: {UserId}, deviceId: {DeviceId}", user.Id, request.DeviceId);
        var device = await _devices.GetByDeviceIdAsync(request.CompanyId, user.Id, request.DeviceId);
        if (device == null)
        {
            _logger.LogInformation("[MobileSubscription] Creating new MobileDevice for userId: {UserId}, deviceId: {DeviceId}", user.Id, request.DeviceId);
            device = new MobileDevice(
                companyId: request.CompanyId,
                mobileUserId: user.Id,
                deviceId: request.DeviceId,
                manufacturer: request.Manufacturer,
                model: request.Model,
                platform: request.Platform,
                osVersion: request.OsVersion,
                appVersion: request.AppVersion,
                pushToken: request.PushToken);
            device.MarkLogin(request.IpAddress, request.ActorUserId);
            device.SetCreatedBy(request.ActorUserId);
            await _devices.AddAsync(device);
            _logger.LogInformation("[MobileSubscription] MobileDevice created with ID: {DeviceId}", device.Id);
        }
        else
        {
            _logger.LogInformation("[MobileSubscription] MobileDevice found with ID: {DeviceId}, updating", device.Id);
            if (device.Status != MobileDeviceStatus.Active)
                device.Activate(request.ActorUserId);

            device.MarkLogin(request.IpAddress, request.ActorUserId);
            device.UpdateHeartbeat(request.AppVersion, request.IpAddress, now, request.ActorUserId);
        }

        _logger.LogInformation("[MobileSubscription] Ensuring default subscription plans exist");
        await EnsureDefaultPlansAsync(request.ActorUserId);

        _logger.LogInformation("[MobileSubscription] Ensuring trial plan exists");
        var plan = await EnsureTrialPlanAsync(request.ActorUserId);
        _logger.LogInformation("[MobileSubscription] Trial plan ID: {PlanId}", plan.Id);

        _logger.LogInformation("[MobileSubscription] Getting/creating MobileSubscription for userId: {UserId}", user.Id);
        var subscription = await _subscriptions.GetByUserIdAsync(request.CompanyId, user.Id);
        if (subscription == null)
        {
            _logger.LogInformation("[MobileSubscription] Creating new MobileSubscription for userId: {UserId}, planId: {PlanId}", user.Id, plan.Id);
            var trialEnd = now.AddDays(Math.Max(1, plan.TrialDays));
            subscription = new MobileSubscription(
                companyId: request.CompanyId,
                mobileUserId: user.Id,
                subscriptionPlanId: plan.Id,
                trialStartUtc: now,
                trialEndUtc: trialEnd);
            subscription.SetCreatedBy(request.ActorUserId);
            await _subscriptions.AddAsync(subscription);
            _logger.LogInformation("[MobileSubscription] MobileSubscription created with ID: {SubscriptionId}", subscription.Id);
        }
        else
        {
            _logger.LogInformation("[MobileSubscription] MobileSubscription already exists: {SubscriptionId}", subscription.Id);
        }

        _logger.LogInformation("[MobileSubscription] Getting/creating MobileLicense for deviceId: {DeviceId}", device.Id);
        var license = await _licenses.GetByDeviceIdAsync(request.CompanyId, device.Id);
        if (license == null)
        {
            _logger.LogInformation("[MobileSubscription] Creating new MobileLicense for deviceId: {DeviceId}, subscriptionId: {SubscriptionId}", device.Id, subscription.Id);
            license = new MobileLicense(
                companyId: request.CompanyId,
                mobileDeviceId: device.Id,
                mobileSubscriptionId: subscription.Id,
                issuedAtUtc: now);
            var expiry = ResolveSubscriptionExpiry(subscription);
            if (expiry.HasValue)
                license.SetExpiry(expiry.Value, request.ActorUserId);

            license.SetCreatedBy(request.ActorUserId);
            await _licenses.AddAsync(license);
            _logger.LogInformation("[MobileSubscription] MobileLicense created with ID: {LicenseId}", license.Id);
        }
        else
        {
            _logger.LogInformation("[MobileSubscription] MobileLicense already exists: {LicenseId}, updating", license.Id);
            if (license.Status != MobileLicenseStatus.Active)
                license.Activate(request.ActorUserId);

            var expiry = ResolveSubscriptionExpiry(subscription);
            license.SetExpiry(expiry, request.ActorUserId);
        }

        _logger.LogInformation("[MobileSubscription] Saving changes to database");
        await _uow.SaveChangesAsync(cancellationToken);
        _logger.LogInformation("[MobileSubscription] Changes saved successfully");

        var expiryUtc = ResolveSubscriptionExpiry(subscription);
        _logger.LogInformation("[MobileSubscription] RegisterOrStartTrialAsync completed successfully. UserId: {UserId}, DeviceId: {DeviceId}", user.Id, device.Id);
        
        return new RegisterMobileCustomerResult(
            customer.Id,
            user.Id,
            device.Id,
            subscription.Id,
            license.Id,
            license.Status,
            subscription.Status,
            subscription.TrialEndUtc,
            ComputeRemainingDays(expiryUtc));
    }

    public async Task<MobileLicenseCheckResult> CheckLicenseAsync(MobileLicenseCheckRequest request, CancellationToken cancellationToken = default)
    {
        MobileValidators.Validate(request);

        var result = await EvaluateAccessAsync(
            request.CompanyId,
            request.MobileUserId,
            request.DeviceId,
            request.AppVersion,
            request.IpAddress,
            request.LastSyncUtc,
            request.ActorUserId,
            cancellationToken);

        return result;
    }

    public async Task<MobileLicenseCheckResult> HeartbeatAsync(MobileHeartbeatRequest request, CancellationToken cancellationToken = default)
    {
        MobileValidators.Validate(request);

        var result = await EvaluateAccessAsync(
            request.CompanyId,
            request.MobileUserId,
            request.DeviceId,
            request.AppVersion,
            request.IpAddress,
            request.LastSyncUtc,
            request.ActorUserId,
            cancellationToken);

        return result;
    }

    public async Task<List<MobileSubscriptionPlanDto>> GetActivePlansAsync(CancellationToken cancellationToken = default)
    {
        await EnsureDefaultPlansAsync(null);
        var plans = await _plans.GetActiveAsync();
        return plans
            .Where(p => p.Code != "MOBILE_LIFETIME")
            .Select(p => new MobileSubscriptionPlanDto(
                p.Id,
                p.Code,
                p.Name,
                p.PlanType,
                p.MonthlyPrice,
                p.AnnualPrice,
                p.LifetimePrice,
                p.TrialDays,
                p.OfflineDays,
                p.GraceDays,
                p.MaximumDevices,
                p.MaximumStaff,
                p.IsActive,
                p.IncludedModulesJson))
            .ToList();
    }

    private async Task<SubscriptionPlan> EnsureTrialPlanAsync(Guid? actorUserId)
    {
        await EnsureDefaultPlansAsync(actorUserId);
        return await _plans.GetByCodeAsync(TrialPlanCode)
            ?? throw new KeyNotFoundException("Trial subscription plan not found.");
    }

    private async Task EnsureDefaultPlansAsync(Guid? actorUserId)
    {
        var trialDays = _configuration.GetValue<int?>("MobileSubscription:TrialDays") ?? 7;
        var graceDays = _configuration.GetValue<int?>("MobileSubscription:GraceDays") ?? 30;
        var offlineDays = _configuration.GetValue<int?>("MobileSubscription:OfflineDays") ?? 3;

        await EnsurePlanAsync(
            code: TrialPlanCode,
            name: "Mobile Trial",
            planType: MobilePlanType.Basic,
            monthlyPrice: 0,
            annualPrice: 0,
            lifetimePrice: 0,
            trialDays: trialDays,
            offlineDays: offlineDays,
            graceDays: graceDays,
            maximumDevices: 2,
            maximumStaff: 2,
            includedModulesJson: "[]",
            isActive: true,
            actorUserId: actorUserId);

        await EnsurePlanAsync(
            code: "QUARTERLY",
            name: "Quarterly Plan",
            planType: MobilePlanType.Pro,
            monthlyPrice: 0,
            annualPrice: _configuration.GetValue<decimal?>("MobileSubscription:Plans:Quarterly:Price") ?? 2999m,
            lifetimePrice: 0,
            trialDays: trialDays,
            offlineDays: offlineDays,
            graceDays: graceDays,
            maximumDevices: 5,
            maximumStaff: 10,
            includedModulesJson: "[]",
            isActive: true,
            actorUserId: actorUserId);

        await EnsurePlanAsync(
            code: "HALF_YEARLY",
            name: "Half Yearly Plan",
            planType: MobilePlanType.Pro,
            monthlyPrice: 0,
            annualPrice: _configuration.GetValue<decimal?>("MobileSubscription:Plans:HalfYearly:Price") ?? 5499m,
            lifetimePrice: 0,
            trialDays: trialDays,
            offlineDays: offlineDays,
            graceDays: graceDays,
            maximumDevices: 5,
            maximumStaff: 10,
            includedModulesJson: "[]",
            isActive: true,
            actorUserId: actorUserId);

        await EnsurePlanAsync(
            code: "ANNUAL",
            name: "Annual Plan",
            planType: MobilePlanType.Pro,
            monthlyPrice: 0,
            annualPrice: _configuration.GetValue<decimal?>("MobileSubscription:Plans:Annual:Price") ?? 9999m,
            lifetimePrice: 0,
            trialDays: trialDays,
            offlineDays: offlineDays,
            graceDays: graceDays,
            maximumDevices: 5,
            maximumStaff: 10,
            includedModulesJson: "[]",
            isActive: true,
            actorUserId: actorUserId);

        await _uow.SaveChangesAsync();
    }

    private async Task EnsurePlanAsync(
        string code,
        string name,
        MobilePlanType planType,
        decimal monthlyPrice,
        decimal annualPrice,
        decimal lifetimePrice,
        int trialDays,
        int offlineDays,
        int graceDays,
        int maximumDevices,
        int maximumStaff,
        string includedModulesJson,
        bool isActive,
        Guid? actorUserId)
    {
        var plan = await _plans.GetByCodeAsync(code);
        if (plan == null)
        {
            plan = new SubscriptionPlan(
                code: code,
                name: name,
                planType: planType,
                monthlyPrice: monthlyPrice,
                annualPrice: annualPrice,
                lifetimePrice: lifetimePrice,
                trialDays: trialDays,
                offlineDays: offlineDays,
                graceDays: graceDays,
                maximumDevices: maximumDevices,
                maximumStaff: maximumStaff,
                includedModulesJson: includedModulesJson);
            plan.SetCreatedBy(actorUserId);
            await _plans.AddAsync(plan);
            return;
        }

        plan.UpdateCatalog(
            name: name,
            planType: planType,
            monthlyPrice: monthlyPrice,
            annualPrice: annualPrice,
            lifetimePrice: lifetimePrice,
            trialDays: trialDays,
            offlineDays: offlineDays,
            graceDays: graceDays,
            maximumDevices: maximumDevices,
            maximumStaff: maximumStaff,
            includedModulesJson: includedModulesJson,
            isActive: isActive,
            updatedBy: actorUserId);
    }

    private async Task<MobileLicenseCheckResult> EvaluateAccessAsync(
        Guid companyId,
        Guid mobileUserId,
        string deviceId,
        string appVersion,
        string? ipAddress,
        DateTime? lastSyncUtc,
        Guid? actorUserId,
        CancellationToken cancellationToken)
    {
        var user = await _users.GetByIdAsync(companyId, mobileUserId)
            ?? throw new KeyNotFoundException("Mobile user not found.");

        if (user.Status != MobileUserStatus.Active)
            throw new UnauthorizedAccessException("Mobile user is not active.");

        var device = await _devices.GetByDeviceIdAsync(companyId, mobileUserId, deviceId)
            ?? throw new KeyNotFoundException("Device is not registered.");

        if (device.Status != MobileDeviceStatus.Active)
            throw new UnauthorizedAccessException("Device is not active.");

        var subscription = await _subscriptions.GetByUserIdAsync(companyId, mobileUserId)
            ?? throw new KeyNotFoundException("Subscription not found.");

        var license = await _licenses.GetByDeviceIdAsync(companyId, device.Id)
            ?? throw new KeyNotFoundException("License not found.");

        device.UpdateHeartbeat(appVersion, ipAddress, lastSyncUtc, actorUserId);

        var now = DateTime.UtcNow;
        var expiryUtc = ResolveSubscriptionExpiry(subscription);
        var remainingDays = ComputeRemainingDays(expiryUtc);

        if (expiryUtc.HasValue && expiryUtc.Value <= now)
        {
            subscription.Expire(actorUserId);
            license.Expire(actorUserId);
            remainingDays = 0;
        }

        subscription.MarkValidated(now, actorUserId);
        license.SetExpiry(expiryUtc, actorUserId);

        if (subscription.Status == MobileSubscriptionStatus.Suspended ||
            subscription.Status == MobileSubscriptionStatus.Cancelled ||
            subscription.Status == MobileSubscriptionStatus.Expired)
        {
            license.Suspend(actorUserId);
        }
        else if (license.Status != MobileLicenseStatus.Revoked)
        {
            license.Activate(actorUserId);
        }

        await _uow.SaveChangesAsync(cancellationToken);

        var planCode = subscription.SubscriptionPlan?.Code ?? TrialPlanCode;
        var graceDays = subscription.SubscriptionPlan?.GraceDays ?? 0;
        var offlineDays = subscription.SubscriptionPlan?.OfflineDays ?? 0;

        var allowsAccess = license.Status == MobileLicenseStatus.Active &&
                           subscription.Status != MobileSubscriptionStatus.Cancelled &&
                           subscription.Status != MobileSubscriptionStatus.Suspended &&
                           subscription.Status != MobileSubscriptionStatus.Expired;

        return new MobileLicenseCheckResult(
            license.Status,
            subscription.Status,
            planCode,
            expiryUtc,
            remainingDays,
            RequiresForceUpdate(appVersion),
            allowsAccess,
            offlineDays,
            graceDays);
    }

    private static DateTime? ResolveSubscriptionExpiry(MobileSubscription subscription)
    {
        return subscription.Status == MobileSubscriptionStatus.Trial
            ? subscription.TrialEndUtc
            : subscription.EndUtc;
    }

    private static int ComputeRemainingDays(DateTime? expiryUtc)
    {
        if (!expiryUtc.HasValue)
            return 0;

        var diff = expiryUtc.Value - DateTime.UtcNow;
        if (diff.TotalDays <= 0)
            return 0;

        return (int)Math.Ceiling(diff.TotalDays);
    }

    private static bool RequiresForceUpdate(string appVersion)
    {
        // Phase 1 foundation: do not enforce app updates until platform settings are introduced.
        return false;
    }
}
