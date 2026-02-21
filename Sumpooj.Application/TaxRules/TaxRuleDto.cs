namespace Sumpooj.Application.TaxRules;

public class TaxRuleDto
{
    public Guid Id { get; set; }
    public string CountryCode { get; set; } = default!;
    public string Name { get; set; } = default!;
    public decimal Rate { get; set; }
    public bool IsInclusive { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAtUtc { get; set; }
    public DateTime? UpdatedAtUtc { get; set; }
}

public class CreateTaxRuleRequest
{
    public string CountryCode { get; set; } = default!;
    public string Name { get; set; } = default!;
    public decimal Rate { get; set; }
    public bool IsInclusive { get; set; }
}

public class UpdateTaxRuleRequest
{
    public string CountryCode { get; set; } = default!;
    public string Name { get; set; } = default!;
    public decimal Rate { get; set; }
    public bool IsInclusive { get; set; }
}
