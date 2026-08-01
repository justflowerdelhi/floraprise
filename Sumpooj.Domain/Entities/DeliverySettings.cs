namespace Sumpooj.Domain.Entities;

public class DeliverySettings : BaseEntity
{
    private DeliverySettings() { }

    public DeliverySettings(Guid companyId)
    {
        if (companyId == Guid.Empty)
            throw new ArgumentException("CompanyId is required.", nameof(companyId));

        CompanyId = companyId;
    }

    public Guid CompanyId { get; private set; }

    // GPS Tracking Settings
    public int LocationUploadIntervalSeconds { get; private set; } = 15;
    public double MinDistanceMetersForUpload { get; private set; } = 25.0;
    public int LocationRetentionDays { get; private set; } = 30;

    // Geofence Settings
    public double ArrivedNearbyRadiusMeters { get; private set; } = 200.0;
    public double ImOutsideRadiusMeters { get; private set; } = 150.0;

    // Delay Settings
    public int DelayThresholdMinutes { get; private set; } = 15;
    public bool AutoNotifyDelay { get; private set; } = true;

    // Proof Requirements
    public bool RequirePhotoProof { get; private set; } = true;
    public bool RequireSignature { get; private set; } = false;
    public bool RequireOTP { get; private set; } = false;
    public int OTPLength { get; private set; } = 4;

    // Battery Optimization
    public bool EnableBatteryOptimization { get; private set; } = true;
    public int LowBatteryThresholdPercent { get; private set; } = 20;

    // Notification Settings
    public bool NotifyCustomerOnAccept { get; private set; } = true;
    public bool NotifyCustomerOnPickup { get; private set; } = true;
    public bool NotifyCustomerOnEnRoute { get; private set; } = true;
    public bool NotifyCustomerOnArrived { get; private set; } = true;
    public bool NotifyCustomerOnDelivered { get; private set; } = true;
    public bool NotifyFloristOnStatusChange { get; private set; } = true;

    // Privacy Settings
    public bool ShowDriverPhoneToCustomer { get; private set; } = false;
    public bool ShowDriverPhotoToCustomer { get; private set; } = true;
    public bool AllowCustomerTracking { get; private set; } = true;

    public void UpdateTrackingSettings(int intervalSeconds, double minDistance, int retentionDays)
    {
        LocationUploadIntervalSeconds = intervalSeconds;
        MinDistanceMetersForUpload = minDistance;
        LocationRetentionDays = retentionDays;
        MarkUpdated();
    }

    public void UpdateGeofenceSettings(double arrivedRadius, double outsideRadius)
    {
        ArrivedNearbyRadiusMeters = arrivedRadius;
        ImOutsideRadiusMeters = outsideRadius;
        MarkUpdated();
    }

    public void UpdateDelaySettings(int thresholdMinutes, bool autoNotify)
    {
        DelayThresholdMinutes = thresholdMinutes;
        AutoNotifyDelay = autoNotify;
        MarkUpdated();
    }

    public void UpdateProofRequirements(bool requirePhoto, bool requireSignature, bool requireOTP, int otpLength)
    {
        RequirePhotoProof = requirePhoto;
        RequireSignature = requireSignature;
        RequireOTP = requireOTP;
        OTPLength = otpLength;
        MarkUpdated();
    }

    public void UpdateBatterySettings(bool enableOptimization, int lowBatteryThreshold)
    {
        EnableBatteryOptimization = enableOptimization;
        LowBatteryThresholdPercent = lowBatteryThreshold;
        MarkUpdated();
    }

    public void UpdateNotificationSettings(
        bool notifyOnAccept, bool notifyOnPickup, bool notifyOnEnRoute,
        bool notifyOnArrived, bool notifyOnDelivered, bool notifyFlorist)
    {
        NotifyCustomerOnAccept = notifyOnAccept;
        NotifyCustomerOnPickup = notifyOnPickup;
        NotifyCustomerOnEnRoute = notifyOnEnRoute;
        NotifyCustomerOnArrived = notifyOnArrived;
        NotifyCustomerOnDelivered = notifyOnDelivered;
        NotifyFloristOnStatusChange = notifyFlorist;
        MarkUpdated();
    }

    public void UpdatePrivacySettings(bool showPhone, bool showPhoto, bool allowTracking)
    {
        ShowDriverPhoneToCustomer = showPhone;
        ShowDriverPhotoToCustomer = showPhoto;
        AllowCustomerTracking = allowTracking;
        MarkUpdated();
    }
}
