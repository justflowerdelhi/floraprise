namespace Sumpooj.Application.Companies;

public class CompanyDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = default!;
    public string Region { get; set; } = default!;
    public bool IsActive { get; set; }
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public string? Address { get; set; }
    public string? ShortDescription { get; set; }
    public string TimeZone { get; set; } = "UTC";
    public string CurrencyCode { get; set; } = "USD";
    public string? TaxIdentifier { get; set; }
    public DateTime CreatedAt { get; set; }
}
