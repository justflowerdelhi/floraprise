namespace Sumpooj.Application.Companies;

public interface ICompanyService
{
    Task<Guid> CreateAsync(CreateCompanyRequest request);
    Task CreateDefaultLocationAsync(Guid companyId);
    Task<CompanyDto?> FindByEmailOrPhoneAsync(string email, string phone);
    Task<IReadOnlyList<CompanyDto>> GetAllAsync();
    Task<CompanyDto?> GetByIdAsync(Guid companyId);
    Task SetActiveAsync(Guid companyId, bool isActive);
    Task UpdateSettingsAsync(Guid companyId, UpdateCompanySettingsRequest request);
}

public class UpdateCompanySettingsRequest
{
    public string? Name { get; set; }
    public string? Phone { get; set; }
    public string? Email { get; set; }
    public string? Address { get; set; }
    public string? ShortDescription { get; set; }
    public string? TimeZone { get; set; }
    public string? CurrencyCode { get; set; }
    public string? TaxIdentifier { get; set; }
}
