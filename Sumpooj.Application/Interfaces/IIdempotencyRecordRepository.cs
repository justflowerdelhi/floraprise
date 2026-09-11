using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IIdempotencyRecordRepository
{
    Task<IdempotencyRecord?> GetByKeyAsync(Guid companyId, string idempotencyKey, CancellationToken cancellationToken = default);
    Task AddAsync(IdempotencyRecord record, CancellationToken cancellationToken = default);
}
