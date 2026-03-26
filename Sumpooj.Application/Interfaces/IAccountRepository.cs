using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IAccountRepository
{
    Task<List<Account>> GetAllAsync(Guid companyId);
}
