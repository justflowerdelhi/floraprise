using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Components.Authorization;
using Microsoft.AspNetCore.Components.Web;
using Sumpooj.Blazor.Auth;
using Sumpooj.Blazor.Data;
using Sumpooj.Blazor.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorPages();
builder.Services.AddServerSideBlazor();
builder.Services.AddSingleton<WeatherForecastService>();

// Register TokenStorage as a concrete type and as the interfaces
builder.Services.AddScoped<TokenStorage>();
builder.Services.AddScoped<ITokenStorage>(sp => sp.GetRequiredService<TokenStorage>());
builder.Services.AddScoped<ITokenStorageNotifier>(sp => sp.GetRequiredService<TokenStorage>());

builder.Services.AddScoped<AuthApiService>();
builder.Services.AddScoped<JwtAuthHandler>();
builder.Services.AddScoped<CustomerApiService>();

builder.Services.AddHttpClient("Api", client =>
{
    client.BaseAddress = new Uri("https://localhost:7223/");
})
.AddHttpMessageHandler<JwtAuthHandler>();

builder.Services.AddAuthorizationCore();

builder.Services.AddScoped<AuthenticationStateProvider,
    JwtAuthenticationStateProvider>();


var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();

app.UseStaticFiles();

app.UseRouting();

app.MapBlazorHub();
app.MapFallbackToPage("/_Host");

app.Run();
