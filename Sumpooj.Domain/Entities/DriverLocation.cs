namespace Sumpooj.Domain.Entities;

public class DriverLocation : BaseEntity
{
    private DriverLocation() { }

    public DriverLocation(
        Guid driverId,
        Guid deliveryId,
        double latitude,
        double longitude,
        double? accuracy = null,
        double? speed = null,
        double? heading = null,
        double? altitude = null,
        int? batteryLevel = null)
    {
        if (driverId == Guid.Empty)
            throw new ArgumentException("DriverId is required.", nameof(driverId));
        if (deliveryId == Guid.Empty)
            throw new ArgumentException("DeliveryId is required.", nameof(deliveryId));
        if (latitude < -90 || latitude > 90)
            throw new ArgumentException("Latitude must be between -90 and 90.", nameof(latitude));
        if (longitude < -180 || longitude > 180)
            throw new ArgumentException("Longitude must be between -180 and 180.", nameof(longitude));

        DriverId = driverId;
        DeliveryId = deliveryId;
        Latitude = latitude;
        Longitude = longitude;
        Accuracy = accuracy;
        Speed = speed;
        Heading = heading;
        Altitude = altitude;
        BatteryLevel = batteryLevel;
        RecordedAt = DateTime.UtcNow;
    }

    public Guid DriverId { get; private set; }
    public Guid DeliveryId { get; private set; }
    public double Latitude { get; private set; }
    public double Longitude { get; private set; }
    public double? Accuracy { get; private set; } // in meters
    public double? Speed { get; private set; } // in m/s
    public double? Heading { get; private set; } // in degrees (0-360)
    public double? Altitude { get; private set; } // in meters
    public int? BatteryLevel { get; private set; } // percentage (0-100)
    public DateTime RecordedAt { get; private set; }

    // Navigation properties
    public Delivery? Delivery { get; private set; }
}
