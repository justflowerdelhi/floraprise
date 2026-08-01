using Floraprise.Mobile.Contracts.Configuration;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Floraprise.Mobile.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddMobileInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        services.Configure<MobileOptions>(configuration.GetSection(MobileOptions.SectionName));
        services.Configure<JwtOptions>(configuration.GetSection(JwtOptions.SectionName));
        services.Configure<DatabaseOptions>(configuration.GetSection(DatabaseOptions.SectionName));
        services.Configure<RedisOptions>(configuration.GetSection(RedisOptions.SectionName));
        services.Configure<StorageOptions>(configuration.GetSection(StorageOptions.SectionName));
        services.Configure<NotificationOptions>(configuration.GetSection(NotificationOptions.SectionName));
        services.Configure<LicenseOptions>(configuration.GetSection(LicenseOptions.SectionName));
        return services;
    }
}
