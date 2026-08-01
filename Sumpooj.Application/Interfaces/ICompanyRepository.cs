using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface ICompanyRepository
{
    Task<Company?> GetByIdAsync(Guid id);
    Task<Company?> GetByCompanyIdAsync(Guid companyId);
    Task<IReadOnlyList<Company>> GetAllAsync();
    Task AddAsync(Company company);
    Task UpdateAsync(Company company);
}
