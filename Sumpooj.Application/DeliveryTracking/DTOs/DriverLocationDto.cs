namespace Sumpooj.Application.DeliveryTracking.DTOs;

public class DriverLocationDto
{
    public Guid Id { get; set; }
    public Guid DriverId { get; set; }
    public Guid DeliveryId { get; set; }
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public double? Accuracy { get; set; }
    public double? Speed { get; set; }
    public double? Heading { get; set; }
    public double? Altitude { get; set; }
    public int? BatteryLevel { get; set; }
    public DateTime RecordedAt { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class UploadLocationRequest
{
    public Guid DeliveryId { get; set; }
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public double? Accuracy { get; set; }
    public double? Speed { get; set; }
    public double? Heading { get; set; }
    public double? Altitude { get; set; }
    public int? BatteryLevel { get; set; }
    public DateTime? RecordedAt { get; set; }
}

public class StartDeliveryRequest
{
    public Guid DeliveryId { get; set; }
}

public class CompleteDeliveryRequest
{
    public Guid DeliveryId { get; set; }
    public string? PhotoUrl { get; set; }
    public string? SignatureData { get; set; }
    public string? Notes { get; set; }
    public string? OtpCode { get; set; }
    public double? CompletionLatitude { get; set; }
    public double? CompletionLongitude { get; set; }
}

public class DeliveryLiveTrackingResponse
{
    public Guid DeliveryId { get; set; }
    public string OrderNumber { get; set; }
    public string Status { get; set; }
    public DriverLocationDto? CurrentLocation { get; set; }
    public string? DriverName { get; set; }
    public string? DriverPhone { get; set; }
    public DateTime? EstimatedArrival { get; set; }
    public double? RemainingDistanceKm { get; set; }
    public DateTime LastUpdated { get; set; }
}
