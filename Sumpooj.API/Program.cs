using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc.Infrastructure;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.IdentityModel.Tokens;
using Scalar.AspNetCore;
using Sumpooj.API.Authorization;
using Sumpooj.API.Hubs;
using Sumpooj.API.Services.Mobile;
using Sumpooj.API.Infrastructure;
using Sumpooj.API.Infrastructure.Health;
using Sumpooj.API.Infrastructure.OpenApi;
using Sumpooj.API.Middleware;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Companies;
using Sumpooj.Application.AI;
using Sumpooj.Application.Deliveries;
using Sumpooj.Application.DeliveryTracking;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Payments;
using Sumpooj.Application.UseCases;
using Sumpooj.Infrastructure;
using Sumpooj.Infrastructure.Companies;
using Sumpooj.Infrastructure.ExternalServices;
using Sumpooj.Infrastructure.Identity;
using Sumpooj.Infrastructure.Persistence;
using Sumpooj.Infrastructure.Persistence.Repositories;
using Sumpooj.Infrastructure.Repositories;
using Sumpooj.Application.Marketing;
using Sumpooj.Application.Email;
using Sumpooj.Application.Mobile;
using Sumpooj.Application.Services;
using Sumpooj.Application.WhatsApp;
using Sumpooj.Infrastructure.Email;
using Sumpooj.Infrastructure.WhatsApp;
using System.Diagnostics;
using System.Security.Claims;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc;

var builder = WebApplication.CreateBuilder(new WebApplicationOptions
{
    Args = args,
    ContentRootPath = AppContext.BaseDirectory
});

var configuredConnectionString = builder.Configuration.GetConnectionString("Default");
Console.WriteLine($"[startup] Using database connection string: {configuredConnectionString?.Replace("Password=", "Password=***", StringComparison.OrdinalIgnoreCase)}");

#region CORS

// Read allowed origins from configuration (appsettings.json)
var corsOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>()
                  ?? Array.Empty<string>();

builder.Services.AddCors(options =>
{
    options.AddPolicy("DefaultCorsPolicy", policy =>
    {
        if (corsOrigins.Length == 0)
        {
            // Development: allow any origin (credentials not supported with *)
            policy.AllowAnyOrigin()
                  .AllowAnyHeader()
                  .AllowAnyMethod();
        }
        else
        {
            policy.WithOrigins(corsOrigins)
                  .AllowAnyHeader()
                  .AllowAnyMethod()
                  .AllowCredentials();
        }
    });
});

#endregion

#region Database

builder.Services.AddDbContext<SumpoojDbContext>(options =>
    options.UseNpgsql(
               builder.Configuration.GetConnectionString("Default"),
               npgsqlOptions =>
               {
                   // Production-safe retries for transient database failures.
                   npgsqlOptions.EnableRetryOnFailure(maxRetryCount: 5, maxRetryDelay: TimeSpan.FromSeconds(8), errorCodesToAdd: null);
                   npgsqlOptions.CommandTimeout(5);
               })
           .ConfigureWarnings(w => w.Ignore(
               Microsoft.EntityFrameworkCore.Diagnostics.RelationalEventId.PendingModelChangesWarning)));

#endregion

#region Identity

builder.Services
    .AddIdentity<ApplicationUser, IdentityRole<Guid>>(options =>
    {
        options.Password.RequireDigit = true;
        options.Password.RequiredLength = 8;
        options.Password.RequireUppercase = true;
        options.Password.RequireLowercase = true;
        options.User.RequireUniqueEmail = true;
    })
    .AddEntityFrameworkStores<SumpoojDbContext>()
    .AddDefaultTokenProviders();

#endregion

#region JWT Authentication

var jwtKey = builder.Configuration["Jwt:Key"]
             ?? builder.Configuration["Jwt__Key"]
             ?? Environment.GetEnvironmentVariable("JWT_KEY")
             ?? Environment.GetEnvironmentVariable("Jwt__Key")
             ?? throw new InvalidOperationException("JWT Key missing. Provide Jwt:Key, Jwt__Key, or JWT_KEY.");
var jwtIssuer = builder.Configuration["Jwt:Issuer"]
                ?? builder.Configuration["Jwt__Issuer"]
                ?? Environment.GetEnvironmentVariable("JWT_ISSUER")
                ?? Environment.GetEnvironmentVariable("Jwt__Issuer")
                ?? throw new InvalidOperationException("JWT Issuer missing. Provide Jwt:Issuer, Jwt__Issuer, or JWT_ISSUER.");

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,

        ValidIssuer = jwtIssuer,
        ValidAudience = jwtIssuer,
        IssuerSigningKey = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(jwtKey)),

        ClockSkew = TimeSpan.Zero
    };
});

// SignalR
builder.Services.AddSignalR();

#endregion

#region Authorization Policies

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy(PolicyNames.PlatformOnly, policy =>
    {
        policy.RequireRole("PlatformSuperAdmin");
        policy.AddRequirements(new PlatformUserRequirement());
    });

    options.AddPolicy(PolicyNames.PlatformSupport, policy =>
    {
        policy.RequireRole("PlatformSuperAdmin", "PlatformSupport");
        policy.AddRequirements(new PlatformUserRequirement());
    });

    options.AddPolicy(PolicyNames.CompanyOnly, policy =>
    {
        policy.AddRequirements(new CompanyUserRequirement());
    });

    options.AddPolicy(PolicyNames.CompanyAdmin, policy =>
    {
        policy.RequireRole("CompanyAdmin");
        policy.AddRequirements(new CompanyUserRequirement());
    });

    options.AddPolicy(PolicyNames.StaffAccess, policy =>
    {
        policy.RequireRole("CompanyAdmin", "Manager", "Staff");
        policy.AddRequirements(new CompanyUserRequirement());
    });
});

builder.Services.AddScoped<IAuthorizationHandler, PlatformUserHandler>();
builder.Services.AddScoped<IAuthorizationHandler, CompanyUserHandler>();

#endregion

#region Tenant Context

builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<ITenantContext, HttpTenantContext>();
builder.Services.AddProblemDetails();

#endregion

#region Application Services

builder.Services.AddScoped<ICustomerRepository, CustomerRepository>();
builder.Services.AddScoped<CustomerService>();

builder.Services.AddScoped<ICompanyService, CompanyService>();

// Mobile license and subscription foundation
builder.Services.AddScoped<IMobileCustomerRepository, MobileCustomerRepository>();
builder.Services.AddScoped<IMobileUserRepository, MobileUserRepository>();
builder.Services.AddScoped<IMobileDeviceRepository, MobileDeviceRepository>();
builder.Services.AddScoped<ISubscriptionPlanRepository, SubscriptionPlanRepository>();
builder.Services.AddScoped<IMobileSubscriptionRepository, MobileSubscriptionRepository>();
builder.Services.AddScoped<IMobileLicenseRepository, MobileLicenseRepository>();
builder.Services.AddScoped<IDeviceSessionRepository, DeviceSessionRepository>();
builder.Services.AddScoped<IMobilePaymentTransactionRepository, MobilePaymentTransactionRepository>();
builder.Services.AddScoped<IMobileUnitOfWork, MobileUnitOfWork>();
builder.Services.AddScoped<IMobileSubscriptionService, MobileSubscriptionService>();
builder.Services.AddScoped<IMobileClientService, MobileClientService>();
builder.Services.AddScoped<ISubscriptionPaymentGateway, RazorpaySubscriptionPaymentGateway>();
builder.Services.AddScoped<ISubscriptionPaymentGateway, StripeSubscriptionPaymentGateway>();
builder.Services.AddScoped<ISubscriptionPaymentGatewayFactory, SubscriptionPaymentGatewayFactory>();

// AI Services
var openAISettings = builder.Configuration.GetSection("OpenAI").Get<OpenAISettings>() ?? new OpenAISettings();
if (string.IsNullOrWhiteSpace(openAISettings.ApiKey))
{
    openAISettings.ApiKey = builder.Configuration["OPENAI_API_KEY"]
        ?? Environment.GetEnvironmentVariable("OPENAI_API_KEY")
        ?? string.Empty;
}
builder.Services.AddSingleton(openAISettings);
builder.Services.AddScoped<IAIUsageRepository, AIUsageRepository>();
builder.Services.AddScoped<GiftCardAIService>();
builder.Services.AddScoped<BouquetAIService>();

builder.Services.AddScoped<IProductRepository, ProductRepository>();
builder.Services.AddScoped<ProductService>();

builder.Services.AddScoped<IBarcodeRepository, BarcodeRepository>();

builder.Services.AddScoped<IProductCategoryRepository, ProductCategoryRepository>();
builder.Services.AddScoped<ProductCategoryService>();

builder.Services.AddScoped<ISupplierRepository, SupplierRepository>();
builder.Services.AddScoped<SupplierService>();

builder.Services.AddScoped<IProductBatchRepository, ProductBatchRepository>();
builder.Services.AddScoped<IInventoryReservationRepository, InventoryReservationRepository>();
builder.Services.AddScoped<IInventoryAdjustmentRepository, InventoryAdjustmentRepository>();
builder.Services.AddScoped<IInventoryLedgerRepository, InventoryLedgerRepository>();
builder.Services.AddScoped<InventoryEntryService>();
builder.Services.AddScoped<InventoryService>();
builder.Services.AddScoped<StockReceiveService>();

// Delivery Tracking Services
builder.Services.AddScoped<IDriverLocationRepository, DriverLocationRepository>();
builder.Services.AddScoped<DriverJourneyService>();
builder.Services.AddScoped<SmartETACalculator>();
builder.Services.AddScoped<ETAUpdateService>();
builder.Services.AddScoped<DeliveryNotificationService>();


builder.Services.AddScoped<IPurchaseOrderRepository, PurchaseOrderRepository>();
builder.Services.AddScoped<PurchaseOrderPdfService>();
builder.Services.AddScoped<PurchaseOrderService>();

builder.Services.AddScoped<ILocationRepository, LocationRepository>();
builder.Services.AddScoped<LocationService>();

// New Services
builder.Services.AddScoped<IStaffRepository, StaffRepository>();
builder.Services.AddScoped<IIdentityService, Sumpooj.Infrastructure.IdentityService>();
builder.Services.AddScoped<StaffService>();

builder.Services.AddScoped<IEventRepository, EventRepository>();
builder.Services.AddScoped<EventService>();

builder.Services.AddScoped<IGiftCardRepository, GiftCardRepository>();
builder.Services.AddScoped<GiftCardService>();

builder.Services.AddScoped<ITaskRepository, TaskRepository>();
builder.Services.AddScoped<TaskService>();

builder.Services.AddScoped<IOrderRepository, OrderRepository>();
builder.Services.AddScoped<OrderService>();

builder.Services.AddScoped<IDeliveryRepository, DeliveryRepository>();
builder.Services.AddScoped<ICompanyRepository, CompanyRepository>();

builder.Services.AddScoped<IPaymentRepository, PaymentRepository>();
builder.Services.AddScoped<PaymentService>();

builder.Services.AddScoped<IRefundRepository, RefundRepository>();
builder.Services.AddScoped<RefundService>();

builder.Services.AddScoped<IDayCloseRepository, DayCloseRepository>();
builder.Services.AddScoped<DayCloseService>();

builder.Services.AddScoped<IJournalEntryRepository, JournalEntryRepository>();
builder.Services.AddScoped<IAccountRepository, AccountRepository>();
builder.Services.AddScoped<AccountingService>();

builder.Services.AddScoped<IShiftRepository, ShiftRepository>();
builder.Services.AddScoped<ShiftService>();

builder.Services.AddScoped<DashboardService>();
builder.Services.AddScoped<IDashboardPreferenceRepository, DashboardPreferenceRepository>();
builder.Services.AddScoped<DashboardPreferenceService>();

// Audit Logging
builder.Services.AddScoped<IAuditLogRepository, AuditLogRepository>();
builder.Services.AddScoped<AuditLogService>();

// Delivery Zones
builder.Services.AddScoped<IDeliveryZoneRepository, DeliveryZoneRepository>();
builder.Services.AddScoped<DeliveryZoneService>();

// Wire Orders
builder.Services.AddScoped<IWireOrderRepository, WireOrderRepository>();
builder.Services.AddScoped<WireOrderService>();

// Corporate Clients (B2B)
builder.Services.AddScoped<ICorporateRepository, CorporateRepository>();
builder.Services.AddScoped<CorporateService>();

// Proposals
builder.Services.AddScoped<IProposalRepository, ProposalRepository>();
builder.Services.AddScoped<ProposalService>();

// Tax Rules
builder.Services.AddScoped<ITaxRuleRepository, TaxRuleRepository>();
builder.Services.AddScoped<TaxRuleService>();
builder.Services.AddScoped<TaxCalculationService>();

// Analytics
builder.Services.AddScoped<ProfitDashboardService>();

// Sales Orders & Deliveries
builder.Services.AddScoped<ISalesOrderRepository, SalesOrderRepository>();
builder.Services.AddScoped<IDeliveryRepository, DeliveryRepository>();
builder.Services.AddScoped<IDeliveryRouteRepository, DeliveryRouteRepository>();
builder.Services.AddScoped<ScheduleDeliveryHandler>();
builder.Services.AddScoped<AssignDeliveryPersonHandler>();
builder.Services.AddScoped<CreateRouteHandler>();
builder.Services.AddScoped<AssignDriverToRouteHandler>();
builder.Services.AddScoped<CompleteRouteHandler>();
builder.Services.AddScoped<StartRouteHandler>();

// Delivery Tracking
builder.Services.AddScoped<IDeliveryLocationRepository, DeliveryLocationRepository>();
builder.Services.AddScoped<IDeliveryTimelineRepository, DeliveryTimelineRepository>();
builder.Services.AddScoped<IDeliveryProofRepository, DeliveryProofRepository>();
builder.Services.AddScoped<IDeliveryLocationService, DeliveryLocationService>();
builder.Services.AddScoped<IDeliveryTimelineService, DeliveryTimelineService>();
builder.Services.AddScoped<IDeliveryProofService, DeliveryProofService>();
builder.Services.AddScoped<IDeliveryTrackingService, DeliveryTrackingService>();
builder.Services.AddScoped<ISignalRBroadcastService, Sumpooj.API.Services.SignalRBroadcastService>();

// Payment Gateway Services
builder.Services.AddHttpClient(); // For gateway HTTP calls
builder.Services.AddScoped<IPaymentGatewayConfigRepository, PaymentGatewayConfigRepository>();
builder.Services.AddScoped<IPaymentTransactionRepository, PaymentTransactionRepository>();
builder.Services.AddScoped<IPaymentGatewayFactory, PaymentGatewayFactory>();
builder.Services.AddScoped<PaymentGatewayConfigService>();
builder.Services.AddScoped<GatewayPaymentService>();

// Production
builder.Services.AddScoped<IFloralRecipeRepository, FloralRecipeRepository>();
builder.Services.AddScoped<IFinishedGoodsBatchRepository, FinishedGoodsBatchRepository>();
builder.Services.AddScoped<IProductionJobRepository, ProductionJobRepository>();
builder.Services.AddScoped<IProductionMaterialUsageRepository, ProductionMaterialUsageRepository>();
builder.Services.AddScoped<IProductionMaintenanceLogRepository, ProductionMaintenanceLogRepository>();
builder.Services.AddScoped<IProductionWastageLogRepository, ProductionWastageLogRepository>();
builder.Services.AddScoped<ProductionService>();

// Barcodes
builder.Services.AddScoped<BarcodeService>();

// Email
builder.Services.Configure<EmailSettings>(builder.Configuration.GetSection("Email"));
builder.Services.AddScoped<IEmailService, SmtpEmailService>();

// Marketing — Demo Requests
builder.Services.AddScoped<IDemoRequestRepository, DemoRequestRepository>();
builder.Services.AddScoped<ILeadNotificationService, LeadNotificationService>();
builder.Services.AddScoped<ITaskAssignmentNotificationService, TaskAssignmentNotificationService>();
builder.Services.AddScoped<DemoRequestService>();

// Audit Action Filter (auto-logs all mutating API actions)
builder.Services.AddScoped<AuditActionFilter>();

// WhatsApp Account Services
builder.Services.AddScoped<IWhatsAppAccountService, Sumpooj.Infrastructure.WhatsApp.WhatsAppAccountService>();

if (builder.Configuration.GetValue("Corporate:EnableBirthdayAutomation", false))
{
    builder.Services.AddHostedService<CorporateBirthdayAutomationHostedService>();
}

#endregion

#region Controllers & OpenAPI

builder.Services.AddControllers(options =>
{
    options.Filters.AddService<AuditActionFilter>();
});

// Built-in OpenAPI (no Swagger UI headaches)
builder.Services.AddOpenApi(options =>
{
    options.AddDocumentTransformer<JwtSecuritySchemeDocumentTransformer>();
    options.AddOperationTransformer<MobileOpenApiOperationTransformer>();
});

// Production readiness health checks
builder.Services.AddHealthChecks()
    .AddCheck("live", () => HealthCheckResult.Healthy("Service is alive."), tags: new[] { "live" })
    .AddCheck<DatabaseConnectivityHealthCheck>("database", tags: new[] { "ready" })
    .AddCheck<DatabaseMigrationsHealthCheck>("migrations", tags: new[] { "ready" })
    .AddCheck<JwtConfigurationHealthCheck>("jwt", tags: new[] { "ready" })
    .AddCheck<MobileServicesHealthCheck>("mobile_services", tags: new[] { "ready" })
    .AddCheck<SubscriptionServicesHealthCheck>("subscription_services", tags: new[] { "ready" })
    .AddCheck<DeviceServicesHealthCheck>("device_services", tags: new[] { "ready" });

#endregion

var app = builder.Build();

#region Middleware

//if (app.Environment.IsDevelopment())
//{
    app.MapOpenApi();
    app.MapScalarApiReference(); // optional API explorer
//}

app.UseExceptionHandler(errorApp =>
{
    errorApp.Run(async context =>
    {
        var exceptionFeature = context.Features.Get<IExceptionHandlerFeature>();
        var logger = context.RequestServices.GetRequiredService<ILogger<Program>>();

        if (exceptionFeature?.Error is not null)
        {
            logger.LogError(exceptionFeature.Error, "Unhandled exception at {Path}", context.Request.Path);
        }

        var factory = context.RequestServices.GetRequiredService<ProblemDetailsFactory>();
        var problem = factory.CreateProblemDetails(
            context,
            statusCode: StatusCodes.Status500InternalServerError,
            title: "Server Error",
            detail: "An unexpected error occurred.");

        problem.Extensions["traceId"] = context.TraceIdentifier;
        context.Response.StatusCode = StatusCodes.Status500InternalServerError;
        await context.Response.WriteAsJsonAsync(problem);
    });
});

// CORS must run FIRST — before HTTPS redirect, auth, etc.
// Otherwise preflight OPTIONS requests get redirected/blocked.
app.UseCors("DefaultCorsPolicy");

app.UseStaticFiles();

if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

app.UseAuthentication();

// Mobile API request telemetry without sensitive payload logging.
app.Use(async (context, next) =>
{
    if (!context.Request.Path.StartsWithSegments("/api/v1/mobile", StringComparison.OrdinalIgnoreCase))
    {
        await next();
        return;
    }

    var logger = context.RequestServices.GetRequiredService<ILogger<Program>>();
    var sw = Stopwatch.StartNew();
    var endpoint = $"{context.Request.Method} {context.Request.Path}";

    string? GetClaim(string claimType) => context.User.FindFirstValue(claimType);

    var requestId = context.TraceIdentifier;
    var companyId = GetClaim("company_id");
    var userId = GetClaim("mobile_user_id") ?? GetClaim(ClaimTypes.NameIdentifier) ?? GetClaim("sub");
    var deviceId = GetClaim("device_id");
    var subscriptionId = GetClaim("subscription_id");

    context.Response.Headers["X-Correlation-ID"] = requestId;
    using var scope = logger.BeginScope(new Dictionary<string, object?>
    {
        ["CorrelationId"] = requestId,
        ["CompanyId"] = companyId,
        ["UserId"] = userId,
        ["DeviceId"] = deviceId,
        ["SubscriptionId"] = subscriptionId,
        ["Endpoint"] = endpoint
    });

    try
    {
        await next();
        sw.Stop();

        logger.LogInformation(
            "Mobile request completed. CorrelationId={CorrelationId} CompanyId={CompanyId} UserId={UserId} DeviceId={DeviceId} SubscriptionId={SubscriptionId} Endpoint={Endpoint} DurationMs={DurationMs} StatusCode={StatusCode}",
            requestId,
            companyId,
            userId,
            deviceId,
            subscriptionId,
            endpoint,
            sw.ElapsedMilliseconds,
            context.Response.StatusCode);
    }
    catch (Exception ex)
    {
        sw.Stop();

        logger.LogError(
            ex,
            "Mobile request failed. CorrelationId={CorrelationId} CompanyId={CompanyId} UserId={UserId} DeviceId={DeviceId} SubscriptionId={SubscriptionId} Endpoint={Endpoint} DurationMs={DurationMs} StatusCode={StatusCode}",
            requestId,
            companyId,
            userId,
            deviceId,
            subscriptionId,
            endpoint,
            sw.ElapsedMilliseconds,
            context.Response.StatusCode);

        throw;
    }
});

app.UseMiddleware<DeliveryRateLimitMiddleware>();
app.UseAuthorization();

app.MapHealthChecks("/health", BuildHealthOptions(check => true));
app.MapHealthChecks("/health/ready", BuildHealthOptions(check => check.Tags.Contains("ready")));
app.MapHealthChecks("/health/live", BuildHealthOptions(check => check.Tags.Contains("live")));

app.MapControllers();

// SignalR Hubs
app.MapHub<DeliveryTrackingHub>("/hubs/delivery-tracking");

#endregion

#region Data Seed
var failOnSeedError = builder.Configuration.GetValue("Database:FailOnSeedError", !app.Environment.IsDevelopment());
var runStartupSqlPatches = builder.Configuration.GetValue("Database:RunStartupSqlPatches", !app.Environment.IsProduction());
var enableSeeding = builder.Configuration.GetValue("Database:EnableSeeding", !app.Environment.IsProduction());
var startupLogger = app.Services.GetRequiredService<ILogger<Program>>();

try
{
    await using var scope = app.Services.CreateAsyncScope();
    var db = scope.ServiceProvider.GetRequiredService<SumpoojDbContext>();

    var startupDbAvailable = await CanConnectWithBackoffAsync(db, startupLogger, app.Environment.IsProduction());

    if (!startupDbAvailable)
    {
        startupLogger.LogWarning(
            "Database is not reachable at startup. Skipping startup SQL patches and seeders. " +
            "Application startup will continue; readiness checks will report database state.");
    }
    else
    {
        if (runStartupSqlPatches)
        {
            await db.Database.ExecuteSqlRawAsync(
            """
            CREATE TABLE IF NOT EXISTS public."__EFMigrationsHistory" (
                "MigrationId" character varying(150) NOT NULL,
                "ProductVersion" character varying(32) NOT NULL,
                CONSTRAINT "PK___EFMigrationsHistory" PRIMARY KEY ("MigrationId")
            );
            """);

            await db.Database.ExecuteSqlRawAsync(
            """
            INSERT INTO public."__EFMigrationsHistory" ("MigrationId", "ProductVersion")
            VALUES
                ('20260317130126_UnifyPhoneOrdersIntoOrders', '8.0.11'),
                ('20260326211015_AddInventoryLedger', '8.0.11'),
                ('20260407165445_AddIsInventoryProcessed', '8.0.11'),
                ('20260727192413_MobileSubscriptionFoundation', '8.0.11')
            ON CONFLICT ("MigrationId") DO NOTHING;
            """);

            // Self-heal for older databases that missed staff migrations.
            await db.Database.ExecuteSqlRawAsync(
            """
            DO $$
            BEGIN
                IF NOT EXISTS (
                    SELECT 1
                    FROM information_schema.columns
                    WHERE table_schema = 'public'
                      AND table_name = 'Staff'
                      AND column_name = 'IdentityUserId'
                ) THEN
                    ALTER TABLE "Staff" ADD COLUMN "IdentityUserId" uuid NULL;
                END IF;
            END $$;
            """);

            // Self-heal: add DriverStatus column if missing (added after initial schema).
            await db.Database.ExecuteSqlRawAsync(
            """
            DO $$
            BEGIN
                IF NOT EXISTS (
                    SELECT 1
                    FROM information_schema.columns
                    WHERE table_schema = 'public'
                      AND table_name = 'Staff'
                      AND column_name = 'DriverStatus'
                ) THEN
                    ALTER TABLE "Staff" ADD COLUMN "DriverStatus" integer NOT NULL DEFAULT 0;
                END IF;
            END $$;
            """);

            await db.Database.ExecuteSqlRawAsync(
            """
            CREATE INDEX IF NOT EXISTS "IX_Staff_IdentityUserId" ON "Staff" ("IdentityUserId");
            """);

            await db.Database.ExecuteSqlRawAsync(
            """
            DO $$
            BEGIN
                IF NOT EXISTS (
                    SELECT 1
                    FROM pg_constraint
                    WHERE conname = 'FK_Staff_AspNetUsers_IdentityUserId'
                ) THEN
                    ALTER TABLE "Staff"
                    ADD CONSTRAINT "FK_Staff_AspNetUsers_IdentityUserId"
                    FOREIGN KEY ("IdentityUserId")
                    REFERENCES "AspNetUsers" ("Id")
                    ON DELETE RESTRICT;
                END IF;
            END $$;
            """);

            await db.Database.ExecuteSqlRawAsync(
            """
            DO $$
            BEGIN
                IF EXISTS (
                    SELECT 1
                    FROM pg_constraint
                    WHERE conname = 'FK_Orders_DeliveryPerson'
                      AND conrelid = '"Orders"'::regclass
                ) THEN
                    ALTER TABLE "Orders" DROP CONSTRAINT "FK_Orders_DeliveryPerson";
                END IF;

                UPDATE "Orders" o
                SET "DeliveryPersonId" = s."Id"
                FROM "Staff" s
                WHERE o."DeliveryPersonId" IS NOT NULL
                  AND o."CompanyId" = s."CompanyId"
                  AND (o."DeliveryPersonId" = s."IdentityUserId" OR o."DeliveryPersonId" = s."UserId");

                UPDATE "Orders" o
                SET "DeliveryPersonId" = NULL
                WHERE o."DeliveryPersonId" IS NOT NULL
                  AND NOT EXISTS (
                      SELECT 1 FROM "Staff" s WHERE s."Id" = o."DeliveryPersonId"
                  );

                ALTER TABLE "Orders"
                ADD CONSTRAINT "FK_Orders_DeliveryPerson"
                FOREIGN KEY ("DeliveryPersonId")
                REFERENCES "Staff" ("Id")
                ON DELETE SET NULL;
            END $$;
            """);

            await db.Database.ExecuteSqlRawAsync(
            """
            DO $$
            BEGIN
                IF NOT EXISTS (
                    SELECT 1
                    FROM information_schema.columns
                    WHERE table_schema = 'public'
                      AND table_name = 'Orders'
                      AND column_name = 'DeliveryPincode'
                ) THEN
                    ALTER TABLE "Orders" ADD COLUMN "DeliveryPincode" text NULL;

                END IF;
            END $$;
            """);

            // Self-heal: add driver portal lifecycle columns if missing.
            await db.Database.ExecuteSqlRawAsync(
            """
            DO $$
            BEGIN
                IF NOT EXISTS (
                    SELECT 1
                    FROM information_schema.columns
                    WHERE table_schema = 'public'
                      AND table_name = 'Deliveries'
                      AND column_name = 'StartedAtUtc'
                ) THEN
                    ALTER TABLE "Deliveries" ADD COLUMN "StartedAtUtc" timestamptz NULL;
                END IF;

                IF NOT EXISTS (
                    SELECT 1
                    FROM information_schema.columns
                    WHERE table_schema = 'public'
                      AND table_name = 'Deliveries'
                      AND column_name = 'CompletedAtUtc'
                ) THEN
                    ALTER TABLE "Deliveries" ADD COLUMN "CompletedAtUtc" timestamptz NULL;
                END IF;

                IF NOT EXISTS (
                    SELECT 1
                    FROM information_schema.columns
                    WHERE table_schema = 'public'
                      AND table_name = 'Deliveries'
                      AND column_name = 'LastLocationUtc'
                ) THEN
                    ALTER TABLE "Deliveries" ADD COLUMN "LastLocationUtc" timestamptz NULL;
                END IF;
            END $$;
            """);

            // Self-heal: ensure live GPS history exists for public driver tracking.
            await db.Database.ExecuteSqlRawAsync(
            """
            DO $$
            BEGIN
                IF NOT EXISTS (
                    SELECT 1
                    FROM information_schema.tables
                    WHERE table_schema = 'public'
                      AND table_name = 'DriverLocations'
                ) THEN
                    CREATE TABLE "DriverLocations" (
                        "Id" uuid NOT NULL,
                        "DriverId" uuid NOT NULL,
                        "DeliveryId" uuid NOT NULL,
                        "Latitude" double precision NOT NULL,
                        "Longitude" double precision NOT NULL,
                        "Accuracy" double precision NULL,
                        "Speed" double precision NULL,
                        "Heading" double precision NULL,
                        "Altitude" double precision NULL,
                        "BatteryLevel" integer NULL,
                        "RecordedAt" timestamp with time zone NOT NULL,
                        "CreatedAtUtc" timestamp with time zone NOT NULL,
                        "UpdatedAtUtc" timestamp with time zone NULL,
                        CONSTRAINT "PK_DriverLocations" PRIMARY KEY ("Id"),
                        CONSTRAINT "FK_DriverLocations_Deliveries_DeliveryId" FOREIGN KEY ("DeliveryId") REFERENCES "Deliveries" ("Id") ON DELETE CASCADE
                    );

                    CREATE INDEX "IX_DriverLocations_DeliveryId" ON "DriverLocations" ("DeliveryId");
                    CREATE INDEX "IX_DriverLocations_DriverId" ON "DriverLocations" ("DriverId");
                    CREATE INDEX "IX_DriverLocations_RecordedAt" ON "DriverLocations" ("RecordedAt");
                    CREATE INDEX "IX_DriverLocations_CreatedAtUtc" ON "DriverLocations" ("CreatedAtUtc");
                    CREATE INDEX "IX_DriverLocations_DriverId_DeliveryId" ON "DriverLocations" ("DriverId", "DeliveryId");
                    CREATE INDEX "IX_DriverLocations_DriverId_RecordedAt" ON "DriverLocations" ("DriverId", "RecordedAt");
                END IF;
            END $$;
            """);

            // Self-heal: ensure delivery settings table exists for token-based public flows.
            await db.Database.ExecuteSqlRawAsync(
            """
            DO $$
            BEGIN
                IF NOT EXISTS (
                    SELECT 1
                    FROM information_schema.tables
                    WHERE table_schema = 'public'
                      AND table_name = 'DeliverySettings'
                ) THEN
                    CREATE TABLE "DeliverySettings" (
                        "Id" uuid NOT NULL,
                        "CompanyId" uuid NOT NULL,
                        "LocationUploadIntervalSeconds" integer NOT NULL,
                        "MinDistanceMetersForUpload" double precision NOT NULL,
                        "LocationRetentionDays" integer NOT NULL,
                        "ArrivedNearbyRadiusMeters" double precision NOT NULL,
                        "ImOutsideRadiusMeters" double precision NOT NULL,
                        "DelayThresholdMinutes" integer NOT NULL,
                        "AutoNotifyDelay" boolean NOT NULL,
                        "RequirePhotoProof" boolean NOT NULL,
                        "RequireSignature" boolean NOT NULL,
                        "RequireOTP" boolean NOT NULL,
                        "OTPLength" integer NOT NULL,
                        "EnableBatteryOptimization" boolean NOT NULL,
                        "LowBatteryThresholdPercent" integer NOT NULL,
                        "NotifyCustomerOnAccept" boolean NOT NULL,
                        "NotifyCustomerOnPickup" boolean NOT NULL,
                        "NotifyCustomerOnEnRoute" boolean NOT NULL,
                        "NotifyCustomerOnArrived" boolean NOT NULL,
                        "NotifyCustomerOnDelivered" boolean NOT NULL,
                        "NotifyFloristOnStatusChange" boolean NOT NULL,
                        "ShowDriverPhoneToCustomer" boolean NOT NULL,
                        "ShowDriverPhotoToCustomer" boolean NOT NULL,
                        "AllowCustomerTracking" boolean NOT NULL,
                        "CreatedAtUtc" timestamp with time zone NOT NULL,
                        "UpdatedAtUtc" timestamp with time zone NULL,
                        CONSTRAINT "PK_DeliverySettings" PRIMARY KEY ("Id")
                    );
                END IF;
            END $$;
            """);

            await db.Database.ExecuteSqlRawAsync(
            """
            CREATE UNIQUE INDEX IF NOT EXISTS "IX_DeliverySettings_CompanyId"
            ON "DeliverySettings" ("CompanyId");
            """);

            // Self-heal: add purchase mismatch flags if database is missing these newer columns.
            await db.Database.ExecuteSqlRawAsync(
            """
            DO $$
            BEGIN
                IF NOT EXISTS (
                    SELECT 1
                    FROM information_schema.columns
                    WHERE table_schema = 'public'
                      AND table_name = 'PurchaseOrderItems'
                      AND column_name = 'IsQuantityMismatch'
                ) THEN
                    ALTER TABLE "PurchaseOrderItems" ADD COLUMN "IsQuantityMismatch" boolean NULL;
                END IF;

                IF NOT EXISTS (
                    SELECT 1
                    FROM information_schema.columns
                    WHERE table_schema = 'public'
                      AND table_name = 'PurchaseOrderItems'
                      AND column_name = 'IsPriceMismatch'
                ) THEN
                    ALTER TABLE "PurchaseOrderItems" ADD COLUMN "IsPriceMismatch" boolean NULL;
                END IF;
            END $$;
            """);

            // Self-heal: create DeliveryRoutes table if it doesn't exist yet
            await db.Database.ExecuteSqlRawAsync(
            """
            DO $$
            BEGIN
                IF NOT EXISTS (
                    SELECT 1
                    FROM information_schema.tables
                    WHERE table_schema = 'public'
                      AND table_name = 'DeliveryRoutes'
                ) THEN
                    CREATE TABLE "DeliveryRoutes" (
                        "Id"               UUID        NOT NULL DEFAULT uuid_generate_v4(),
                        "DeliveryPersonId" UUID        NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000',
                        "RouteDate"        TIMESTAMPTZ NOT NULL,
                        "Name"             TEXT        NOT NULL DEFAULT '',
                        "Status"           INTEGER     NOT NULL DEFAULT 0,
                        "CreatedAtUtc"     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
                        "UpdatedAtUtc"     TIMESTAMPTZ NULL,
                        CONSTRAINT "PK_DeliveryRoutes" PRIMARY KEY ("Id")
                    );
                    CREATE INDEX "IX_DeliveryRoutes_RouteDate" ON "DeliveryRoutes" ("RouteDate");
                END IF;
            END $$;
            """);

            // Self-heal: align legacy mobile schema with current mobile admin module.
            // This is intentionally additive/non-destructive so existing data is preserved.
            await db.Database.ExecuteSqlRawAsync(
            """
            CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

            CREATE TABLE IF NOT EXISTS "MobileCustomers" (
                "Id" uuid NOT NULL DEFAULT uuid_generate_v4(),
                "CompanyId" uuid NOT NULL,
                "BusinessName" character varying(160) NOT NULL DEFAULT '',
                "OwnerName" character varying(120) NOT NULL DEFAULT '',
                "Mobile" character varying(32) NOT NULL DEFAULT '',
                "Email" character varying(160),
                "City" character varying(100),
                "State" character varying(100),
                "Country" character varying(100),
                "IsDeleted" boolean NOT NULL DEFAULT false,
                "DeletedAtUtc" timestamptz,
                "CreatedBy" uuid,
                "UpdatedBy" uuid,
                "CreatedAtUtc" timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
                "UpdatedAtUtc" timestamptz,
                "RowVersion" bytea NOT NULL DEFAULT E'\\x',
                CONSTRAINT "PK_MobileCustomers" PRIMARY KEY ("Id")
            );

            CREATE TABLE IF NOT EXISTS "SubscriptionPlans" (
                "Id" uuid NOT NULL DEFAULT uuid_generate_v4(),
                "Code" character varying(40) NOT NULL,
                "Name" character varying(100) NOT NULL,
                "PlanType" character varying(24) NOT NULL,
                "MonthlyPrice" numeric(18,2) NOT NULL DEFAULT 0,
                "AnnualPrice" numeric(18,2) NOT NULL DEFAULT 0,
                "LifetimePrice" numeric(18,2) NOT NULL DEFAULT 0,
                "TrialDays" integer NOT NULL DEFAULT 30,
                "OfflineDays" integer NOT NULL DEFAULT 3,
                "GraceDays" integer NOT NULL DEFAULT 5,
                "MaximumDevices" integer NOT NULL DEFAULT 1,
                "MaximumStaff" integer NOT NULL DEFAULT 1,
                "IncludedModulesJson" text NOT NULL DEFAULT '[]',
                "IsActive" boolean NOT NULL DEFAULT true,
                "IsDeleted" boolean NOT NULL DEFAULT false,
                "DeletedAtUtc" timestamptz,
                "CreatedBy" uuid,
                "UpdatedBy" uuid,
                "CreatedAtUtc" timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
                "UpdatedAtUtc" timestamptz,
                "RowVersion" bytea NOT NULL DEFAULT E'\\x',
                CONSTRAINT "PK_SubscriptionPlans" PRIMARY KEY ("Id")
            );

            CREATE TABLE IF NOT EXISTS "MobileUsers" (
                "Id" uuid NOT NULL DEFAULT uuid_generate_v4(),
                "CompanyId" uuid NOT NULL,
                "MobileCustomerId" uuid,
                "FullName" character varying(120) NOT NULL DEFAULT '',
                "Mobile" character varying(32) NOT NULL DEFAULT '',
                "Email" character varying(160),
                "Status" character varying(24) NOT NULL DEFAULT 'Active',
                "PreferredLanguage" character varying(16) NOT NULL DEFAULT 'en-IN',
                "PreferredTheme" character varying(32) NOT NULL DEFAULT 'system',
                "IsDeleted" boolean NOT NULL DEFAULT false,
                "DeletedAtUtc" timestamptz,
                "CreatedBy" uuid,
                "UpdatedBy" uuid,
                "CreatedAtUtc" timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
                "UpdatedAtUtc" timestamptz,
                "RowVersion" bytea NOT NULL DEFAULT E'\\x',
                CONSTRAINT "PK_MobileUsers" PRIMARY KEY ("Id")
            );

            CREATE TABLE IF NOT EXISTS "MobileSubscriptions" (
                "Id" uuid NOT NULL DEFAULT uuid_generate_v4(),
                "CompanyId" uuid NOT NULL,
                "MobileUserId" uuid NOT NULL,
                "SubscriptionPlanId" uuid,
                "Status" character varying(24) NOT NULL DEFAULT 'Trial',
                "TrialStartUtc" timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
                "TrialEndUtc" timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP + INTERVAL '30 days',
                "StartUtc" timestamptz,
                "EndUtc" timestamptz,
                "GraceEndUtc" timestamptz,
                "LastValidatedUtc" timestamptz,
                "AutoRenew" boolean NOT NULL DEFAULT false,
                "IsDeleted" boolean NOT NULL DEFAULT false,
                "DeletedAtUtc" timestamptz,
                "CreatedBy" uuid,
                "UpdatedBy" uuid,
                "CreatedAtUtc" timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
                "UpdatedAtUtc" timestamptz,
                "RowVersion" bytea NOT NULL DEFAULT E'\\x',
                CONSTRAINT "PK_MobileSubscriptions" PRIMARY KEY ("Id")
            );

            CREATE TABLE IF NOT EXISTS "MobileDevices" (
                "Id" uuid NOT NULL DEFAULT uuid_generate_v4(),
                "CompanyId" uuid NOT NULL,
                "MobileUserId" uuid,
                "DeviceId" character varying(120),
                "Manufacturer" character varying(80),
                "Model" character varying(120),
                "Platform" character varying(24) NOT NULL DEFAULT 'android',
                "OsVersion" character varying(80),
                "AppVersion" character varying(40) NOT NULL DEFAULT '1.0.0',
                "PushToken" character varying(512),
                "LastIpAddress" character varying(64),
                "LastLoginAtUtc" timestamptz,
                "LastHeartbeatAtUtc" timestamptz,
                "LastSyncAtUtc" timestamptz,
                "Status" character varying(24) NOT NULL DEFAULT 'Active',
                "IsDeleted" boolean NOT NULL DEFAULT false,
                "DeletedAtUtc" timestamptz,
                "CreatedBy" uuid,
                "UpdatedBy" uuid,
                "CreatedAtUtc" timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
                "UpdatedAtUtc" timestamptz,
                "RowVersion" bytea NOT NULL DEFAULT E'\\x',
                CONSTRAINT "PK_MobileDevices" PRIMARY KEY ("Id")
            );

            CREATE TABLE IF NOT EXISTS "MobileLicenses" (
                "Id" uuid NOT NULL DEFAULT uuid_generate_v4(),
                "CompanyId" uuid NOT NULL,
                "MobileDeviceId" uuid,
                "MobileSubscriptionId" uuid,
                "Status" character varying(24) NOT NULL DEFAULT 'Active',
                "IssuedAtUtc" timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
                "ExpiryUtc" timestamptz,
                "RevokedAtUtc" timestamptz,
                "IsDeleted" boolean NOT NULL DEFAULT false,
                "DeletedAtUtc" timestamptz,
                "CreatedBy" uuid,
                "UpdatedBy" uuid,
                "CreatedAtUtc" timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
                "UpdatedAtUtc" timestamptz,
                "RowVersion" bytea NOT NULL DEFAULT E'\\x',
                CONSTRAINT "PK_MobileLicenses" PRIMARY KEY ("Id")
            );

            DO $$
            BEGIN
                -- Legacy MobileDevices used UserId + DeviceFingerprintHash + DeviceName.
                IF EXISTS (
                    SELECT 1 FROM information_schema.columns
                    WHERE table_schema = 'public' AND table_name = 'MobileDevices' AND column_name = 'UserId'
                ) AND NOT EXISTS (
                    SELECT 1 FROM information_schema.columns
                    WHERE table_schema = 'public' AND table_name = 'MobileDevices' AND column_name = 'MobileUserId'
                ) THEN
                    ALTER TABLE "MobileDevices" ADD COLUMN "MobileUserId" uuid NULL;
                    EXECUTE 'UPDATE "MobileDevices" SET "MobileUserId" = "UserId" WHERE "MobileUserId" IS NULL';
                END IF;

                IF NOT EXISTS (
                    SELECT 1 FROM information_schema.columns
                    WHERE table_schema = 'public' AND table_name = 'MobileDevices' AND column_name = 'DeviceId'
                ) THEN
                    ALTER TABLE "MobileDevices" ADD COLUMN "DeviceId" character varying(120) NULL;
                END IF;

                IF EXISTS (
                    SELECT 1 FROM information_schema.columns
                    WHERE table_schema = 'public' AND table_name = 'MobileDevices' AND column_name = 'DeviceFingerprintHash'
                ) THEN
                    EXECUTE 'UPDATE "MobileDevices" SET "DeviceId" = COALESCE("DeviceId", "DeviceFingerprintHash", "Id"::text)';
                ELSE
                    EXECUTE 'UPDATE "MobileDevices" SET "DeviceId" = COALESCE("DeviceId", "Id"::text)';
                END IF;

                IF NOT EXISTS (
                    SELECT 1 FROM information_schema.columns
                    WHERE table_schema = 'public' AND table_name = 'MobileDevices' AND column_name = 'Model'
                ) THEN
                    ALTER TABLE "MobileDevices" ADD COLUMN "Model" character varying(120) NULL;
                END IF;

                IF EXISTS (
                    SELECT 1 FROM information_schema.columns
                    WHERE table_schema = 'public' AND table_name = 'MobileDevices' AND column_name = 'DeviceName'
                ) THEN
                    EXECUTE 'UPDATE "MobileDevices" SET "Model" = COALESCE("Model", "DeviceName")';
                END IF;

                IF NOT EXISTS (
                    SELECT 1 FROM information_schema.columns
                    WHERE table_schema = 'public' AND table_name = 'MobileDevices' AND column_name = 'Status'
                ) THEN
                    ALTER TABLE "MobileDevices" ADD COLUMN "Status" character varying(24) NULL;
                END IF;

                IF EXISTS (
                    SELECT 1 FROM information_schema.columns
                    WHERE table_schema = 'public' AND table_name = 'MobileDevices' AND column_name = 'IsActive'
                ) THEN
                    EXECUTE 'UPDATE "MobileDevices" SET "Status" = COALESCE("Status", CASE WHEN "IsActive" THEN ''Active'' ELSE ''Disabled'' END)';
                ELSE
                    EXECUTE 'UPDATE "MobileDevices" SET "Status" = COALESCE("Status", ''Active'')';
                END IF;

                IF NOT EXISTS (
                    SELECT 1 FROM information_schema.columns
                    WHERE table_schema = 'public' AND table_name = 'MobileDevices' AND column_name = 'LastHeartbeatAtUtc'
                ) THEN
                    ALTER TABLE "MobileDevices" ADD COLUMN "LastHeartbeatAtUtc" timestamptz NULL;
                END IF;

                IF EXISTS (
                    SELECT 1 FROM information_schema.columns
                    WHERE table_schema = 'public' AND table_name = 'MobileDevices' AND column_name = 'LastSeenAtUtc'
                ) THEN
                    EXECUTE 'UPDATE "MobileDevices" SET "LastHeartbeatAtUtc" = COALESCE("LastHeartbeatAtUtc", "LastSeenAtUtc")';
                END IF;

                IF NOT EXISTS (
                    SELECT 1 FROM information_schema.columns
                    WHERE table_schema = 'public' AND table_name = 'MobileDevices' AND column_name = 'IsDeleted'
                ) THEN
                    ALTER TABLE "MobileDevices" ADD COLUMN "IsDeleted" boolean NOT NULL DEFAULT false;
                END IF;

                IF NOT EXISTS (
                    SELECT 1 FROM information_schema.columns
                    WHERE table_schema = 'public' AND table_name = 'MobileDevices' AND column_name = 'CreatedBy'
                ) THEN
                    ALTER TABLE "MobileDevices" ADD COLUMN "CreatedBy" uuid NULL;
                END IF;

                IF NOT EXISTS (
                    SELECT 1 FROM information_schema.columns
                    WHERE table_schema = 'public' AND table_name = 'MobileDevices' AND column_name = 'UpdatedBy'
                ) THEN
                    ALTER TABLE "MobileDevices" ADD COLUMN "UpdatedBy" uuid NULL;
                END IF;

                IF NOT EXISTS (
                    SELECT 1 FROM information_schema.columns
                    WHERE table_schema = 'public' AND table_name = 'MobileDevices' AND column_name = 'RowVersion'
                ) THEN
                    ALTER TABLE "MobileDevices" ADD COLUMN "RowVersion" bytea NOT NULL DEFAULT E'\\x';
                END IF;

                IF EXISTS (
                    SELECT 1 FROM information_schema.columns
                    WHERE table_schema = 'public' AND table_name = 'MobileUsers' AND column_name = 'CustomerId'
                ) AND NOT EXISTS (
                    SELECT 1 FROM information_schema.columns
                    WHERE table_schema = 'public' AND table_name = 'MobileUsers' AND column_name = 'MobileCustomerId'
                ) THEN
                    ALTER TABLE "MobileUsers" ADD COLUMN "MobileCustomerId" uuid NULL;
                    EXECUTE 'UPDATE "MobileUsers" SET "MobileCustomerId" = "CustomerId" WHERE "MobileCustomerId" IS NULL';
                END IF;

                IF NOT EXISTS (
                    SELECT 1 FROM information_schema.columns
                    WHERE table_schema = 'public' AND table_name = 'MobileUsers' AND column_name = 'IsDeleted'
                ) THEN
                    ALTER TABLE "MobileUsers" ADD COLUMN "IsDeleted" boolean NOT NULL DEFAULT false;
                END IF;
            END $$;

            CREATE INDEX IF NOT EXISTS "IX_MobileUsers_CompanyId_Status" ON "MobileUsers" ("CompanyId", "Status");
            CREATE INDEX IF NOT EXISTS "IX_MobileDevices_CompanyId_Status" ON "MobileDevices" ("CompanyId", "Status");
            CREATE INDEX IF NOT EXISTS "IX_MobileLicenses_CompanyId_Status" ON "MobileLicenses" ("CompanyId", "Status");

            INSERT INTO "SubscriptionPlans"
            (
                "Id", "Code", "Name", "PlanType", "MonthlyPrice", "AnnualPrice", "LifetimePrice", "TrialDays",
                "OfflineDays", "GraceDays", "MaximumDevices", "MaximumStaff", "IncludedModulesJson", "IsActive",
                "IsDeleted", "CreatedAtUtc", "RowVersion"
            )
            SELECT
                uuid_generate_v4(),
                'MOBILE_TRIAL',
                'Mobile Trial',
                'Basic',
                0,
                0,
                0,
                30,
                3,
                5,
                2,
                2,
                '[]',
                true,
                false,
                CURRENT_TIMESTAMP,
                E'\\x'
            WHERE NOT EXISTS (SELECT 1 FROM "SubscriptionPlans" WHERE "Code" = 'MOBILE_TRIAL');
            """);
        }

        if (enableSeeding)
        {
            await DataSeeder.SeedAsync(app.Services);
            await CategoryMigrationService.MigrateAsync(app.Services);
        }
        else
        {
            startupLogger.LogInformation("Database seeding is disabled by configuration.");
        }
    }
}
catch (Exception ex)
{
    if (failOnSeedError)
    {
        startupLogger.LogError(ex, "An error occurred during startup database patching or seeding.");
        throw; // Keep strict behavior when configured.
    }

    startupLogger.LogWarning(ex, "Startup database patching/seeding failed, but startup will continue because Database:FailOnSeedError is false.");
}

#endregion

app.Run();

static async Task<bool> CanConnectWithBackoffAsync(SumpoojDbContext db, ILogger logger, bool strictMode)
{
    const int maxRetries = 3;
    var delay = TimeSpan.FromMilliseconds(250);

    for (var attempt = 1; attempt <= maxRetries; attempt++)
    {
        using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(2));

        try
        {
            if (await db.Database.CanConnectAsync(cts.Token))
            {
                if (attempt > 1)
                {
                    logger.LogInformation("Database connectivity recovered on attempt {Attempt}.", attempt);
                }

                return true;
            }
        }
        catch (OperationCanceledException)
        {
            logger.LogWarning("Database startup connectivity attempt {Attempt} timed out.", attempt);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Database startup connectivity attempt {Attempt} failed.", attempt);
        }

        if (attempt < maxRetries)
        {
            logger.LogWarning("Retrying database startup connectivity in {DelayMs} ms.", delay.TotalMilliseconds);
            await Task.Delay(delay);
            delay = TimeSpan.FromMilliseconds(delay.TotalMilliseconds * 2);
        }
    }

    if (strictMode)
    {
        logger.LogError("Database connectivity failed after {MaxRetries} attempts in strict mode.", maxRetries);
    }

    return false;
}

static HealthCheckOptions BuildHealthOptions(Func<HealthCheckRegistration, bool> predicate)
{
    return new HealthCheckOptions
    {
        Predicate = predicate,
        ResultStatusCodes =
        {
            [HealthStatus.Healthy] = StatusCodes.Status200OK,
            [HealthStatus.Degraded] = StatusCodes.Status503ServiceUnavailable,
            [HealthStatus.Unhealthy] = StatusCodes.Status503ServiceUnavailable
        },
        ResponseWriter = async (context, report) =>
        {
            context.Response.ContentType = "application/json";
            var payload = new
            {
                status = report.Status.ToString(),
                durationMs = report.TotalDuration.TotalMilliseconds,
                checks = report.Entries.ToDictionary(
                    entry => entry.Key,
                    entry => new
                    {
                        status = entry.Value.Status.ToString(),
                        description = entry.Value.Description,
                        durationMs = entry.Value.Duration.TotalMilliseconds,
                        data = entry.Value.Data
                    })
            };

            await context.Response.WriteAsync(JsonSerializer.Serialize(payload));
        }
    };
}
