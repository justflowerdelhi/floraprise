using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Common;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.WireOrders;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class WireOrderRepository : IWireOrderRepository
{
    private readonly SumpoojDbContext _db;

    public WireOrderRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public async Task<WireOrder?> GetByIdAsync(Guid companyId, Guid id)
    {
        return await _db.WireOrders
            .FirstOrDefaultAsync(w => w.CompanyId == companyId && w.Id == id);
    }

    public async Task<WireOrder?> GetByWireOrderNumberAsync(Guid companyId, string wireOrderNumber)
    {
        return await _db.WireOrders
            .FirstOrDefaultAsync(w => w.CompanyId == companyId && w.WireOrderNumber == wireOrderNumber);
    }

    public async Task<PagedResult<WireOrderDto>> SearchAsync(Guid companyId, WireOrderSearchRequest request)
    {
        var query = _db.WireOrders
            .Where(w => w.CompanyId == companyId && w.IsActive);

        if (request.WireService.HasValue)
        {
            query = query.Where(w => w.WireService == request.WireService.Value);
        }

        if (request.Status.HasValue)
        {
            query = query.Where(w => w.Status == request.Status.Value);
        }

        if (request.FromDate.HasValue)
        {
            query = query.Where(w => w.DeliveryDate >= request.FromDate.Value);
        }

        if (request.ToDate.HasValue)
        {
            query = query.Where(w => w.DeliveryDate <= request.ToDate.Value);
        }

        if (!string.IsNullOrWhiteSpace(request.Query))
        {
            var q = request.Query.ToLower();
            query = query.Where(w =>
                w.WireOrderNumber.ToLower().Contains(q) ||
                w.RecipientName.ToLower().Contains(q) ||
                (w.SenderName != null && w.SenderName.ToLower().Contains(q)));
        }

        var total = await query.CountAsync();

        var items = await query
            .OrderByDescending(w => w.ReceivedDate)
            .Skip((request.Page - 1) * request.PageSize)
            .Take(request.PageSize)
            .Select(w => new WireOrderDto
            {
                Id = w.Id,
                ExternalOrderId = w.WireOrderNumber,
                Platform = w.WireService.ToString(),
                WireService = w.WireService,
                WireOrderNumber = w.WireOrderNumber,
                ReceivedDate = w.ReceivedDate,
                DeliveryDate = w.DeliveryDate,
                TimeSlot = w.TimeSlot,
                Status = w.Status,
                SenderName = w.SenderName,
                SenderPhone = w.SenderPhone,
                SenderEmail = w.SenderEmail,
                RecipientName = w.RecipientName,
                RecipientPhone = w.RecipientPhone,
                DeliveryAddress = w.DeliveryAddress,
                DeliveryCity = w.DeliveryCity,
                DeliveryZipCode = w.DeliveryZipCode,
                DeliveryInstructions = w.DeliveryInstructions,
                CardMessage = w.CardMessage,
                GrossAmount = w.WireAmount,
                Commission = w.WireServiceFee,
                Fees = 0,
                NetPayout = w.NetAmount,
                FulfillmentCost = w.FulfillmentCost,
                ProductDescription = w.ProductDescription,
                WireProductCode = w.WireProductCode,
                SubstitutionNotes = w.SubstitutionNotes,
                LinkedOrderId = w.LinkedOrderId,
                AssignedToUserId = w.AssignedToUserId,
                InternalNotes = w.InternalNotes,
                ConfirmationCode = w.ConfirmationCode,
                FulfilledAt = w.FulfilledAt,
                RejectionReason = w.RejectionReason,
                CreatedAtUtc = w.CreatedAtUtc
            })
            .ToListAsync();

        return new PagedResult<WireOrderDto>(items, total, request.Page, request.PageSize);
    }

    public async Task<List<WireOrderDto>> GetTodaysOrdersAsync(Guid companyId)
    {
        var today = DateTime.UtcNow.Date;
        return await _db.WireOrders
            .Where(w => w.CompanyId == companyId && w.IsActive)
            .Where(w => w.DeliveryDate.Date == today)
            .OrderBy(w => w.TimeSlot)
            .Select(w => new WireOrderDto
            {
                Id = w.Id,
                ExternalOrderId = w.WireOrderNumber,
                Platform = w.WireService.ToString(),
                WireService = w.WireService,
                WireOrderNumber = w.WireOrderNumber,
                ReceivedDate = w.ReceivedDate,
                DeliveryDate = w.DeliveryDate,
                TimeSlot = w.TimeSlot,
                Status = w.Status,
                RecipientName = w.RecipientName,
                RecipientPhone = w.RecipientPhone,
                DeliveryAddress = w.DeliveryAddress,
                GrossAmount = w.WireAmount,
                NetPayout = w.NetAmount,
                ProductDescription = w.ProductDescription,
                AssignedToUserId = w.AssignedToUserId,
                CreatedAtUtc = w.CreatedAtUtc
            })
            .ToListAsync();
    }

    public async Task<List<WireOrderDto>> GetPendingOrdersAsync(Guid companyId)
    {
        return await _db.WireOrders
            .Where(w => w.CompanyId == companyId && w.IsActive)
            .Where(w => w.Status == WireOrderStatus.Received || w.Status == WireOrderStatus.Accepted)
            .OrderBy(w => w.DeliveryDate)
            .Select(w => new WireOrderDto
            {
                Id = w.Id,
                ExternalOrderId = w.WireOrderNumber,
                Platform = w.WireService.ToString(),
                WireService = w.WireService,
                WireOrderNumber = w.WireOrderNumber,
                ReceivedDate = w.ReceivedDate,
                DeliveryDate = w.DeliveryDate,
                TimeSlot = w.TimeSlot,
                Status = w.Status,
                RecipientName = w.RecipientName,
                DeliveryAddress = w.DeliveryAddress,
                GrossAmount = w.WireAmount,
                NetPayout = w.NetAmount,
                ProductDescription = w.ProductDescription,
                CreatedAtUtc = w.CreatedAtUtc
            })
            .ToListAsync();
    }

    public async Task<WireOrderSummaryDto> GetSummaryAsync(Guid companyId, DateTime fromDate, DateTime toDate)
    {
        var orders = await _db.WireOrders
            .Where(w => w.CompanyId == companyId && w.IsActive)
            .Where(w => w.ReceivedDate >= fromDate && w.ReceivedDate <= toDate)
            .ToListAsync();

        var summary = new WireOrderSummaryDto
        {
            TotalOrders = orders.Count,
            PendingOrders = orders.Count(o => o.Status == WireOrderStatus.Received),
            AcceptedOrders = orders.Count(o => o.Status == WireOrderStatus.Accepted || o.Status == WireOrderStatus.InProgress),
            FulfilledOrders = orders.Count(o => o.Status == WireOrderStatus.Fulfilled),
            RejectedOrders = orders.Count(o => o.Status == WireOrderStatus.Rejected || o.Status == WireOrderStatus.Cancelled),
            TotalGrossAmount = orders.Sum(o => o.WireAmount),
            TotalCommission = orders.Sum(o => o.WireServiceFee),
            TotalFees = 0,
            TotalNetPayout = orders.Sum(o => o.NetAmount),
            TotalFulfillmentCost = orders.Where(o => o.FulfillmentCost.HasValue).Sum(o => o.FulfillmentCost!.Value),
            TotalProfit = orders.Where(o => o.FulfillmentCost.HasValue).Sum(o => o.NetAmount - o.FulfillmentCost!.Value)
        };

        summary.ByPlatform = orders
            .GroupBy(o => o.WireService.ToString())
            .ToDictionary(g => g.Key, g => g.Count());

        summary.ByStatus = orders
            .GroupBy(o => o.Status.ToString())
            .ToDictionary(g => g.Key, g => g.Count());

        return summary;
    }

    public async Task AddAsync(WireOrder order)
    {
        await _db.WireOrders.AddAsync(order);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(WireOrder order)
    {
        _db.WireOrders.Update(order);
        await _db.SaveChangesAsync();
    }
}
