namespace Sumpooj.Domain.Entities;

public class TaxRule : BaseEntity
{
    private TaxRule() { }

    public TaxRule(
        Guid companyId,
        string countryCode,
        string name,
        decimal rate,
        bool isInclusive)
    {
        CompanyId = companyId;
        CountryCode = countryCode;
        Name = name;
        Rate = rate;
        IsInclusive = isInclusive;
        IsActive = true;
    }

    public Guid CompanyId { get; private set; }
    public string CountryCode { get; private set; } = default!;
    public string Name { get; private set; } = default!;
    public decimal Rate { get; private set; }
    public bool IsInclusive { get; private set; }
    public bool IsActive { get; private set; }

    public void Update(string countryCode, string name, decimal rate, bool isInclusive)
    {
        CountryCode = countryCode;
        Name = name;
        Rate = rate;
        IsInclusive = isInclusive;
        MarkUpdated();
    }

    public void Activate()
    {
        IsActive = true;
        MarkUpdated();
    }

    public void Deactivate()
    {
        IsActive = false;
        MarkUpdated();
    }
}
