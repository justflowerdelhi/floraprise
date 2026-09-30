namespace Sumpooj.Application.Marketing;

public class DemoRequestDto
{
    public string FullName { get; set; } = default!;
    public string BusinessEmail { get; set; } = default!;
    public string? PhoneNumber { get; set; }
    public string? Phone { get; set; }
    public string? BusinessType { get; set; }
    public string? CurrentSoftware { get; set; }
    public string? Notes { get; set; }
    public DateTime? SubmittedAt { get; set; }

    public string? ResolvedPhone => !string.IsNullOrWhiteSpace(PhoneNumber) ? PhoneNumber : Phone;
}
