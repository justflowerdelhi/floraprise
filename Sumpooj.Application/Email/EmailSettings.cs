namespace Sumpooj.Application.Email;

public class EmailSettings
{
    public string SmtpHost { get; set; } = "smtp.gmail.com";
    public int SmtpPort { get; set; } = 587;
    public bool UseSsl { get; set; } = true;
    public string SenderName { get; set; } = "Floraprise";
    public string SenderEmail { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}
