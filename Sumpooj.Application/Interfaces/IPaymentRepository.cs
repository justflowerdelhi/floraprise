using Sumpooj.Application.Payments;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IPaymentRepository
{
    Task<Payment?> GetByIdAsync(Guid id);
    Task<List<PaymentDto>> GetByOrderIdAsync(Guid orderId);
    Task<decimal> GetTotalPaidForOrderAsync(Guid orderId);
    Task<decimal> GetTodayTotalAsync();
    Task AddAsync(Payment payment);
    Task UpdateAsync(Payment payment);
}
