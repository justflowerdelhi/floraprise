namespace Sumpooj.Application.Email;

public interface IEmailService
{
    Task SendAsync(string toEmail, string subject, string htmlBody);
    Task SendAsync(string toEmail, string toName, string subject, string htmlBody);
}
