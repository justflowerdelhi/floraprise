using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Sumpooj.Application.Email;
using Sumpooj.Application.Interfaces;

namespace Sumpooj.Infrastructure.ExternalServices;

public class LeadNotificationService : ILeadNotificationService
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IConfiguration _configuration;
    private readonly ILogger<LeadNotificationService> _logger;
    private readonly IEmailService _emailService;

    public LeadNotificationService(
        IHttpClientFactory httpClientFactory,
        IConfiguration configuration,
        ILogger<LeadNotificationService> logger,
        IEmailService emailService)
    {
        _httpClientFactory = httpClientFactory;
        _configuration = configuration;
        _logger = logger;
        _emailService = emailService;
    }

    public async Task NotifyNewDemoRequestAsync(
        string fullName,
        string businessEmail,
        string? phoneNumber,
        string? businessType,
        string? currentSoftware,
        string? notes,
        DateTime submittedAt)
    {
        // ── Email notification ─────────────────────────────────────────
        // Email is best-effort and must not prevent other notifications.
        try
        {
            var htmlBody = $"""
                <html>
                <body style="font-family: Arial, sans-serif; color: #222;">
                    <h2 style="color:#124e2c;">New Floraprise Demo Request</h2>

                    <table cellpadding="8" cellspacing="0"
                           style="border-collapse:collapse; width:100%; max-width:700px;">
                        <tr>
                            <td style="font-weight:bold; border-bottom:1px solid #ddd;">
                                Full Name
                            </td>
                            <td style="border-bottom:1px solid #ddd;">
                                {System.Net.WebUtility.HtmlEncode(fullName)}
                            </td>
                        </tr>
                        <tr>
                            <td style="font-weight:bold; border-bottom:1px solid #ddd;">
                                Business Email
                            </td>
                            <td style="border-bottom:1px solid #ddd;">
                                {System.Net.WebUtility.HtmlEncode(businessEmail)}
                            </td>
                        </tr>
                        <tr>
                            <td style="font-weight:bold; border-bottom:1px solid #ddd;">
                                Phone / WhatsApp
                            </td>
                            <td style="border-bottom:1px solid #ddd;">
                                {System.Net.WebUtility.HtmlEncode(phoneNumber ?? "—")}
                            </td>
                        </tr>
                        <tr>
                            <td style="font-weight:bold; border-bottom:1px solid #ddd;">
                                Business Type
                            </td>
                            <td style="border-bottom:1px solid #ddd;">
                                {System.Net.WebUtility.HtmlEncode(businessType ?? "—")}
                            </td>
                        </tr>
                        <tr>
                            <td style="font-weight:bold; border-bottom:1px solid #ddd;">
                                Current Software
                            </td>
                            <td style="border-bottom:1px solid #ddd;">
                                {System.Net.WebUtility.HtmlEncode(currentSoftware ?? "—")}
                            </td>
                        </tr>
                        <tr>
                            <td style="font-weight:bold; border-bottom:1px solid #ddd;">
                                Additional Notes
                            </td>
                            <td style="border-bottom:1px solid #ddd;">
                                {System.Net.WebUtility.HtmlEncode(notes ?? "—")}
                            </td>
                        </tr>
                        <tr>
                            <td style="font-weight:bold;">
                                Submitted
                            </td>
                            <td>
                                {submittedAt:yyyy-MM-dd HH:mm} UTC
                            </td>
                        </tr>
                    </table>

                    <p style="margin-top:24px; color:#666;">
                        This notification was generated automatically from the
                        Floraprise website demo request form.
                    </p>
                </body>
                </html>
                """;

            await _emailService.SendAsync(
                "care@justflower.in",
                $"New Floraprise Demo Request — {fullName}",
                htmlBody);

            _logger.LogInformation(
                "Demo request email notification sent for {Email}",
                businessEmail);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(
                ex,
                "Failed to send demo request email notification for {Email}",
                businessEmail);
        }

        // ── Arattai (Zoho Cliq) notification ──────────────────────────
        await SendArattaiNotificationAsync(
            fullName,
            businessEmail,
            phoneNumber,
            businessType,
            currentSoftware,
            notes,
            submittedAt);
    }

    private async Task SendArattaiNotificationAsync(
        string fullName,
        string businessEmail,
        string? phoneNumber,
        string? businessType,
        string? currentSoftware,
        string? notes,
        DateTime submittedAt)
    {
        var webhookUrl = _configuration["Arattai:WebhookUrl"];

        if (string.IsNullOrEmpty(webhookUrl))
        {
            _logger.LogWarning(
                "Arattai webhook URL is not configured. Skipping notification.");
            return;
        }

        var message = $"""
            🌸 *New Demo Request*
            ─────────────────────
            *Name:* {fullName}
            *Email:* {businessEmail}
            *Phone / WhatsApp:* {phoneNumber ?? "—"}
            *Business Type:* {businessType ?? "—"}
            *Current Software:* {currentSoftware ?? "—"}
            *Notes:* {notes ?? "—"}
            *Submitted:* {submittedAt:yyyy-MM-dd HH:mm} UTC
            ─────────────────────
            """;

        var payload = new { text = message };
        var json = JsonSerializer.Serialize(payload);
        var content = new StringContent(
            json,
            Encoding.UTF8,
            "application/json");

        try
        {
            var client = _httpClientFactory.CreateClient();
            var response = await client.PostAsync(webhookUrl, content);

            if (response.IsSuccessStatusCode)
            {
                _logger.LogInformation(
                    "Arattai notification sent for demo request from {FullName} ({Email})",
                    fullName,
                    businessEmail);
            }
            else
            {
                var body = await response.Content.ReadAsStringAsync();

                _logger.LogWarning(
                    "Arattai webhook returned {StatusCode}: {Body}",
                    (int)response.StatusCode,
                    body);
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(
                ex,
                "Failed to send Arattai notification for {Email}",
                businessEmail);
        }
    }
}