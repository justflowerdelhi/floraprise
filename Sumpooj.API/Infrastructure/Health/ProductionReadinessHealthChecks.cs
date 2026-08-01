using System.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Sumpooj.API.Services.Mobile;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Mobile;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.API.Infrastructure.Health;

internal static class DatabaseHealthCircuit
{
    private static readonly object LockObject = new();
    private static int _consecutiveFailures;
    private static DateTimeOffset? _openUntilUtc;

    public static bool IsOpen()
    {
        lock (LockObject)
        {
            if (_openUntilUtc.HasValue && _openUntilUtc.Value > DateTimeOffset.UtcNow)
            {
                return true;
            }

            if (_openUntilUtc.HasValue && _openUntilUtc.Value <= DateTimeOffset.UtcNow)
            {
                _openUntilUtc = null;
                _consecutiveFailures = 0;
            }

            return false;
        }
    }

    public static void MarkSuccess()
    {
        lock (LockObject)
        {
            _consecutiveFailures = 0;
            _openUntilUtc = null;
        }
    }

    public static void MarkFailure()
    {
        lock (LockObject)
        {
            _consecutiveFailures++;
            if (_consecutiveFailures >= 3)
            {
                _openUntilUtc = DateTimeOffset.UtcNow.AddSeconds(10);
            }
        }
    }

    public static DateTimeOffset? OpenUntilUtc
    {
        get
        {
            lock (LockObject)
            {
                return _openUntilUtc;
            }
        }
    }
}

public sealed class DatabaseConnectivityHealthCheck : IHealthCheck
{
    private readonly SumpoojDbContext _dbContext;

    public DatabaseConnectivityHealthCheck(SumpoojDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        if (DatabaseHealthCircuit.IsOpen())
        {
            return HealthCheckResult.Unhealthy(
                "Database connectivity circuit is open.",
                data: new Dictionary<string, object>
                {
                    ["circuitOpen"] = true,
                    ["openUntilUtc"] = DatabaseHealthCircuit.OpenUntilUtc?.ToString("O") ?? string.Empty
                });
        }

        using var timeoutCts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        timeoutCts.CancelAfter(TimeSpan.FromSeconds(2));

        try
        {
            var canConnect = await _dbContext.Database.CanConnectAsync(timeoutCts.Token);
            if (!canConnect)
            {
                DatabaseHealthCircuit.MarkFailure();
                return HealthCheckResult.Unhealthy(
                    "Database connectivity check failed.",
                    data: new Dictionary<string, object>
                    {
                        ["circuitOpen"] = DatabaseHealthCircuit.IsOpen()
                    });
            }

            DatabaseHealthCircuit.MarkSuccess();
            return HealthCheckResult.Healthy("Database connectivity check passed.");
        }
        catch (OperationCanceledException)
        {
            DatabaseHealthCircuit.MarkFailure();
            return HealthCheckResult.Unhealthy(
                "Database connectivity timed out.",
                data: new Dictionary<string, object>
                {
                    ["timeoutMs"] = 2000,
                    ["circuitOpen"] = DatabaseHealthCircuit.IsOpen()
                });
        }
        catch (Exception ex)
        {
            DatabaseHealthCircuit.MarkFailure();
            return HealthCheckResult.Unhealthy(
                "Database connectivity check failed.",
                ex,
                new Dictionary<string, object>
                {
                    ["exceptionType"] = ex.GetType().Name,
                    ["circuitOpen"] = DatabaseHealthCircuit.IsOpen()
                });
        }
    }
}

public sealed class DatabaseMigrationsHealthCheck : IHealthCheck
{
    private readonly SumpoojDbContext _dbContext;

    public DatabaseMigrationsHealthCheck(SumpoojDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        if (DatabaseHealthCircuit.IsOpen())
        {
            return HealthCheckResult.Unhealthy(
                "Database migration check skipped because connectivity circuit is open.",
                data: new Dictionary<string, object>
                {
                    ["circuitOpen"] = true,
                    ["openUntilUtc"] = DatabaseHealthCircuit.OpenUntilUtc?.ToString("O") ?? string.Empty
                });
        }

        using var timeoutCts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        timeoutCts.CancelAfter(TimeSpan.FromSeconds(2));

        try
        {
            if (!await _dbContext.Database.CanConnectAsync(timeoutCts.Token))
            {
                DatabaseHealthCircuit.MarkFailure();
                return HealthCheckResult.Unhealthy("Database unreachable. Migration state cannot be verified.");
            }

            var pending = (await _dbContext.Database.GetPendingMigrationsAsync(timeoutCts.Token)).ToList();
            if (pending.Count > 0)
            {
                DatabaseHealthCircuit.MarkSuccess();
                return HealthCheckResult.Healthy(
                    "Database is reachable; EF reports pending migrations, but readiness is being tolerated for deployment.",
                    data: new Dictionary<string, object>
                    {
                        ["pendingCount"] = pending.Count,
                        ["pendingMigrations"] = pending
                    });
            }

            DatabaseHealthCircuit.MarkSuccess();
            return HealthCheckResult.Healthy("No pending migrations.");
        }
        catch (OperationCanceledException)
        {
            DatabaseHealthCircuit.MarkFailure();
            return HealthCheckResult.Unhealthy(
                "Database migration check timed out.",
                data: new Dictionary<string, object>
                {
                    ["timeoutMs"] = 2000,
                    ["circuitOpen"] = DatabaseHealthCircuit.IsOpen()
                });
        }
        catch (Exception ex)
        {
            DatabaseHealthCircuit.MarkFailure();
            return HealthCheckResult.Unhealthy(
                "Database migration check failed.",
                ex,
                new Dictionary<string, object>
                {
                    ["exceptionType"] = ex.GetType().Name,
                    ["circuitOpen"] = DatabaseHealthCircuit.IsOpen()
                });
        }
    }

    private async Task<bool> HasCompatibleMobileSchemaAsync(CancellationToken cancellationToken)
    {
        var connection = _dbContext.Database.GetDbConnection();
        var wasOpen = connection.State == ConnectionState.Open;

        if (!wasOpen)
        {
            await connection.OpenAsync(cancellationToken);
        }

        try
        {
            await using var command = connection.CreateCommand();
            command.CommandText = """
                SELECT EXISTS (
                    SELECT 1
                    FROM information_schema.tables
                    WHERE table_schema = 'public'
                      AND table_name IN ('MobileCustomers', 'MobileUsers', 'MobileDevices', 'MobileSubscriptions', 'MobileLicenses', 'SubscriptionPlans')
                );
                """;

            var result = await command.ExecuteScalarAsync(cancellationToken);
            return result is bool boolResult && boolResult;
        }
        finally
        {
            if (!wasOpen)
            {
                await connection.CloseAsync();
            }
        }
    }
}

public sealed class JwtConfigurationHealthCheck : IHealthCheck
{
    private readonly IConfiguration _configuration;

    public JwtConfigurationHealthCheck(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        var key = _configuration["Jwt:Key"];
        var issuer = _configuration["Jwt:Issuer"];

        if (string.IsNullOrWhiteSpace(key) || string.IsNullOrWhiteSpace(issuer))
        {
            return Task.FromResult(HealthCheckResult.Unhealthy("JWT configuration is missing required values."));
        }

        if (key.Length < 32)
        {
            return Task.FromResult(HealthCheckResult.Unhealthy("JWT key length is below recommended minimum."));
        }

        return Task.FromResult(HealthCheckResult.Healthy("JWT configuration check passed."));
    }
}

public sealed class MobileServicesHealthCheck : IHealthCheck
{
    private readonly IServiceProvider _serviceProvider;

    public MobileServicesHealthCheck(IServiceProvider serviceProvider)
    {
        _serviceProvider = serviceProvider;
    }

    public Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        using var scope = _serviceProvider.CreateScope();
        var isService = scope.ServiceProvider.GetRequiredService<IServiceProviderIsService>();
        if (!isService.IsService(typeof(IMobileClientService)))
        {
            return Task.FromResult(HealthCheckResult.Unhealthy("IMobileClientService is not registered."));
        }

        return Task.FromResult(HealthCheckResult.Healthy("Mobile services are registered."));
    }
}

public sealed class SubscriptionServicesHealthCheck : IHealthCheck
{
    private readonly IServiceProvider _serviceProvider;

    public SubscriptionServicesHealthCheck(IServiceProvider serviceProvider)
    {
        _serviceProvider = serviceProvider;
    }

    public Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        using var scope = _serviceProvider.CreateScope();
        var isService = scope.ServiceProvider.GetRequiredService<IServiceProviderIsService>();
        if (!isService.IsService(typeof(IMobileSubscriptionService)))
        {
            return Task.FromResult(HealthCheckResult.Unhealthy("IMobileSubscriptionService is not registered."));
        }

        return Task.FromResult(HealthCheckResult.Healthy("Subscription services are registered."));
    }
}

public sealed class DeviceServicesHealthCheck : IHealthCheck
{
    private readonly IServiceProvider _serviceProvider;

    public DeviceServicesHealthCheck(IServiceProvider serviceProvider)
    {
        _serviceProvider = serviceProvider;
    }

    public Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        using var scope = _serviceProvider.CreateScope();
        var isService = scope.ServiceProvider.GetRequiredService<IServiceProviderIsService>();
        if (!isService.IsService(typeof(IMobileDeviceRepository)))
        {
            return Task.FromResult(HealthCheckResult.Unhealthy("IMobileDeviceRepository is not registered."));
        }

        return Task.FromResult(HealthCheckResult.Healthy("Device services are registered."));
    }
}
