using Sumpooj.Domain.Entities;
using Sumpooj.Application.Interfaces;
using System;
using System.Linq;
using System.Threading.Tasks;
using System.Collections.Generic;

namespace Sumpooj.Application.Deliveries;

public class CreateRouteHandler
{
    private readonly IDeliveryRepository _deliveryRepo;
    private readonly IDeliveryRouteRepository _routeRepo;

    public CreateRouteHandler(IDeliveryRepository deliveryRepo, IDeliveryRouteRepository routeRepo)
    {
        _deliveryRepo = deliveryRepo;
        _routeRepo = routeRepo;
    }

    public async Task<Guid> Handle(CreateRouteCommand command)
    {
        // Fetch deliveries by IDs
        var deliveries = await _deliveryRepo.GetByIdsAsync(command.DeliveryIds);

        // Validate: Status == Scheduled, DeliveryRouteId == null
        var valid = deliveries.Where(d => d.Status == DeliveryStatus.Scheduled && d.DeliveryRouteId == null).ToList();
        if (valid.Count != command.DeliveryIds.Count)
            throw new InvalidOperationException("All deliveries must be Scheduled and unassigned.");

        // Sort by PostalCode, then TimeSlot
        var sorted = valid.OrderBy(d => d.PostalCode).ThenBy(d => d.TimeSlot).ToList();

        // Create DeliveryRoute (Status = Draft)
        var route = new DeliveryRoute(Guid.Empty, command.RouteDate, "Route"); // Driver assignment is route-first
        await _routeRepo.AddAsync(route);

        // Assign StopOrder
        int stopOrder = 1;
        foreach (var delivery in sorted)
        {
            delivery.AssignToRoute(route.Id, stopOrder++);
            await _deliveryRepo.UpdateAsync(delivery);
        }

        // Return routeId
        return route.Id;
    }
}
