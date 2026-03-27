using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class CustomerRepository : ICustomerRepository
{
    private readonly SumpoojDbContext _db;

    public CustomerRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public async Task<(List<Customer>, int)> SearchAsync(
        string? query,
        int page,
        int pageSize)
    {
        var q = _db.Customers
            .AsNoTracking()
            .Where(c => c.IsActive);

        if (!string.IsNullOrWhiteSpace(query))
        {
            query = query.ToLower();

            q = q.Where(c =>
                c.Name.ToLower().Contains(query) ||
                (c.Email != null && c.Email.ToLower().Contains(query)) ||
                (c.Phone != null && c.Phone.Contains(query)));
        }

        var total = await q.CountAsync();

        var items = await q
            .OrderBy(c => c.Name)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return (items, total);
    }

    public async Task<Customer?> FindByPhoneOrNameAsync(Guid companyId, string? phone, string? name)
    {
        var normalizedPhone = NormalizeDigits(phone);
        if (!string.IsNullOrWhiteSpace(normalizedPhone))
        {
            // Evaluate phone normalization in memory to handle varied stored formats.
            var phoneCandidates = await _db.Customers
                .AsNoTracking()
                .Where(c => c.CompanyId == companyId && c.IsActive && c.Phone != null && c.Name != "Walk-In Customer")
                .ToListAsync();

            var byPhone = phoneCandidates.FirstOrDefault(c => NormalizeDigits(c.Phone) == normalizedPhone);
            if (byPhone != null) return byPhone;
        }

        var normalizedName = (name ?? string.Empty).Trim().ToLowerInvariant();
        if (!string.IsNullOrWhiteSpace(normalizedName))
        {
            return await _db.Customers
                .AsNoTracking()
                .Where(c => c.CompanyId == companyId && c.IsActive && c.Name != "Walk-In Customer")
                .OrderBy(c => c.CreatedAtUtc)
                .FirstOrDefaultAsync(c => c.Name.ToLower() == normalizedName);
        }

        return null;
    }

    private static string NormalizeDigits(string? value)
    {
        if (string.IsNullOrWhiteSpace(value)) return string.Empty;
        return new string(value.Where(char.IsDigit).ToArray());
    }

    public Task<Customer?> GetByIdAsync(Guid id)
        => _db.Customers.FirstOrDefaultAsync(c => c.Id == id);

    public async Task AddAsync(Customer customer)
    {
        _db.Customers.Add(customer);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(Customer customer)
    {
        _db.Customers.Update(customer);
        await _db.SaveChangesAsync();
    }

    public async Task<Customer> GetOrCreateWalkInCustomerAsync(Guid companyId)
    {
        const string walkInName = "Walk-In Customer";
        var existing = await _db.Customers
            .FirstOrDefaultAsync(c => c.CompanyId == companyId && c.Name == walkInName);

        if (existing != null)
            return existing;

        var walkIn = new Customer(companyId, walkInName, null, null);
        _db.Customers.Add(walkIn);
        await _db.SaveChangesAsync();
        return walkIn;
    }
}
