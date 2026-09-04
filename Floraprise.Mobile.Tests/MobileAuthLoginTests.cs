using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Sumpooj.API.Controllers;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Sumpooj.API.Controllers.Mobile;
using Sumpooj.API.Services.Mobile;
using Sumpooj.Application.Companies;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Mobile;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Companies;
using Sumpooj.Infrastructure.Identity;
using Sumpooj.Infrastructure.Persistence;
using Sumpooj.Infrastructure.Repositories;
using Xunit;

namespace Floraprise.Mobile.Tests;

public sealed class MobileAuthLoginTests : IDisposable
{
    private readonly ServiceProvider _provider;
    private readonly SumpoojDbContext _db;
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly RoleManager<IdentityRole<Guid>> _roleManager;
    private readonly MobileClientService _service;
    private readonly MobileAuthController _controller;

    public MobileAuthLoginTests()
    {
        var services = new ServiceCollection();
        services.AddLogging();
        services.AddSingleton<IConfiguration>(new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Jwt:Key"] = "test-mobile-auth-signing-key-with-enough-length-123456",
                ["Jwt:Issuer"] = "https://api.test.floraprise.local",
                ["Jwt:MobileAccessTokenMinutes"] = "30",
                ["MobileSubscription:TrialDays"] = "7",
                ["MobileSubscription:GraceDays"] = "30",
                ["MobileSubscription:OfflineDays"] = "3",
            })
            .Build());
        services.AddDbContext<SumpoojDbContext>(options =>
            options.UseInMemoryDatabase($"MobileAuthLogin_{Guid.NewGuid():N}"));
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
        services.AddScoped<ICompanyService, CompanyService>();
        services.AddScoped<IMobileClientService, MobileClientService>();
        services.AddScoped<MobileClientService>();
        services.AddScoped<MobileAuthController>();

        _provider = services.BuildServiceProvider();
        _db = _provider.GetRequiredService<SumpoojDbContext>();
        _userManager = _provider.GetRequiredService<UserManager<ApplicationUser>>();
        _roleManager = _provider.GetRequiredService<RoleManager<IdentityRole<Guid>>>();
        _service = _provider.GetRequiredService<MobileClientService>();
        _controller = _provider.GetRequiredService<MobileAuthController>();
    }

    public void Dispose()
    {
        _db.Dispose();
        _provider.Dispose();
    }

    private static ClaimsPrincipal Principal(params Claim[] claims) =>
        new(new ClaimsIdentity(claims, "test"));

    [Fact]
    public async Task Login_WithCompanyId_StillWorks()
    {
        var seeded = await SeedCompanyUserAsync();

        var response = await _service.LoginAsync(LoginRequest(
            identifier: seeded.User.Email!,
            password: seeded.Password,
            companyId: seeded.Company.Id));

        Assert.Equal(seeded.Company.Id, response.CompanyId);
        Assert.NotEqual(Guid.Empty, response.MobileUserId);
        Assert.NotEqual(Guid.Empty, response.MobileDeviceId);
        Assert.NotEmpty(response.AccessToken);
        Assert.NotEmpty(response.RefreshToken);
        Assert.Equal(seeded.Company.Id, response.Bootstrap.Company.Id);
    }

    [Fact]
    public async Task Login_WithoutCompanyId_ResolvesCompanyFromApplicationUser()
    {
        var seeded = await SeedCompanyUserAsync();

        var response = await _service.LoginAsync(LoginRequest(
            identifier: seeded.User.PhoneNumber!,
            password: seeded.Password));

        Assert.Equal(seeded.Company.Id, response.CompanyId);
        Assert.Equal(seeded.Company.Id, response.Bootstrap.Company.Id);

        var jwt = new JwtSecurityTokenHandler().ReadJwtToken(response.AccessToken);
        Assert.Equal(seeded.Company.Id.ToString(), jwt.Claims.Single(c => c.Type == "company_id").Value);
        Assert.Equal(response.MobileUserId.ToString(), jwt.Claims.Single(c => c.Type == JwtRegisteredClaimNames.Sub).Value);
        Assert.Equal(response.MobileUserId.ToString(), jwt.Claims.Single(c => c.Type == "mobile_user_id").Value);
        Assert.Equal(seeded.User.Id.ToString(), jwt.Claims.Single(c => c.Type == "identity_user_id").Value);
        Assert.NotEqual(response.MobileUserId, seeded.User.Id);
        Assert.Equal("test-device-001", jwt.Claims.Single(c => c.Type == "device_id").Value);
        Assert.Equal("mobile", jwt.Claims.Single(c => c.Type == "client_type").Value);
    }

    [Fact]
    public async Task Login_WithoutCompanyId_CreatesDeviceSessionAndRefreshRotates()
    {
        var seeded = await SeedCompanyUserAsync();
        var login = await _service.LoginAsync(LoginRequest(seeded.User.Email!, seeded.Password));

        var refresh = await _service.RefreshAsync(new MobileApiRefreshRequest(login.RefreshToken));

        Assert.NotEqual(login.RefreshToken, refresh.RefreshToken);
        Assert.Equal(seeded.Company.Id, refresh.CompanyId);
        Assert.Equal(login.MobileUserId, refresh.MobileUserId);
        Assert.Equal(login.MobileDeviceId, refresh.MobileDeviceId);
        Assert.False((await _db.DeviceSessions.SingleAsync(x => x.RefreshToken == login.RefreshToken)).IsActive(DateTime.UtcNow));
        Assert.True((await _db.DeviceSessions.SingleAsync(x => x.RefreshToken == refresh.RefreshToken)).IsActive(DateTime.UtcNow));

        var jwt = new JwtSecurityTokenHandler().ReadJwtToken(refresh.AccessToken);
        Assert.Equal(login.MobileUserId.ToString(), jwt.Claims.Single(c => c.Type == JwtRegisteredClaimNames.Sub).Value);
        Assert.Equal(login.MobileUserId.ToString(), jwt.Claims.Single(c => c.Type == "mobile_user_id").Value);
        Assert.Equal(seeded.User.Id.ToString(), jwt.Claims.Single(c => c.Type == "identity_user_id").Value);
    }

    [Fact]
    public void InventoryIdentityResolution_UsesIdentityUserIdForMobileToken()
    {
        var mobileUserId = Guid.NewGuid();
        var identityUserId = Guid.NewGuid();
        var principal = Principal(
            new Claim("client_type", "mobile"),
            new Claim("mobile_user_id", mobileUserId.ToString()),
            new Claim("identity_user_id", identityUserId.ToString()),
            new Claim(JwtRegisteredClaimNames.Sub, mobileUserId.ToString()));

        Assert.Equal(identityUserId, InventoryUserIdentityResolver.Resolve(principal));
    }

    [Fact]
    public void InventoryIdentityResolution_RejectsOldMobileTokenWithoutIdentityUserId()
    {
        var mobileUserId = Guid.NewGuid();
        var principal = Principal(
            new Claim("client_type", "mobile"),
            new Claim("mobile_user_id", mobileUserId.ToString()),
            new Claim(JwtRegisteredClaimNames.Sub, mobileUserId.ToString()));

        Assert.Throws<UnauthorizedAccessException>(() => InventoryUserIdentityResolver.Resolve(principal));
    }

    [Fact]
    public void InventoryIdentityResolution_UsesNameIdentifierForLegacyToken()
    {
        var identityUserId = Guid.NewGuid();
        var principal = Principal(new Claim(ClaimTypes.NameIdentifier, identityUserId.ToString()));

        Assert.Equal(identityUserId, InventoryUserIdentityResolver.Resolve(principal));
    }

    [Fact]
    public async Task Login_WrongPassword_Fails()
    {
        var seeded = await SeedCompanyUserAsync();

        await Assert.ThrowsAsync<UnauthorizedAccessException>(() => _service.LoginAsync(
            LoginRequest(seeded.User.Email!, "Wrong@123456")));
    }

    [Fact]
    public async Task Login_UnknownIdentifier_Fails()
    {
        await Assert.ThrowsAsync<UnauthorizedAccessException>(() => _service.LoginAsync(
            LoginRequest("missing@example.com", "Test@123456")));
    }

    [Fact]
    public async Task Login_DisabledUser_Fails()
    {
        var seeded = await SeedCompanyUserAsync(isActive: false);

        await Assert.ThrowsAsync<UnauthorizedAccessException>(() => _service.LoginAsync(
            LoginRequest(seeded.User.Email!, seeded.Password)));
    }

    [Fact]
    public async Task Login_PlatformUserWithoutCompany_FailsMobileCompanyLogin()
    {
        var user = new ApplicationUser
        {
            UserName = "platform@example.com",
            Email = "platform@example.com",
            PhoneNumber = "9000000000",
            CompanyId = null,
            IsActive = true,
            EmailConfirmed = true,
            PhoneNumberConfirmed = true,
        };
        var result = await _userManager.CreateAsync(user, "Test@123456");
        Assert.True(result.Succeeded, string.Join(", ", result.Errors.Select(e => e.Description)));

        var error = await Assert.ThrowsAsync<UnauthorizedAccessException>(() => _service.LoginAsync(
            LoginRequest(user.Email!, "Test@123456")));
        Assert.Equal("Mobile access requires a company account.", error.Message);
    }

    [Fact]
    public async Task Register_NewCompany_Succeeds()
    {
        await EnsureCompanyAdminRoleAsync();

        var result = await _controller.Register(RegisterRequest(
            companyName: "New Florist",
            mobile: "9876543210",
            email: "new@example.com"), CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(ok.Value);
        Assert.Equal(1, await _db.Companies.CountAsync(c => c.Name == "New Florist"));
    }

    [Fact]
    public async Task Register_SameCompanyNameAndNormalizedPhone_IsRejected()
    {
        await SeedCompanyOnlyAsync("Rose Palace", "+91 98765 43210", "rose@example.com");
        var beforeCount = await _db.Companies.CountAsync();

        var result = await _controller.Register(RegisterRequest(
            companyName: "  rose-palace  ",
            mobile: "9876543210",
            email: "owner@example.com"), CancellationToken.None);

        var conflict = Assert.IsType<ConflictObjectResult>(result);
        Assert.Contains("This company is already registered with Floraprise", conflict.Value!.ToString());
        Assert.Equal(beforeCount, await _db.Companies.CountAsync());
    }

    [Fact]
    public async Task Register_SameCompanyNameWithDifferentPhone_IsAllowed()
    {
        await EnsureCompanyAdminRoleAsync();
        await SeedCompanyOnlyAsync("Rose Palace", "9876543210", "rose@example.com");

        var result = await _controller.Register(RegisterRequest(
            companyName: "Rose Palace",
            mobile: "9876543211",
            email: "rose2@example.com"), CancellationToken.None);

        Assert.IsType<OkObjectResult>(result);
        Assert.Equal(2, await _db.Companies.CountAsync(c => c.Name == "Rose Palace"));
    }

    [Fact]
    public async Task Register_DifferentCompanyNameWithSameNormalizedPhone_IsNotCompanyDuplicate()
    {
        await EnsureCompanyAdminRoleAsync();
        await SeedCompanyOnlyAsync("Rose Palace", "9876543210", "rose@example.com");

        var result = await _controller.Register(RegisterRequest(
            companyName: "Lotus Palace",
            mobile: "9876543210",
            email: "lotus@example.com"), CancellationToken.None);

        Assert.IsType<OkObjectResult>(result);
        Assert.Equal(2, await _db.Companies.CountAsync());
    }

    [Fact]
    public async Task Register_PhoneFormattingDifferences_AreNormalizedForCompanyDuplicate()
    {
        await SeedCompanyOnlyAsync("Morning Flowers", "+919876543210", "morning@example.com");

        var result = await _controller.Register(RegisterRequest(
            companyName: "Morning Flowers",
            mobile: "98765 43210",
            email: "other@example.com"), CancellationToken.None);

        Assert.IsType<ConflictObjectResult>(result);
        Assert.Equal(1, await _db.Companies.CountAsync());
    }

    private async Task<(Company Company, ApplicationUser User, string Password)> SeedCompanyUserAsync(bool isActive = true)
    {
        var company = new Company(
            name: "Test Florist",
            region: "IN",
            email: "owner@example.com",
            phone: "9999999999",
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
            UserName = "owner@example.com",
            Email = "owner@example.com",
            PhoneNumber = "9876543210",
            CompanyId = company.Id,
            IsActive = isActive,
            EmailConfirmed = true,
            PhoneNumberConfirmed = true,
        };
        var result = await _userManager.CreateAsync(user, password);
        Assert.True(result.Succeeded, string.Join(", ", result.Errors.Select(e => e.Description)));
        return (company, user, password);
    }

    private async Task<Company> SeedCompanyOnlyAsync(string name, string phone, string email)
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
        return company;
    }

    private async Task EnsureCompanyAdminRoleAsync()
    {
        if (!await _roleManager.RoleExistsAsync("CompanyAdmin"))
        {
            var result = await _roleManager.CreateAsync(new IdentityRole<Guid>("CompanyAdmin"));
            Assert.True(result.Succeeded, string.Join(", ", result.Errors.Select(e => e.Description)));
        }
    }

    private static MobileApiRegisterRequest RegisterRequest(string companyName, string mobile, string email)
    {
        return new MobileApiRegisterRequest(
            CompanyName: companyName,
            OwnerName: "Test Owner",
            Mobile: mobile,
            Address: "Test Address",
            City: "Delhi",
            Email: email,
            Password: "Test@123456",
            DeviceId: $"device-{Guid.NewGuid():N}",
            Platform: "ANDROID",
            Manufacturer: "Test",
            Model: "Test Phone",
            OsVersion: "15",
            AppVersion: "1.0.0",
            PushToken: null,
            IpAddress: "127.0.0.1");
    }

    private static MobileApiLoginRequest LoginRequest(string identifier, string password, Guid? companyId = null)
    {
        return new MobileApiLoginRequest(
            CompanyId: companyId,
            Identifier: identifier,
            Password: password,
            DeviceId: "test-device-001",
            Platform: "ANDROID",
            Manufacturer: "Test",
            Model: "Test Phone",
            OsVersion: "15",
            AppVersion: "1.0.0",
            PushToken: null,
            IpAddress: "127.0.0.1");
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