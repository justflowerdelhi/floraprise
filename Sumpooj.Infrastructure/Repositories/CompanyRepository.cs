using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class CompanyRepository : ICompanyRepository
{
    private readonly SumpoojDbContext _context;

    public CompanyRepository(SumpoojDbContext context)
    {
        _context = context;
    }

    public async Task<Company?> GetByIdAsync(Guid id)
    {
        return await _context.Companies.FindAsync(id);
    }

    public async Task<Company?> GetByCompanyIdAsync(Guid companyId)
    {
        return await _context.Companies.FirstOrDefaultAsync(c => c.Id == companyId);
    }

    public async Task<IReadOnlyList<Company>> GetAllAsync()
    {
        return await _context.Companies.ToListAsync();
    }

    public async Task AddAsync(Company company)
    {
        await _context.Companies.AddAsync(company);
        await _context.SaveChangesAsync();
    }

    public async Task UpdateAsync(Company company)
    {
        _context.Companies.Update(company);
        await _context.SaveChangesAsync();
    }
}
