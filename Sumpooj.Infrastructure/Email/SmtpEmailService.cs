using System.Net;
using System.Net.Mail;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Sumpooj.Application.Email;

namespace Sumpooj.Infrastructure.Email;

public class SmtpEmailService : IEmailService
{
    private readonly EmailSettings _settings;
    private readonly ILogger<SmtpEmailService> _logger;

    public SmtpEmailService(IOptions<EmailSettings> settings, ILogger<SmtpEmailService> logger)
    {
        _settings = settings.Value;
        _logger = logger;
    }

    public Task SendAsync(string toEmail, string subject, string htmlBody)
        => SendAsync(toEmail, "", subject, htmlBody);

    public async Task SendAsync(string toEmail, string toName, string subject, string htmlBody)
    {
        if (string.IsNullOrWhiteSpace(_settings.Username) || string.IsNullOrWhiteSpace(_settings.Password))
        {
            _logger.LogWarning("Email not configured — skipping send to {To}: {Subject}", toEmail, subject);
            return;
        }

        try
        {
            using var client = new SmtpClient(_settings.SmtpHost, _settings.SmtpPort)
            {
                Credentials = new NetworkCredential(_settings.Username, _settings.Password),
                EnableSsl = _settings.UseSsl,
            };

            var from = new MailAddress(_settings.SenderEmail, _settings.SenderName);
            var to = string.IsNullOrWhiteSpace(toName)
                ? new MailAddress(toEmail)
                : new MailAddress(toEmail, toName);

            using var message = new MailMessage(from, to)
            {
                Subject = subject,
                Body = htmlBody,
                IsBodyHtml = true,
            };

            await client.SendMailAsync(message);
            _logger.LogInformation("Email sent to {To}: {Subject}", toEmail, subject);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send email to {To}: {Subject}", toEmail, subject);
            throw;
        }
    }
}
