using System.Text.Json.Serialization;
using Floraprise.License.Api.Data;
using Floraprise.License.Api.Repositories;
using Floraprise.License.Api.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

var connectionString = builder.Configuration.GetConnectionString("LicenseDatabase")
    ?? throw new InvalidOperationException("Connection string 'LicenseDatabase' is required.");

builder.Services.AddDbContext<LicenseDbContext>(options =>
    options.UseNpgsql(connectionString));

builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
    });

builder.Services.AddScoped<ICustomerRepository, CustomerRepository>();
builder.Services.AddScoped<IDeviceRepository, DeviceRepository>();
builder.Services.AddScoped<ILicenseRepository, LicenseRepository>();
builder.Services.AddScoped<IClock, SystemClock>();
builder.Services.AddScoped<ILicenseService, LicenseService>();

builder.Services.AddHealthChecks();

var app = builder.Build();

app.Use(async (context, next) =>
{
    try
    {
        await next(context);
    }
    catch (Exception exception)
    {
        var logger = context.RequestServices
            .GetRequiredService<ILoggerFactory>()
            .CreateLogger("UnhandledException");
        logger.LogError(exception, "Unhandled API exception.");

        context.Response.StatusCode = StatusCodes.Status500InternalServerError;
        await context.Response.WriteAsJsonAsync(new ProblemDetails
        {
            Title = "Unexpected server error",
            Status = StatusCodes.Status500InternalServerError,
            Detail = "Floraprise License API could not complete the request."
        });
    }
});

app.MapControllers();
app.MapHealthChecks("/health");

app.Run();

public partial class Program
{
}