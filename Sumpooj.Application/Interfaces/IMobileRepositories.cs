using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IMobileCustomerRepository
{
    Task<MobileCustomer?> GetByIdAsync(Guid companyId, Guid customerId);
    Task<MobileCustomer?> GetByMobileAsync(Guid companyId, string mobile);
    Task AddAsync(MobileCustomer customer);
}

public interface IMobileUserRepository
{
    Task<MobileUser?> GetByIdAsync(Guid companyId, Guid userId);
    Task<MobileUser?> GetByMobileAsync(Guid companyId, string mobile);
    Task AddAsync(MobileUser user);
}

public interface IMobileDeviceRepository
{
    Task<MobileDevice?> GetByDeviceIdAsync(Guid companyId, Guid mobileUserId, string deviceId);
    Task<MobileDevice?> GetByIdAsync(Guid companyId, Guid mobileDeviceId);
    Task AddAsync(MobileDevice device);
}

public interface ISubscriptionPlanRepository
{
    Task<SubscriptionPlan?> GetByCodeAsync(string code);
    Task<SubscriptionPlan?> GetByIdAsync(Guid id);
    Task<List<SubscriptionPlan>> GetActiveAsync();
    Task AddAsync(SubscriptionPlan plan);
}

public interface IMobileSubscriptionRepository
{
    Task<MobileSubscription?> GetByUserIdAsync(Guid companyId, Guid mobileUserId);
    Task AddAsync(MobileSubscription subscription);
}

public interface IMobileLicenseRepository
{
    Task<MobileLicense?> GetByDeviceIdAsync(Guid companyId, Guid mobileDeviceId);
    Task AddAsync(MobileLicense license);
}

public interface IDeviceSessionRepository
{
    Task<DeviceSession?> GetByRefreshTokenAsync(string refreshToken);
    Task<List<DeviceSession>> GetActiveByDeviceAsync(Guid companyId, Guid mobileDeviceId);
    Task AddAsync(DeviceSession session);
}

public interface IMobilePaymentTransactionRepository
{
    Task AddAsync(MobilePaymentTransaction paymentTransaction);
    Task<List<MobilePaymentTransaction>> GetBySubscriptionAsync(Guid companyId, Guid subscriptionId);
}

public interface IMobileUnitOfWork
{
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
