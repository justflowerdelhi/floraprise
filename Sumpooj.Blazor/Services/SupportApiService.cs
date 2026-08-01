using System.Net.Http.Json;

namespace Sumpooj.Blazor.Services;

public class SupportApiService
{
    private readonly HttpClient _http;

    public SupportApiService(IHttpClientFactory factory)
    {
        _http = factory.CreateClient("Api");
    }

    public async Task<MobileAdminSupportActivityPagedResultDto> GetSupportActivityPageAsync(int page = 1, int pageSize = 20)
    {
        var response = await _http.GetAsync($"api/platform/mobile-admin/support-activity?page={page}&pageSize={pageSize}");
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<MobileAdminSupportActivityPagedResultDto>() ?? new();
    }

    public async Task<List<SupportActivityDto>> GetSupportActivityAsync()
    {
        var result = await GetSupportActivityPageAsync(1, 50);
        return result.Items ?? new();
    }
}

public class SupportActivityDto
{
    public DateTime DateTimeUtc { get; set; }
    public string SupportUser { get; set; } = string.Empty;
    public string Customer { get; set; } = string.Empty;
    public string Action { get; set; } = string.Empty;
    public string? PreviousValue { get; set; }
    public string? NewValue { get; set; }
    public string? Notes { get; set; }
}

public class MobileAdminSupportActivityPagedResultDto
{
    public List<SupportActivityDto> Items { get; set; } = new();
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
}
