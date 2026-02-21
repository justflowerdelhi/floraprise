using Sumpooj.Application.Interfaces;
using Sumpooj.Application.TaxRules;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.UseCases;

public class TaxRuleService
{
    private readonly ITaxRuleRepository _repository;

    public TaxRuleService(ITaxRuleRepository repository)
    {
        _repository = repository;
    }

    public async Task<List<TaxRuleDto>> GetByCountryAsync(Guid companyId, string countryCode, bool activeOnly = true)
    {
        return await _repository.GetByCountryAsync(companyId, countryCode, activeOnly);
    }

    public async Task<List<TaxRuleDto>> GetAllAsync(Guid companyId, bool activeOnly = true)
    {
        return await _repository.GetAllAsync(companyId, activeOnly);
    }

    public async Task<TaxRuleDto?> GetByIdAsync(Guid companyId, Guid id)
    {
        var rule = await _repository.GetByIdAsync(companyId, id);
        return rule == null ? null : MapToDto(rule);
    }

    public async Task<TaxRuleDto> CreateAsync(Guid companyId, CreateTaxRuleRequest request)
    {
        var rule = new TaxRule(
            companyId,
            request.CountryCode.ToUpperInvariant(),
            request.Name,
            request.Rate,
            request.IsInclusive);

        await _repository.AddAsync(rule);
        return MapToDto(rule);
    }

    public async Task<TaxRuleDto?> UpdateAsync(Guid companyId, Guid id, UpdateTaxRuleRequest request)
    {
        var rule = await _repository.GetByIdAsync(companyId, id);
        if (rule == null) return null;

        rule.Update(
            request.CountryCode.ToUpperInvariant(),
            request.Name,
            request.Rate,
            request.IsInclusive);

        await _repository.UpdateAsync(rule);
        return MapToDto(rule);
    }

    public async Task<bool> DeactivateAsync(Guid companyId, Guid id)
    {
        var rule = await _repository.GetByIdAsync(companyId, id);
        if (rule == null) return false;

        rule.Deactivate();
        await _repository.UpdateAsync(rule);
        return true;
    }

    public async Task<bool> ActivateAsync(Guid companyId, Guid id)
    {
        var rule = await _repository.GetByIdAsync(companyId, id);
        if (rule == null) return false;

        rule.Activate();
        await _repository.UpdateAsync(rule);
        return true;
    }

    private static TaxRuleDto MapToDto(TaxRule rule) => new()
    {
        Id = rule.Id,
        CountryCode = rule.CountryCode,
        Name = rule.Name,
        Rate = rule.Rate,
        IsInclusive = rule.IsInclusive,
        IsActive = rule.IsActive,
        CreatedAtUtc = rule.CreatedAtUtc,
        UpdatedAtUtc = rule.UpdatedAtUtc
    };
}
