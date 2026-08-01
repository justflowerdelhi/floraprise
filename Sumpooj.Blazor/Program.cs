using Microsoft.AspNetCore.Components.Authorization;
using Microsoft.AspNetCore.Components.Web;
using MudBlazor.Services;
using Sumpooj.Blazor.Auth;
using Sumpooj.Blazor.Data;
using Sumpooj.Blazor.Services;
using Sumpooj.Infrastructure.Persistence;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorPages();
builder.Services.AddServerSideBlazor();
builder.Services.AddMudServices();

// Database
builder.Services.AddDbContext<SumpoojDbContext>();

// Owner Authentication
builder.Services.AddScoped<OwnerAuthService>();

// API Services
builder.Services.AddScoped<SubscriptionApiService>();
builder.Services.AddScoped<DeliveryApiService>();
builder.Services.AddScoped<SupportApiService>();
builder.Services.AddScoped<NotificationApiService>();
builder.Services.AddScoped<DeviceApiService>();
builder.Services.AddScoped<SystemApiService>();

// State
builder.Services.AddScoped<OwnerState>();

// HTTP Client
builder.Services.AddHttpClient("Api", client =>
{
    client.BaseAddress = new Uri(builder.Configuration["ApiBaseUrl"] ?? "http://localhost:5148/");
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    app.UseHsts();
}

// Disable HTTPS redirection for development to avoid redirect loop
if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

app.UseStaticFiles();
app.UseRouting();

app.MapBlazorHub();
app.MapFallbackToPage("/_Host");

app.Run();
