using Floraprise.License.Api.Data;
using Floraprise.License.Api.DTOs;
using Floraprise.License.Api.Entities;
using Floraprise.License.Api.Repositories;
using Microsoft.EntityFrameworkCore;

namespace Floraprise.License.Api.Services;

public sealed class LicenseService : ILicenseService
{
    private static readonly TimeSpan TrialDuration = TimeSpan.FromDays(14);

    private readonly LicenseDbContext _dbContext;
    private readonly ICustomerRepository _customers;
    private readonly IDeviceRepository _devices;
    private readonly ILicenseRepository _licenses;
    private readonly IClock _clock;
    private readonly ILogger<LicenseService> _logger;

    public LicenseService(
        LicenseDbContext dbContext,
        ICustomerRepository customers,
        IDeviceRepository devices,
        ILicenseRepository licenses,
        IClock clock,
        ILogger<LicenseService> logger)
    {
        _dbContext = dbContext;
        _customers = customers;
        _devices = devices;
        _licenses = licenses;
        _clock = clock;
        _logger = logger;
    }

    public async Task<LicenseRegistrationResponse> RegisterAsync(
        RegisterLicenseRequest request,
        CancellationToken cancellationToken)
    {
        var now = _clock.UtcNow;
        var mobile = Normalize(request.Mobile);

        await using var transaction = await _dbContext.Database.BeginTransactionAsync(cancellationToken);

        var customer = await _customers.GetByMobileAsync(mobile, cancellationToken);
        if (customer is null)
        {
            customer = new Customer
            {
                Id = Guid.NewGuid(),
                BusinessName = request.BusinessName.Trim(),
                OwnerName = request.OwnerName.Trim(),
                Mobile = mobile,
                Email = NormalizeOptional(request.Email),
                City = NormalizeOptional(request.City),
                State = NormalizeOptional(request.State) ?? string.Empty,
                Country = NormalizeOptional(request.Country) ?? "India",
                CreatedAt = now
            };
            await _customers.AddAsync(customer, cancellationToken);
            _logger.LogInformation("Created cloud license customer {CustomerId}.", customer.Id);
        }

        await EnsureDeviceAsync(customer.Id, request, now, cancellationToken);
        var license = await EnsureTrialLicenseAsync(customer.Id, now, cancellationToken);
        RecalculateStatus(license, now);

        await _dbContext.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);

        return new LicenseRegistrationResponse(
            customer.Id,
            license.Status,
            license.TrialEnd,
            RemainingDays(ExpiryFor(license), now));
    }

    public async Task<LicenseCheckResponse?> CheckAsync(
        Guid customerId,
        string deviceId,
        CancellationToken cancellationToken)
    {
        var normalizedDeviceId = Normalize(deviceId);
        var device = await _devices.GetAsync(customerId, normalizedDeviceId, cancellationToken);
        if (device is null)
        {
            return null;
        }

        var license = await _licenses.GetByCustomerIdAsync(customerId, cancellationToken);
        if (license is null)
        {
            return null;
        }

        var now = _clock.UtcNow;
        RecalculateStatus(license, now);
        device.LastSeen = now;
        await _dbContext.SaveChangesAsync(cancellationToken);

        var expiry = ExpiryFor(license);
        return new LicenseCheckResponse(
            license.Status,
            license.Plan,
            expiry,
            RemainingDays(expiry, now));
    }

    public async Task<bool> HeartbeatAsync(
        LicenseHeartbeatRequest request,
        CancellationToken cancellationToken)
    {
        var device = await _devices.GetAsync(
            request.CustomerId,
            Normalize(request.DeviceId),
            cancellationToken);
        if (device is null)
        {
            return false;
        }

        device.LastSeen = _clock.UtcNow;
        device.AppVersion = request.AppVersion.Trim();
        await _dbContext.SaveChangesAsync(cancellationToken);
        return true;
    }

    private async Task EnsureDeviceAsync(
        Guid customerId,
        RegisterLicenseRequest request,
        DateTime now,
        CancellationToken cancellationToken)
    {
        var deviceId = Normalize(request.DeviceId);
        var device = await _devices.GetAsync(customerId, deviceId, cancellationToken);
        if (device is not null)
        {
            device.Platform = request.Platform.Trim();
            device.Model = NormalizeOptional(request.Model);
            device.AndroidVersion = NormalizeOptional(request.AndroidVersion);
            device.AppVersion = request.AppVersion.Trim();
            device.LastSeen = now;
            return;
        }

        await _devices.AddAsync(new Device
        {
            Id = Guid.NewGuid(),
            CustomerId = customerId,
            DeviceId = deviceId,
            Platform = request.Platform.Trim(),
            Model = NormalizeOptional(request.Model),
            AndroidVersion = NormalizeOptional(request.AndroidVersion),
            AppVersion = request.AppVersion.Trim(),
            RegisteredAt = now,
            LastSeen = now
        }, cancellationToken);
    }

    private async Task<Entities.License> EnsureTrialLicenseAsync(
        Guid customerId,
        DateTime now,
        CancellationToken cancellationToken)
    {
        var license = await _licenses.GetByCustomerIdAsync(customerId, cancellationToken);
        if (license is not null)
        {
            return license;
        }

        license = new Entities.License
        {
            Id = Guid.NewGuid(),
            CustomerId = customerId,
            Plan = LicensePlan.Trial,
            Status = LicenseStatus.Trial,
            TrialStart = now,
            TrialEnd = now.Add(TrialDuration),
            CreatedAt = now
        };
        await _licenses.AddAsync(license, cancellationToken);
        return license;
    }

    private static void RecalculateStatus(Entities.License license, DateTime now)
    {
        if (license.Status == LicenseStatus.Suspended)
        {
            return;
        }

        var expiry = ExpiryFor(license);
        if (expiry is null || now > expiry.Value)
        {
            license.Status = LicenseStatus.Expired;
            return;
        }

        license.Status = license.Plan == LicensePlan.Trial
            ? LicenseStatus.Trial
            : LicenseStatus.Active;
    }

    private static DateTime? ExpiryFor(Entities.License license)
    {
        return license.Plan == LicensePlan.Trial
            ? license.TrialEnd
            : license.LicenseEnd;
    }

    private static int RemainingDays(DateTime? expiry, DateTime now)
    {
        if (expiry is null || expiry.Value <= now)
        {
            return 0;
        }

        return Math.Max(0, (int)Math.Ceiling((expiry.Value - now).TotalDays));
    }

    private static string Normalize(string value)
    {
        return value.Trim();
    }

    private static string? NormalizeOptional(string? value)
    {
        var trimmed = value?.Trim();
        return string.IsNullOrWhiteSpace(trimmed) ? null : trimmed;
    }
}