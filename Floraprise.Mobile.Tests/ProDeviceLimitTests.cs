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
    public async Task ProAccount_AllowsThreeActiveDevices_AndRejectsFourthDevice()
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

        // Verify all 3 devices are active
        var activeDevices = await _db.MobileDevices.Where(d => d.CompanyId == seeded.Company.Id && d.Status == MobileDeviceStatus.Active).ToListAsync();
        Assert.Equal(3, activeDevices.Count);

        // Device 4 -> rejected with clear limit message
        var ex = await Assert.ThrowsAsync<InvalidOperationException>(() =>
            _clientService.LoginAsync(MakeLoginRequest(seeded.User.Email!, seeded.Password, "device-fourth-004", "ANDROID")));

        Assert.Contains("Maximum 3 devices are already active for this account.", ex.Message);
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
    public async Task RevokingDevice_AllowsNewDeviceRegistration()
    {
        var seeded = await SeedCompanyUserAsync();

        await _clientService.LoginAsync(MakeLoginRequest(seeded.User.Email!, seeded.Password, "device-1", "ANDROID"));
        await UpgradeToProAsync(seeded.Company.Id);

        await _clientService.LoginAsync(MakeLoginRequest(seeded.User.Email!, seeded.Password, "device-2", "ANDROID"));
        await _clientService.LoginAsync(MakeLoginRequest(seeded.User.Email!, seeded.Password, "device-3", "WEB"));

        // 4th device rejected
        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            _clientService.LoginAsync(MakeLoginRequest(seeded.User.Email!, seeded.Password, "device-4", "ANDROID")));

        // Revoke / deactivate device-1
        var dev1 = await _db.MobileDevices.FirstAsync(d => d.DeviceId == "device-1");
        dev1.Revoke(null);
        await _db.SaveChangesAsync();

        // 4th device can now log in successfully
        var login4 = await _clientService.LoginAsync(MakeLoginRequest(seeded.User.Email!, seeded.Password, "device-4", "ANDROID"));
        Assert.NotNull(login4.AccessToken);

        var activeDevices = await _db.MobileDevices.Where(d => d.CompanyId == seeded.Company.Id && d.Status == MobileDeviceStatus.Active).ToListAsync();
        Assert.Equal(3, activeDevices.Count);
    }

    [Fact]
    public async Task TenantIsolation_DevicesOfOneTenant_DoNotAffectAnotherTenantDeviceLimit()
    {
        var tenantA = await SeedCompanyUserAsync("Tenant A Florist", "9111111111", "a@example.com");
        var tenantB = await SeedCompanyUserAsync("Tenant B Florist", "9222222222", "b@example.com");

        // Tenant A logs in 3 devices on Pro
        await _clientService.LoginAsync(MakeLoginRequest(tenantA.User.Email!, tenantA.Password, "dev-a-1", "ANDROID"));
        await UpgradeToProAsync(tenantA.Company.Id);
        await _clientService.LoginAsync(MakeLoginRequest(tenantA.User.Email!, tenantA.Password, "dev-a-2", "ANDROID"));
        await _clientService.LoginAsync(MakeLoginRequest(tenantA.User.Email!, tenantA.Password, "dev-a-3", "WEB"));

        // Tenant A 4th device rejected
        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            _clientService.LoginAsync(MakeLoginRequest(tenantA.User.Email!, tenantA.Password, "dev-a-4", "ANDROID")));

        // Tenant B can register and log in their own devices independently
        var b1 = await _clientService.LoginAsync(MakeLoginRequest(tenantB.User.Email!, tenantB.Password, "dev-b-1", "ANDROID"));
        Assert.NotNull(b1.AccessToken);
        await UpgradeToProAsync(tenantB.Company.Id);

        var b2 = await _clientService.LoginAsync(MakeLoginRequest(tenantB.User.Email!, tenantB.Password, "dev-b-2", "ANDROID"));
        Assert.NotNull(b2.AccessToken);

        var b3 = await _clientService.LoginAsync(MakeLoginRequest(tenantB.User.Email!, tenantB.Password, "dev-b-3", "WEB"));
        Assert.NotNull(b3.AccessToken);

        Assert.Equal(3, await _db.MobileDevices.CountAsync(d => d.CompanyId == tenantA.Company.Id && d.Status == MobileDeviceStatus.Active));
        Assert.Equal(3, await _db.MobileDevices.CountAsync(d => d.CompanyId == tenantB.Company.Id && d.Status == MobileDeviceStatus.Active));
    }

    [Fact]
    public async Task BasicOrTrialPlan_PreservesOriginalDeviceLimitOfTwo()
    {
        var seeded = await SeedCompanyUserAsync("Basic Florist", "9333333333", "basic@example.com");

        // Basic / trial user logs in 2 devices
        await _clientService.LoginAsync(MakeLoginRequest(seeded.User.Email!, seeded.Password, "basic-dev-1", "ANDROID"));
        await _clientService.LoginAsync(MakeLoginRequest(seeded.User.Email!, seeded.Password, "basic-dev-2", "WEB"));

        // 3rd device on Basic/Trial is rejected with 2 devices message
        var ex = await Assert.ThrowsAsync<InvalidOperationException>(() =>
            _clientService.LoginAsync(MakeLoginRequest(seeded.User.Email!, seeded.Password, "basic-dev-3", "ANDROID")));

        Assert.Contains("Maximum 2 devices are already active for this account.", ex.Message);
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
