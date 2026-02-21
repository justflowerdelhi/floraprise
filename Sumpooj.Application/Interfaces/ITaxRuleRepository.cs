using Sumpooj.Application.TaxRules;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface ITaxRuleRepository
{
    Task<TaxRule?> GetByIdAsync(Guid companyId, Guid id);
    Task<List<TaxRuleDto>> GetByCountryAsync(Guid companyId, string countryCode, bool activeOnly = true);
    Task<List<TaxRuleDto>> GetAllAsync(Guid companyId, bool activeOnly = true);
    Task AddAsync(TaxRule taxRule);
    Task UpdateAsync(TaxRule taxRule);
}
