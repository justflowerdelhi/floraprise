using Sumpooj.Application.Refunds;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IRefundRepository
{
    Task<Refund?> GetByIdAsync(Guid companyId, Guid id);
    Task<List<RefundDto>> GetByOrderIdAsync(Guid orderId);
    Task<decimal> GetTotalRefundedForOrderAsync(Guid orderId);
    Task AddAsync(Refund refund);
    Task UpdateAsync(Refund refund);
}
