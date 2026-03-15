using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Payments;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class PaymentRepository : IPaymentRepository
{
    private readonly SumpoojDbContext _db;

    public PaymentRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public async Task<Payment?> GetByIdAsync(Guid id)
    {
        return await _db.Payments.FirstOrDefaultAsync(p => p.Id == id);
    }

    public async Task<List<PaymentDto>> GetByOrderIdAsync(Guid orderId)
    {
        return await _db.Payments
            .Where(p => p.OrderId == orderId)
            .OrderByDescending(p => p.CreatedAtUtc)
            .Select(p => new PaymentDto
            {
                Id = p.Id,
                OrderId = p.OrderId,
                LocationId = p.LocationId,
                Method = p.Method.ToString(),
                Amount = p.Amount,
                Status = p.Status.ToString(),
                TransactionId = p.TransactionId,
                AuthorizationCode = p.AuthorizationCode,
                CardBrand = p.CardBrand,
                Last4 = p.Last4,
                TerminalId = p.TerminalId,
                CreatedAtUtc = p.CreatedAtUtc
            })
            .ToListAsync();
    }

    public async Task<decimal> GetTotalPaidForOrderAsync(Guid orderId)
    {
        return await _db.Payments
            .Where(p => p.OrderId == orderId && p.Status == PaymentTransactionStatus.Approved)
            .SumAsync(p => p.Amount);
    }

    public async Task<decimal> GetTodayTotalAsync()
    {
        var today = DateTime.UtcNow.Date;
        return await _db.Payments
            .Where(p => p.Status == PaymentTransactionStatus.Approved && p.CreatedAtUtc.Date == today)
            .SumAsync(p => p.Amount);
    }

    public async Task<List<Payment>> GetByDateAsync(Guid companyId, Guid locationId, DateTime date)
    {
        var dayStart = DateTime.SpecifyKind(date.Date, DateTimeKind.Utc);
        var dayEnd = dayStart.AddDays(1);
        var query = _db.Payments
            .Where(p => p.CompanyId == companyId
                && p.CreatedAtUtc >= dayStart && p.CreatedAtUtc < dayEnd
                && p.Status == PaymentTransactionStatus.Approved);

        // Filter by location only if a specific location is provided
        if (locationId != Guid.Empty)
            query = query.Where(p => p.LocationId == locationId);

        return await query.ToListAsync();
    }

    public async Task AddAsync(Payment payment)
    {
        await _db.Payments.AddAsync(payment);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(Payment payment)
    {
        _db.Payments.Update(payment);
        await _db.SaveChangesAsync();
    }
}
