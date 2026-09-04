using Sumpooj.Application.Common;
using Sumpooj.Application.Customers;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.UseCases;

public partial class CustomerService
{
    private readonly ICustomerRepository _repo;
    private readonly ITenantContext _tenant;

    public CustomerService(
        ICustomerRepository repo,
        ITenantContext tenant)
    {
        _repo = repo;
        _tenant = tenant;
    }

    public async Task<PagedResult<CustomerDto>> SearchAsync(CustomerSearchRequest request)
    {
        var (items, total) = await _repo.SearchAsync(
            request.Query,
            request.Page,
            request.PageSize);

        return new PagedResult<CustomerDto>
        {
            Items = items.Select(ToDto).ToList(),
            TotalCount = total,
            Page = request.Page,
            PageSize = request.PageSize
        };
    }

    public async Task<CustomerDto?> GetAsync(Guid id)
    {
        var customer = await _repo.GetByIdAsync(id);
        if (customer == null || !customer.IsActive)
            return null;

        return ToDto(customer);
    }

    public async Task<CustomerDto> CreateAsync(CreateCustomerRequest request)
    {
        if (_tenant.CompanyId == null)
            throw new InvalidOperationException("Company context required");

        var customer = new Customer(
            companyId: _tenant.CompanyId.Value,
            name: request.Name,
            email: request.Email,
            phone: request.Phone
        );

        customer.UpdateMobileCrm(request.BirthdayMonthDay, request.AnniversaryMonthDay, request.CompanyName,
            request.Department, request.Notes, request.TotalOrders, request.LastOrderAtUtc, request.PendingPaymentAmount,
            request.RewardPoints, request.LifetimeRewardPoints, request.RedeemedRewardPoints, request.LastRewardActivityAtUtc);
        await _repo.AddAsync(customer);
        return ToDto(customer);
    }

    public async Task<CustomerDto> UpdateContactAsync(Guid id, UpdateCustomerRequest request)
    {
        var customer = await _repo.GetByIdAsync(id)
            ?? throw new KeyNotFoundException("Customer not found");

        customer.UpdateContact(request.Email, request.Phone, request.Name);
        customer.UpdateMobileCrm(request.BirthdayMonthDay, request.AnniversaryMonthDay, request.CompanyName,
            request.Department, request.Notes, request.TotalOrders, request.LastOrderAtUtc, request.PendingPaymentAmount,
            request.RewardPoints, request.LifetimeRewardPoints, request.RedeemedRewardPoints, request.LastRewardActivityAtUtc);
        await _repo.UpdateAsync(customer);
        return ToDto(customer);
    }

    public async Task UpdateCardMessageAsync(Guid id, string? message)
    {
        var customer = await _repo.GetByIdAsync(id)
            ?? throw new KeyNotFoundException("Customer not found");

        customer.UpdateDefaultCardMessage(message);
        await _repo.UpdateAsync(customer);
    }

    public async Task DeactivateAsync(Guid id)
    {
        var customer = await _repo.GetByIdAsync(id)
            ?? throw new KeyNotFoundException("Customer not found");

        customer.MarkInactive();
        await _repo.UpdateAsync(customer);
    }

    public async Task ReactivateAsync(Guid id)
    {
        var customer = await _repo.GetByIdAsync(id)
            ?? throw new KeyNotFoundException("Customer not found");

        customer.MarkActive();
        await _repo.UpdateAsync(customer);
    }

    public async Task UpdateNotesAsync(Guid id, string? notes)
    {
        var customer = await _repo.GetByIdAsync(id)
            ?? throw new KeyNotFoundException("Customer not found");

        customer.UpdateNotes(notes);
        await _repo.UpdateAsync(customer);
    }

    private static CustomerDto ToDto(Customer c) => new()
    {
        Id = c.Id,
        Name = c.Name,
        Email = c.Email,
        Phone = c.Phone,
        Notes = c.Notes,
        BirthdayMonthDay = c.BirthdayMonthDay,
        AnniversaryMonthDay = c.AnniversaryMonthDay,
        CompanyName = c.CompanyName,
        Department = c.Department,
        TotalOrders = c.TotalOrders,
        LastOrderAtUtc = c.LastOrderAtUtc,
        PendingPaymentAmount = c.PendingPaymentAmount,
        RewardPoints = c.RewardPoints,
        LifetimeRewardPoints = c.LifetimeRewardPoints,
        RedeemedRewardPoints = c.RedeemedRewardPoints,
        LastRewardActivityAtUtc = c.LastRewardActivityAtUtc
    };
}
