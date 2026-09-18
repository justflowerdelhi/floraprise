using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Sumpooj.Infrastructure.Identity;
using Sumpooj.API.Controllers.Mobile;
using Sumpooj.API.Services.Mobile;
using Sumpooj.Application.Companies;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Mobile;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Companies;
using Sumpooj.Infrastructure.Persistence;
using Sumpooj.Infrastructure.Repositories;
using Xunit;

namespace Floraprise.Mobile.Tests;

public sealed class ProDeviceLimitTests : IDisposable
{
    private readonly ServiceProvider _provider;
    private readonly SumpoojDbContext _db;
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly RoleManager<IdentityRole<Guid>> _roleManager;
    private readonly MobileClientService _clientService;
    private readonly IMobileSubscriptionService _subscriptionService;

    public ProDeviceLimitTests()
    {
        var services = new ServiceCollection();
        services.AddLogging();
        services.AddSingleton<IConfiguration>(new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Jwt:Key"] = "test-mobile-auth-signing-key-with-enough-length-123456",
                ["Jwt:Issuer"] = "https://api.test.floraprise.local",
                ["Jwt:MobileAccessTokenMinutes"] = "30",
                ["MobileSubscription:ProMaxDevices"] = "3",
                ["MobileSubscription:TrialDays"] = "7",
                ["MobileSubscription:GraceDays"] = "30",
                ["MobileSubscription:OfflineDays"] = "3",
            })
            .Build());
        services.AddDbContext<SumpoojDbContext>(options =>
            options.UseInMemoryDatabase($"ProDeviceLimit_{Guid.NewGuid():N}")
                .ConfigureWarnings(warnings => warnings.Ignore(InMemoryEventId.TransactionIgnoredWarning)));
        services.AddSingleton<ITenantContext, TestTenantContext>();
        services.AddIdentity<ApplicationUser, IdentityRole<Guid>>(options =>
        {
            options.Password.RequireDigit = true;
            options.Password.RequiredLength = 8;
            options.Password.RequireUppercase = true;
            options.Password.RequireLowercase = true;
            options.User.RequireUniqueEmail = true;
        })
        .AddEntityFrameworkStores<SumpoojDbContext>()
        .AddDefaultTokenProviders();

        services.AddScoped<IMobileCustomerRepository, MobileCustomerRepository>();
        services.AddScoped<IMobileUserRepository, MobileUserRepository>();
        services.AddScoped<IMobileDeviceRepository, MobileDeviceRepository>();
        services.AddScoped<ISubscriptionPlanRepository, SubscriptionPlanRepository>();
        services.AddScoped<IMobileSubscriptionRepository, MobileSubscriptionRepository>();
        services.AddScoped<IMobileLicenseRepository, MobileLicenseRepository>();
        services.AddScoped<IDeviceSessionRepository, DeviceSessionRepository>();
        services.AddScoped<IMobilePaymentTransactionRepository, MobilePaymentTransactionRepository>();
        services.AddScoped<IMobileUnitOfWork, MobileUnitOfWork>();
        services.AddScoped<IMobileSubscriptionService, MobileSubscriptionService>();
        services.AddScoped<ISubscriptionPaymentGatewayFactory, TestPaymentGatewayFactory>();
        services.AddScoped<ILocationRepository, LocationRepository>();
        services.AddScoped<ICompanyService, CompanyService>();
        services.AddScoped<IMobileClientService, MobileClientService>();
        services.AddScoped<MobileClientService>();
        services.AddScoped<MobileAuthController>();

        _provider = services.BuildServiceProvider();
        _db = _provider.GetRequiredService<SumpoojDbContext>();
        _userManager = _provider.GetRequiredService<UserManager<ApplicationUser>>();
        _roleManager = _provider.GetRequiredService<RoleManager<IdentityRole<Guid>>>();
        _clientService = _provider.GetRequiredService<MobileClientService>();
        _subscriptionService = _provider.GetRequiredService<IMobileSubscriptionService>();
    }

    public void Dispose()
    {
        _db.Dispose();
        _provider.Dispose();
    }

    [Fact]
    public async Task EnsureDefaultPlans_ConfiguresProPlansWithThreeMaxDevices()
    {
        var plans = await _subscriptionService.GetActivePlansAsync(CancellationToken.None);
        var proPlans = plans.Where(p => p.PlanType == MobilePlanType.Pro).ToList();

        Assert.NotEmpty(proPlans);
        foreach (var plan in proPlans)
        {
            Assert.Equal(3, plan.MaximumDevices);
        }
    }

    [Fact]
    public async Task ProAccount_AllowsMultipleDevices_FourthAndBeyondSucceed()
    {
        var seeded = await SeedCompanyUserAsync();

        // Device 1 (e.g. Android phone)
        var login1 = await _clientService.LoginAsync(MakeLoginRequest(seeded.User.Email!, seeded.Password, "device-phone-001", "ANDROID"));
        Assert.NotNull(login1.AccessToken);

        // Upgrade account to Pro (Quarterly)
        await UpgradeToProAsync(seeded.Company.Id);

        // Device 2 (e.g. Android POS terminal)
        var login2 = await _clientService.LoginAsync(MakeLoginRequest(seeded.User.Email!, seeded.Password, "device-pos-002", "ANDROID"));
        Assert.NotNull(login2.AccessToken);

        // Device 3 (e.g. Pro Web in Chrome)
        var login3 = await _clientService.LoginAsync(MakeLoginRequest(seeded.User.Email!, seeded.Password, "device-web-003", "WEB"));
        Assert.NotNull(login3.AccessToken);

        // Device 4 (e.g. Pro Web in Edge / another computer) -> succeeds without quota error
        var login4 = await _clientService.LoginAsync(MakeLoginRequest(seeded.User.Email!, seeded.Password, "device-fourth-004", "WEB"));
        Assert.NotNull(login4.AccessToken);

        // Device 5 (e.g. Android tablet) -> succeeds without quota error
        var login5 = await _clientService.LoginAsync(MakeLoginRequest(seeded.User.Email!, seeded.Password, "device-fifth-005", "ANDROID"));
        Assert.NotNull(login5.AccessToken);

        // Verify all 5 devices are active in database
        var activeDevices = await _db.MobileDevices.Where(d => d.CompanyId == seeded.Company.Id && d.Status == MobileDeviceStatus.Active).ToListAsync();
        Assert.Equal(5, activeDevices.Count);
    }

    [Fact]
    public async Task ProAccount_ReLoginWithSameDeviceId_SucceedsWithoutConsumingNewSlot()
    {
        var seeded = await SeedCompanyUserAsync();

        // Login device 1
        var login1 = await _clientService.LoginAsync(MakeLoginRequest(seeded.User.Email!, seeded.Password, "device-web-persistent", "WEB"));
        Assert.NotNull(login1.AccessToken);

        // Re-login device 1 (e.g. browser refresh or repeated auth)
        var login1Repeat = await _clientService.LoginAsync(MakeLoginRequest(seeded.User.Email!, seeded.Password, "device-web-persistent", "WEB"));
        Assert.NotNull(login1Repeat.AccessToken);

        // Active device count remains 1
        var activeDevices = await _db.MobileDevices.Where(d => d.CompanyId == seeded.Company.Id && d.Status == MobileDeviceStatus.Active).ToListAsync();
        Assert.Single(activeDevices);
    }

    [Fact]
    public async Task DeactivatingAndReactivatingDevice_SucceedsSeamlessly()
    {
        var seeded = await SeedCompanyUserAsync();

        await _clientService.LoginAsync(MakeLoginRequest(seeded.User.Email!, seeded.Password, "device-1", "ANDROID"));
        await UpgradeToProAsync(seeded.Company.Id);

        await _clientService.LoginAsync(MakeLoginRequest(seeded.User.Email!, seeded.Password, "device-2", "ANDROID"));
        await _clientService.LoginAsync(MakeLoginRequest(seeded.User.Email!, seeded.Password, "device-3", "WEB"));
        await _clientService.LoginAsync(MakeLoginRequest(seeded.User.Email!, seeded.Password, "device-4", "WEB"));

        // Revoke / deactivate device-1
        var dev1 = await _db.MobileDevices.FirstAsync(d => d.DeviceId == "device-1");
        dev1.Revoke(null);
        await _db.SaveChangesAsync();

        // Reactivate device-1 by logging in again
        var login1Reactivate = await _clientService.LoginAsync(MakeLoginRequest(seeded.User.Email!, seeded.Password, "device-1", "ANDROID"));
        Assert.NotNull(login1Reactivate.AccessToken);

        var refreshedDev1 = await _db.MobileDevices.FirstAsync(d => d.DeviceId == "device-1");
        Assert.Equal(MobileDeviceStatus.Active, refreshedDev1.Status);
    }

    [Fact]
    public async Task TenantIsolation_MultipleDevicesAcrossTenants_OperateIndependently()
    {
        var tenantA = await SeedCompanyUserAsync("Tenant A Florist", "9111111111", "a@example.com");
        var tenantB = await SeedCompanyUserAsync("Tenant B Florist", "9222222222", "b@example.com");

        // Tenant A logs in 4 devices on Pro
        await _clientService.LoginAsync(MakeLoginRequest(tenantA.User.Email!, tenantA.Password, "dev-a-1", "ANDROID"));
        await UpgradeToProAsync(tenantA.Company.Id);
        await _clientService.LoginAsync(MakeLoginRequest(tenantA.User.Email!, tenantA.Password, "dev-a-2", "ANDROID"));
        await _clientService.LoginAsync(MakeLoginRequest(tenantA.User.Email!, tenantA.Password, "dev-a-3", "WEB"));
        var a4 = await _clientService.LoginAsync(MakeLoginRequest(tenantA.User.Email!, tenantA.Password, "dev-a-4", "ANDROID"));
        Assert.NotNull(a4.AccessToken);

        // Tenant B can register and log in 4 of their own devices independently
        var b1 = await _clientService.LoginAsync(MakeLoginRequest(tenantB.User.Email!, tenantB.Password, "dev-b-1", "ANDROID"));
        Assert.NotNull(b1.AccessToken);
        await UpgradeToProAsync(tenantB.Company.Id);

        var b2 = await _clientService.LoginAsync(MakeLoginRequest(tenantB.User.Email!, tenantB.Password, "dev-b-2", "ANDROID"));
        Assert.NotNull(b2.AccessToken);

        var b3 = await _clientService.LoginAsync(MakeLoginRequest(tenantB.User.Email!, tenantB.Password, "dev-b-3", "WEB"));
        Assert.NotNull(b3.AccessToken);

        var b4 = await _clientService.LoginAsync(MakeLoginRequest(tenantB.User.Email!, tenantB.Password, "dev-b-4", "WEB"));
        Assert.NotNull(b4.AccessToken);

        Assert.Equal(4, await _db.MobileDevices.CountAsync(d => d.CompanyId == tenantA.Company.Id && d.Status == MobileDeviceStatus.Active));
        Assert.Equal(4, await _db.MobileDevices.CountAsync(d => d.CompanyId == tenantB.Company.Id && d.Status == MobileDeviceStatus.Active));
    }

    [Fact]
    public async Task MultiDevice_SessionAndRefreshTokenWorkflow_WorksIndependentlyPerDevice()
    {
        var seeded = await SeedCompanyUserAsync();

        var login1 = await _clientService.LoginAsync(MakeLoginRequest(seeded.User.Email!, seeded.Password, "dev-session-1", "ANDROID"));
        var login2 = await _clientService.LoginAsync(MakeLoginRequest(seeded.User.Email!, seeded.Password, "dev-session-2", "WEB"));
        var login3 = await _clientService.LoginAsync(MakeLoginRequest(seeded.User.Email!, seeded.Password, "dev-session-3", "WEB"));
        var login4 = await _clientService.LoginAsync(MakeLoginRequest(seeded.User.Email!, seeded.Password, "dev-session-4", "ANDROID"));

        Assert.NotNull(login1.RefreshToken);
        Assert.NotNull(login2.RefreshToken);
        Assert.NotNull(login3.RefreshToken);
        Assert.NotNull(login4.RefreshToken);

        // Refresh token on device 1
        var refreshed1 = await _clientService.RefreshAsync(new MobileApiRefreshRequest(login1.RefreshToken));
        Assert.NotNull(refreshed1.AccessToken);
        Assert.NotNull(refreshed1.RefreshToken);
        Assert.NotEqual(login1.RefreshToken, refreshed1.RefreshToken);

        // Refresh token on device 4
        var refreshed4 = await _clientService.RefreshAsync(new MobileApiRefreshRequest(login4.RefreshToken));
        Assert.NotNull(refreshed4.AccessToken);
        Assert.NotNull(refreshed4.RefreshToken);
        Assert.NotEqual(login4.RefreshToken, refreshed4.RefreshToken);

        // Verify device 2 and device 3 sessions remain active with their original refresh tokens
        Assert.True((await _db.DeviceSessions.SingleAsync(x => x.RefreshToken == login2.RefreshToken)).IsActive(DateTime.UtcNow));
        Assert.True((await _db.DeviceSessions.SingleAsync(x => x.RefreshToken == login3.RefreshToken)).IsActive(DateTime.UtcNow));
    }

    [Fact]
    public async Task MultiDevice_InvalidCredentials_ThrowsUnauthorizedException()
    {
        var seeded = await SeedCompanyUserAsync();

        // 3 valid logins
        await _clientService.LoginAsync(MakeLoginRequest(seeded.User.Email!, seeded.Password, "dev-sec-1", "ANDROID"));
        await _clientService.LoginAsync(MakeLoginRequest(seeded.User.Email!, seeded.Password, "dev-sec-2", "WEB"));
        await _clientService.LoginAsync(MakeLoginRequest(seeded.User.Email!, seeded.Password, "dev-sec-3", "WEB"));

        // 4th login with incorrect password -> UnauthorizedAccessException
        await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
            _clientService.LoginAsync(MakeLoginRequest(seeded.User.Email!, "WrongPassword@123", "dev-sec-4", "ANDROID")));
    }

    [Fact]
    public async Task MultiDevice_LicenseAndHeartbeatValidation_WorksForEachDevice()
    {
        var seeded = await SeedCompanyUserAsync();

        var login1 = await _clientService.LoginAsync(MakeLoginRequest(seeded.User.Email!, seeded.Password, "dev-val-1", "ANDROID"));
        var login2 = await _clientService.LoginAsync(MakeLoginRequest(seeded.User.Email!, seeded.Password, "dev-val-2", "WEB"));
        var login3 = await _clientService.LoginAsync(MakeLoginRequest(seeded.User.Email!, seeded.Password, "dev-val-3", "WEB"));
        var login4 = await _clientService.LoginAsync(MakeLoginRequest(seeded.User.Email!, seeded.Password, "dev-val-4", "ANDROID"));

        // Heartbeat for dev 1
        var hb1 = await _subscriptionService.HeartbeatAsync(new MobileHeartbeatRequest(
            seeded.Company.Id,
            login1.MobileUserId,
            "dev-val-1",
            "1.0.0",
            "127.0.0.1",
            DateTime.UtcNow,
            seeded.User.Id));
        Assert.True(hb1.AllowsAccess);
        Assert.Equal(MobileLicenseStatus.Active, hb1.LicenseStatus);

        // Heartbeat for dev 4
        var hb4 = await _subscriptionService.HeartbeatAsync(new MobileHeartbeatRequest(
            seeded.Company.Id,
            login4.MobileUserId,
            "dev-val-4",
            "1.0.0",
            "127.0.0.1",
            DateTime.UtcNow,
            seeded.User.Id));
        Assert.True(hb4.AllowsAccess);
        Assert.Equal(MobileLicenseStatus.Active, hb4.LicenseStatus);
    }

    [Fact]
    public async Task PlanMatrix_Quarterly_HalfYearly_Annual_AllResolveToThreeDevices()
    {
        var plans = await _subscriptionService.GetActivePlansAsync(CancellationToken.None);

        var quarterly = plans.Single(p => p.Code == "QUARTERLY");
        var halfYearly = plans.Single(p => p.Code == "HALF_YEARLY");
        var annual = plans.Single(p => p.Code == "ANNUAL");

        Assert.Equal(3, quarterly.MaximumDevices);
        Assert.Equal(3, halfYearly.MaximumDevices);
        Assert.Equal(3, annual.MaximumDevices);

        Assert.Equal(MobilePlanType.Pro, quarterly.PlanType);
        Assert.Equal(MobilePlanType.Pro, halfYearly.PlanType);
        Assert.Equal(MobilePlanType.Pro, annual.PlanType);
    }

    private async Task UpgradeToProAsync(Guid companyId)
    {
        var proPlan = await _db.SubscriptionPlans.FirstAsync(p => p.Code == "QUARTERLY");
        var sub = await _db.MobileSubscriptions.FirstAsync(s => s.CompanyId == companyId);
        sub.ChangePlan(proPlan.Id, null);
        sub.Activate(DateTime.UtcNow, DateTime.UtcNow.AddDays(90), true, null);
        await _db.SaveChangesAsync();
    }

    private static MobileApiLoginRequest MakeLoginRequest(string email, string password, string deviceId, string platform)
    {
        return new MobileApiLoginRequest(
            CompanyId: null,
            Identifier: email,
            Password: password,
            DeviceId: deviceId,
            Platform: platform,
            Manufacturer: "TestMan",
            Model: "TestModel",
            OsVersion: "1.0",
            AppVersion: "1.0.0",
            PushToken: null,
            IpAddress: "127.0.0.1");
    }

    private async Task<(Company Company, ApplicationUser User, string Password)> SeedCompanyUserAsync(
        string name = "Pro Florist Shop",
        string phone = "9123456780",
        string email = "owner@florist.example")
    {
        var company = new Company(
            name: name,
            region: "IN",
            email: email,
            phone: phone,
            address: "Test Address",
            shortDescription: null,
            logoPath: null,
            timeZone: "Asia/Kolkata",
            currencyCode: "INR",
            taxIdentifier: null);
        _db.Companies.Add(company);
        await _db.SaveChangesAsync();

        const string password = "Test@123456";
        var user = new ApplicationUser
        {
            UserName = email,
            Email = email,
            PhoneNumber = phone,
            CompanyId = company.Id,
            IsActive = true,
            EmailConfirmed = true,
            PhoneNumberConfirmed = true,
        };
        var result = await _userManager.CreateAsync(user, password);
        Assert.True(result.Succeeded, string.Join(", ", result.Errors.Select(e => e.Description)));
        return (company, user, password);
    }

    private sealed class TestPaymentGatewayFactory : ISubscriptionPaymentGatewayFactory
    {
        public ISubscriptionPaymentGateway Resolve(MobilePaymentGatewayType gatewayType) => throw new NotSupportedException();
    }

    private sealed class TestTenantContext : ITenantContext
    {
        public Guid? CompanyId => null;
        public string? Region => null;
        public bool IsPlatformUser => true;
    }
}
