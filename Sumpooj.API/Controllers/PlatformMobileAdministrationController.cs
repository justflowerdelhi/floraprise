using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using System.Text;
using Sumpooj.API.Services.Mobile;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Mobile;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/platform/mobile-admin")]
public sealed class PlatformMobileAdministrationController : ControllerBase
{
    private readonly SumpoojDbContext _db;
    private readonly IMobileClientService _mobileClientService;
    private readonly IMobileSubscriptionService _mobileSubscriptionService;

    public PlatformMobileAdministrationController(
        SumpoojDbContext db,
        IMobileClientService mobileClientService,
        IMobileSubscriptionService mobileSubscriptionService)
    {
        _db = db;
        _mobileClientService = mobileClientService;
        _mobileSubscriptionService = mobileSubscriptionService;
    }

    [HttpGet("dashboard")]
    public async Task<IActionResult> GetDashboard([FromQuery] Guid? companyId = null)
    {
        var utcNow = DateTime.UtcNow;
        var onlineThresholdUtc = utcNow.AddHours(-24);
        var renewalsThresholdUtc = utcNow.AddDays(30);
        var todayStartUtc = utcNow.Date;
        var tomorrowStartUtc = todayStartUtc.AddDays(1);
        var staleDeviceThresholdUtc = utcNow.AddDays(-7);
        var newCustomerThresholdUtc = utcNow.AddDays(-7);

        var users = _db.MobileUsers.AsNoTracking().Where(x => !x.IsDeleted);
        var subscriptions = _db.MobileSubscriptions.AsNoTracking().Where(x => !x.IsDeleted);
        var devices = _db.MobileDevices.AsNoTracking().Where(x => !x.IsDeleted);
        var payments = _db.MobilePaymentTransactions.AsNoTracking().Where(x => !x.IsDeleted);
        var customers = _db.MobileCustomers.AsNoTracking().Where(x => !x.IsDeleted);

        if (companyId.HasValue)
        {
            users = users.Where(x => x.CompanyId == companyId.Value);
            subscriptions = subscriptions.Where(x => x.CompanyId == companyId.Value);
            devices = devices.Where(x => x.CompanyId == companyId.Value);
            payments = payments.Where(x => x.CompanyId == companyId.Value);
            customers = customers.Where(x => x.CompanyId == companyId.Value);
        }

        var activeUsers = await users.CountAsync(x => x.Status == MobileUserStatus.Active);
        var trialUsers = await subscriptions.CountAsync(x => x.Status == MobileSubscriptionStatus.Trial);
        var activeSubscriptions = await subscriptions.CountAsync(x => x.Status == MobileSubscriptionStatus.Active);
        var renewalsDue = await subscriptions.CountAsync(x =>
            (x.Status == MobileSubscriptionStatus.Active || x.Status == MobileSubscriptionStatus.Grace)
            && x.EndUtc.HasValue
            && x.EndUtc.Value <= renewalsThresholdUtc);
        var onlineDevices = await devices.CountAsync(x =>
            x.Status == MobileDeviceStatus.Active
            && x.LastHeartbeatAtUtc.HasValue
            && x.LastHeartbeatAtUtc.Value >= onlineThresholdUtc);
        var totalRevenue = await payments
            .Where(x => x.PaymentStatus == MobilePaymentStatus.Paid)
            .SumAsync(x => (decimal?)x.Amount) ?? 0m;
        var trialExpiringToday = await subscriptions.CountAsync(x =>
            x.Status == MobileSubscriptionStatus.Trial
            && x.TrialEndUtc >= todayStartUtc
            && x.TrialEndUtc < tomorrowStartUtc);
        var renewalsDueToday = await subscriptions.CountAsync(x =>
            (x.Status == MobileSubscriptionStatus.Active || x.Status == MobileSubscriptionStatus.Grace)
            && x.EndUtc.HasValue
            && x.EndUtc.Value >= todayStartUtc
            && x.EndUtc.Value < tomorrowStartUtc);
        var devicesOffline7Days = await devices.CountAsync(x =>
            x.Status != MobileDeviceStatus.Active
            || !x.LastHeartbeatAtUtc.HasValue
            || x.LastHeartbeatAtUtc.Value < staleDeviceThresholdUtc);
        var failedPayments = await payments.CountAsync(x => x.PaymentStatus == MobilePaymentStatus.Failed);
        var recentlySuspendedAccounts = await users.CountAsync(x =>
            x.Status == MobileUserStatus.Suspended
            && x.UpdatedAtUtc.HasValue
            && x.UpdatedAtUtc.Value >= newCustomerThresholdUtc);
        var newCustomersLast7Days = await customers.CountAsync(x => x.CreatedAtUtc >= newCustomerThresholdUtc);

        return Ok(new MobileAdminDashboardDto
        {
            ActiveUsers = activeUsers,
            TrialUsers = trialUsers,
            ActiveSubscriptions = activeSubscriptions,
            RenewalsDue = renewalsDue,
            Revenue = totalRevenue,
            OnlineDevices = onlineDevices,
            TrialExpiringToday = trialExpiringToday,
            RenewalsDueToday = renewalsDueToday,
            DevicesOffline7Days = devicesOffline7Days,
            FailedPayments = failedPayments,
            RecentlySuspendedAccounts = recentlySuspendedAccounts,
            NewCustomersLast7Days = newCustomersLast7Days,
        });
    }

    [HttpGet("search/global")]
    public async Task<IActionResult> GlobalSearch([FromQuery] string? q, [FromQuery] Guid? companyId = null, [FromQuery] int limit = 20)
    {
        if (string.IsNullOrWhiteSpace(q))
            return Ok(new List<MobileAdminGlobalSearchResultDto>());

        var query = q.Trim();
        var normalized = query.ToLowerInvariant();
        var effectiveLimit = Math.Clamp(limit, 1, 50);
        var parsedGuid = Guid.TryParse(query, out var guidValue) ? guidValue : (Guid?)null;

        var usersQuery = _db.MobileUsers
            .AsNoTracking()
            .Include(x => x.MobileCustomer)
            .Include(x => x.Subscription)
                .ThenInclude(x => x!.SubscriptionPlan)
            .Where(x => !x.IsDeleted);

        if (companyId.HasValue)
            usersQuery = usersQuery.Where(x => x.CompanyId == companyId.Value);

        usersQuery = usersQuery.Where(x =>
            x.FullName.ToLower().Contains(normalized)
            || x.Mobile.ToLower().Contains(normalized)
            || (x.Email != null && x.Email.ToLower().Contains(normalized))
            || (x.MobileCustomer != null && x.MobileCustomer.BusinessName.ToLower().Contains(normalized))
            || (x.MobileCustomer != null && x.MobileCustomer.OwnerName.ToLower().Contains(normalized))
            || _db.Companies.Any(c => c.Id == x.CompanyId && c.TaxIdentifier != null && c.TaxIdentifier.ToLower().Contains(normalized)));

        var matchedUsers = await usersQuery
            .OrderByDescending(x => x.CreatedAtUtc)
            .Take(effectiveLimit)
            .ToListAsync();

        if (matchedUsers.Count < effectiveLimit)
        {
            var userIdsByDevice = await _db.MobileDevices
                .AsNoTracking()
                .Where(x => !x.IsDeleted && x.DeviceId.ToLower().Contains(normalized))
                .Select(x => x.MobileUserId)
                .Distinct()
                .Take(effectiveLimit)
                .ToListAsync();

            var userIdsByLicense = await _db.MobileLicenses
                .AsNoTracking()
                .Where(x => !x.IsDeleted && x.Id.ToString().ToLower().Contains(normalized))
                .Join(_db.MobileDevices.AsNoTracking(), l => l.MobileDeviceId, d => d.Id, (l, d) => d.MobileUserId)
                .Distinct()
                .Take(effectiveLimit)
                .ToListAsync();

            var userIdsBySubscription = parsedGuid.HasValue
                ? await _db.MobileSubscriptions
                    .AsNoTracking()
                    .Where(x => !x.IsDeleted && x.Id == parsedGuid.Value)
                    .Select(x => x.MobileUserId)
                    .Distinct()
                    .Take(effectiveLimit)
                    .ToListAsync()
                : new List<Guid>();

            var extraIds = userIdsByDevice
                .Concat(userIdsByLicense)
                .Concat(userIdsBySubscription)
                .Where(id => matchedUsers.All(x => x.Id != id))
                .Distinct()
                .Take(effectiveLimit - matchedUsers.Count)
                .ToList();

            if (extraIds.Count > 0)
            {
                var extraUsers = await _db.MobileUsers
                    .AsNoTracking()
                    .Include(x => x.MobileCustomer)
                    .Include(x => x.Subscription)
                        .ThenInclude(x => x!.SubscriptionPlan)
                    .Where(x => !x.IsDeleted && extraIds.Contains(x.Id) && (!companyId.HasValue || x.CompanyId == companyId.Value))
                    .ToListAsync();
                matchedUsers.AddRange(extraUsers);
            }
        }

        var userIds = matchedUsers.Select(x => x.Id).Distinct().ToList();
        var deviceStats = await _db.MobileDevices
            .AsNoTracking()
            .Where(x => !x.IsDeleted && userIds.Contains(x.MobileUserId))
            .GroupBy(x => x.MobileUserId)
            .Select(g => new
            {
                UserId = g.Key,
                Count = g.Count(),
                LastSeen = g.Max(x => x.LastHeartbeatAtUtc ?? x.LastLoginAtUtc)
            })
            .ToListAsync();
        var deviceLookup = deviceStats.ToDictionary(x => x.UserId, x => x);

        var result = matchedUsers
            .Take(effectiveLimit)
            .Select(x =>
            {
                deviceLookup.TryGetValue(x.Id, out var ds);
                return new MobileAdminGlobalSearchResultDto
                {
                    CompanyId = x.CompanyId,
                    MobileUserId = x.Id,
                    BusinessName = x.MobileCustomer?.BusinessName ?? x.FullName,
                    CurrentPlan = x.Subscription?.SubscriptionPlan?.Name ?? x.Subscription?.SubscriptionPlan?.Code,
                    Status = x.Subscription?.Status.ToString() ?? x.Status.ToString(),
                    LastSeenAtUtc = ds?.LastSeen,
                    DeviceCount = ds?.Count ?? 0,
                };
            })
            .ToList();

        return Ok(result);
    }

    [HttpGet("devices")]
    public async Task<IActionResult> GetDevices([FromQuery] MobileAdminDeviceQuery query)
    {
        var page = query.Page <= 0 ? 1 : query.Page;
        var pageSize = query.PageSize <= 0 ? 20 : Math.Min(query.PageSize, 100);
        var onlineThresholdUtc = DateTime.UtcNow.AddHours(-24);

        var baseQuery = _db.MobileDevices
            .AsNoTracking()
            .Include(x => x.MobileUser)
                .ThenInclude(x => x!.MobileCustomer)
            .Include(x => x.License)
                .ThenInclude(x => x!.MobileSubscription)
                    .ThenInclude(x => x!.SubscriptionPlan)
            .Where(x => !x.IsDeleted);

        if (query.CompanyId.HasValue)
            baseQuery = baseQuery.Where(x => x.CompanyId == query.CompanyId.Value);

        if (!string.IsNullOrWhiteSpace(query.Platform))
        {
            var platform = query.Platform.Trim().ToLowerInvariant();
            baseQuery = baseQuery.Where(x => x.Platform.ToLower() == platform);
        }

        if (!string.IsNullOrWhiteSpace(query.AppVersion))
        {
            var version = query.AppVersion.Trim().ToLowerInvariant();
            baseQuery = baseQuery.Where(x => x.AppVersion.ToLower().Contains(version));
        }

        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var search = query.Search.Trim().ToLowerInvariant();
            baseQuery = baseQuery.Where(x =>
                x.DeviceId.ToLower().Contains(search)
                || (x.Model != null && x.Model.ToLower().Contains(search))
                || (x.MobileUser != null && x.MobileUser.MobileCustomer != null && x.MobileUser.MobileCustomer.BusinessName.ToLower().Contains(search))
                || (x.MobileUser != null && x.MobileUser.FullName.ToLower().Contains(search)));
        }

        if (!string.IsNullOrWhiteSpace(query.ConnectionStatus))
        {
            var status = query.ConnectionStatus.Trim().ToLowerInvariant();
            if (status == "online")
            {
                baseQuery = baseQuery.Where(x => x.Status == MobileDeviceStatus.Active && x.LastHeartbeatAtUtc.HasValue && x.LastHeartbeatAtUtc.Value >= onlineThresholdUtc);
            }
            else if (status == "offline")
            {
                baseQuery = baseQuery.Where(x => x.Status != MobileDeviceStatus.Active || !x.LastHeartbeatAtUtc.HasValue || x.LastHeartbeatAtUtc.Value < onlineThresholdUtc);
            }
        }

        if (!string.IsNullOrWhiteSpace(query.SubscriptionType))
        {
            var type = query.SubscriptionType.Trim().ToLowerInvariant();
            if (type == "trial")
                baseQuery = baseQuery.Where(x => x.License != null && x.License.MobileSubscription != null && x.License.MobileSubscription.Status == MobileSubscriptionStatus.Trial);
            else if (type == "paid")
                baseQuery = baseQuery.Where(x => x.License != null && x.License.MobileSubscription != null && x.License.MobileSubscription.Status != MobileSubscriptionStatus.Trial);
        }

        var totalCount = await baseQuery.CountAsync();
        var rows = await baseQuery
            .OrderByDescending(x => x.CreatedAtUtc)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        var items = rows.Select(x => new MobileAdminDeviceListItemDto
        {
            MobileDeviceId = x.Id,
            CompanyId = x.CompanyId,
            MobileUserId = x.MobileUserId,
            DeviceName = string.IsNullOrWhiteSpace(x.Model) ? x.DeviceId : x.Model!,
            DeviceId = x.DeviceId,
            BusinessName = x.MobileUser?.MobileCustomer?.BusinessName,
            Platform = x.Platform,
            OsVersion = x.OsVersion,
            AppVersion = x.AppVersion,
            Online = x.Status == MobileDeviceStatus.Active && x.LastHeartbeatAtUtc.HasValue && x.LastHeartbeatAtUtc.Value >= onlineThresholdUtc,
            LastSeenAtUtc = x.LastHeartbeatAtUtc ?? x.LastLoginAtUtc,
            RegisteredAtUtc = x.CreatedAtUtc,
            SubscriptionType = x.License?.MobileSubscription?.Status == MobileSubscriptionStatus.Trial ? "Trial" : "Paid",
            DeviceStatus = x.Status.ToString(),
        }).ToList();

        return Ok(new MobileAdminDevicePagedResultDto
        {
            Items = items,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize,
        });
    }

    [HttpGet("licenses")]
    public async Task<IActionResult> GetLicenses([FromQuery] MobileAdminLicenseQuery query)
    {
        var page = query.Page <= 0 ? 1 : query.Page;
        var pageSize = query.PageSize <= 0 ? 20 : Math.Min(query.PageSize, 100);

        var baseQuery = _db.MobileLicenses
            .AsNoTracking()
            .Include(x => x.MobileDevice)
                .ThenInclude(x => x!.MobileUser)
                    .ThenInclude(x => x!.MobileCustomer)
            .Include(x => x.MobileSubscription)
                .ThenInclude(x => x!.SubscriptionPlan)
            .Where(x => !x.IsDeleted);

        if (query.CompanyId.HasValue)
            baseQuery = baseQuery.Where(x => x.CompanyId == query.CompanyId.Value);

        if (!string.IsNullOrWhiteSpace(query.Status) && Enum.TryParse<MobileLicenseStatus>(query.Status, true, out var status))
            baseQuery = baseQuery.Where(x => x.Status == status);

        if (!string.IsNullOrWhiteSpace(query.PlanCode))
        {
            var code = query.PlanCode.Trim().ToUpperInvariant();
            baseQuery = baseQuery.Where(x => x.MobileSubscription != null && x.MobileSubscription.SubscriptionPlan != null && x.MobileSubscription.SubscriptionPlan.Code == code);
        }

        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var search = query.Search.Trim().ToLowerInvariant();
            baseQuery = baseQuery.Where(x =>
                x.Id.ToString().ToLower().Contains(search)
                || (x.MobileDevice != null && x.MobileDevice.MobileUser != null && x.MobileDevice.MobileUser.MobileCustomer != null && x.MobileDevice.MobileUser.MobileCustomer.BusinessName.ToLower().Contains(search))
                || (x.MobileDevice != null && x.MobileDevice.DeviceId.ToLower().Contains(search)));
        }

        var totalCount = await baseQuery.CountAsync();
        var rows = await baseQuery
            .OrderByDescending(x => x.CreatedAtUtc)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        var items = rows.Select(x =>
        {
            var sub = x.MobileSubscription;
            var remaining = sub == null ? 0 : GetRemainingDays(sub);
            return new MobileAdminLicenseListItemDto
            {
                MobileLicenseId = x.Id,
                CompanyId = x.CompanyId,
                MobileUserId = x.MobileDevice?.MobileUserId ?? Guid.Empty,
                LicenseNumber = x.Id.ToString(),
                BusinessName = x.MobileDevice?.MobileUser?.MobileCustomer?.BusinessName,
                Plan = sub?.SubscriptionPlan?.Name ?? sub?.SubscriptionPlan?.Code,
                Status = x.Status.ToString(),
                IssueDateUtc = x.IssuedAtUtc,
                ExpiryDateUtc = x.ExpiryUtc,
                RemainingDays = remaining,
            };
        }).ToList();

        return Ok(new MobileAdminLicensePagedResultDto
        {
            Items = items,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize,
        });
    }

    [HttpPost("devices/{mobileDeviceId:guid}/disable")]
    public async Task<IActionResult> DisableDevice([FromRoute] Guid mobileDeviceId, [FromBody] MobileAdminSupportActionRequest request, CancellationToken cancellationToken)
    {
        var device = await _db.MobileDevices
            .FirstOrDefaultAsync(x => x.CompanyId == request.CompanyId && x.Id == mobileDeviceId && !x.IsDeleted, cancellationToken);
        if (device == null)
            return NotFound(new { message = "Device not found." });

        var previous = new { Status = device.Status.ToString() };
        device.Disable(null);

        var license = await _db.MobileLicenses.FirstOrDefaultAsync(x => x.CompanyId == request.CompanyId && x.MobileDeviceId == device.Id && !x.IsDeleted, cancellationToken);
        license?.Suspend(null);

        await _db.SaveChangesAsync(cancellationToken);
        await LogSupportActionAsync(request.CompanyId, device.MobileUserId, "DEVICE_DISABLED", previous, new { Status = device.Status.ToString() }, request.Notes, cancellationToken);

        return Ok(new { message = "Device disabled successfully." });
    }

    [HttpPost("devices/{mobileDeviceId:guid}/force-logout")]
    public async Task<IActionResult> ForceLogoutDevice([FromRoute] Guid mobileDeviceId, [FromBody] MobileAdminSupportActionRequest request, CancellationToken cancellationToken)
    {
        var device = await _db.MobileDevices
            .FirstOrDefaultAsync(x => x.CompanyId == request.CompanyId && x.Id == mobileDeviceId && !x.IsDeleted, cancellationToken);
        if (device == null)
            return NotFound(new { message = "Device not found." });

        var sessions = await _db.DeviceSessions
            .Where(x => x.CompanyId == request.CompanyId && x.MobileDeviceId == mobileDeviceId && x.Status == DeviceSessionStatus.Active && !x.IsDeleted)
            .ToListAsync(cancellationToken);

        var prev = new { ActiveSessions = sessions.Count };
        foreach (var session in sessions)
            session.Logout(null);

        await _db.SaveChangesAsync(cancellationToken);
        await LogSupportActionAsync(request.CompanyId, device.MobileUserId, "DEVICE_FORCE_LOGOUT", prev, new { ActiveSessions = 0 }, request.Notes, cancellationToken);

        return Ok(new { message = "Device sessions logged out.", loggedOutSessions = sessions.Count });
    }

    [HttpPost("devices/{mobileDeviceId:guid}/reset")]
    public async Task<IActionResult> ResetDeviceById([FromRoute] Guid mobileDeviceId, [FromBody] MobileAdminSupportActionRequest request, CancellationToken cancellationToken)
    {
        var device = await _db.MobileDevices
            .FirstOrDefaultAsync(x => x.CompanyId == request.CompanyId && x.Id == mobileDeviceId && !x.IsDeleted, cancellationToken);
        if (device == null)
            return NotFound(new { message = "Device not found." });

        var sessions = await _db.DeviceSessions
            .Where(x => x.CompanyId == request.CompanyId && x.MobileDeviceId == mobileDeviceId && x.Status == DeviceSessionStatus.Active && !x.IsDeleted)
            .ToListAsync(cancellationToken);
        foreach (var session in sessions)
            session.Logout(null);

        var license = await _db.MobileLicenses
            .FirstOrDefaultAsync(x => x.CompanyId == request.CompanyId && x.MobileDeviceId == mobileDeviceId && !x.IsDeleted, cancellationToken);
        var prev = new { DeviceStatus = device.Status.ToString(), LicenseStatus = license?.Status.ToString() };
        license?.Suspend(null);
        device.Disable(null);

        await _db.SaveChangesAsync(cancellationToken);
        await LogSupportActionAsync(request.CompanyId, device.MobileUserId, "DEVICE_RESET", prev, new { DeviceStatus = device.Status.ToString(), LicenseStatus = license?.Status.ToString() }, request.Notes, cancellationToken);

        return Ok(new { message = "Device reset successfully." });
    }

    [HttpPost("licenses/{mobileLicenseId:guid}/activate")]
    public async Task<IActionResult> ActivateLicense([FromRoute] Guid mobileLicenseId, [FromBody] MobileAdminSupportActionRequest request, CancellationToken cancellationToken)
    {
        var license = await _db.MobileLicenses
            .Include(x => x.MobileDevice)
            .FirstOrDefaultAsync(x => x.CompanyId == request.CompanyId && x.Id == mobileLicenseId && !x.IsDeleted, cancellationToken);
        if (license == null)
            return NotFound(new { message = "License not found." });

        var prev = new { Status = license.Status.ToString() };
        license.Activate(null);
        await _db.SaveChangesAsync(cancellationToken);
        await LogSupportActionAsync(request.CompanyId, license.MobileDevice?.MobileUserId, "LICENSE_ACTIVATED", prev, new { Status = license.Status.ToString() }, request.Notes, cancellationToken);

        return Ok(new { message = "License activated." });
    }

    [HttpPost("licenses/{mobileLicenseId:guid}/suspend")]
    public async Task<IActionResult> SuspendLicense([FromRoute] Guid mobileLicenseId, [FromBody] MobileAdminSupportActionRequest request, CancellationToken cancellationToken)
    {
        var license = await _db.MobileLicenses
            .Include(x => x.MobileDevice)
            .FirstOrDefaultAsync(x => x.CompanyId == request.CompanyId && x.Id == mobileLicenseId && !x.IsDeleted, cancellationToken);
        if (license == null)
            return NotFound(new { message = "License not found." });

        var prev = new { Status = license.Status.ToString() };
        license.Suspend(null);
        await _db.SaveChangesAsync(cancellationToken);
        await LogSupportActionAsync(request.CompanyId, license.MobileDevice?.MobileUserId, "LICENSE_SUSPENDED", prev, new { Status = license.Status.ToString() }, request.Notes, cancellationToken);

        return Ok(new { message = "License suspended." });
    }

    [HttpPost("licenses/{mobileLicenseId:guid}/resume")]
    public async Task<IActionResult> ResumeLicense([FromRoute] Guid mobileLicenseId, [FromBody] MobileAdminSupportActionRequest request, CancellationToken cancellationToken)
    {
        var license = await _db.MobileLicenses
            .Include(x => x.MobileDevice)
            .FirstOrDefaultAsync(x => x.CompanyId == request.CompanyId && x.Id == mobileLicenseId && !x.IsDeleted, cancellationToken);
        if (license == null)
            return NotFound(new { message = "License not found." });

        var prev = new { Status = license.Status.ToString() };
        license.Activate(null);
        await _db.SaveChangesAsync(cancellationToken);
        await LogSupportActionAsync(request.CompanyId, license.MobileDevice?.MobileUserId, "LICENSE_RESUMED", prev, new { Status = license.Status.ToString() }, request.Notes, cancellationToken);

        return Ok(new { message = "License resumed." });
    }

    [HttpPost("licenses/{mobileLicenseId:guid}/extend")]
    public async Task<IActionResult> ExtendLicense([FromRoute] Guid mobileLicenseId, [FromBody] MobileAdminLicenseExtendRequest request, CancellationToken cancellationToken)
    {
        var license = await _db.MobileLicenses
            .Include(x => x.MobileDevice)
            .FirstOrDefaultAsync(x => x.CompanyId == request.CompanyId && x.Id == mobileLicenseId && !x.IsDeleted, cancellationToken);
        if (license == null)
            return NotFound(new { message = "License not found." });

        var start = license.ExpiryUtc ?? DateTime.UtcNow;
        var prev = new { ExpiryUtc = license.ExpiryUtc };
        license.SetExpiry(start.AddDays(Math.Max(1, request.ExtendByDays)), null);

        await _db.SaveChangesAsync(cancellationToken);
        await LogSupportActionAsync(request.CompanyId, license.MobileDevice?.MobileUserId, "LICENSE_EXTENDED", prev, new { ExpiryUtc = license.ExpiryUtc, request.ExtendByDays }, request.Notes, cancellationToken);

        return Ok(new { message = "License extended.", expiryUtc = license.ExpiryUtc });
    }

    [HttpPost("licenses/{mobileLicenseId:guid}/convert-trial")]
    public async Task<IActionResult> ConvertTrialToPaid([FromRoute] Guid mobileLicenseId, [FromBody] MobileAdminConvertTrialRequest request, CancellationToken cancellationToken)
    {
        var license = await _db.MobileLicenses
            .Include(x => x.MobileDevice)
            .FirstOrDefaultAsync(x => x.CompanyId == request.CompanyId && x.Id == mobileLicenseId && !x.IsDeleted, cancellationToken);
        if (license == null || license.MobileDevice == null)
            return NotFound(new { message = "License not found." });

        var response = await _mobileClientService.UpgradeAsync(
            request.CompanyId,
            license.MobileDevice.MobileUserId,
            new MobilePlanChangeRequest(request.PlanId, request.BillingCycle),
            cancellationToken);

        await LogSupportActionAsync(request.CompanyId, license.MobileDevice.MobileUserId, "TRIAL_CONVERTED_TO_PAID", new { LicenseId = mobileLicenseId }, new { request.PlanId, request.BillingCycle }, request.Notes, cancellationToken);
        return Ok(response);
    }

    [HttpGet("support-activity")]
    public async Task<IActionResult> GetSupportActivity([FromQuery] MobileAdminSupportActivityQuery query)
    {
        var page = query.Page <= 0 ? 1 : query.Page;
        var pageSize = query.PageSize <= 0 ? 20 : Math.Min(query.PageSize, 200);

        var baseQuery = _db.AuditLogs.AsNoTracking()
            .Where(x => x.EntityType == "MobileSupport");

        if (query.CompanyId.HasValue)
            baseQuery = baseQuery.Where(x => x.CompanyId == query.CompanyId.Value);

        if (query.FromUtc.HasValue)
            baseQuery = baseQuery.Where(x => x.Timestamp >= query.FromUtc.Value);

        if (query.ToUtc.HasValue)
            baseQuery = baseQuery.Where(x => x.Timestamp <= query.ToUtc.Value);

        if (!string.IsNullOrWhiteSpace(query.Action))
        {
            var action = query.Action.Trim().ToLowerInvariant();
            baseQuery = baseQuery.Where(x => x.Action.ToLower().Contains(action));
        }

        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var search = query.Search.Trim().ToLowerInvariant();
            baseQuery = baseQuery.Where(x =>
                (x.EntityName != null && x.EntityName.ToLower().Contains(search))
                || (x.Description != null && x.Description.ToLower().Contains(search))
                || (x.UserName != null && x.UserName.ToLower().Contains(search))
                || (x.NewValues != null && x.NewValues.ToLower().Contains(search))
                || (x.OldValues != null && x.OldValues.ToLower().Contains(search)));
        }

        var totalCount = await baseQuery.CountAsync();
        var rows = await baseQuery
            .OrderByDescending(x => x.Timestamp)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        var items = rows.Select(x => new MobileAdminSupportActivityItemDto
        {
            DateTimeUtc = x.Timestamp,
            SupportUser = x.UserName ?? "Unknown",
            Customer = x.EntityName ?? "Unknown",
            Action = x.Action,
            PreviousValue = x.OldValues,
            NewValue = x.NewValues,
            Notes = x.Description,
        }).ToList();

        return Ok(new MobileAdminSupportActivityPagedResultDto
        {
            Items = items,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize,
        });
    }

    [HttpGet("support-activity/export")]
    public async Task<IActionResult> ExportSupportActivity([FromQuery] MobileAdminSupportActivityQuery query)
    {
        var baseQuery = _db.AuditLogs.AsNoTracking()
            .Where(x => x.EntityType == "MobileSupport");

        if (query.CompanyId.HasValue)
            baseQuery = baseQuery.Where(x => x.CompanyId == query.CompanyId.Value);

        if (query.FromUtc.HasValue)
            baseQuery = baseQuery.Where(x => x.Timestamp >= query.FromUtc.Value);

        if (query.ToUtc.HasValue)
            baseQuery = baseQuery.Where(x => x.Timestamp <= query.ToUtc.Value);

        if (!string.IsNullOrWhiteSpace(query.Action))
        {
            var action = query.Action.Trim().ToLowerInvariant();
            baseQuery = baseQuery.Where(x => x.Action.ToLower().Contains(action));
        }

        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var search = query.Search.Trim().ToLowerInvariant();
            baseQuery = baseQuery.Where(x =>
                (x.EntityName != null && x.EntityName.ToLower().Contains(search))
                || (x.Description != null && x.Description.ToLower().Contains(search))
                || (x.UserName != null && x.UserName.ToLower().Contains(search)));
        }

        var rows = await baseQuery
            .OrderByDescending(x => x.Timestamp)
            .Take(5000)
            .ToListAsync();

        var sb = new StringBuilder();
        sb.AppendLine("DateTimeUtc,SupportUser,Customer,Action,PreviousValue,NewValue,Notes");
        foreach (var row in rows)
        {
            sb.AppendLine(string.Join(",",
                Csv(row.Timestamp.ToString("O")),
                Csv(row.UserName ?? "Unknown"),
                Csv(row.EntityName ?? "Unknown"),
                Csv(row.Action),
                Csv(row.OldValues ?? string.Empty),
                Csv(row.NewValues ?? string.Empty),
                Csv(row.Description ?? string.Empty)));
        }

        var bytes = Encoding.UTF8.GetBytes(sb.ToString());
        return File(bytes, "text/csv", $"mobile-support-activity-{DateTime.UtcNow:yyyyMMddHHmmss}.csv");
    }

    [HttpGet("plans")]
    public async Task<IActionResult> GetPlans(CancellationToken cancellationToken)
    {
        var plans = await _mobileSubscriptionService.GetActivePlansAsync(cancellationToken);
        return Ok(plans);
    }

    [HttpGet("customers")]
    public async Task<IActionResult> GetCustomers([FromQuery] MobileAdminCustomerQuery query)
    {
        var page = query.Page <= 0 ? 1 : query.Page;
        var pageSize = query.PageSize <= 0 ? 20 : Math.Min(query.PageSize, 100);

        var baseQuery = _db.MobileUsers
            .AsNoTracking()
            .Include(x => x.Subscription)
                .ThenInclude(x => x!.SubscriptionPlan)
            .Include(x => x.MobileCustomer)
            .Where(x => !x.IsDeleted);

        if (query.CompanyId.HasValue)
        {
            baseQuery = baseQuery.Where(x => x.CompanyId == query.CompanyId.Value);
        }

        if (!string.IsNullOrWhiteSpace(query.UserStatus)
            && Enum.TryParse<MobileUserStatus>(query.UserStatus, true, out var userStatus))
        {
            baseQuery = baseQuery.Where(x => x.Status == userStatus);
        }

        if (!string.IsNullOrWhiteSpace(query.SubscriptionStatus)
            && Enum.TryParse<MobileSubscriptionStatus>(query.SubscriptionStatus, true, out var subscriptionStatus))
        {
            baseQuery = baseQuery.Where(x => x.Subscription != null && x.Subscription.Status == subscriptionStatus);
        }

        if (!string.IsNullOrWhiteSpace(query.PlanCode))
        {
            var planCode = query.PlanCode.Trim().ToUpperInvariant();
            baseQuery = baseQuery.Where(x => x.Subscription != null
                                             && x.Subscription.SubscriptionPlan != null
                                             && x.Subscription.SubscriptionPlan.Code == planCode);
        }

        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var search = query.Search.Trim().ToLowerInvariant();
            baseQuery = baseQuery.Where(x =>
                x.FullName.ToLower().Contains(search)
                || x.Mobile.ToLower().Contains(search)
                || (x.Email != null && x.Email.ToLower().Contains(search))
                || (x.MobileCustomer != null && x.MobileCustomer.BusinessName.ToLower().Contains(search))
                || (x.MobileCustomer != null && x.MobileCustomer.OwnerName.ToLower().Contains(search))
            );
        }

        var totalCount = await baseQuery.CountAsync();

        var users = await baseQuery
            .OrderByDescending(x => x.CreatedAtUtc)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        var userIds = users.Select(x => x.Id).ToList();
        var deviceStats = await _db.MobileDevices
            .AsNoTracking()
            .Where(x => userIds.Contains(x.MobileUserId) && !x.IsDeleted)
            .GroupBy(x => x.MobileUserId)
            .Select(g => new
            {
                MobileUserId = g.Key,
                TotalDevices = g.Count(),
                OnlineDevices = g.Count(x => x.Status == MobileDeviceStatus.Active
                                             && x.LastHeartbeatAtUtc.HasValue
                                             && x.LastHeartbeatAtUtc.Value >= DateTime.UtcNow.AddHours(-24))
            })
            .ToListAsync();

        var deviceLookup = deviceStats.ToDictionary(x => x.MobileUserId, x => x);

        var items = users.Select(x =>
        {
            deviceLookup.TryGetValue(x.Id, out var ds);
            return new MobileAdminCustomerListItemDto
            {
                MobileUserId = x.Id,
                CompanyId = x.CompanyId,
                CustomerName = x.FullName,
                BusinessName = x.MobileCustomer?.BusinessName,
                Mobile = x.Mobile,
                Email = x.Email,
                UserStatus = x.Status.ToString(),
                SubscriptionStatus = x.Subscription?.Status.ToString() ?? "Unknown",
                PlanCode = x.Subscription?.SubscriptionPlan?.Code,
                PlanName = x.Subscription?.SubscriptionPlan?.Name,
                TrialEndUtc = x.Subscription?.TrialEndUtc,
                SubscriptionEndUtc = x.Subscription?.EndUtc,
                RemainingDays = GetRemainingDays(x.Subscription),
                TotalDevices = ds?.TotalDevices ?? 0,
                OnlineDevices = ds?.OnlineDevices ?? 0,
            };
        }).ToList();

        return Ok(new MobileAdminCustomerPagedResultDto
        {
            Items = items,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize,
        });
    }

    [HttpGet("customers/{mobileUserId:guid}")]
    public async Task<IActionResult> GetCustomerDetails([FromRoute] Guid mobileUserId, [FromQuery] Guid companyId)
    {
        var user = await _db.MobileUsers
            .AsNoTracking()
            .Include(x => x.MobileCustomer)
            .Include(x => x.Subscription)
                .ThenInclude(x => x!.SubscriptionPlan)
            .FirstOrDefaultAsync(x => x.CompanyId == companyId && x.Id == mobileUserId && !x.IsDeleted);

        if (user == null)
            return NotFound(new { message = "Mobile customer not found." });

        var devices = await _db.MobileDevices
            .AsNoTracking()
            .Where(x => x.CompanyId == companyId && x.MobileUserId == mobileUserId && !x.IsDeleted)
            .Select(x => new MobileAdminDeviceDto
            {
                DeviceId = x.DeviceId,
                Platform = x.Platform,
                AppVersion = x.AppVersion,
                Status = x.Status.ToString(),
                LastHeartbeatAtUtc = x.LastHeartbeatAtUtc,
                LastLoginAtUtc = x.LastLoginAtUtc,
                LastSyncAtUtc = x.LastSyncAtUtc,
                LastIpAddress = x.LastIpAddress,
            })
            .OrderByDescending(x => x.LastHeartbeatAtUtc)
            .ToListAsync();

        var payments = await _db.MobilePaymentTransactions
            .AsNoTracking()
            .Where(x => x.CompanyId == companyId
                        && user.Subscription != null
                        && x.MobileSubscriptionId == user.Subscription.Id
                        && !x.IsDeleted)
            .OrderByDescending(x => x.CreatedAtUtc)
            .Take(10)
            .Select(x => new MobileAdminPaymentDto
            {
                TransactionRef = x.TransactionRef,
                Amount = x.Amount,
                Currency = x.Currency,
                PaymentStatus = x.PaymentStatus.ToString(),
                PaymentType = x.PaymentType.ToString(),
                CreatedAtUtc = x.CreatedAtUtc,
                PaidAtUtc = x.PaidAtUtc,
            })
            .ToListAsync();

        var activityTimeline = new List<MobileAdminTimelineItemDto>
        {
            new()
            {
                TimestampUtc = user.CreatedAtUtc,
                Category = "customer",
                Title = "Mobile customer created",
                Description = $"{user.FullName} ({user.Mobile}) was onboarded.",
            }
        };

        if (user.Subscription != null)
        {
            activityTimeline.Add(new MobileAdminTimelineItemDto
            {
                TimestampUtc = user.Subscription.CreatedAtUtc,
                Category = "subscription",
                Title = "Subscription started",
                Description = $"{user.Subscription.Status} on plan {user.Subscription.SubscriptionPlan?.Code ?? "N/A"}",
            });

            if (user.Subscription.UpdatedAtUtc.HasValue)
            {
                activityTimeline.Add(new MobileAdminTimelineItemDto
                {
                    TimestampUtc = user.Subscription.UpdatedAtUtc.Value,
                    Category = "subscription",
                    Title = "Subscription updated",
                    Description = $"Status: {user.Subscription.Status}",
                });
            }
        }

        foreach (var payment in payments)
        {
            activityTimeline.Add(new MobileAdminTimelineItemDto
            {
                TimestampUtc = payment.PaidAtUtc ?? payment.CreatedAtUtc,
                Category = "payment",
                Title = "Payment event",
                Description = $"{payment.TransactionRef} • {payment.PaymentStatus} • {payment.Currency} {payment.Amount:0.##}",
            });
        }

        foreach (var device in devices)
        {
            if (device.LastLoginAtUtc.HasValue)
            {
                activityTimeline.Add(new MobileAdminTimelineItemDto
                {
                    TimestampUtc = device.LastLoginAtUtc.Value,
                    Category = "device",
                    Title = "Device login",
                    Description = $"{device.DeviceId} ({device.Platform}) logged in.",
                });
            }

            if (device.LastHeartbeatAtUtc.HasValue)
            {
                activityTimeline.Add(new MobileAdminTimelineItemDto
                {
                    TimestampUtc = device.LastHeartbeatAtUtc.Value,
                    Category = "device",
                    Title = "Device heartbeat",
                    Description = $"{device.DeviceId} status {device.Status}.",
                });
            }
        }

        activityTimeline = activityTimeline
            .OrderByDescending(x => x.TimestampUtc)
            .Take(100)
            .ToList();

        return Ok(new MobileAdminCustomerDetailDto
        {
            MobileUserId = user.Id,
            CompanyId = user.CompanyId,
            CustomerName = user.FullName,
            BusinessName = user.MobileCustomer?.BusinessName,
            OwnerName = user.MobileCustomer?.OwnerName,
            City = user.MobileCustomer?.City,
            State = user.MobileCustomer?.State,
            Country = user.MobileCustomer?.Country,
            Mobile = user.Mobile,
            Email = user.Email,
            UserStatus = user.Status.ToString(),
            SubscriptionStatus = user.Subscription?.Status.ToString() ?? "Unknown",
            PlanCode = user.Subscription?.SubscriptionPlan?.Code,
            PlanName = user.Subscription?.SubscriptionPlan?.Name,
            TrialEndUtc = user.Subscription?.TrialEndUtc,
            SubscriptionEndUtc = user.Subscription?.EndUtc,
            AutoRenew = user.Subscription?.AutoRenew,
            RemainingDays = GetRemainingDays(user.Subscription),
            Devices = devices,
            RecentPayments = payments,
            ActivityTimeline = activityTimeline,
        });
    }

    [HttpPost("customers/{mobileUserId:guid}/upgrade-plan")]
    public async Task<IActionResult> UpgradePlan([FromRoute] Guid mobileUserId, [FromBody] MobileAdminUpgradePlanRequest request, CancellationToken cancellationToken)
    {
        var before = await _db.MobileSubscriptions.AsNoTracking()
            .Include(x => x.SubscriptionPlan)
            .FirstOrDefaultAsync(x => x.CompanyId == request.CompanyId && x.MobileUserId == mobileUserId && !x.IsDeleted, cancellationToken);

        var response = await _mobileClientService.UpgradeAsync(
            request.CompanyId,
            mobileUserId,
            new MobilePlanChangeRequest(request.PlanId, request.BillingCycle),
            cancellationToken);

        await LogSupportActionAsync(
            request.CompanyId,
            mobileUserId,
            "PLAN_UPGRADED",
            new { Plan = before?.SubscriptionPlan?.Code, before?.Status },
            new { request.PlanId, request.BillingCycle },
            request.Notes,
            cancellationToken);

        return Ok(response);
    }

    [HttpPost("customers/{mobileUserId:guid}/renew")]
    public async Task<IActionResult> Renew([FromRoute] Guid mobileUserId, [FromBody] MobileAdminRenewRequest request, CancellationToken cancellationToken)
    {
        var before = await _db.MobileSubscriptions.AsNoTracking()
            .FirstOrDefaultAsync(x => x.CompanyId == request.CompanyId && x.MobileUserId == mobileUserId && !x.IsDeleted, cancellationToken);

        var response = await _mobileClientService.RenewAsync(
            request.CompanyId,
            mobileUserId,
            new MobileRenewRequest(request.BillingCycle, request.AutoRenew),
            cancellationToken);

        await LogSupportActionAsync(
            request.CompanyId,
            mobileUserId,
            "SUBSCRIPTION_RENEWED",
            new { before?.EndUtc, before?.Status },
            new { request.BillingCycle, request.AutoRenew },
            request.Notes,
            cancellationToken);

        return Ok(response);
    }

    [HttpPost("customers/{mobileUserId:guid}/suspend")]
    public async Task<IActionResult> Suspend([FromRoute] Guid mobileUserId, [FromBody] MobileAdminCompanyScopedRequest request, CancellationToken cancellationToken)
    {
        var user = await _db.MobileUsers
            .Include(x => x.Subscription)
            .FirstOrDefaultAsync(x => x.CompanyId == request.CompanyId && x.Id == mobileUserId && !x.IsDeleted, cancellationToken);

        if (user == null)
            return NotFound(new { message = "Mobile customer not found." });

        user.Suspend(null);
        user.Subscription?.Suspend(null);

        var devices = await _db.MobileDevices
            .Where(x => x.CompanyId == request.CompanyId && x.MobileUserId == mobileUserId && !x.IsDeleted)
            .ToListAsync(cancellationToken);
        foreach (var device in devices)
        {
            device.Disable(null);
        }

        var deviceIds = devices.Select(x => x.Id).ToList();
        var licenses = await _db.MobileLicenses
            .Where(x => x.CompanyId == request.CompanyId
                        && deviceIds.Contains(x.MobileDeviceId)
                        && !x.IsDeleted)
            .ToListAsync(cancellationToken);
        foreach (var license in licenses)
        {
            license.Suspend(null);
        }

        await _db.SaveChangesAsync(cancellationToken);
        await LogSupportActionAsync(request.CompanyId, mobileUserId, "ACCOUNT_SUSPENDED", new { UserStatus = "Active" }, new { UserStatus = "Suspended" }, request.Notes, cancellationToken);

        return Ok(new { message = "Mobile customer suspended successfully." });
    }

    [HttpPost("customers/{mobileUserId:guid}/activate")]
    public async Task<IActionResult> Activate([FromRoute] Guid mobileUserId, [FromBody] MobileAdminCompanyScopedRequest request, CancellationToken cancellationToken)
    {
        var user = await _db.MobileUsers
            .FirstOrDefaultAsync(x => x.CompanyId == request.CompanyId && x.Id == mobileUserId && !x.IsDeleted, cancellationToken);

        if (user == null)
            return NotFound(new { message = "Mobile customer not found." });

        user.Activate(null);

        var deviceIds = await _db.MobileDevices
            .Where(x => x.CompanyId == request.CompanyId && x.MobileUserId == mobileUserId && !x.IsDeleted)
            .Select(x => x.Id)
            .ToListAsync(cancellationToken);

        var licenses = await _db.MobileLicenses
            .Where(x => x.CompanyId == request.CompanyId && deviceIds.Contains(x.MobileDeviceId) && !x.IsDeleted)
            .ToListAsync(cancellationToken);
        foreach (var license in licenses)
            license.Activate(null);

        await _db.SaveChangesAsync(cancellationToken);
        await LogSupportActionAsync(request.CompanyId, mobileUserId, "ACCOUNT_ACTIVATED", new { UserStatus = "Suspended" }, new { UserStatus = "Active" }, request.Notes, cancellationToken);

        return Ok(new { message = "Mobile customer activated successfully." });
    }

    [HttpPost("customers/{mobileUserId:guid}/extend")]
    public async Task<IActionResult> ExtendCustomerLicense([FromRoute] Guid mobileUserId, [FromBody] MobileAdminLicenseExtendRequest request, CancellationToken cancellationToken)
    {
        var deviceIds = await _db.MobileDevices
            .Where(x => x.CompanyId == request.CompanyId && x.MobileUserId == mobileUserId && !x.IsDeleted)
            .Select(x => x.Id)
            .ToListAsync(cancellationToken);

        var license = await _db.MobileLicenses
            .Where(x => x.CompanyId == request.CompanyId && deviceIds.Contains(x.MobileDeviceId) && !x.IsDeleted)
            .OrderByDescending(x => x.ExpiryUtc)
            .FirstOrDefaultAsync(cancellationToken);

        if (license == null)
            return NotFound(new { message = "No active license found for this customer." });

        var prev = new { license.ExpiryUtc };
        var start = license.ExpiryUtc.HasValue && license.ExpiryUtc > DateTime.UtcNow
            ? license.ExpiryUtc.Value
            : DateTime.UtcNow;
        license.SetExpiry(start.AddDays(Math.Max(1, request.ExtendByDays)), null);

        await _db.SaveChangesAsync(cancellationToken);
        await LogSupportActionAsync(request.CompanyId, mobileUserId, "LICENSE_EXTENDED", prev, new { license.ExpiryUtc, request.ExtendByDays }, request.Notes, cancellationToken);

        return Ok(new { message = "License extended.", expiryUtc = license.ExpiryUtc });
    }
    public async Task<IActionResult> ResetDevice([FromRoute] Guid mobileUserId, [FromBody] MobileAdminResetDeviceRequest request, CancellationToken cancellationToken)
    {
        var deviceQuery = _db.MobileDevices.Where(x =>
            x.CompanyId == request.CompanyId
            && x.MobileUserId == mobileUserId
            && !x.IsDeleted);

        MobileDevice? device;
        if (!string.IsNullOrWhiteSpace(request.DeviceId))
        {
            var targetId = request.DeviceId.Trim();
            device = await deviceQuery.FirstOrDefaultAsync(x => x.DeviceId == targetId, cancellationToken);
        }
        else
        {
            device = await deviceQuery
                .OrderByDescending(x => x.LastHeartbeatAtUtc)
                .ThenByDescending(x => x.LastLoginAtUtc)
                .FirstOrDefaultAsync(cancellationToken);
        }

        if (device == null)
            return NotFound(new { message = "Device not found." });

        var sessions = await _db.DeviceSessions
            .Where(x => x.CompanyId == request.CompanyId
                        && x.MobileDeviceId == device.Id
                        && x.Status == DeviceSessionStatus.Active
                        && !x.IsDeleted)
            .ToListAsync(cancellationToken);
        foreach (var session in sessions)
        {
            session.Logout(null);
        }

        var license = await _db.MobileLicenses.FirstOrDefaultAsync(x =>
            x.CompanyId == request.CompanyId
            && x.MobileDeviceId == device.Id
            && !x.IsDeleted, cancellationToken);
        license?.Suspend(null);

        device.Disable(null);

        await _db.SaveChangesAsync(cancellationToken);
        await LogSupportActionAsync(request.CompanyId, mobileUserId, "DEVICE_RESET", new { Device = device.DeviceId }, new { DeviceStatus = device.Status.ToString(), LicenseStatus = license?.Status.ToString() }, request.Notes, cancellationToken);

        return Ok(new { message = "Device reset successfully.", deviceId = device.DeviceId });
    }

    [HttpPost("customers/{mobileUserId:guid}/force-logout")]
    public async Task<IActionResult> ForceLogout([FromRoute] Guid mobileUserId, [FromBody] MobileAdminForceLogoutRequest request, CancellationToken cancellationToken)
    {
        var deviceQuery = _db.MobileDevices.Where(x =>
            x.CompanyId == request.CompanyId
            && x.MobileUserId == mobileUserId
            && !x.IsDeleted);

        if (!string.IsNullOrWhiteSpace(request.DeviceId))
        {
            var targetDeviceId = request.DeviceId.Trim();
            deviceQuery = deviceQuery.Where(x => x.DeviceId == targetDeviceId);
        }

        var deviceIds = await deviceQuery.Select(x => x.Id).ToListAsync(cancellationToken);
        if (deviceIds.Count == 0)
            return NotFound(new { message = "Device not found for logout." });

        var sessions = await _db.DeviceSessions
            .Where(x => x.CompanyId == request.CompanyId
                        && deviceIds.Contains(x.MobileDeviceId)
                        && x.Status == DeviceSessionStatus.Active
                        && !x.IsDeleted)
            .ToListAsync(cancellationToken);

        foreach (var session in sessions)
        {
            session.Logout(null);
        }

        await _db.SaveChangesAsync(cancellationToken);
        await LogSupportActionAsync(request.CompanyId, mobileUserId, "FORCE_LOGOUT", new { ActiveSessions = sessions.Count }, new { ActiveSessions = 0 }, request.Notes, cancellationToken);

        return Ok(new
        {
            message = "Active sessions logged out successfully.",
            loggedOutSessions = sessions.Count,
            scope = string.IsNullOrWhiteSpace(request.DeviceId) ? "all-devices" : "single-device",
        });
    }

    private async Task LogSupportActionAsync(
        Guid companyId,
        Guid? mobileUserId,
        string action,
        object? previousValue,
        object? newValue,
        string? notes,
        CancellationToken cancellationToken)
    {
        string? customerName = null;
        if (mobileUserId.HasValue)
        {
            customerName = await _db.MobileUsers
                .AsNoTracking()
                .Where(x => x.CompanyId == companyId && x.Id == mobileUserId.Value && !x.IsDeleted)
                .Select(x => x.MobileCustomer != null ? x.MobileCustomer.BusinessName : x.FullName)
                .FirstOrDefaultAsync(cancellationToken);
        }

        var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        var userName = User.FindFirstValue(ClaimTypes.Name) ?? User.Identity?.Name ?? "Platform Support";
        var parsedUserId = Guid.TryParse(userIdClaim, out var userId) ? userId : (Guid?)null;

        var log = new AuditLog(
            companyId,
            parsedUserId,
            userName,
            action,
            "MobileSupport",
            mobileUserId,
            customerName ?? mobileUserId?.ToString());

        log.SetOldValues(previousValue == null ? null : System.Text.Json.JsonSerializer.Serialize(previousValue));
        log.SetNewValues(newValue == null ? null : System.Text.Json.JsonSerializer.Serialize(newValue));
        log.SetDescription(notes);

        _db.AuditLogs.Add(log);
        await _db.SaveChangesAsync(cancellationToken);
    }

    private static string Csv(string? value)
    {
        if (string.IsNullOrEmpty(value)) return "\"\"";
        return $"\"{value.Replace("\"", "\"\"")}\"";
    }

    private static int GetRemainingDays(MobileSubscription? subscription)
    {
        if (subscription == null)
            return 0;

        var referenceUtc = subscription.Status == MobileSubscriptionStatus.Trial
            ? subscription.TrialEndUtc
            : subscription.EndUtc;

        if (!referenceUtc.HasValue)
            return 0;

        return Math.Max(0, (int)Math.Ceiling((referenceUtc.Value - DateTime.UtcNow).TotalDays));
    }
}

public sealed class MobileAdminDashboardDto
{
    public int ActiveUsers { get; set; }
    public int TrialUsers { get; set; }
    public int ActiveSubscriptions { get; set; }
    public int RenewalsDue { get; set; }
    public decimal Revenue { get; set; }
    public int OnlineDevices { get; set; }
    public int TrialExpiringToday { get; set; }
    public int RenewalsDueToday { get; set; }
    public int DevicesOffline7Days { get; set; }
    public int FailedPayments { get; set; }
    public int RecentlySuspendedAccounts { get; set; }
    public int NewCustomersLast7Days { get; set; }
}

public sealed class MobileAdminGlobalSearchResultDto
{
    public Guid CompanyId { get; set; }
    public Guid MobileUserId { get; set; }
    public string BusinessName { get; set; } = string.Empty;
    public string? CurrentPlan { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime? LastSeenAtUtc { get; set; }
    public int DeviceCount { get; set; }
}

public sealed class MobileAdminDeviceQuery
{
    public Guid? CompanyId { get; set; }
    public string? Search { get; set; }
    public string? ConnectionStatus { get; set; }
    public string? SubscriptionType { get; set; }
    public string? AppVersion { get; set; }
    public string? Platform { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}

public sealed class MobileAdminDevicePagedResultDto
{
    public List<MobileAdminDeviceListItemDto> Items { get; set; } = new();
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
}

public sealed class MobileAdminDeviceListItemDto
{
    public Guid MobileDeviceId { get; set; }
    public Guid CompanyId { get; set; }
    public Guid MobileUserId { get; set; }
    public string DeviceName { get; set; } = string.Empty;
    public string DeviceId { get; set; } = string.Empty;
    public string? BusinessName { get; set; }
    public string Platform { get; set; } = string.Empty;
    public string? OsVersion { get; set; }
    public string AppVersion { get; set; } = string.Empty;
    public bool Online { get; set; }
    public DateTime? LastSeenAtUtc { get; set; }
    public DateTime RegisteredAtUtc { get; set; }
    public string SubscriptionType { get; set; } = string.Empty;
    public string DeviceStatus { get; set; } = string.Empty;
}

public sealed class MobileAdminLicenseQuery
{
    public Guid? CompanyId { get; set; }
    public string? Search { get; set; }
    public string? Status { get; set; }
    public string? PlanCode { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}

public sealed class MobileAdminLicensePagedResultDto
{
    public List<MobileAdminLicenseListItemDto> Items { get; set; } = new();
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
}

public sealed class MobileAdminLicenseListItemDto
{
    public Guid MobileLicenseId { get; set; }
    public Guid CompanyId { get; set; }
    public Guid MobileUserId { get; set; }
    public string LicenseNumber { get; set; } = string.Empty;
    public string? BusinessName { get; set; }
    public string? Plan { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime IssueDateUtc { get; set; }
    public DateTime? ExpiryDateUtc { get; set; }
    public int RemainingDays { get; set; }
}

public sealed class MobileAdminSupportActivityQuery
{
    public Guid? CompanyId { get; set; }
    public string? Search { get; set; }
    public string? Action { get; set; }
    public DateTime? FromUtc { get; set; }
    public DateTime? ToUtc { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}

public sealed class MobileAdminSupportActivityPagedResultDto
{
    public List<MobileAdminSupportActivityItemDto> Items { get; set; } = new();
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
}

public sealed class MobileAdminSupportActivityItemDto
{
    public DateTime DateTimeUtc { get; set; }
    public string SupportUser { get; set; } = string.Empty;
    public string Customer { get; set; } = string.Empty;
    public string Action { get; set; } = string.Empty;
    public string? PreviousValue { get; set; }
    public string? NewValue { get; set; }
    public string? Notes { get; set; }
}

public sealed class MobileAdminCustomerQuery
{
    public Guid? CompanyId { get; set; }
    public string? Search { get; set; }
    public string? UserStatus { get; set; }
    public string? SubscriptionStatus { get; set; }
    public string? PlanCode { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}

public sealed class MobileAdminCustomerPagedResultDto
{
    public List<MobileAdminCustomerListItemDto> Items { get; set; } = new();
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
}

public sealed class MobileAdminCustomerListItemDto
{
    public Guid MobileUserId { get; set; }
    public Guid CompanyId { get; set; }
    public string CustomerName { get; set; } = string.Empty;
    public string? BusinessName { get; set; }
    public string Mobile { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string UserStatus { get; set; } = string.Empty;
    public string SubscriptionStatus { get; set; } = string.Empty;
    public string? PlanCode { get; set; }
    public string? PlanName { get; set; }
    public DateTime? TrialEndUtc { get; set; }
    public DateTime? SubscriptionEndUtc { get; set; }
    public int RemainingDays { get; set; }
    public int TotalDevices { get; set; }
    public int OnlineDevices { get; set; }
}

public sealed class MobileAdminCustomerDetailDto
{
    public Guid MobileUserId { get; set; }
    public Guid CompanyId { get; set; }
    public string CustomerName { get; set; } = string.Empty;
    public string? BusinessName { get; set; }
    public string? OwnerName { get; set; }
    public string? City { get; set; }
    public string? State { get; set; }
    public string? Country { get; set; }
    public string Mobile { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string UserStatus { get; set; } = string.Empty;
    public string SubscriptionStatus { get; set; } = string.Empty;
    public string? PlanCode { get; set; }
    public string? PlanName { get; set; }
    public DateTime? TrialEndUtc { get; set; }
    public DateTime? SubscriptionEndUtc { get; set; }
    public bool? AutoRenew { get; set; }
    public int RemainingDays { get; set; }
    public List<MobileAdminDeviceDto> Devices { get; set; } = new();
    public List<MobileAdminPaymentDto> RecentPayments { get; set; } = new();
    public List<MobileAdminTimelineItemDto> ActivityTimeline { get; set; } = new();
}

public sealed class MobileAdminTimelineItemDto
{
    public DateTime TimestampUtc { get; set; }
    public string Category { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
}

public sealed class MobileAdminDeviceDto
{
    public string DeviceId { get; set; } = string.Empty;
    public string Platform { get; set; } = string.Empty;
    public string AppVersion { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime? LastHeartbeatAtUtc { get; set; }
    public DateTime? LastLoginAtUtc { get; set; }
    public DateTime? LastSyncAtUtc { get; set; }
    public string? LastIpAddress { get; set; }
}

public sealed class MobileAdminPaymentDto
{
    public string TransactionRef { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "INR";
    public string PaymentStatus { get; set; } = string.Empty;
    public string PaymentType { get; set; } = string.Empty;
    public DateTime CreatedAtUtc { get; set; }
    public DateTime? PaidAtUtc { get; set; }
}

public class MobileAdminCompanyScopedRequest
{
    public Guid CompanyId { get; set; }
    public string? Notes { get; set; }
}

public sealed class MobileAdminUpgradePlanRequest : MobileAdminCompanyScopedRequest
{
    public Guid PlanId { get; set; }
    public string BillingCycle { get; set; } = "monthly";
}

public sealed class MobileAdminRenewRequest : MobileAdminCompanyScopedRequest
{
    public string BillingCycle { get; set; } = "monthly";
    public bool AutoRenew { get; set; }
}

public sealed class MobileAdminResetDeviceRequest : MobileAdminCompanyScopedRequest
{
    public string? DeviceId { get; set; }
}

public sealed class MobileAdminForceLogoutRequest : MobileAdminCompanyScopedRequest
{
    public string? DeviceId { get; set; }
}

public sealed class MobileAdminSupportActionRequest : MobileAdminCompanyScopedRequest
{
}

public sealed class MobileAdminLicenseExtendRequest : MobileAdminCompanyScopedRequest
{
    public int ExtendByDays { get; set; }
}

public sealed class MobileAdminConvertTrialRequest : MobileAdminCompanyScopedRequest
{
    public Guid PlanId { get; set; }
    public string BillingCycle { get; set; } = "monthly";
}