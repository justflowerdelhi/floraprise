using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public sealed class MobileCustomerRepository : IMobileCustomerRepository
{
    private readonly SumpoojDbContext _db;

    public MobileCustomerRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public Task<MobileCustomer?> GetByIdAsync(Guid companyId, Guid customerId)
    {
        return _db.MobileCustomers.FirstOrDefaultAsync(x => x.CompanyId == companyId && x.Id == customerId && !x.IsDeleted);
    }

    public Task<MobileCustomer?> GetByMobileAsync(Guid companyId, string mobile)
    {
        var normalized = mobile.Trim();
        return _db.MobileCustomers.FirstOrDefaultAsync(x => x.CompanyId == companyId && x.Mobile == normalized && !x.IsDeleted);
    }

    public async Task AddAsync(MobileCustomer customer)
    {
        await _db.MobileCustomers.AddAsync(customer);
    }
}

public sealed class MobileUserRepository : IMobileUserRepository
{
    private readonly SumpoojDbContext _db;

    public MobileUserRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public Task<MobileUser?> GetByIdAsync(Guid companyId, Guid userId)
    {
        return _db.MobileUsers
            .Include(x => x.Subscription)
            .FirstOrDefaultAsync(x => x.CompanyId == companyId && x.Id == userId && !x.IsDeleted);
    }

    public Task<MobileUser?> GetByMobileAsync(Guid companyId, string mobile)
    {
        var normalized = mobile.Trim();
        return _db.MobileUsers
            .Include(x => x.Subscription)
            .FirstOrDefaultAsync(x => x.CompanyId == companyId && x.Mobile == normalized && !x.IsDeleted);
    }

    public async Task AddAsync(MobileUser user)
    {
        await _db.MobileUsers.AddAsync(user);
    }
}

public sealed class MobileDeviceRepository : IMobileDeviceRepository
{
    private readonly SumpoojDbContext _db;

    public MobileDeviceRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public Task<MobileDevice?> GetByDeviceIdAsync(Guid companyId, Guid mobileUserId, string deviceId)
    {
        var normalized = deviceId.Trim();
        return _db.MobileDevices
            .Include(x => x.License)
            .FirstOrDefaultAsync(x => x.CompanyId == companyId && x.MobileUserId == mobileUserId && x.DeviceId == normalized && !x.IsDeleted);
    }

    public Task<MobileDevice?> GetByIdAsync(Guid companyId, Guid mobileDeviceId)
    {
        return _db.MobileDevices
            .Include(x => x.License)
            .FirstOrDefaultAsync(x => x.CompanyId == companyId && x.Id == mobileDeviceId && !x.IsDeleted);
    }

    public async Task AddAsync(MobileDevice device)
    {
        await _db.MobileDevices.AddAsync(device);
    }
}

public sealed class SubscriptionPlanRepository : ISubscriptionPlanRepository
{
    private readonly SumpoojDbContext _db;

    public SubscriptionPlanRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public Task<SubscriptionPlan?> GetByCodeAsync(string code)
    {
        var normalized = code.Trim().ToUpperInvariant();
        return _db.SubscriptionPlans.FirstOrDefaultAsync(x => x.Code == normalized && !x.IsDeleted);
    }

    public Task<SubscriptionPlan?> GetByIdAsync(Guid id)
    {
        return _db.SubscriptionPlans.FirstOrDefaultAsync(x => x.Id == id && !x.IsDeleted);
    }

    public Task<List<SubscriptionPlan>> GetActiveAsync()
    {
        return _db.SubscriptionPlans
            .Where(x => x.IsActive && !x.IsDeleted)
            .OrderBy(x => x.Name)
            .ToListAsync();
    }

    public async Task AddAsync(SubscriptionPlan plan)
    {
        await _db.SubscriptionPlans.AddAsync(plan);
    }
}

public sealed class MobileSubscriptionRepository : IMobileSubscriptionRepository
{
    private readonly SumpoojDbContext _db;

    public MobileSubscriptionRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public Task<MobileSubscription?> GetByUserIdAsync(Guid companyId, Guid mobileUserId)
    {
        return _db.MobileSubscriptions
            .Include(x => x.SubscriptionPlan)
            .Include(x => x.FeatureEntitlements)
            .FirstOrDefaultAsync(x => x.CompanyId == companyId && x.MobileUserId == mobileUserId && !x.IsDeleted);
    }

    public async Task AddAsync(MobileSubscription subscription)
    {
        await _db.MobileSubscriptions.AddAsync(subscription);
    }
}

public sealed class MobileLicenseRepository : IMobileLicenseRepository
{
    private readonly SumpoojDbContext _db;

    public MobileLicenseRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public Task<MobileLicense?> GetByDeviceIdAsync(Guid companyId, Guid mobileDeviceId)
    {
        return _db.MobileLicenses
            .FirstOrDefaultAsync(x => x.CompanyId == companyId && x.MobileDeviceId == mobileDeviceId && !x.IsDeleted);
    }

    public async Task AddAsync(MobileLicense license)
    {
        await _db.MobileLicenses.AddAsync(license);
    }
}

public sealed class DeviceSessionRepository : IDeviceSessionRepository
{
    private readonly SumpoojDbContext _db;

    public DeviceSessionRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public Task<DeviceSession?> GetByRefreshTokenAsync(string refreshToken)
    {
        return _db.DeviceSessions.FirstOrDefaultAsync(x => x.RefreshToken == refreshToken && !x.IsDeleted);
    }

    public Task<List<DeviceSession>> GetActiveByDeviceAsync(Guid companyId, Guid mobileDeviceId)
    {
        return _db.DeviceSessions
            .Where(x => x.CompanyId == companyId && x.MobileDeviceId == mobileDeviceId && x.Status == DeviceSessionStatus.Active && !x.IsDeleted)
            .ToListAsync();
    }

    public async Task AddAsync(DeviceSession session)
    {
        await _db.DeviceSessions.AddAsync(session);
    }
}

public sealed class MobilePaymentTransactionRepository : IMobilePaymentTransactionRepository
{
    private readonly SumpoojDbContext _db;

    public MobilePaymentTransactionRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public async Task AddAsync(MobilePaymentTransaction paymentTransaction)
    {
        await _db.MobilePaymentTransactions.AddAsync(paymentTransaction);
    }

    public Task<List<MobilePaymentTransaction>> GetBySubscriptionAsync(Guid companyId, Guid subscriptionId)
    {
        return _db.MobilePaymentTransactions
            .Where(x => x.CompanyId == companyId && x.MobileSubscriptionId == subscriptionId && !x.IsDeleted)
            .OrderByDescending(x => x.CreatedAtUtc)
            .ToListAsync();
    }
}

public sealed class MobileUnitOfWork : IMobileUnitOfWork
{
    private readonly SumpoojDbContext _db;

    public MobileUnitOfWork(SumpoojDbContext db)
    {
        _db = db;
    }

    public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        return _db.SaveChangesAsync(cancellationToken);
    }
}
