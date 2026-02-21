using Sumpooj.Application.Common;
using Sumpooj.Application.Proposals;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IProposalRepository
{
    Task<Proposal?> GetByIdAsync(Guid companyId, Guid id);
    Task<Proposal?> GetByNumberAsync(Guid companyId, string proposalNumber);
    Task<PagedResult<ProposalDto>> SearchAsync(Guid companyId, ProposalSearchRequest request);
    Task<List<ProposalDto>> GetByEventAsync(Guid companyId, Guid eventId);
    Task<string> GenerateProposalNumberAsync(Guid companyId);
    Task AddAsync(Proposal proposal);
    Task UpdateAsync(Proposal proposal);
}
