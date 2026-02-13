namespace Sumpooj.Application.Companies;

public interface ICompanyService
{
    Task<Guid> CreateAsync(CreateCompanyRequest request);
    Task<IReadOnlyList<CompanyDto>> GetAllAsync();
    Task SetActiveAsync(Guid companyId, bool isActive);
}
