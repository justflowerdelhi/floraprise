using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Sumpooj.Application.Interfaces;

namespace Sumpooj.Infrastructure.ExternalServices;

public class LeadNotificationService : ILeadNotificationService
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IConfiguration _configuration;
    private readonly ILogger<LeadNotificationService> _logger;

    public LeadNotificationService(
        IHttpClientFactory httpClientFactory,
        IConfiguration configuration,
        ILogger<LeadNotificationService> logger)
    {
        _httpClientFactory = httpClientFactory;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task NotifyNewDemoRequestAsync(
        string fullName,
        string businessEmail,
        string? businessType,
        string? currentSoftware,
        string? notes,
        DateTime submittedAt)
    {
        // ── Email notification (placeholder — replace with SMTP / SendGrid / SES) ──
        _logger.LogInformation(
            """
            === NEW DEMO REQUEST — Email to sales@floraprise.com ===
            Full Name       : {FullName}
            Email           : {Email}
            Business Type   : {BusinessType}
            Current Software: {CurrentSoftware}
            Notes           : {Notes}
            Date Submitted  : {SubmittedAt:yyyy-MM-dd HH:mm} UTC
            =====================================================
            """,
            fullName, businessEmail, businessType,
            currentSoftware, notes, submittedAt);

        // ── Arattai (Zoho Cliq) notification ──
        await SendArattaiNotificationAsync(fullName, businessEmail, businessType, currentSoftware, notes, submittedAt);
    }

    private async Task SendArattaiNotificationAsync(
        string fullName,
        string businessEmail,
        string? businessType,
        string? currentSoftware,
        string? notes,
        DateTime submittedAt)
    {
        var webhookUrl = _configuration["Arattai:WebhookUrl"];

        if (string.IsNullOrEmpty(webhookUrl))
        {
            _logger.LogWarning("Arattai webhook URL is not configured. Skipping notification.");
            return;
        }

        var message = $"""
            🌸 *New Demo Request*
            ━━━━━━━━━━━━━━━━━━━━
            *Name:* {fullName}
            *Email:* {businessEmail}
            *Business Type:* {businessType ?? "—"}
            *Current Software:* {currentSoftware ?? "—"}
            *Notes:* {notes ?? "—"}
            *Submitted:* {submittedAt:yyyy-MM-dd HH:mm} UTC
            ━━━━━━━━━━━━━━━━━━━━
            """;

        var payload = new { text = message };
        var json = JsonSerializer.Serialize(payload);
        var content = new StringContent(json, Encoding.UTF8, "application/json");

        try
        {
            var client = _httpClientFactory.CreateClient();
            var response = await client.PostAsync(webhookUrl, content);

            if (response.IsSuccessStatusCode)
            {
                _logger.LogInformation(
                    "Arattai notification sent for demo request from {FullName} ({Email})",
                    fullName, businessEmail);
            }
            else
            {
                var body = await response.Content.ReadAsStringAsync();
                _logger.LogWarning(
                    "Arattai webhook returned {StatusCode}: {Body}",
                    (int)response.StatusCode, body);
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to send Arattai notification for {Email}", businessEmail);
        }
    }
}
