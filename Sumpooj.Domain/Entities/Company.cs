namespace Sumpooj.Domain.Entities;

public class Company : BaseEntity
{
    private Company() { }

    public Company(
        string name,
        string region,
        string? email,
        string? phone,
        string? address,
        string? shortDescription,
        string? logoPath,
        string timeZone,
        string currencyCode,
        string? taxIdentifier)
    {
        Name = name;
        Region = region;
        Email = email;
        Phone = phone;
        Address = address;
        ShortDescription = shortDescription;

        LogoPath = logoPath;              // e.g. /uploads/logos/{companyId}.png
        TimeZone = timeZone;              // e.g. "Asia/Kolkata"
        CurrencyCode = currencyCode;      // e.g. "INR", "USD"
        TaxIdentifier = taxIdentifier;    // GST/VAT number

        IsActive = true;
    }

    // Identity
    public string Name { get; private set; }
    public bool IsActive { get; private set; }

    // Hosting / Compliance
    public string Region { get; private set; }

    // Contact
    public string? Email { get; private set; }
    public string? Phone { get; private set; }
    public string? Address { get; private set; }
    public string? ShortDescription { get; private set; }

    // Branding (PASSIVE)
    public string? LogoPath { get; private set; }

    // Localization (PASSIVE)
    public string TimeZone { get; private set; }
    public string CurrencyCode { get; private set; }

    // Tax (PASSIVE)
    public string? TaxIdentifier { get; private set; }

    // Controlled updates
    public void UpdateBranding(string? logoPath)
    {
        LogoPath = logoPath;
        MarkUpdated();
    }

    public void UpdateLocalization(string timeZone, string currencyCode)
    {
        TimeZone = timeZone;
        CurrencyCode = currencyCode;
        MarkUpdated();
    }

    public void UpdateTax(string? taxIdentifier)
    {
        TaxIdentifier = taxIdentifier;
        MarkUpdated();
    }

    public void Deactivate()
    {
        IsActive = false;
        MarkUpdated();
    }
    public void Activate()
    {
        IsActive = true;
        MarkUpdated();
    }
}
