using Sumpooj.Application.Payments;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IPaymentRepository
{
    Task<Payment?> GetByIdAsync(Guid id);
    Task<List<PaymentDto>> GetByOrderIdAsync(Guid orderId);
    Task<decimal> GetTotalPaidForOrderAsync(Guid orderId);
    Task<decimal> GetTodayTotalAsync();
    Task<List<Payment>> GetByDateAsync(Guid companyId, Guid locationId, DateTime date);
    Task AddAsync(Payment payment);
    Task UpdateAsync(Payment payment);
}
