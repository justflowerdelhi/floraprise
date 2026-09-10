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
        // Include payments without a location (phone orders) in location-specific views too
        if (locationId != Guid.Empty)
            query = query.Where(p => p.LocationId == locationId || p.LocationId == null);

        return await query.ToListAsync();
    }

    public async Task AddAsync(Payment payment, DateTime? businessDate = null)
    {
        await _db.Payments.AddAsync(payment);
        if (payment.Method == PaymentMethod.Cash && payment.Status == PaymentTransactionStatus.Approved)
        {
            await AddCashBookEntryForPaymentAsync(payment, businessDate);
        }
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(Payment payment, DateTime? businessDate = null)
    {
        _db.Payments.Update(payment);
        if (payment.Method == PaymentMethod.Cash && payment.Status == PaymentTransactionStatus.Approved)
        {
            await AddCashBookEntryForPaymentAsync(payment, businessDate);
        }
        await _db.SaveChangesAsync();
    }

    private async Task AddCashBookEntryForPaymentAsync(Payment payment, DateTime? businessDate)
    {
        if (payment.Method != PaymentMethod.Cash || payment.Status != PaymentTransactionStatus.Approved || payment.Amount <= 0)
            return;

        var entryDate = businessDate.HasValue
            ? DateTime.SpecifyKind(businessDate.Value.Date, DateTimeKind.Utc)
            : DateTime.SpecifyKind(payment.CreatedAtUtc.Date, DateTimeKind.Utc);

        var order = await _db.Orders.AsNoTracking().FirstOrDefaultAsync(o => o.CompanyId == payment.CompanyId && o.Id == payment.OrderId);
        var orderIdentifier = order != null && !string.IsNullOrWhiteSpace(order.OrderNumber)
            ? order.OrderNumber.Trim()
            : payment.OrderId.ToString();

        var paymentIdStr = payment.Id.ToString();

        var alreadyExists = await _db.CashBookEntries.AnyAsync(e =>
            e.CompanyId == payment.CompanyId &&
            e.Date == entryDate &&
            (e.Description.Contains(paymentIdStr) ||
             e.Description == $"POS cash sale {orderIdentifier}" ||
             e.Description == $"Cash payment for order {orderIdentifier}"));

        if (alreadyExists)
            return;

        var currentBalance = await _db.CashBookEntries
            .Where(e => e.CompanyId == payment.CompanyId && e.Date == entryDate)
            .OrderByDescending(e => e.CreatedAtUtc)
            .Select(e => (decimal?)e.RunningBalance)
            .FirstOrDefaultAsync() ?? 0m;

        var entry = new CashBookEntry(
            payment.CompanyId,
            entryDate,
            CashBookTransactionType.CashSale,
            $"Cash payment for order {orderIdentifier} [{payment.Id}]",
            payment.Amount,
            payment.Amount,
            0m,
            currentBalance + payment.Amount);

        await _db.CashBookEntries.AddAsync(entry);
    }
}
