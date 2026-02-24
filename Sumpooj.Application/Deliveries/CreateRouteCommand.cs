namespace Sumpooj.Application.Deliveries;

public record CreateRouteCommand(
    DateTime RouteDate,
    List<Guid> DeliveryIds
);
