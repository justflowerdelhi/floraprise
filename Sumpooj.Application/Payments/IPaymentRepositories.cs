using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Payments;

/// <summary>
/// Repository interface for PaymentGatewayConfig
/// </summary>
public interface IPaymentGatewayConfigRepository
{
    Task<PaymentGatewayConfig?> GetByIdAsync(Guid id);
    Task<PaymentGatewayConfig?> GetDefaultForCompanyAsync(Guid companyId);
    Task<IReadOnlyList<PaymentGatewayConfig>> GetByCompanyAsync(Guid companyId);
    Task<PaymentGatewayConfig?> GetByCompanyAndTypeAsync(Guid companyId, PaymentGatewayType gatewayType);
    Task AddAsync(PaymentGatewayConfig config);
    Task UpdateAsync(PaymentGatewayConfig config);
    Task DeleteAsync(PaymentGatewayConfig config);
    Task ClearDefaultsForCompanyAsync(Guid companyId);
}

/// <summary>
/// Repository interface for PaymentTransaction
/// </summary>
public interface IPaymentTransactionRepository
{
    Task<PaymentTransaction?> GetByIdAsync(Guid id);
    Task<PaymentTransaction?> GetByTransactionRefAsync(string transactionRef);
    Task<PaymentTransaction?> GetByGatewayPaymentIdAsync(Guid companyId, string gatewayPaymentId);
    Task<IReadOnlyList<PaymentTransaction>> GetByOrderIdAsync(Guid orderId);
    Task<IReadOnlyList<PaymentTransaction>> SearchAsync(
        Guid companyId,
        GatewayPaymentStatus? status = null,
        DateTime? fromDate = null,
        DateTime? toDate = null,
        int page = 1,
        int pageSize = 20);
    Task<int> GetCountAsync(Guid companyId, GatewayPaymentStatus? status = null);
    Task AddAsync(PaymentTransaction transaction);
    Task UpdateAsync(PaymentTransaction transaction);
}
