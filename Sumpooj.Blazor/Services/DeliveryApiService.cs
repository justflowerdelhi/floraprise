using System.Net.Http.Json;

namespace Sumpooj.Blazor.Services;

public class DeliveryApiService
{
    private readonly HttpClient _http;

    public DeliveryApiService(IHttpClientFactory factory)
    {
        _http = factory.CreateClient("Api");
    }

    public async Task<List<LiveDeliveryDto>> GetLiveDeliveriesAsync()
    {
        var response = await _http.GetAsync("api/public/tracking/live");
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<List<LiveDeliveryDto>>() ?? new();
    }

    public async Task<DeliveryDetailDto?> GetDeliveryDetailAsync(string token)
    {
        var response = await _http.GetAsync($"api/public/tracking/driver/{token}");
        if (response.IsSuccessStatusCode)
        {
            return await response.Content.ReadFromJsonAsync<DeliveryDetailDto>();
        }
        return null;
    }
}

public class LiveDeliveryDto
{
    public Guid DeliveryId { get; set; }
    public string OrderNumber { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;
    public string? CustomerPhone { get; set; }
    public string FloristName { get; set; } = string.Empty;
    public string DriverName { get; set; } = string.Empty;
    public string? DriverPhone { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime? Eta { get; set; }
    public DateTime LastUpdate { get; set; }
    public string? TrackingToken { get; set; }
    public string? DeliveryAddress { get; set; }
    public double? DestLat { get; set; }
    public double? DestLng { get; set; }
    public double? DriverLat { get; set; }
    public double? DriverLng { get; set; }
    public DateTime? DriverUpdatedAt { get; set; }
}

public class DeliveryDetailDto
{
    public string OrderNumber { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;
    public string DeliveryAddress { get; set; } = string.Empty;
    public string? CustomerPhone { get; set; }
    public string TimeSlot { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public double? CurrentLatitude { get; set; }
    public double? CurrentLongitude { get; set; }
    public DateTime? LastGpsUpdate { get; set; }
    public string DriverLink { get; set; } = string.Empty;
    public string CustomerLink { get; set; } = string.Empty;
}
