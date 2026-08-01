using Sumpooj.Application.Interfaces;

namespace Sumpooj.Application.DeliveryTracking;

/// <summary>
/// Smart ETA Calculator
/// Calculates estimated time of arrival based on distance, average speed, and traffic conditions
/// </summary>
public class SmartETACalculator
{
    private const double DefaultAverageSpeedKph = 30.0; // Default average speed in city (km/h)
    private const double HighwayAverageSpeedKph = 60.0; // Highway average speed (km/h)
    private const double TrafficFactorLow = 1.0; // No traffic
    private const double TrafficFactorMedium = 1.3; // Moderate traffic
    private const double TrafficFactorHigh = 1.8; // Heavy traffic

    /// <summary>
    /// Calculate ETA based on distance and current conditions
    /// </summary>
    public static DateTime CalculateETA(
        double distanceKm,
        double? currentSpeedKph = null,
        string? trafficCondition = null,
        DateTime? startTime = null)
    {
        var baseTime = startTime ?? DateTime.UtcNow;
        
        // Use current speed if available, otherwise use default
        var averageSpeed = currentSpeedKph ?? DefaultAverageSpeedKph;
        
        // Apply traffic factor
        var trafficFactor = GetTrafficFactor(trafficCondition);
        var effectiveSpeed = averageSpeed / trafficFactor;
        
        // Calculate travel time in minutes
        var travelTimeMinutes = (distanceKm / effectiveSpeed) * 60;
        
        // Add buffer time (10%)
        var bufferMinutes = travelTimeMinutes * 0.1;
        
        var totalMinutes = travelTimeMinutes + bufferMinutes;
        
        return baseTime.AddMinutes(totalMinutes);
    }

    /// <summary>
    /// Calculate ETA between two GPS coordinates
    /// </summary>
    public static DateTime CalculateETABetweenCoordinates(
        double fromLat, double fromLon,
        double toLat, double toLon,
        double? currentSpeedKph = null,
        string? trafficCondition = null,
        DateTime? startTime = null)
    {
        var distanceKm = CalculateDistance(fromLat, fromLon, toLat, toLon);
        return CalculateETA(distanceKm, currentSpeedKph, trafficCondition, startTime);
    }

    /// <summary>
    /// Calculate distance between two coordinates using Haversine formula
    /// </summary>
    public static double CalculateDistance(double lat1, double lon1, double lat2, double lon2)
    {
        const double R = 6371; // Earth's radius in km
        
        var dLat = ToRadians(lat2 - lat1);
        var dLon = ToRadians(lon2 - lon1);
        
        var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                Math.Cos(ToRadians(lat1)) * Math.Cos(ToRadians(lat2)) *
                Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
        
        var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
        
        return R * c;
    }

    private static double ToRadians(double angle)
    {
        return angle * Math.PI / 180.0;
    }

    private static double GetTrafficFactor(string? trafficCondition)
    {
        return trafficCondition?.ToLower() switch
        {
            "low" or "none" => TrafficFactorLow,
            "medium" or "moderate" => TrafficFactorMedium,
            "high" or "heavy" => TrafficFactorHigh,
            _ => TrafficFactorLow // Default to no traffic
        };
    }

    /// <summary>
    /// Predict arrival time for a route with multiple stops
    /// </summary>
    public static List<RouteStopETA> CalculateRouteETA(
        List<RouteStop> stops,
        double? currentSpeedKph = null,
        string? trafficCondition = null,
        DateTime? startTime = null)
    {
        var results = new List<RouteStopETA>();
        var currentTime = startTime ?? DateTime.UtcNow;
        
        for (int i = 0; i < stops.Count; i++)
        {
            var stop = stops[i];
            DateTime eta;
            
            if (i == 0)
            {
                // First stop - calculate from current location
                eta = CalculateETABetweenCoordinates(
                    stop.CurrentLat, stop.CurrentLon,
                    stop.Latitude, stop.Longitude,
                    currentSpeedKph, trafficCondition, currentTime);
            }
            else
            {
                // Subsequent stops - calculate from previous stop
                var prevStop = stops[i - 1];
                eta = CalculateETABetweenCoordinates(
                    prevStop.Latitude, prevStop.Longitude,
                    stop.Latitude, stop.Longitude,
                    currentSpeedKph, trafficCondition, currentTime);
            }
            
            results.Add(new RouteStopETA
            {
                StopId = stop.StopId,
                StopOrder = stop.StopOrder,
                Address = stop.Address,
                ETA = eta,
                DistanceFromPrevious = i == 0 ? stop.DistanceFromCurrent : CalculateDistance(
                    stops[i - 1].Latitude, stops[i - 1].Longitude,
                    stop.Latitude, stop.Longitude)
            });
            
            currentTime = eta.AddMinutes(5); // Add 5 minutes for delivery time
        }
        
        return results;
    }
}

public class RouteStop
{
    public string StopId { get; set; } = string.Empty;
    public int StopOrder { get; set; }
    public string Address { get; set; } = string.Empty;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public double CurrentLat { get; set; }
    public double CurrentLon { get; set; }
    public double DistanceFromCurrent { get; set; }
}

public class RouteStopETA
{
    public string StopId { get; set; } = string.Empty;
    public int StopOrder { get; set; }
    public string Address { get; set; } = string.Empty;
    public DateTime ETA { get; set; }
    public double DistanceFromPrevious { get; set; }
}
