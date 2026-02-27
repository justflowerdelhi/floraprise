using Sumpooj.Application.Common;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Suppliers;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.UseCases;

public class SupplierService
{
    private readonly ISupplierRepository _repo;
    private readonly ITenantContext _tenant;

    public SupplierService(ISupplierRepository repo, ITenantContext tenant)
    {
        _repo = repo;
        _tenant = tenant;
    }

    public async Task<PagedResult<SupplierDto>> SearchAsync(SupplierSearchRequest request)
    {
        var (items, total) = await _repo.SearchAsync(
            request.Query,
            request.IsActive,
            request.Page,
            request.PageSize);

        return new PagedResult<SupplierDto>
        {
            Items = items.Select(ToDto).ToList(),
            TotalCount = total,
            Page = request.Page,
            PageSize = request.PageSize
        };
    }

    public async Task<List<SupplierDto>> GetAllActiveAsync()
    {
        var suppliers = await _repo.GetAllActiveAsync();
        return suppliers.Select(ToDto).ToList();
    }

    public async Task<SupplierDto?> GetAsync(Guid id)
    {
        var supplier = await _repo.GetByIdAsync(id);
        return supplier == null ? null : ToDto(supplier);
    }

    public async Task<Guid> CreateAsync(CreateSupplierRequest request)
    {
        if (_tenant.CompanyId == null)
            throw new InvalidOperationException("Company context required");

        var supplier = new Supplier(
            companyId: _tenant.CompanyId.Value,
            name: request.Name,
            contactPerson: request.ContactPerson,
            email: request.Email,
            phone: request.Phone,
            address: request.Address);

        supplier.SetPaymentTerms(request.PaymentTermsDays);
        supplier.SetTaxIdentifier(request.TaxIdentifier);

        await _repo.AddAsync(supplier);
        return supplier.Id;
    }

    public async Task UpdateAsync(Guid id, UpdateSupplierRequest request)
    {
        var supplier = await _repo.GetByIdAsync(id)
            ?? throw new KeyNotFoundException("Supplier not found");

        if (request.Name != null || request.ContactPerson != null || request.Email != null || 
            request.Phone != null || request.Address != null)
        {
            supplier.UpdateContactInfo(
                request.ContactPerson ?? supplier.ContactPerson,
                request.Email ?? supplier.Email,
                request.Phone ?? supplier.Phone,
                request.Address ?? supplier.Address);
        }

        if (request.PaymentTermsDays.HasValue)
        {
            supplier.SetPaymentTerms(request.PaymentTermsDays.Value);
        }

        if (request.TaxIdentifier != null)
        {
            supplier.SetTaxIdentifier(request.TaxIdentifier);
        }

        if (request.Rating != null && Enum.TryParse<SupplierRating>(request.Rating, true, out var rating))
        {
            supplier.SetRating(rating);
        }

        await _repo.UpdateAsync(supplier);
    }

    public async Task DeactivateAsync(Guid id)
    {
        var supplier = await _repo.GetByIdAsync(id)
            ?? throw new KeyNotFoundException("Supplier not found");

        supplier.Deactivate();
        await _repo.UpdateAsync(supplier);
    }

    private static SupplierDto ToDto(Supplier s) => new()
    {
        Id = s.Id,
        Name = s.Name,
        ContactPerson = s.ContactPerson,
        Email = s.Email,
        Phone = s.Phone,
        Address = s.Address,
        IsActive = s.IsActive,
        Rating = s.Rating.ToString(),
        Notes = s.Notes,
        PaymentTermsDays = s.PaymentTermsDays,
        TaxIdentifier = s.TaxIdentifier,
        LastOrderDate = s.LastOrderDate,
        TotalOrdersCount = s.TotalOrdersCount,
        TotalSpentAmount = s.TotalSpentAmount,
        CreatedAtUtc = s.CreatedAtUtc
    };

    private static SupplierListDto ToListDto(Supplier s) => new()
    {
        Id = s.Id,
        Name = s.Name,
        ContactPerson = s.ContactPerson,
        Email = s.Email,
        Phone = s.Phone,
        IsActive = s.IsActive,
        Rating = s.Rating.ToString(),
        TotalOrdersCount = s.TotalOrdersCount
    };
}
