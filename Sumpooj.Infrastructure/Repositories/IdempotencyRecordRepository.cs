using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class IdempotencyRecordRepository : IIdempotencyRecordRepository
{
    private readonly SumpoojDbContext _db;

    public IdempotencyRecordRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public async Task<IdempotencyRecord?> GetByKeyAsync(Guid companyId, string idempotencyKey, CancellationToken cancellationToken = default)
    {
        var trimmedKey = idempotencyKey.Trim();
        return await _db.IdempotencyRecords
            .FirstOrDefaultAsync(r => r.CompanyId == companyId && r.IdempotencyKey == trimmedKey, cancellationToken);
    }

    public async Task AddAsync(IdempotencyRecord record, CancellationToken cancellationToken = default)
    {
        await _db.IdempotencyRecords.AddAsync(record, cancellationToken);
        await _db.SaveChangesAsync(cancellationToken);
    }
}
