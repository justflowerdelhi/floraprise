using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Sumpooj.Application.Interfaces;

namespace Sumpooj.Infrastructure.Services;

public sealed class FcmNotificationService : IFcmNotificationService
{
    private readonly HttpClient _httpClient;
    private readonly IConfiguration _configuration;
    private readonly ILogger<FcmNotificationService> _logger;

    public FcmNotificationService(
        HttpClient httpClient,
        IConfiguration configuration,
        ILogger<FcmNotificationService> logger)
    {
        _httpClient = httpClient;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task<bool> SendDataNotificationAsync(
        string pushToken,
        IDictionary<string, string> data,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(pushToken)) return false;

        var serverKey = _configuration["Firebase:ServerKey"]
            ?? _configuration["Notifications:FcmServerKey"];

        if (string.IsNullOrWhiteSpace(serverKey))
        {
            _logger.LogDebug(
                "FCM: Simulating notification to token {TokenPreview}... Data: {DataSummary}",
                pushToken.Length > 10 ? pushToken[..10] : pushToken,
                data.TryGetValue("title", out var title) ? title : "Task Reminder");
            return true;
        }

        try
        {
            var payload = new
            {
                to = pushToken,
                priority = "high",
                content_available = true,
                data
            };

            var json = JsonSerializer.Serialize(payload);
            using var request = new HttpRequestMessage(HttpMethod.Post, "https://fcm.googleapis.com/fcm/send")
            {
                Content = new StringContent(json, Encoding.UTF8, "application/json")
            };
            request.Headers.TryAddWithoutValidation("Authorization", $"key={serverKey.Trim()}");

            var response = await _httpClient.SendAsync(request, cancellationToken);
            if (response.IsSuccessStatusCode)
            {
                _logger.LogInformation("FCM notification dispatched successfully to token {TokenPreview}...",
                    pushToken.Length > 10 ? pushToken[..10] : pushToken);
                return true;
            }

            var responseBody = await response.Content.ReadAsStringAsync(cancellationToken);
            _logger.LogWarning("FCM dispatch returned status {StatusCode}: {ResponseBody}",
                response.StatusCode, responseBody);
            return false;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "FCM dispatch exception to token {TokenPreview}...",
                pushToken.Length > 10 ? pushToken[..10] : pushToken);
            return false;
        }
    }

    public async Task<int> SendDataNotificationMulticastAsync(
        IEnumerable<string> pushTokens,
        IDictionary<string, string> data,
        CancellationToken cancellationToken = default)
    {
        var tokens = pushTokens.Where(t => !string.IsNullOrWhiteSpace(t)).Distinct().ToList();
        if (tokens.Count == 0) return 0;

        var serverKey = _configuration["Firebase:ServerKey"]
            ?? _configuration["Notifications:FcmServerKey"];

        if (string.IsNullOrWhiteSpace(serverKey))
        {
            _logger.LogDebug(
                "FCM: Simulating multicast notification to {Count} device(s)... Data: {DataSummary}",
                tokens.Count,
                data.TryGetValue("title", out var title) ? title : "Task Reminder");
            return tokens.Count;
        }

        int successCount = 0;

        // Batch into groups of 500 for FCM registration_ids limit
        foreach (var batch in tokens.Chunk(500))
        {
            try
            {
                var payload = new
                {
                    registration_ids = batch,
                    priority = "high",
                    content_available = true,
                    data
                };

                var json = JsonSerializer.Serialize(payload);
                using var request = new HttpRequestMessage(HttpMethod.Post, "https://fcm.googleapis.com/fcm/send")
                {
                    Content = new StringContent(json, Encoding.UTF8, "application/json")
                };
                request.Headers.TryAddWithoutValidation("Authorization", $"key={serverKey.Trim()}");

                var response = await _httpClient.SendAsync(request, cancellationToken);
                if (response.IsSuccessStatusCode)
                {
                    successCount += batch.Length;
                }
                else
                {
                    var responseBody = await response.Content.ReadAsStringAsync(cancellationToken);
                    _logger.LogWarning("FCM multicast batch returned status {StatusCode}: {ResponseBody}",
                        response.StatusCode, responseBody);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "FCM multicast batch exception for {Count} tokens", batch.Length);
            }
        }

        return successCount;
    }
}
