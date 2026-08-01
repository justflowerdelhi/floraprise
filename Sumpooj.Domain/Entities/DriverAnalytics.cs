namespace Sumpooj.Domain.Entities;

public class DriverAnalytics : BaseEntity
{
    private DriverAnalytics() { }

    public DriverAnalytics(Guid driverId, DateTime date)
    {
        if (driverId == Guid.Empty)
            throw new ArgumentException("DriverId is required.", nameof(driverId));

        DriverId = driverId;
        Date = date;
    }

    public Guid DriverId { get; private set; }
    public DateTime Date { get; private set; }

    // Delivery counts
    public int TotalDeliveries { get; private set; }
    public int CompletedDeliveries { get; private set; }
    public int FailedDeliveries { get; private set; }
    public int DelayedDeliveries { get; private set; }

    // Time metrics (in minutes)
    public double AverageDeliveryTimeMinutes { get; private set; }
    public double TotalDeliveryTimeMinutes { get; private set; }
    public double AverageTimeToPickupMinutes { get; private set; }
    public double AverageTimeToDeliveryMinutes { get; private set; }

    // Distance metrics (in km)
    public double TotalDistanceKm { get; private set; }
    public double AverageDistancePerDeliveryKm { get; private set; }

    // GPS tracking metrics
    public int TotalLocationUpdates { get; private set; }
    public double AverageLocationAccuracyMeters { get; private set; }
    public int TrackingMinutes { get; private set; }

    // Battery metrics
    public double AverageBatteryLevel { get; private set; }
    public int LowBatteryAlerts { get; private set; }

    public void RecordDelivery(bool completed, bool delayed, double deliveryTimeMinutes, double distanceKm)
    {
        TotalDeliveries++;
        if (completed) CompletedDeliveries++;
        if (delayed) DelayedDeliveries++;
        if (!completed) FailedDeliveries++;

        TotalDeliveryTimeMinutes += deliveryTimeMinutes;
        AverageDeliveryTimeMinutes = TotalDeliveryTimeMinutes / TotalDeliveries;

        TotalDistanceKm += distanceKm;
        AverageDistancePerDeliveryKm = TotalDistanceKm / TotalDeliveries;

        MarkUpdated();
    }

    public void RecordLocationUpdate(double accuracy, int batteryLevel)
    {
        TotalLocationUpdates++;
        
        // Update average accuracy
        AverageLocationAccuracyMeters = 
            (AverageLocationAccuracyMeters * (TotalLocationUpdates - 1) + accuracy) / TotalLocationUpdates;

        // Update average battery
        AverageBatteryLevel = 
            (AverageBatteryLevel * (TotalLocationUpdates - 1) + batteryLevel) / TotalLocationUpdates;

        if (batteryLevel < 20)
            LowBatteryAlerts++;

        MarkUpdated();
    }

    public void AddTrackingMinutes(int minutes)
    {
        TrackingMinutes += minutes;
        MarkUpdated();
    }

    public void UpdateTimeMetrics(double timeToPickup, double timeToDelivery)
    {
        var count = CompletedDeliveries;
        if (count == 0) return;

        AverageTimeToPickupMinutes = 
            (AverageTimeToPickupMinutes * (count - 1) + timeToPickup) / count;
        AverageTimeToDeliveryMinutes = 
            (AverageTimeToDeliveryMinutes * (count - 1) + timeToDelivery) / count;

        MarkUpdated();
    }
}
