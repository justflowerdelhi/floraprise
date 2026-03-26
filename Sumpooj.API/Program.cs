using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Scalar.AspNetCore;
using Sumpooj.API.Authorization;
using Sumpooj.API.Infrastructure;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Companies;
using Sumpooj.Application.AI;
using Sumpooj.Application.Deliveries;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Payments;
using Sumpooj.Application.UseCases;
using Sumpooj.Infrastructure;
using Sumpooj.Infrastructure.Companies;
using Sumpooj.Infrastructure.ExternalServices;
using Sumpooj.Infrastructure.Identity;
using Sumpooj.Infrastructure.Persistence;
using Sumpooj.Infrastructure.Repositories;
using Sumpooj.Application.Marketing;
using Sumpooj.Application.Email;
using Sumpooj.Infrastructure.Email;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

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
    options.UseNpgsql(builder.Configuration.GetConnectionString("Default"))
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
             ?? throw new InvalidOperationException("JWT Key missing");
var jwtIssuer = builder.Configuration["Jwt:Issuer"]
                ?? throw new InvalidOperationException("JWT Issuer missing");

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

#endregion

#region Application Services

builder.Services.AddScoped<ICustomerRepository, CustomerRepository>();
builder.Services.AddScoped<CustomerService>();

builder.Services.AddScoped<ICompanyService, CompanyService>();

// AI Services
var openAISettings = builder.Configuration.GetSection("OpenAI").Get<OpenAISettings>() ?? new OpenAISettings();
builder.Services.AddSingleton(openAISettings);
builder.Services.AddScoped<IAIUsageRepository, AIUsageRepository>();
builder.Services.AddScoped<GiftCardAIService>();
builder.Services.AddScoped<BouquetAIService>();

builder.Services.AddScoped<IProductRepository, ProductRepository>();
builder.Services.AddScoped<ProductService>();

builder.Services.AddScoped<IProductCategoryRepository, ProductCategoryRepository>();
builder.Services.AddScoped<ProductCategoryService>();

builder.Services.AddScoped<ISupplierRepository, SupplierRepository>();
builder.Services.AddScoped<SupplierService>();

builder.Services.AddScoped<IProductBatchRepository, ProductBatchRepository>();
builder.Services.AddScoped<IInventoryAdjustmentRepository, InventoryAdjustmentRepository>();
builder.Services.AddScoped<IInventoryLedgerRepository, InventoryLedgerRepository>();
builder.Services.AddScoped<InventoryService>();

builder.Services.AddScoped<IPurchaseOrderRepository, PurchaseOrderRepository>();
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
builder.Services.AddScoped<DemoRequestService>();

// Audit Action Filter (auto-logs all mutating API actions)
builder.Services.AddScoped<AuditActionFilter>();

#endregion

#region Controllers & OpenAPI

builder.Services.AddControllers(options =>
{
    options.Filters.AddService<AuditActionFilter>();
});

// Built-in OpenAPI (no Swagger UI headaches)
builder.Services.AddOpenApi();

#endregion

var app = builder.Build();

#region Middleware

//if (app.Environment.IsDevelopment())
//{
    app.MapOpenApi();
    app.MapScalarApiReference(); // optional API explorer
//}

// CORS must run FIRST — before HTTPS redirect, auth, etc.
// Otherwise preflight OPTIONS requests get redirected/blocked.
app.UseCors("DefaultCorsPolicy");

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

#endregion

#region Data Seed
var failOnSeedError = builder.Configuration.GetValue("Database:FailOnSeedError", !app.Environment.IsDevelopment());

try
{
    await DataSeeder.SeedAsync(app.Services);

    // Migrate existing products to use dynamic CategoryId
    await CategoryMigrationService.MigrateAsync(app.Services);
}
catch (Exception ex)
{
    var logger = app.Services.GetRequiredService<ILogger<Program>>();
    if (failOnSeedError)
    {
        logger.LogError(ex, "An error occurred during data seeding.");
        throw; // Keep strict behavior when configured.
    }

    logger.LogWarning(ex, "Data seeding failed, but startup will continue because Database:FailOnSeedError is false.");
}

#endregion

app.Run();
