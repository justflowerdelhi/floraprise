using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Refunds;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class RefundRepository : IRefundRepository
{
    private readonly SumpoojDbContext _db;

    public RefundRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public async Task<Refund?> GetByIdAsync(Guid companyId, Guid id)
    {
        return await _db.Refunds
            .Include(r => r.Items)
            .FirstOrDefaultAsync(r => r.CompanyId == companyId && r.Id == id);
    }

    public async Task<List<RefundDto>> GetByOrderIdAsync(Guid orderId)
    {
        return await _db.Refunds
            .Include(r => r.Items)
            .Where(r => r.OrderId == orderId)
            .OrderByDescending(r => r.CreatedAtUtc)
            .Select(r => new RefundDto
            {
                Id = r.Id,
                OrderId = r.OrderId,
                RefundNumber = r.RefundNumber,
                Method = r.Method.ToString(),
                Status = r.Status.ToString(),
                Reason = r.Reason,
                RefundedAmount = r.RefundedAmount,
                TransactionId = r.TransactionId,
                Notes = r.Notes,
                Items = r.Items.Select(i => new RefundItemDto
                {
                    ProductId = i.ProductId,
                    ProductName = i.ProductName,
                    Quantity = i.Quantity,
                    UnitPrice = i.UnitPrice,
                    RefundAmount = i.RefundAmount,
                    Restock = i.Restock
                }).ToList(),
                CreatedAtUtc = r.CreatedAtUtc
            })
            .ToListAsync();
    }

    public async Task<decimal> GetTotalRefundedForOrderAsync(Guid orderId)
    {
        return await _db.Refunds
            .Where(r => r.OrderId == orderId && r.Status == RefundStatus.Processed)
            .SumAsync(r => r.RefundedAmount);
    }

    public async Task AddAsync(Refund refund)
    {
        await _db.Refunds.AddAsync(refund);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(Refund refund)
    {
        _db.Refunds.Update(refund);
        await _db.SaveChangesAsync();
    }
}
