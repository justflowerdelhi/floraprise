using FluentValidation;
using Floraprise.Mobile.Application.Validators;
using Microsoft.Extensions.DependencyInjection;

namespace Floraprise.Mobile.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddMobileApplication(this IServiceCollection services)
    {
        services.AddValidatorsFromAssembly(typeof(DependencyInjection).Assembly);
        services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(typeof(DependencyInjection).Assembly));
        return services;
    }
}
