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
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.UseCases;
using Sumpooj.Infrastructure;
using Sumpooj.Infrastructure.Companies;
using Sumpooj.Infrastructure.Identity;
using Sumpooj.Infrastructure.Persistence;
using Sumpooj.Infrastructure.Repositories;
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
            // If no origins configured allow nothing by default - caller can adjust appsettings
            policy.WithOrigins()
                  .AllowAnyHeader()
                  .AllowAnyMethod();
        }
        else
        {
            policy.WithOrigins(corsOrigins)
                  .AllowAnyHeader()
                  .AllowAnyMethod();
        }
    });
});

#endregion

#region Database

builder.Services.AddDbContext<SumpoojDbContext>(options =>
    options.UseNpgsql(
        builder.Configuration.GetConnectionString("Default")));

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

builder.Services.AddScoped<IProductRepository, ProductRepository>();
builder.Services.AddScoped<ProductService>();

builder.Services.AddScoped<ISupplierRepository, SupplierRepository>();
builder.Services.AddScoped<SupplierService>();

builder.Services.AddScoped<IProductBatchRepository, ProductBatchRepository>();
builder.Services.AddScoped<IInventoryAdjustmentRepository, InventoryAdjustmentRepository>();
builder.Services.AddScoped<InventoryService>();

builder.Services.AddScoped<IPurchaseOrderRepository, PurchaseOrderRepository>();
builder.Services.AddScoped<PurchaseOrderService>();

builder.Services.AddScoped<ILocationRepository, LocationRepository>();
builder.Services.AddScoped<LocationService>();

// New Services
builder.Services.AddScoped<IStaffRepository, StaffRepository>();
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

builder.Services.AddScoped<DashboardService>();

// Audit Logging
builder.Services.AddScoped<IAuditLogRepository, AuditLogRepository>();
builder.Services.AddScoped<AuditLogService>();

#endregion

#region Controllers & OpenAPI

builder.Services.AddControllers();

// Built-in OpenAPI (no Swagger UI headaches)
builder.Services.AddOpenApi();

#endregion

var app = builder.Build();

#region Middleware

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference(); // optional API explorer
}

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

// Enable CORS using the configured policy
app.UseCors("DefaultCorsPolicy");

app.MapControllers();

#endregion

#region Data Seed

await DataSeeder.SeedAsync(app.Services);

#endregion

app.Run();
