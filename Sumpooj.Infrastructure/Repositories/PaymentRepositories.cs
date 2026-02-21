using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Payments;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class PaymentGatewayConfigRepository : IPaymentGatewayConfigRepository
{
    private readonly SumpoojDbContext _db;

    public PaymentGatewayConfigRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public async Task<PaymentGatewayConfig?> GetByIdAsync(Guid id)
    {
        return await _db.PaymentGatewayConfigs.FindAsync(id);
    }

    public async Task<PaymentGatewayConfig?> GetDefaultForCompanyAsync(Guid companyId)
    {
        return await _db.PaymentGatewayConfigs
            .Where(c => c.CompanyId == companyId && c.IsDefault && c.IsActive)
            .FirstOrDefaultAsync();
    }

    public async Task<IReadOnlyList<PaymentGatewayConfig>> GetByCompanyAsync(Guid companyId)
    {
        return await _db.PaymentGatewayConfigs
            .Where(c => c.CompanyId == companyId)
            .OrderByDescending(c => c.IsDefault)
            .ThenBy(c => c.Name)
            .ToListAsync();
    }

    public async Task<PaymentGatewayConfig?> GetByCompanyAndTypeAsync(Guid companyId, PaymentGatewayType gatewayType)
    {
        return await _db.PaymentGatewayConfigs
            .Where(c => c.CompanyId == companyId && c.GatewayType == gatewayType)
            .FirstOrDefaultAsync();
    }

    public async Task AddAsync(PaymentGatewayConfig config)
    {
        _db.PaymentGatewayConfigs.Add(config);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(PaymentGatewayConfig config)
    {
        _db.PaymentGatewayConfigs.Update(config);
        await _db.SaveChangesAsync();
    }

    public async Task DeleteAsync(PaymentGatewayConfig config)
    {
        _db.PaymentGatewayConfigs.Remove(config);
        await _db.SaveChangesAsync();
    }

    public async Task ClearDefaultsForCompanyAsync(Guid companyId)
    {
        var defaults = await _db.PaymentGatewayConfigs
            .Where(c => c.CompanyId == companyId && c.IsDefault)
            .ToListAsync();

        foreach (var config in defaults)
        {
            config.RemoveDefault();
        }

        await _db.SaveChangesAsync();
    }
}

public class PaymentTransactionRepository : IPaymentTransactionRepository
{
    private readonly SumpoojDbContext _db;

    public PaymentTransactionRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public async Task<PaymentTransaction?> GetByIdAsync(Guid id)
    {
        return await _db.PaymentTransactions.FindAsync(id);
    }

    public async Task<PaymentTransaction?> GetByTransactionRefAsync(string transactionRef)
    {
        return await _db.PaymentTransactions
            .Where(t => t.TransactionRef == transactionRef)
            .FirstOrDefaultAsync();
    }

    public async Task<PaymentTransaction?> GetByGatewayPaymentIdAsync(Guid companyId, string gatewayPaymentId)
    {
        return await _db.PaymentTransactions
            .Where(t => t.CompanyId == companyId && t.GatewayPaymentId == gatewayPaymentId)
            .FirstOrDefaultAsync();
    }

    public async Task<IReadOnlyList<PaymentTransaction>> GetByOrderIdAsync(Guid orderId)
    {
        return await _db.PaymentTransactions
            .Where(t => t.OrderId == orderId)
            .OrderByDescending(t => t.CreatedAtUtc)
            .ToListAsync();
    }

    public async Task<IReadOnlyList<PaymentTransaction>> SearchAsync(
        Guid companyId,
        GatewayPaymentStatus? status = null,
        DateTime? fromDate = null,
        DateTime? toDate = null,
        int page = 1,
        int pageSize = 20)
    {
        var query = _db.PaymentTransactions.Where(t => t.CompanyId == companyId);

        if (status.HasValue)
            query = query.Where(t => t.Status == status.Value);

        if (fromDate.HasValue)
            query = query.Where(t => t.CreatedAtUtc >= fromDate.Value);

        if (toDate.HasValue)
            query = query.Where(t => t.CreatedAtUtc <= toDate.Value);

        return await query
            .OrderByDescending(t => t.CreatedAtUtc)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();
    }

    public async Task<int> GetCountAsync(Guid companyId, GatewayPaymentStatus? status = null)
    {
        var query = _db.PaymentTransactions.Where(t => t.CompanyId == companyId);

        if (status.HasValue)
            query = query.Where(t => t.Status == status.Value);

        return await query.CountAsync();
    }

    public async Task AddAsync(PaymentTransaction transaction)
    {
        _db.PaymentTransactions.Add(transaction);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(PaymentTransaction transaction)
    {
        _db.PaymentTransactions.Update(transaction);
        await _db.SaveChangesAsync();
    }
}
