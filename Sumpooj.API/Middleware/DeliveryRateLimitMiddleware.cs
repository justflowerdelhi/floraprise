using System.Collections.Concurrent;

namespace Sumpooj.API.Middleware;

public class DeliveryRateLimitMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<DeliveryRateLimitMiddleware> _logger;
    private readonly ConcurrentDictionary<string, RateLimitCounter> _counters;
    private readonly int _maxRequestsPerMinute = 60; // 1 request per second
    private readonly int _maxRequestsPerHour = 1000;

    public DeliveryRateLimitMiddleware(
        RequestDelegate next,
        ILogger<DeliveryRateLimitMiddleware> logger)
    {
        _next = next;
        _logger = logger;
        _counters = new ConcurrentDictionary<string, RateLimitCounter>();
    }

    public async Task InvokeAsync(HttpContext context)
    {
        // Only apply to location upload endpoints
        if (!context.Request.Path.StartsWithSegments("/api/delivery/location"))
        {
            await _next(context);
            return;
        }

        var clientId = GetClientId(context);
        var counter = _counters.GetOrAdd(clientId, _ => new RateLimitCounter());

        // Check minute limit
        if (counter.MinuteCount >= _maxRequestsPerMinute)
        {
            _logger.LogWarning("Rate limit exceeded for client {ClientId} (minute limit)", clientId);
            context.Response.StatusCode = StatusCodes.Status429TooManyRequests;
            await context.Response.WriteAsync("Rate limit exceeded. Please try again later.");
            return;
        }

        // Check hour limit
        if (counter.HourCount >= _maxRequestsPerHour)
        {
            _logger.LogWarning("Rate limit exceeded for client {ClientId} (hour limit)", clientId);
            context.Response.StatusCode = StatusCodes.Status429TooManyRequests;
            await context.Response.WriteAsync("Rate limit exceeded. Please try again later.");
            return;
        }

        // Increment counters
        counter.Increment();

        await _next(context);
    }

    private string GetClientId(HttpContext context)
    {
        // Use user ID if authenticated, otherwise use IP
        var userId = context.User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (!string.IsNullOrEmpty(userId))
        {
            return $"user:{userId}";
        }

        var ip = context.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        return $"ip:{ip}";
    }

    private class RateLimitCounter
    {
        private int _minuteCount;
        private int _hourCount;
        private DateTime _minuteReset;
        private DateTime _hourReset;

        public RateLimitCounter()
        {
            _minuteReset = DateTime.UtcNow.AddMinutes(1);
            _hourReset = DateTime.UtcNow.AddHours(1);
        }

        public int MinuteCount => _minuteCount;
        public int HourCount => _hourCount;

        public void Increment()
        {
            // Reset counters if time has passed
            if (DateTime.UtcNow > _minuteReset)
            {
                _minuteCount = 0;
                _minuteReset = DateTime.UtcNow.AddMinutes(1);
            }

            if (DateTime.UtcNow > _hourReset)
            {
                _hourCount = 0;
                _hourReset = DateTime.UtcNow.AddHours(1);
            }

            _minuteCount++;
            _hourCount++;
        }
    }
}
