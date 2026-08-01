namespace Sumpooj.Domain.Entities;

public class DeliveryLocation : BaseEntity
{
    private DeliveryLocation() { }

    public DeliveryLocation(
        Guid deliveryId,
        double latitude,
        double longitude,
        double speedKph)
    {
        if (deliveryId == Guid.Empty)
            throw new ArgumentException("DeliveryId is required.", nameof(deliveryId));
        if (latitude < -90 || latitude > 90)
            throw new ArgumentException("Invalid latitude.", nameof(latitude));
        if (longitude < -180 || longitude > 180)
            throw new ArgumentException("Invalid longitude.", nameof(longitude));

        DeliveryId = deliveryId;
        Latitude = latitude;
        Longitude = longitude;
        SpeedKph = speedKph;
        RecordedAt = DateTime.UtcNow;
    }

    public Guid DeliveryId { get; private set; }
    public double Latitude { get; private set; }
    public double Longitude { get; private set; }
    public double SpeedKph { get; private set; }
    public DateTime RecordedAt { get; private set; }

    // Optional: Link to route for driver tracking
    public Guid? DeliveryRouteId { get; private set; }
    public Guid? DriverId { get; private set; }

    public void SetRouteContext(Guid? routeId, Guid? driverId)
    {
        DeliveryRouteId = routeId;
        DriverId = driverId;
        MarkUpdated();
    }
}
