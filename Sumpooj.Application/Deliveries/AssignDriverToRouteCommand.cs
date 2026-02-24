namespace Sumpooj.Application.Deliveries;

public record AssignDriverToRouteCommand(
    Guid RouteId,
    Guid DriverId
);
