using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class AccountRepository : IAccountRepository
{
    private readonly SumpoojDbContext _db;

    public AccountRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public async Task<List<Account>> GetAllAsync(Guid companyId)
    {
        return await _db.Accounts
            .AsNoTracking()
            .Where(a => a.CompanyId == companyId)
            .ToListAsync();
    }
}
