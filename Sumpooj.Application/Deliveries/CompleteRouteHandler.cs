using Sumpooj.Domain.Entities;
using Sumpooj.Application.Interfaces;
using System;
using System.Threading.Tasks;

namespace Sumpooj.Application.Deliveries;

public class CompleteRouteHandler
{
    private readonly IDeliveryRouteRepository _routeRepo;
    private readonly IStaffRepository _staffRepo;

    public CompleteRouteHandler(IDeliveryRouteRepository routeRepo, IStaffRepository staffRepo)
    {
        _routeRepo = routeRepo;
        _staffRepo = staffRepo;
    }

    public async Task<bool> Handle(Guid routeId)
    {
        // 1. Load route
        var route = await _routeRepo.GetByIdAsync(routeId);
        if (route == null)
            throw new InvalidOperationException("Route not found.");

        // 2. Validate route.Status == InProgress
        if (route.Status != DeliveryRouteStatus.InProgress)
            throw new InvalidOperationException("Route must be InProgress to complete.");

        // 3. Load driver using route.DeliveryPersonId
        if (route.DeliveryPersonId == Guid.Empty)
            throw new InvalidOperationException("Route has no assigned driver.");
        var driver = await _staffRepo.GetByIdAsync(route.DeliveryPersonId);
        if (driver == null)
            throw new InvalidOperationException("Driver not found.");

        // 4. Complete route
        route.CompleteRoute();
        // 5. Set driver as Available
        driver.SetAvailable();

        // 6. Save both
        await _routeRepo.UpdateAsync(route);
        await _staffRepo.UpdateAsync(driver);

        return true;
    }
}
