using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IInventoryLedgerRepository
{
    Task AddAsync(InventoryLedger entry);
    Task<List<InventoryLedger>> GetByProductAsync(Guid companyId, Guid productId);
}
