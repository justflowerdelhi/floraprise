using System.Net.Http.Json;

namespace Sumpooj.Blazor.Services;

public class DeviceApiService
{
    private readonly HttpClient _http;

    public DeviceApiService(IHttpClientFactory factory)
    {
        _http = factory.CreateClient("Api");
    }

    public async Task<List<DeviceDto>> GetDevicesAsync()
    {
        var response = await _http.GetAsync("api/platform/mobile-admin/devices");
        response.EnsureSuccessStatusCode();
        var result = await response.Content.ReadFromJsonAsync<MobileAdminDevicePagedResultDto>();
        return result?.Items ?? new();
    }

    public async Task<bool> DeactivateAsync(Guid deviceId, Guid companyId)
    {
        var response = await _http.PostAsJsonAsync($"api/platform/mobile-admin/devices/{deviceId}/disable", new { companyId });
        return response.IsSuccessStatusCode;
    }

    public async Task<bool> ForceLogoutAsync(Guid deviceId, Guid companyId)
    {
        var response = await _http.PostAsJsonAsync($"api/platform/mobile-admin/devices/{deviceId}/force-logout", new { companyId });
        return response.IsSuccessStatusCode;
    }

    public async Task<bool> ResetAsync(Guid deviceId, Guid companyId)
    {
        var response = await _http.PostAsJsonAsync($"api/platform/mobile-admin/devices/{deviceId}/reset", new { companyId });
        return response.IsSuccessStatusCode;
    }
}

public class DeviceDto
{
    public Guid MobileDeviceId { get; set; }
    public Guid CompanyId { get; set; }
    public Guid MobileUserId { get; set; }
    public string Platform { get; set; } = string.Empty;
    public string Model { get; set; } = string.Empty;
    public string OsVersion { get; set; } = string.Empty;
    public DateTime? LastSeenUtc { get; set; }
    public bool IsOnline { get; set; }
    // Additional properties for Devices page
    public string BusinessName { get; set; } = string.Empty;
    public string DeviceName { get; set; } = string.Empty;
    public string AppVersion { get; set; } = string.Empty;
    public DateTime? LastSeenAtUtc { get; set; }
    public string DeviceStatus { get; set; } = string.Empty;
}

public class DeviceDetailDto
{
    public Guid Id { get; set; }
    public string CompanyName { get; set; } = string.Empty;
    public string DeviceName { get; set; } = string.Empty;
    public string DeviceModel { get; set; } = string.Empty;
    public string AndroidVersion { get; set; } = string.Empty;
    public string AppVersion { get; set; } = string.Empty;
    public DateTime LastSync { get; set; }
    public string Status { get; set; } = string.Empty;
    public string? DeviceId { get; set; }
    public string? SerialNumber { get; set; }
    public List<SyncHistoryDto> SyncHistory { get; set; } = new();
}

public class SyncHistoryDto
{
    public DateTime SyncTime { get; set; }
    public bool Success { get; set; }
    public string? ErrorMessage { get; set; }
}

public class MobileAdminDevicePagedResultDto
{
    public List<DeviceDto> Items { get; set; } = new();
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
}
