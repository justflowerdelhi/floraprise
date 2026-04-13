using Sumpooj.Domain.Entities;
using Sumpooj.Application.Interfaces;
using System;
using System.Threading.Tasks;

namespace Sumpooj.Application.Deliveries;

public class AssignDriverToRouteHandler
{
    private readonly IDeliveryRouteRepository _routeRepo;
    private readonly IStaffRepository _staffRepo;

    public AssignDriverToRouteHandler(IDeliveryRouteRepository routeRepo, IStaffRepository staffRepo)
    {
        _routeRepo = routeRepo;
        _staffRepo = staffRepo;
    }

    public async Task<bool> Handle(AssignDriverToRouteCommand command)
    {
        // 1. Load DeliveryRoute by RouteId
        var route = await _routeRepo.GetByIdAsync(command.RouteId);
        if (route == null)
            throw new InvalidOperationException("Route not found.");

        // 2. Load Staff (driver) by DriverId
        var driver = await _staffRepo.GetByIdAsync(command.DriverId);
        if (driver == null)
            throw new InvalidOperationException("Driver not found.");

        // 3. Validate
        if (route.Status != DeliveryRouteStatus.Draft)
            throw new InvalidOperationException("Route must be in Draft status.");
        if (route.DeliveryPersonId != Guid.Empty)
            throw new InvalidOperationException("Route already has a driver assigned.");
        // Note: DriverStatus is NOT validated here — a driver may appear Engaged from a
        // previous route that was cancelled or not properly completed. The route-level
        // DeliveryPersonId guard above is the authoritative duplication check.

        // 4. Assign driver to route
        route.AssignDriver(command.DriverId);
        // 5. Set driver as Engaged
        driver.SetEngaged();

        // 6. Save both entities
        await _routeRepo.UpdateAsync(route);
        await _staffRepo.UpdateAsync(driver);

        // 7. Return success
        return true;
    }
}
