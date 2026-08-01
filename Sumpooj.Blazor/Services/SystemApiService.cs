using System.Net.Http.Json;

namespace Sumpooj.Blazor.Services;

public class SystemApiService
{
    private readonly HttpClient _http;

    public SystemApiService(IHttpClientFactory factory)
    {
        _http = factory.CreateClient("Api");
    }

    public async Task<SystemStatusDto> GetSystemStatusAsync()
    {
        var response = await _http.GetAsync("api/v1/system/status");
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<SystemStatusDto>() ?? new();
    }

    public async Task<bool> ToggleMaintenanceModeAsync(bool enabled)
    {
        var response = await _http.PostAsJsonAsync("api/v1/system/maintenance", new { Enabled = enabled });
        return response.IsSuccessStatusCode;
    }

    public async Task<bool> ToggleKillSwitchAsync(bool enabled)
    {
        var response = await _http.PostAsJsonAsync("api/v1/system/killswitch", new { Enabled = enabled });
        return response.IsSuccessStatusCode;
    }
}

public class SystemStatusDto
{
    public string AppVersion { get; set; } = string.Empty;
    public string ApiStatus { get; set; } = string.Empty;
    public string DatabaseStatus { get; set; } = string.Empty;
    public string RazorpayStatus { get; set; } = string.Empty;
    public bool MaintenanceMode { get; set; }
    public bool KillSwitchActive { get; set; }
    public DateTime TimestampUtc { get; set; }
}
