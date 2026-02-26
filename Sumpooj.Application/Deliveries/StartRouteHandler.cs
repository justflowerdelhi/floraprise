using Sumpooj.Domain.Entities;
using Sumpooj.Application.Interfaces;

namespace Sumpooj.Application.Deliveries;

public class StartRouteHandler
{
    private readonly IDeliveryRouteRepository _routeRepo;

    public StartRouteHandler(IDeliveryRouteRepository routeRepo)
    {
        _routeRepo = routeRepo;
    }

    public async Task<bool> Handle(Guid routeId)
    {
        var route = await _routeRepo.GetByIdAsync(routeId);
        if (route == null)
            throw new InvalidOperationException("Route not found.");

        route.StartRoute();
        await _routeRepo.UpdateAsync(route);
        return true;
    }
}
