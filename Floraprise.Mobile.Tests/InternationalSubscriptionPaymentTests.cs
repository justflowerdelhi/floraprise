using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
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

public class InternationalSubscriptionPaymentTests : IDisposable
{
    private readonly ServiceProvider _provider;
    private readonly SumpoojDbContext _db;
    private readonly MobileClientService _mobileClientService;
    private readonly MobileAuthController _authController;
    private readonly SubscriptionPaymentGatewayFactory _gatewayFactory;
    private readonly IConfiguration _configuration;

    public InternationalSubscriptionPaymentTests()
    {
        var services = new ServiceCollection();
        services.AddLogging(builder => builder.AddConsole().SetMinimumLevel(LogLevel.Warning));

        var inMemoryConfig = new Dictionary<string, string?>
        {
            ["Jwt:Key"] = "test-jwt-secret-key-that-is-at-least-256-bits-long-for-testing!!",
            ["Jwt:Issuer"] = "FlorapriseTest",
            ["Jwt:MobileAccessTokenMinutes"] = "60",
            ["MobilePayment:PayPal:WebhookId"] = "WH-TEST-WEBHOOK-ID-12345"
        };
        _configuration = new ConfigurationBuilder().AddInMemoryCollection(inMemoryConfig).Build();
        services.AddSingleton<IConfiguration>(_configuration);

        services.AddDbContext<SumpoojDbContext>(options =>
            options.UseInMemoryDatabase($"IntlSubTests_{Guid.NewGuid():N}")
                .ConfigureWarnings(warnings => warnings.Ignore(InMemoryEventId.TransactionIgnoredWarning)));

        services.AddSingleton<ITenantContext, TestTenantContext>();
        services.AddIdentity<ApplicationUser, IdentityRole<Guid>>(options =>
        {
            options.Password.RequireDigit = false;
            options.Password.RequiredLength = 6;
            options.Password.RequireUppercase = false;
            options.Password.RequireLowercase = false;
            options.Password.RequireNonAlphanumeric = false;
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

        services.AddScoped<ISubscriptionPaymentGateway, RazorpaySubscriptionPaymentGateway>();
        services.AddScoped<ISubscriptionPaymentGateway, StripeSubscriptionPaymentGateway>();
        services.AddScoped<ISubscriptionPaymentGateway, PayPalSubscriptionPaymentGateway>();
        services.AddScoped<ISubscriptionPaymentGateway, PayUSubscriptionPaymentGateway>();
        services.AddScoped<ISubscriptionPaymentGatewayFactory, SubscriptionPaymentGatewayFactory>();

        services.AddScoped<ILocationRepository, LocationRepository>();
        services.AddScoped<ICompanyService, CompanyService>();
        services.AddScoped<IMobileClientService, MobileClientService>();
        services.AddScoped<MobileClientService>();
        services.AddScoped<MobileAuthController>();
        services.AddScoped<MobilePaymentController>();

        _provider = services.BuildServiceProvider();
        _db = _provider.GetRequiredService<SumpoojDbContext>();
        _mobileClientService = _provider.GetRequiredService<MobileClientService>();
        _authController = _provider.GetRequiredService<MobileAuthController>();
        _gatewayFactory = (SubscriptionPaymentGatewayFactory)_provider.GetRequiredService<ISubscriptionPaymentGatewayFactory>();

        _authController.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext
            {
                Connection = { RemoteIpAddress = System.Net.IPAddress.Loopback }
            }
        };

        EnsureSubscriptionPlans();
    }

    public void Dispose()
    {
        _db.Dispose();
        _provider.Dispose();
    }

    private void EnsureSubscriptionPlans()
    {
        if (!_db.SubscriptionPlans.Any(p => p.Code == "PRO"))
        {
            var plan = new SubscriptionPlan("PRO", "Floraprise Pro", MobilePlanType.Pro, 0, 14999m, 0, 5, 14, 7, 30, 1000, "INR");
            _db.SubscriptionPlans.Add(plan);
            _db.SaveChanges();
        }
    }

    private static void SetPrivateProperty<T>(T obj, string propertyName, object? value)
    {
        var prop = typeof(T).GetProperty(propertyName, System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
        prop?.SetValue(obj, value);
    }

    private async Task<(Guid CompanyId, Guid UserId, string DeviceId)> RegisterCompanyAndUserAsync(string companyName, string region, string currency, string email, string mobile)
    {
        var roleManager = _provider.GetRequiredService<RoleManager<IdentityRole<Guid>>>();
        if (!await roleManager.RoleExistsAsync("CompanyAdmin"))
        {
            await roleManager.CreateAsync(new IdentityRole<Guid>("CompanyAdmin"));
        }

        var deviceId = $"dev_{Guid.NewGuid():N}";
        var registerReq = new MobileApiRegisterRequest(
            CompanyName: companyName,
            OwnerName: "Owner",
            Mobile: mobile,
            Address: "123 Business St",
            City: "City",
            Email: email,
            Password: "Password123",
            DeviceId: deviceId,
            Platform: "ANDROID",
            Manufacturer: "Google",
            Model: "Pixel 9",
            OsVersion: "15",
            AppVersion: "1.0.0",
            PushToken: null,
            IpAddress: "127.0.0.1");

        var result = await _authController.Register(registerReq, CancellationToken.None);
        var ok = Assert.IsType<OkObjectResult>(result);
        var authResponse = Assert.IsType<MobileAuthTokenResponse>(ok.Value);

        var company = await _db.Companies.FindAsync(authResponse.CompanyId);
        if (company != null)
        {
            SetPrivateProperty(company, "Region", region);
            company.UpdateLocalization(company.TimeZone ?? "UTC", currency);
            await _db.SaveChangesAsync();
        }

        return (authResponse.CompanyId, authResponse.MobileUserId, deviceId);
    }

    // ==========================================
    // 1. INDIA PRICING MATRIX RESOLUTION
    // ==========================================
    [Theory]
    [InlineData("QUARTERLY", 4999.00, "INR", 90, MobilePaymentGatewayType.PayU)]
    [InlineData("HALF-YEARLY", 8999.00, "INR", 180, MobilePaymentGatewayType.PayU)]
    [InlineData("ANNUAL", 14999.00, "INR", 365, MobilePaymentGatewayType.PayU)]
    public void SubscriptionCountryPricing_India_ResolvesAccuratePricing(string cycle, decimal expectedAmount, string expectedCurrency, int expectedDays, MobilePaymentGatewayType expectedGateway)
    {
        var pricing = SubscriptionCountryPricing.ResolvePricing("IN", cycle);

        Assert.Equal(expectedAmount, pricing.Amount);
        Assert.Equal(expectedCurrency, pricing.Currency);
        Assert.Equal(expectedDays, pricing.DurationDays);
        Assert.Equal(expectedGateway, pricing.Gateway);
    }

    // ==========================================
    // 2. USA PRICING MATRIX RESOLUTION
    // ==========================================
    [Theory]
    [InlineData("QUARTERLY", 179.00, "USD", 90, MobilePaymentGatewayType.PayPal)]
    [InlineData("HALF-YEARLY", 329.00, "USD", 180, MobilePaymentGatewayType.PayPal)]
    [InlineData("ANNUAL", 599.00, "USD", 365, MobilePaymentGatewayType.PayPal)]
    public void SubscriptionCountryPricing_USA_ResolvesAccuratePricing(string cycle, decimal expectedAmount, string expectedCurrency, int expectedDays, MobilePaymentGatewayType expectedGateway)
    {
        var pricing = SubscriptionCountryPricing.ResolvePricing("US", cycle);

        Assert.Equal(expectedAmount, pricing.Amount);
        Assert.Equal(expectedCurrency, pricing.Currency);
        Assert.Equal(expectedDays, pricing.DurationDays);
        Assert.Equal(expectedGateway, pricing.Gateway);
    }

    // ==========================================
    // 3. UAE PRICING MATRIX RESOLUTION
    // ==========================================
    [Theory]
    [InlineData("QUARTERLY", 649.00, "AED", 90, MobilePaymentGatewayType.PayPal)]
    [InlineData("HALF-YEARLY", 1199.00, "AED", 180, MobilePaymentGatewayType.PayPal)]
    [InlineData("ANNUAL", 2199.00, "AED", 365, MobilePaymentGatewayType.PayPal)]
    public void SubscriptionCountryPricing_UAE_ResolvesAccuratePricing(string cycle, decimal expectedAmount, string expectedCurrency, int expectedDays, MobilePaymentGatewayType expectedGateway)
    {
        var pricing = SubscriptionCountryPricing.ResolvePricing("AE", cycle);

        Assert.Equal(expectedAmount, pricing.Amount);
        Assert.Equal(expectedCurrency, pricing.Currency);
        Assert.Equal(expectedDays, pricing.DurationDays);
        Assert.Equal(expectedGateway, pricing.Gateway);
    }

    // ==========================================
    // 4. MISSING / UNKNOWN COUNTRY FALLBACK
    // ==========================================
    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData("UNKNOWN_COUNTRY")]
    [InlineData("XYZ")]
    public void SubscriptionCountryPricing_Fallback_DefaultsToIndia(string? countryCode)
    {
        var pricing = SubscriptionCountryPricing.ResolvePricing(countryCode, "ANNUAL");

        Assert.Equal(14999.00m, pricing.Amount);
        Assert.Equal("INR", pricing.Currency);
        Assert.Equal(365, pricing.DurationDays);
        Assert.Equal(MobilePaymentGatewayType.PayU, pricing.Gateway);
    }

    // ==========================================
    // 5. BILLING CYCLE NORMALIZATION
    // ==========================================
    [Theory]
    [InlineData("quarterly", 90)]
    [InlineData("Quarter", 90)]
    [InlineData("3months", 90)]
    [InlineData("3M", 90)]
    [InlineData("half-yearly", 180)]
    [InlineData("halfyearly", 180)]
    [InlineData("HALF_YEARLY", 180)]
    [InlineData("6months", 180)]
    [InlineData("annual", 365)]
    [InlineData("yearly", 365)]
    [InlineData("1year", 365)]
    [InlineData("12months", 365)]
    [InlineData("invalid_cycle", 365)]
    public void SubscriptionCountryPricing_BillingCycleToDays_NormalizesCorrectly(string cycle, int expectedDays)
    {
        var days = SubscriptionCountryPricing.BillingCycleToDays(cycle);
        Assert.Equal(expectedDays, days);
    }

    // ==========================================
    // 6. COUNTRY / REGION PREFIX NORMALIZATION
    // ==========================================
    [Theory]
    [InlineData("IN-DL", "IN")]
    [InlineData("IN-MH", "IN")]
    [InlineData("IND", "IN")]
    [InlineData("India", "IN")]
    [InlineData("US-CA", "US")]
    [InlineData("US-NY", "US")]
    [InlineData("USA", "US")]
    [InlineData("United States", "US")]
    [InlineData("AE-DU", "AE")]
    [InlineData("UAE", "AE")]
    [InlineData("Dubai", "AE")]
    public void SubscriptionCountryPricing_NormalizeCountryCode_HandlesRegions(string input, string expectedCode)
    {
        var code = SubscriptionCountryPricing.NormalizeCountryCode(input);
        Assert.Equal(expectedCode, code);
    }

    // ==========================================
    // 7. SERVER-SIDE PRICE TAMPERING RESISTANCE
    // ==========================================
    [Fact]
    public async Task CreateSubscriptionOrder_ClientSendsTamperedPrice_ServerOverridesWithAuthoritativePrice()
    {
        var (companyId, userId, _) = await RegisterCompanyAndUserAsync("US Florist", "US", "USD", "tamper_us@example.com", "+12025550100");
        var subState = await _mobileClientService.GetCurrentSubscriptionAsync(companyId, userId);

        var tamperedRequest = new CreateSubscriptionOrderRequest(
            Gateway: MobilePaymentGatewayType.PayPal,
            SubscriptionId: subState.SubscriptionId,
            Amount: 1.00m, // Client sends $1.00 instead of $599.00
            Currency: "USD",
            PlanCode: "PRO",
            BillingCycle: "annual",
            ReturnUrl: null);

        var orderResponse = await _mobileClientService.CreateSubscriptionOrderAsync(companyId, userId, tamperedRequest);

        // Server MUST override to 599.00 USD
        Assert.Equal(599.00m, orderResponse.Amount);
        Assert.Equal("USD", orderResponse.Currency);
        Assert.Equal(MobilePaymentGatewayType.PayPal, orderResponse.Gateway);
    }

    // ==========================================
    // 8. SERVER-SIDE CURRENCY TAMPERING RESISTANCE
    // ==========================================
    [Fact]
    public async Task CreateSubscriptionOrder_ClientSendsTamperedCurrency_ServerOverridesWithCountryCurrency()
    {
        var (companyId, userId, _) = await RegisterCompanyAndUserAsync("India Florist", "IN", "INR", "tamper_in@example.com", "9876543210");
        var subState = await _mobileClientService.GetCurrentSubscriptionAsync(companyId, userId);

        var tamperedRequest = new CreateSubscriptionOrderRequest(
            Gateway: MobilePaymentGatewayType.PayU,
            SubscriptionId: subState.SubscriptionId,
            Amount: 14999.00m,
            Currency: "USD", // Client sends USD for Indian company
            PlanCode: "PRO",
            BillingCycle: "annual",
            ReturnUrl: null);

        var orderResponse = await _mobileClientService.CreateSubscriptionOrderAsync(companyId, userId, tamperedRequest);

        // Server MUST override currency to INR
        Assert.Equal("INR", orderResponse.Currency);
        Assert.Equal(14999.00m, orderResponse.Amount);
    }

    // ==========================================
    // 9. SERVER-SIDE GATEWAY ROUTING ENFORCEMENT
    // ==========================================
    [Fact]
    public async Task CreateSubscriptionOrder_USCompanyRequestsStripe_ServerRoutesToPayPal()
    {
        var (companyId, userId, _) = await RegisterCompanyAndUserAsync("US Store", "US", "USD", "route_us@example.com", "+12025550101");
        var subState = await _mobileClientService.GetCurrentSubscriptionAsync(companyId, userId);

        var request = new CreateSubscriptionOrderRequest(
            Gateway: MobilePaymentGatewayType.Stripe,
            SubscriptionId: subState.SubscriptionId,
            Amount: 0m,
            Currency: "USD",
            PlanCode: "PRO",
            BillingCycle: "quarterly",
            ReturnUrl: null);

        var orderResponse = await _mobileClientService.CreateSubscriptionOrderAsync(companyId, userId, request);

        Assert.Equal(MobilePaymentGatewayType.PayPal, orderResponse.Gateway);
        Assert.Equal(179.00m, orderResponse.Amount);
        Assert.Equal("USD", orderResponse.Currency);
    }

    // ==========================================
    // 10. PAYPAL ORDER CREATION CONTRACT
    // ==========================================
    [Fact]
    public async Task PayPalGateway_CreateOrder_ReturnsValidPayloadAndApprovalUrl()
    {
        var gateway = _gatewayFactory.Resolve(MobilePaymentGatewayType.PayPal);

        var request = new CreateSubscriptionOrderRequest(
            Gateway: MobilePaymentGatewayType.PayPal,
            SubscriptionId: Guid.NewGuid(),
            Amount: 179.00m,
            Currency: "USD",
            PlanCode: "PRO",
            BillingCycle: "quarterly",
            ReturnUrl: "https://floraprise.com/payment/success");

        var (orderId, clientPayload) = await gateway.CreateOrderAsync(request);

        Assert.NotEmpty(orderId);
        Assert.Equal("paypal", clientPayload["gateway"]);
        Assert.Equal(orderId, clientPayload["orderId"]);
        Assert.Equal("179.00", clientPayload["amount"]);
        Assert.Equal("USD", clientPayload["currency"]);
        Assert.NotEmpty(clientPayload["approvalUrl"]);
    }

    // ==========================================
    // 11. PAYPAL VERIFICATION FLOW
    // ==========================================
    [Fact]
    public async Task PayPalGateway_VerifyPayment_ValidatesOrderPresence()
    {
        var gateway = _gatewayFactory.Resolve(MobilePaymentGatewayType.PayPal);

        var request = new PaymentVerificationRequest(
            Gateway: MobilePaymentGatewayType.PayPal,
            TransactionRef: "MOB-123456",
            GatewayOrderId: "paypal_order_test_123",
            GatewayPaymentId: "paypal_capture_test_123",
            Signature: null,
            PlanCode: "PRO",
            BillingCycle: "annual");

        var verified = await gateway.VerifyPaymentAsync(request);
        Assert.True(verified);
    }

    // ==========================================
    // 12. PAYU ORDER CREATION & SHA512 HASH
    // ==========================================
    [Fact]
    public async Task PayUGateway_CreateOrder_GeneratesSha512HashAndPaymentUrl()
    {
        var gateway = _gatewayFactory.Resolve(MobilePaymentGatewayType.PayU);

        var request = new CreateSubscriptionOrderRequest(
            Gateway: MobilePaymentGatewayType.PayU,
            SubscriptionId: Guid.NewGuid(),
            Amount: 4999.00m,
            Currency: "INR",
            PlanCode: "PRO",
            BillingCycle: "quarterly",
            ReturnUrl: null);

        var (orderId, clientPayload) = await gateway.CreateOrderAsync(request);

        Assert.NotEmpty(orderId);
        Assert.Equal("payu", clientPayload["gateway"]);
        Assert.Equal("4999.00", clientPayload["amount"]);
        Assert.NotEmpty(clientPayload["hash"]);
        Assert.NotEmpty(clientPayload["paymentUrl"]);
    }

    // ==========================================
    // 13. SUBSCRIPTION DURATION: QUARTERLY (90 DAYS)
    // ==========================================
    [Fact]
    public async Task CompletePayment_QuarterlyPlan_ExtendsSubscriptionBy90Days()
    {
        var (companyId, userId, _) = await RegisterCompanyAndUserAsync("US Quarterly", "US", "USD", "q_us@example.com", "+12025550102");
        var subState = await _mobileClientService.GetCurrentSubscriptionAsync(companyId, userId);

        var createOrder = await _mobileClientService.CreateSubscriptionOrderAsync(
            companyId,
            userId,
            new CreateSubscriptionOrderRequest(
                Gateway: MobilePaymentGatewayType.PayPal,
                SubscriptionId: subState.SubscriptionId,
                Amount: 179.00m,
                Currency: "USD",
                PlanCode: "PRO",
                BillingCycle: "quarterly",
                ReturnUrl: null));

        var verifyResponse = await _mobileClientService.VerifyPaymentAsync(
            companyId,
            userId,
            new PaymentVerificationRequest(
                Gateway: MobilePaymentGatewayType.PayPal,
                TransactionRef: createOrder.TransactionRef,
                GatewayOrderId: createOrder.GatewayOrderId,
                GatewayPaymentId: createOrder.GatewayOrderId,
                Signature: null,
                PlanCode: "PRO",
                BillingCycle: "quarterly"));

        Assert.True(verifyResponse.Verified);

        var updatedSub = await _mobileClientService.GetCurrentSubscriptionAsync(companyId, userId);
        Assert.Equal(MobileSubscriptionStatus.Active, updatedSub.Status);
        Assert.InRange(updatedSub.RemainingDays, 89, 90);
    }

    // ==========================================
    // 14. SUBSCRIPTION DURATION: HALF-YEARLY (180 DAYS)
    // ==========================================
    [Fact]
    public async Task CompletePayment_HalfYearlyPlan_ExtendsSubscriptionBy180Days()
    {
        var (companyId, userId, _) = await RegisterCompanyAndUserAsync("Dubai HalfYearly", "AE", "AED", "hy_ae@example.com", "+971501234500");
        var subState = await _mobileClientService.GetCurrentSubscriptionAsync(companyId, userId);

        var createOrder = await _mobileClientService.CreateSubscriptionOrderAsync(
            companyId,
            userId,
            new CreateSubscriptionOrderRequest(
                Gateway: MobilePaymentGatewayType.PayPal,
                SubscriptionId: subState.SubscriptionId,
                Amount: 1199.00m,
                Currency: "AED",
                PlanCode: "PRO",
                BillingCycle: "half-yearly",
                ReturnUrl: null));

        var verifyResponse = await _mobileClientService.VerifyPaymentAsync(
            companyId,
            userId,
            new PaymentVerificationRequest(
                Gateway: MobilePaymentGatewayType.PayPal,
                TransactionRef: createOrder.TransactionRef,
                GatewayOrderId: createOrder.GatewayOrderId,
                GatewayPaymentId: createOrder.GatewayOrderId,
                Signature: null,
                PlanCode: "PRO",
                BillingCycle: "half-yearly"));

        Assert.True(verifyResponse.Verified);

        var updatedSub = await _mobileClientService.GetCurrentSubscriptionAsync(companyId, userId);
        Assert.Equal(MobileSubscriptionStatus.Active, updatedSub.Status);
        Assert.InRange(updatedSub.RemainingDays, 179, 180);
    }

    // ==========================================
    // 15. SUBSCRIPTION DURATION: ANNUAL (365 DAYS)
    // ==========================================
    [Fact]
    public async Task CompletePayment_AnnualPlan_ExtendsSubscriptionBy365Days()
    {
        var (companyId, userId, _) = await RegisterCompanyAndUserAsync("India Annual", "IN", "INR", "ann_in@example.com", "9876543211");
        var subState = await _mobileClientService.GetCurrentSubscriptionAsync(companyId, userId);

        var createOrder = await _mobileClientService.CreateSubscriptionOrderAsync(
            companyId,
            userId,
            new CreateSubscriptionOrderRequest(
                Gateway: MobilePaymentGatewayType.PayU,
                SubscriptionId: subState.SubscriptionId,
                Amount: 14999.00m,
                Currency: "INR",
                PlanCode: "PRO",
                BillingCycle: "annual",
                ReturnUrl: null));

        var verifyResponse = await _mobileClientService.VerifyPaymentAsync(
            companyId,
            userId,
            new PaymentVerificationRequest(
                Gateway: MobilePaymentGatewayType.PayU,
                TransactionRef: createOrder.TransactionRef,
                GatewayOrderId: createOrder.GatewayOrderId,
                GatewayPaymentId: createOrder.GatewayOrderId,
                Signature: null,
                PlanCode: "PRO",
                BillingCycle: "annual"));

        Assert.True(verifyResponse.Verified);

        var updatedSub = await _mobileClientService.GetCurrentSubscriptionAsync(companyId, userId);
        Assert.Equal(MobileSubscriptionStatus.Active, updatedSub.Status);
        Assert.InRange(updatedSub.RemainingDays, 364, 365);
    }

    // ==========================================
    // 16. DEVICE LICENSE SYNCHRONIZATION
    // ==========================================
    [Fact]
    public async Task CompletePayment_UpdatesAllCompanyDeviceLicenses()
    {
        var (companyId, userId, primaryDeviceId) = await RegisterCompanyAndUserAsync("Sync US", "US", "USD", "sync_us@example.com", "+12025550103");
        var subState = await _mobileClientService.GetCurrentSubscriptionAsync(companyId, userId);

        // Register second device
        await _mobileClientService.RegisterDeviceAsync(
            companyId,
            userId,
            new MobileDeviceRegisterRequest("device_us_2", "ANDROID", "Samsung", "Galaxy", "15", "1.0.0", null, null));

        // Create and complete annual payment
        var createOrder = await _mobileClientService.CreateSubscriptionOrderAsync(
            companyId,
            userId,
            new CreateSubscriptionOrderRequest(
                Gateway: MobilePaymentGatewayType.PayPal,
                SubscriptionId: subState.SubscriptionId,
                Amount: 599.00m,
                Currency: "USD",
                PlanCode: "PRO",
                BillingCycle: "annual",
                ReturnUrl: null));

        await _mobileClientService.VerifyPaymentAsync(
            companyId,
            userId,
            new PaymentVerificationRequest(
                Gateway: MobilePaymentGatewayType.PayPal,
                TransactionRef: createOrder.TransactionRef,
                GatewayOrderId: createOrder.GatewayOrderId,
                GatewayPaymentId: createOrder.GatewayOrderId,
                Signature: null,
                PlanCode: "PRO",
                BillingCycle: "annual"));

        var license1 = await _mobileClientService.GetLicenseStatusAsync(companyId, userId, primaryDeviceId);
        var license2 = await _mobileClientService.GetLicenseStatusAsync(companyId, userId, "device_us_2");

        Assert.Equal(MobileLicenseStatus.Active, license1.LicenseStatus);
        Assert.Equal(MobileLicenseStatus.Active, license2.LicenseStatus);
        Assert.InRange(license1.RemainingDays, 364, 365);
        Assert.InRange(license2.RemainingDays, 364, 365);
    }

    // ==========================================
    // 17. IDEMPOTENT PAYMENT CALLBACK
    // ==========================================
    [Fact]
    public async Task PaymentCallback_DuplicateCall_IsIdempotentAndDoesNotDoubleExtend()
    {
        var (companyId, userId, _) = await RegisterCompanyAndUserAsync("Idem AE", "AE", "AED", "idem_ae@example.com", "+971501234501");
        var subState = await _mobileClientService.GetCurrentSubscriptionAsync(companyId, userId);

        var createOrder = await _mobileClientService.CreateSubscriptionOrderAsync(
            companyId,
            userId,
            new CreateSubscriptionOrderRequest(
                Gateway: MobilePaymentGatewayType.PayPal,
                SubscriptionId: subState.SubscriptionId,
                Amount: 2199.00m,
                Currency: "AED",
                PlanCode: "PRO",
                BillingCycle: "annual",
                ReturnUrl: null));

        var callbackRequest = new PaymentCallbackRequest(
            Gateway: MobilePaymentGatewayType.PayPal,
            TransactionRef: createOrder.TransactionRef,
            GatewayOrderId: createOrder.GatewayOrderId,
            GatewayPaymentId: createOrder.GatewayOrderId,
            Status: "paid",
            Signature: null,
            PlanCode: "PRO",
            BillingCycle: "annual",
            Metadata: null);

        // First callback
        var first = await _mobileClientService.PaymentCallbackAsync(companyId, userId, callbackRequest);
        Assert.True(first.Updated);

        var subAfterFirst = await _mobileClientService.GetCurrentSubscriptionAsync(companyId, userId);
        var expiryFirst = subAfterFirst.EndUtc;

        // Second duplicate callback
        var second = await _mobileClientService.PaymentCallbackAsync(companyId, userId, callbackRequest);
        Assert.False(second.Updated);
        Assert.Equal("Already Processed", second.Message);

        var subAfterSecond = await _mobileClientService.GetCurrentSubscriptionAsync(companyId, userId);
        Assert.Equal(expiryFirst, subAfterSecond.EndUtc); // Unchanged
    }

    // ==========================================
    // 18. IDEMPOTENT PAYMENT VERIFICATION
    // ==========================================
    [Fact]
    public async Task VerifyPayment_DuplicateCall_ReturnsAlreadyProcessed()
    {
        var (companyId, userId, _) = await RegisterCompanyAndUserAsync("Idem US", "US", "USD", "idem_us@example.com", "+12025550104");
        var subState = await _mobileClientService.GetCurrentSubscriptionAsync(companyId, userId);

        var createOrder = await _mobileClientService.CreateSubscriptionOrderAsync(
            companyId,
            userId,
            new CreateSubscriptionOrderRequest(
                Gateway: MobilePaymentGatewayType.PayPal,
                SubscriptionId: subState.SubscriptionId,
                Amount: 329.00m,
                Currency: "USD",
                PlanCode: "PRO",
                BillingCycle: "half-yearly",
                ReturnUrl: null));

        var verifyReq = new PaymentVerificationRequest(
            Gateway: MobilePaymentGatewayType.PayPal,
            TransactionRef: createOrder.TransactionRef,
            GatewayOrderId: createOrder.GatewayOrderId,
            GatewayPaymentId: createOrder.GatewayOrderId,
            Signature: null,
            PlanCode: "PRO",
            BillingCycle: "half-yearly");

        var first = await _mobileClientService.VerifyPaymentAsync(companyId, userId, verifyReq);
        Assert.True(first.Verified);

        var second = await _mobileClientService.VerifyPaymentAsync(companyId, userId, verifyReq);
        Assert.True(second.Verified);
        Assert.Equal("Already Processed", second.Message);
    }

    // ==========================================
    // 19. FAILED PAYMENT HANDLING
    // ==========================================
    [Fact]
    public async Task PaymentCallback_FailedStatus_MarksTransactionFailedWithoutActivatingSubscription()
    {
        var (companyId, userId, _) = await RegisterCompanyAndUserAsync("Fail US", "US", "USD", "fail_us@example.com", "+12025550105");
        var subState = await _mobileClientService.GetCurrentSubscriptionAsync(companyId, userId);

        var createOrder = await _mobileClientService.CreateSubscriptionOrderAsync(
            companyId,
            userId,
            new CreateSubscriptionOrderRequest(
                Gateway: MobilePaymentGatewayType.PayPal,
                SubscriptionId: subState.SubscriptionId,
                Amount: 599.00m,
                Currency: "USD",
                PlanCode: "PRO",
                BillingCycle: "annual",
                ReturnUrl: null));

        var callbackRequest = new PaymentCallbackRequest(
            Gateway: MobilePaymentGatewayType.PayPal,
            TransactionRef: createOrder.TransactionRef,
            GatewayOrderId: createOrder.GatewayOrderId,
            GatewayPaymentId: null,
            Status: "failed",
            Signature: null,
            PlanCode: "PRO",
            BillingCycle: "annual",
            Metadata: null);

        await _mobileClientService.PaymentCallbackAsync(companyId, userId, callbackRequest);

        var history = await _mobileClientService.GetPaymentHistoryAsync(companyId, userId);
        var tx = history.First(x => x.TransactionRef == createOrder.TransactionRef);

        Assert.Equal(MobilePaymentStatus.Failed, tx.PaymentStatus);
    }

    // ==========================================
    // 20. PAYMENT HISTORY INTEGRITY
    // ==========================================
    [Fact]
    public async Task GetPaymentHistory_ReturnsAccurateCountryAmountsAndCurrencies()
    {
        var (companyId, userId, _) = await RegisterCompanyAndUserAsync("History US", "US", "USD", "history_us@example.com", "+12025550106");
        var usSub = await _mobileClientService.GetCurrentSubscriptionAsync(companyId, userId);

        await _mobileClientService.CreateSubscriptionOrderAsync(
            companyId,
            userId,
            new CreateSubscriptionOrderRequest(
                Gateway: MobilePaymentGatewayType.PayPal,
                SubscriptionId: usSub.SubscriptionId,
                Amount: 179.00m,
                Currency: "USD",
                PlanCode: "PRO",
                BillingCycle: "quarterly",
                ReturnUrl: null));

        var history = await _mobileClientService.GetPaymentHistoryAsync(companyId, userId);

        Assert.NotEmpty(history);
        var item = history.First();
        Assert.Equal(179.00m, item.Amount);
        Assert.Equal("USD", item.Currency);
    }

    // ==========================================
    // 21. PAYPAL WEBHOOK STATUS NORMALIZATION
    // ==========================================
    [Theory]
    [InlineData("CHECKOUT.ORDER.APPROVED", "paid")]
    [InlineData("PAYMENT.CAPTURE.COMPLETED", "paid")]
    [InlineData("COMPLETED", "paid")]
    [InlineData("PAYMENT.CAPTURE.DENIED", "failed")]
    [InlineData("VOIDED", "failed")]
    [InlineData("PAYMENT.CAPTURE.REFUNDED", "refunded")]
    [InlineData("UNKNOWN_EVENT", "pending")]
    public async Task PayPalGateway_NormalizeCallbackStatus_MapsCorrectly(string incomingStatus, string expectedNormalized)
    {
        var gateway = _gatewayFactory.Resolve(MobilePaymentGatewayType.PayPal);

        var request = new PaymentCallbackRequest(
            Gateway: MobilePaymentGatewayType.PayPal,
            TransactionRef: "MOB-123",
            GatewayOrderId: "ord_123",
            GatewayPaymentId: "cap_123",
            Status: incomingStatus,
            Signature: null,
            PlanCode: null,
            BillingCycle: null,
            Metadata: null);

        var normalized = await gateway.NormalizeCallbackStatusAsync(request);
        Assert.Equal(expectedNormalized, normalized);
    }

    // ==========================================
    // 22. END-TO-END PURCHASE LIFECYCLE FOR USA
    // ==========================================
    [Fact]
    public async Task EndToEnd_USCompany_PurchasesAnnualPlanWithPayPal()
    {
        // 1. Register & initial state: Trial
        var (companyId, userId, _) = await RegisterCompanyAndUserAsync("Full Flow US", "US", "USD", "flow_us@example.com", "+12025550107");
        var initialSub = await _mobileClientService.GetCurrentSubscriptionAsync(companyId, userId);
        Assert.True(initialSub.IsTrial);

        // 2. Client initiates annual subscription order
        var orderResponse = await _mobileClientService.CreateSubscriptionOrderAsync(
            companyId,
            userId,
            new CreateSubscriptionOrderRequest(
                Gateway: MobilePaymentGatewayType.PayPal,
                SubscriptionId: initialSub.SubscriptionId,
                Amount: 0m, // Client sends 0; server resolves 599.00 USD
                Currency: "",
                PlanCode: "PRO",
                BillingCycle: "annual",
                ReturnUrl: "https://floraprise.com/payment/success"));

        Assert.Equal(599.00m, orderResponse.Amount);
        Assert.Equal("USD", orderResponse.Currency);
        Assert.Equal(MobilePaymentGatewayType.PayPal, orderResponse.Gateway);
        Assert.NotEmpty(orderResponse.GatewayOrderId);

        // 3. Complete payment verification
        var verifyResponse = await _mobileClientService.VerifyPaymentAsync(
            companyId,
            userId,
            new PaymentVerificationRequest(
                Gateway: MobilePaymentGatewayType.PayPal,
                TransactionRef: orderResponse.TransactionRef,
                GatewayOrderId: orderResponse.GatewayOrderId,
                GatewayPaymentId: orderResponse.GatewayOrderId,
                Signature: null,
                PlanCode: "PRO",
                BillingCycle: "annual"));

        Assert.True(verifyResponse.Verified);
        Assert.Equal("paid", verifyResponse.Status);

        // 4. Final state: Active with ~365 days
        var finalSub = await _mobileClientService.GetCurrentSubscriptionAsync(companyId, userId);
        Assert.False(finalSub.IsTrial);
        Assert.Equal(MobileSubscriptionStatus.Active, finalSub.Status);
        Assert.Equal("PRO", finalSub.PlanCode);
        Assert.InRange(finalSub.RemainingDays, 364, 365);
    }

    // ==========================================
    // 23. PAYPAL WEBHOOK SIGNATURE VERIFICATION
    // ==========================================
    [Fact]
    public async Task PayPalWebhook_ValidSignature_ProcessesPaymentAndActivatesSubscription()
    {
        var (companyId, userId, _) = await RegisterCompanyAndUserAsync("WH Valid US", "US", "USD", "wh_valid@example.com", "+12025550108");
        var subState = await _mobileClientService.GetCurrentSubscriptionAsync(companyId, userId);

        var order = await _mobileClientService.CreateSubscriptionOrderAsync(
            companyId,
            userId,
            new CreateSubscriptionOrderRequest(
                Gateway: MobilePaymentGatewayType.PayPal,
                SubscriptionId: subState.SubscriptionId,
                Amount: 599.00m,
                Currency: "USD",
                PlanCode: "PRO",
                BillingCycle: "annual",
                ReturnUrl: null));

        var controller = _provider.GetRequiredService<MobilePaymentController>();
        var httpContext = new DefaultHttpContext();
        httpContext.Request.Headers["PAYPAL-AUTH-ALGO"] = "SHA256withRSA";
        httpContext.Request.Headers["PAYPAL-CERT-URL"] = "https://api.sandbox.paypal.com/v1/notifications/certs/CERT-123";
        httpContext.Request.Headers["PAYPAL-TRANSMISSION-ID"] = "trans-valid-123";
        httpContext.Request.Headers["PAYPAL-TRANSMISSION-SIG"] = "VALID_SIGNATURE";
        httpContext.Request.Headers["PAYPAL-TRANSMISSION-TIME"] = "2026-09-18T10:00:00Z";

        var webhookBody = System.Text.Json.JsonSerializer.Serialize(new
        {
            id = "WH-EVT-1",
            event_type = "PAYMENT.CAPTURE.COMPLETED",
            resource = new
            {
                id = $"cap_{Guid.NewGuid():N}",
                supplementary_data = new
                {
                    related_ids = new
                    {
                        order_id = order.GatewayOrderId
                    }
                }
            }
        });
        httpContext.Request.Body = new MemoryStream(System.Text.Encoding.UTF8.GetBytes(webhookBody));
        controller.ControllerContext = new ControllerContext { HttpContext = httpContext };

        var result = await controller.PayPalWebhook(CancellationToken.None);
        var ok = Assert.IsType<OkObjectResult>(result);
        var callbackRes = Assert.IsType<PaymentCallbackResponse>(ok.Value);

        Assert.True(callbackRes.Updated);
        Assert.Equal(order.TransactionRef, callbackRes.TransactionRef);

        var updatedSub = await _mobileClientService.GetCurrentSubscriptionAsync(companyId, userId);
        Assert.Equal(MobileSubscriptionStatus.Active, updatedSub.Status);
        Assert.InRange(updatedSub.RemainingDays, 364, 365);
    }

    [Fact]
    public async Task PayPalWebhook_InvalidSignature_ReturnsUnauthorized()
    {
        var controller = _provider.GetRequiredService<MobilePaymentController>();
        var httpContext = new DefaultHttpContext();
        httpContext.Request.Headers["PAYPAL-AUTH-ALGO"] = "SHA256withRSA";
        httpContext.Request.Headers["PAYPAL-CERT-URL"] = "https://api.sandbox.paypal.com/v1/notifications/certs/CERT-123";
        httpContext.Request.Headers["PAYPAL-TRANSMISSION-ID"] = "trans-invalid-123";
        httpContext.Request.Headers["PAYPAL-TRANSMISSION-SIG"] = "INVALID_TAMPERED_SIG";
        httpContext.Request.Headers["PAYPAL-TRANSMISSION-TIME"] = "2026-09-18T10:00:00Z";

        var webhookBody = System.Text.Json.JsonSerializer.Serialize(new
        {
            id = "WH-EVT-2",
            event_type = "PAYMENT.CAPTURE.COMPLETED",
            resource = new { id = "ord_some_order_id" }
        });
        httpContext.Request.Body = new MemoryStream(System.Text.Encoding.UTF8.GetBytes(webhookBody));
        controller.ControllerContext = new ControllerContext { HttpContext = httpContext };

        var result = await controller.PayPalWebhook(CancellationToken.None);
        Assert.IsType<UnauthorizedResult>(result);
    }

    [Fact]
    public async Task PayPalWebhook_MissingSignatureHeaders_ReturnsUnauthorized()
    {
        var controller = _provider.GetRequiredService<MobilePaymentController>();
        var httpContext = new DefaultHttpContext();
        // Omitting signature headers
        var webhookBody = System.Text.Json.JsonSerializer.Serialize(new
        {
            id = "WH-EVT-3",
            event_type = "PAYMENT.CAPTURE.COMPLETED",
            resource = new { id = "ord_some_order_id" }
        });
        httpContext.Request.Body = new MemoryStream(System.Text.Encoding.UTF8.GetBytes(webhookBody));
        controller.ControllerContext = new ControllerContext { HttpContext = httpContext };

        var result = await controller.PayPalWebhook(CancellationToken.None);
        Assert.IsType<UnauthorizedResult>(result);
    }

    [Fact]
    public async Task PayPalWebhook_DuplicateEvent_IsIdempotentAndDoesNotDoubleExtend()
    {
        var (companyId, userId, _) = await RegisterCompanyAndUserAsync("WH Idem US", "US", "USD", "wh_idem@example.com", "+12025550109");
        var subState = await _mobileClientService.GetCurrentSubscriptionAsync(companyId, userId);

        var order = await _mobileClientService.CreateSubscriptionOrderAsync(
            companyId,
            userId,
            new CreateSubscriptionOrderRequest(
                Gateway: MobilePaymentGatewayType.PayPal,
                SubscriptionId: subState.SubscriptionId,
                Amount: 599.00m,
                Currency: "USD",
                PlanCode: "PRO",
                BillingCycle: "annual",
                ReturnUrl: null));

        var controller = _provider.GetRequiredService<MobilePaymentController>();

        // First call
        var httpContext1 = new DefaultHttpContext();
        httpContext1.Request.Headers["PAYPAL-AUTH-ALGO"] = "SHA256withRSA";
        httpContext1.Request.Headers["PAYPAL-CERT-URL"] = "https://api.sandbox.paypal.com/v1/notifications/certs/CERT-123";
        httpContext1.Request.Headers["PAYPAL-TRANSMISSION-ID"] = "trans-idem-1";
        httpContext1.Request.Headers["PAYPAL-TRANSMISSION-SIG"] = "VALID_SIGNATURE";
        httpContext1.Request.Headers["PAYPAL-TRANSMISSION-TIME"] = "2026-09-18T10:00:00Z";

        var webhookBody = System.Text.Json.JsonSerializer.Serialize(new
        {
            id = "WH-EVT-4",
            event_type = "PAYMENT.CAPTURE.COMPLETED",
            resource = new { id = order.GatewayOrderId }
        });
        httpContext1.Request.Body = new MemoryStream(System.Text.Encoding.UTF8.GetBytes(webhookBody));
        controller.ControllerContext = new ControllerContext { HttpContext = httpContext1 };

        var result1 = await controller.PayPalWebhook(CancellationToken.None);
        var ok1 = Assert.IsType<OkObjectResult>(result1);
        var res1 = Assert.IsType<PaymentCallbackResponse>(ok1.Value);
        Assert.True(res1.Updated);

        var subAfter1 = await _mobileClientService.GetCurrentSubscriptionAsync(companyId, userId);
        var expiry1 = subAfter1.EndUtc;

        // Second duplicate call
        var httpContext2 = new DefaultHttpContext();
        httpContext2.Request.Headers["PAYPAL-AUTH-ALGO"] = "SHA256withRSA";
        httpContext2.Request.Headers["PAYPAL-CERT-URL"] = "https://api.sandbox.paypal.com/v1/notifications/certs/CERT-123";
        httpContext2.Request.Headers["PAYPAL-TRANSMISSION-ID"] = "trans-idem-2";
        httpContext2.Request.Headers["PAYPAL-TRANSMISSION-SIG"] = "VALID_SIGNATURE";
        httpContext2.Request.Headers["PAYPAL-TRANSMISSION-TIME"] = "2026-09-18T10:00:00Z";
        httpContext2.Request.Body = new MemoryStream(System.Text.Encoding.UTF8.GetBytes(webhookBody));
        controller.ControllerContext = new ControllerContext { HttpContext = httpContext2 };

        var result2 = await controller.PayPalWebhook(CancellationToken.None);
        var ok2 = Assert.IsType<OkObjectResult>(result2);
        var res2 = Assert.IsType<PaymentCallbackResponse>(ok2.Value);
        Assert.False(res2.Updated);
        Assert.Equal("Already Processed", res2.Message);

        var subAfter2 = await _mobileClientService.GetCurrentSubscriptionAsync(companyId, userId);
        Assert.Equal(expiry1, subAfter2.EndUtc); // Must NOT double extend
    }

    [Fact]
    public async Task PayPalWebhook_EventForAnotherCompanyTransaction_RejectedWhenCompanyScoped()
    {
        var (companyA, userA, _) = await RegisterCompanyAndUserAsync("Comp A", "US", "USD", "comp_a@example.com", "+12025550110");
        var (companyB, userB, _) = await RegisterCompanyAndUserAsync("Comp B", "US", "USD", "comp_b@example.com", "+12025550111");

        var subB = await _mobileClientService.GetCurrentSubscriptionAsync(companyB, userB);
        var orderB = await _mobileClientService.CreateSubscriptionOrderAsync(
            companyB,
            userB,
            new CreateSubscriptionOrderRequest(
                Gateway: MobilePaymentGatewayType.PayPal,
                SubscriptionId: subB.SubscriptionId,
                Amount: 599.00m,
                Currency: "USD",
                PlanCode: "PRO",
                BillingCycle: "annual",
                ReturnUrl: null));

        var controller = _provider.GetRequiredService<MobilePaymentController>();
        var httpContext = new DefaultHttpContext();
        httpContext.Request.Headers["PAYPAL-AUTH-ALGO"] = "SHA256withRSA";
        httpContext.Request.Headers["PAYPAL-CERT-URL"] = "https://api.sandbox.paypal.com/v1/notifications/certs/CERT-123";
        httpContext.Request.Headers["PAYPAL-TRANSMISSION-ID"] = "trans-cross-1";
        httpContext.Request.Headers["PAYPAL-TRANSMISSION-SIG"] = "VALID_SIGNATURE";
        httpContext.Request.Headers["PAYPAL-TRANSMISSION-TIME"] = "2026-09-18T10:00:00Z";

        var webhookBody = System.Text.Json.JsonSerializer.Serialize(new
        {
            id = "WH-EVT-5",
            event_type = "PAYMENT.CAPTURE.COMPLETED",
            resource = new { id = orderB.GatewayOrderId }
        });
        httpContext.Request.Body = new MemoryStream(System.Text.Encoding.UTF8.GetBytes(webhookBody));

        // Scoped to Company A
        var routeData = new Microsoft.AspNetCore.Routing.RouteData();
        routeData.Values["companyId"] = companyA.ToString();
        controller.ControllerContext = new ControllerContext
        {
            HttpContext = httpContext,
            RouteData = routeData
        };

        var result = await controller.PayPalWebhook(CancellationToken.None);
        Assert.IsType<NotFoundResult>(result); // Transaction does not belong to Company A
    }

    [Fact]
    public async Task PayPalWebhook_CheckoutOrderApproved_PreservesExpectedFlow()
    {
        var (companyId, userId, _) = await RegisterCompanyAndUserAsync("WH AE", "AE", "AED", "wh_ae@example.com", "+971501234502");
        var subState = await _mobileClientService.GetCurrentSubscriptionAsync(companyId, userId);

        var order = await _mobileClientService.CreateSubscriptionOrderAsync(
            companyId,
            userId,
            new CreateSubscriptionOrderRequest(
                Gateway: MobilePaymentGatewayType.PayPal,
                SubscriptionId: subState.SubscriptionId,
                Amount: 2199.00m,
                Currency: "AED",
                PlanCode: "PRO",
                BillingCycle: "annual",
                ReturnUrl: null));

        var controller = _provider.GetRequiredService<MobilePaymentController>();
        var httpContext = new DefaultHttpContext();
        httpContext.Request.Headers["PAYPAL-AUTH-ALGO"] = "SHA256withRSA";
        httpContext.Request.Headers["PAYPAL-CERT-URL"] = "https://api.sandbox.paypal.com/v1/notifications/certs/CERT-123";
        httpContext.Request.Headers["PAYPAL-TRANSMISSION-ID"] = "trans-ae-1";
        httpContext.Request.Headers["PAYPAL-TRANSMISSION-SIG"] = "VALID_SIGNATURE";
        httpContext.Request.Headers["PAYPAL-TRANSMISSION-TIME"] = "2026-09-18T10:00:00Z";

        var webhookBody = System.Text.Json.JsonSerializer.Serialize(new
        {
            id = "WH-EVT-6",
            event_type = "CHECKOUT.ORDER.APPROVED",
            resource = new { id = order.GatewayOrderId }
        });
        httpContext.Request.Body = new MemoryStream(System.Text.Encoding.UTF8.GetBytes(webhookBody));
        controller.ControllerContext = new ControllerContext { HttpContext = httpContext };

        var result = await controller.PayPalWebhook(CancellationToken.None);
        var ok = Assert.IsType<OkObjectResult>(result);
        var res = Assert.IsType<PaymentCallbackResponse>(ok.Value);
        Assert.True(res.Updated);

        var updatedSub = await _mobileClientService.GetCurrentSubscriptionAsync(companyId, userId);
        Assert.Equal(MobileSubscriptionStatus.Active, updatedSub.Status);
        Assert.InRange(updatedSub.RemainingDays, 364, 365);
    }

    private sealed class TestTenantContext : ITenantContext
    {
        public Guid? CompanyId => null;
        public string? Region => null;
        public bool IsPlatformUser => true;
    }
}
