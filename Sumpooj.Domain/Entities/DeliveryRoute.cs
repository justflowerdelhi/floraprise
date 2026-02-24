namespace Sumpooj.Domain.Entities;

public class DeliveryRoute : BaseEntity
{
    private DeliveryRoute() { }

    public DeliveryRoute(Guid deliveryPersonId, DateTime routeDate, string name)
    {
        DeliveryPersonId = deliveryPersonId;
        RouteDate = routeDate;
        Name = name;
        Status = DeliveryRouteStatus.Draft;
    }

    public Guid DeliveryPersonId { get; private set; }
    public DateTime RouteDate { get; private set; }
    public string Name { get; private set; } = string.Empty;
    public DeliveryRouteStatus Status { get; private set; }

    public void AssignDriver(Guid driverId)
    {
        if (Status != DeliveryRouteStatus.Draft)
            throw new InvalidOperationException("Only Draft routes can be assigned a driver.");
        if (DeliveryPersonId != Guid.Empty)
            throw new InvalidOperationException("Driver already assigned.");
        DeliveryPersonId = driverId;
        Status = DeliveryRouteStatus.Assigned;
        MarkUpdated();
    }

    public void StartRoute()
    {
        if (Status != DeliveryRouteStatus.Assigned)
            throw new InvalidOperationException("Only Assigned routes can be started.");
        if (DeliveryPersonId == Guid.Empty)
            throw new InvalidOperationException("Route must have a driver assigned.");
        Status = DeliveryRouteStatus.InProgress;
        MarkUpdated();
    }

    public void CompleteRoute()
    {
        if (Status != DeliveryRouteStatus.InProgress)
            throw new InvalidOperationException("Only InProgress routes can be completed.");
        Status = DeliveryRouteStatus.Completed;
        MarkUpdated();
    }

    public void CancelRoute()
    {
        if (Status == DeliveryRouteStatus.Completed)
            throw new InvalidOperationException("Cannot cancel a completed route.");
        Status = DeliveryRouteStatus.Cancelled;
        MarkUpdated();
    }
}

public enum DeliveryRouteStatus
{
    Draft,
    Assigned,
    InProgress,
    Completed,
    Cancelled
}
