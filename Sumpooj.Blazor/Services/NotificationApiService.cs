using System.Net.Http.Json;

namespace Sumpooj.Blazor.Services;

public class NotificationApiService
{
    private readonly HttpClient _http;

    public NotificationApiService(IHttpClientFactory factory)
    {
        _http = factory.CreateClient("Api");
    }

    public async Task<bool> SendNotificationAsync(NotificationRequest request)
    {
        var response = await _http.PostAsJsonAsync("api/v1/notifications/send", request);
        if (response.IsSuccessStatusCode) return true;

        var details = await response.Content.ReadAsStringAsync();
        throw new InvalidOperationException(
            string.IsNullOrWhiteSpace(details)
                ? $"Notification API returned {(int)response.StatusCode} {response.ReasonPhrase}."
                : $"Notification API returned {(int)response.StatusCode}: {details}");
    }
}

public class NotificationRequest
{
    public string Type { get; set; } = string.Empty;
    public string RecipientType { get; set; } = string.Empty;
    public List<Guid>? CompanyIds { get; set; }
    public List<Guid>? DeviceIds { get; set; }
    public Guid? DeviceId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
}
