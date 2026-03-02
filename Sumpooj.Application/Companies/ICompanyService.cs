namespace Sumpooj.Application.Companies;

public interface ICompanyService
{
    Task<Guid> CreateAsync(CreateCompanyRequest request);
    Task<IReadOnlyList<CompanyDto>> GetAllAsync();
    Task<CompanyDto?> GetByIdAsync(Guid companyId);
    Task SetActiveAsync(Guid companyId, bool isActive);
    Task UpdateSettingsAsync(Guid companyId, UpdateCompanySettingsRequest request);
}

public class UpdateCompanySettingsRequest
{
    public string? TimeZone { get; set; }
    public string? CurrencyCode { get; set; }
    public string? TaxIdentifier { get; set; }
}
