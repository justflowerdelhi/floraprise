using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Common;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Orders;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class OrderRepository : IOrderRepository
{
    private readonly SumpoojDbContext _db;

    public OrderRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public async Task<Order?> GetByIdAsync(Guid companyId, Guid id)
    {
        return await _db.Orders
            .Include(o => o.Items)
            .FirstOrDefaultAsync(o => o.CompanyId == companyId && o.Id == id);
    }

    public async Task<Order?> GetByOrderNumberAsync(Guid companyId, string orderNumber)
    {
        return await _db.Orders
            .Include(o => o.Items)
            .FirstOrDefaultAsync(o => o.CompanyId == companyId && o.OrderNumber == orderNumber);
    }

    public async Task<List<Order>> GetByIdsAsync(Guid companyId, List<Guid> ids)
    {
        return await _db.Orders
            .Where(o => o.CompanyId == companyId && ids.Contains(o.Id))
            .ToListAsync();
    }

    public async Task<PagedResult<OrderListDto>> SearchAsync(Guid companyId, OrderSearchRequest request)
    {
        var query = _db.Orders.Where(o => o.CompanyId == companyId && o.IsActive);

        if (!string.IsNullOrWhiteSpace(request.Query))
        {
            var q = request.Query.ToLower();
            query = query.Where(o =>
                o.OrderNumber.ToLower().Contains(q) ||
                (o.RecipientName != null && o.RecipientName.ToLower().Contains(q)));
        }

        if (request.CustomerId.HasValue)
        {
            query = query.Where(o => o.CustomerId == request.CustomerId.Value);
        }

        if (!string.IsNullOrWhiteSpace(request.Status) && Enum.TryParse<OrderStatus>(request.Status, true, out var status))
        {
            query = query.Where(o => o.Status == status);
        }

        if (!string.IsNullOrWhiteSpace(request.PaymentStatus) && Enum.TryParse<PaymentStatus>(request.PaymentStatus, true, out var paymentStatus))
        {
            query = query.Where(o => o.PaymentStatus == paymentStatus);
        }

        if (request.FromDate.HasValue)
        {
            query = query.Where(o => o.OrderDate >= request.FromDate.Value);
        }

        if (request.ToDate.HasValue)
        {
            query = query.Where(o => o.OrderDate <= request.ToDate.Value);
        }

        if (request.DeliveryDate.HasValue)
        {
            var date = request.DeliveryDate.Value.Date;
            query = query.Where(o => o.DeliveryDate.Date == date);
        }

        var total = await query.CountAsync();

        var items = await query
            .OrderByDescending(o => o.OrderDate)
            .Skip((request.Page - 1) * request.PageSize)
            .Take(request.PageSize)
            .Select(o => new OrderListDto
            {
                Id = o.Id,
                OrderNumber = o.OrderNumber,
                CustomerName = o.Customer!.Name,
                OrderDate = o.OrderDate,
                DeliveryDate = o.DeliveryDate,
                Status = o.Status.ToString(),
                PaymentStatus = o.PaymentStatus.ToString(),
                FulfillmentStatus = o.FulfillmentStatus.ToString(),
                OrderSource = o.OrderSource.ToString(),
                TotalAmount = o.TotalAmount,
                ItemCount = o.Items.Count,
                RecipientName = o.RecipientName,
                DeliveryPriority = o.DeliveryPriority.ToString()
            })
            .ToListAsync();

        return new PagedResult<OrderListDto>(items, total, request.Page, request.PageSize);
    }

    public async Task<List<OrderListDto>> GetTodaysOrdersAsync(Guid companyId, Guid? locationId = null)
    {
        var today = DateTime.UtcNow.Date;
        var query = _db.Orders.Where(o => o.CompanyId == companyId && o.IsActive && o.OrderDate.Date == today);

        return await query
            .OrderByDescending(o => o.OrderDate)
            .Select(o => new OrderListDto
            {
                Id = o.Id,
                OrderNumber = o.OrderNumber,
                CustomerName = o.Customer!.Name,
                OrderDate = o.OrderDate,
                DeliveryDate = o.DeliveryDate,
                Status = o.Status.ToString(),
                PaymentStatus = o.PaymentStatus.ToString(),
                FulfillmentStatus = o.FulfillmentStatus.ToString(),
                OrderSource = o.OrderSource.ToString(),
                TotalAmount = o.TotalAmount,
                ItemCount = o.Items.Count,
                RecipientName = o.RecipientName,
                DeliveryPriority = o.DeliveryPriority.ToString()
            })
            .ToListAsync();
    }

    public async Task<List<OrderListDto>> GetByDateAsync(Guid companyId, DateTime date)
    {
        return await _db.Orders
            .Where(o => o.CompanyId == companyId && o.IsActive && o.DeliveryDate.Date == date.Date)
            .OrderBy(o => o.DeliveryDate)
            .Select(o => new OrderListDto
            {
                Id = o.Id,
                OrderNumber = o.OrderNumber,
                CustomerName = o.Customer!.Name,
                OrderDate = o.OrderDate,
                DeliveryDate = o.DeliveryDate,
                Status = o.Status.ToString(),
                PaymentStatus = o.PaymentStatus.ToString(),
                FulfillmentStatus = o.FulfillmentStatus.ToString(),
                OrderSource = o.OrderSource.ToString(),
                TotalAmount = o.TotalAmount,
                ItemCount = o.Items.Count,
                RecipientName = o.RecipientName,
                DeliveryPriority = o.DeliveryPriority.ToString()
            })
            .ToListAsync();
    }

    public async Task<List<OrderListDto>> GetByCustomerAsync(Guid companyId, Guid customerId)
    {
        return await _db.Orders
            .Where(o => o.CompanyId == companyId && o.CustomerId == customerId)
            .OrderByDescending(o => o.OrderDate)
            .Select(o => new OrderListDto
            {
                Id = o.Id,
                OrderNumber = o.OrderNumber,
                CustomerName = o.Customer!.Name,
                OrderDate = o.OrderDate,
                DeliveryDate = o.DeliveryDate,
                Status = o.Status.ToString(),
                PaymentStatus = o.PaymentStatus.ToString(),
                FulfillmentStatus = o.FulfillmentStatus.ToString(),
                OrderSource = o.OrderSource.ToString(),
                TotalAmount = o.TotalAmount,
                ItemCount = o.Items.Count,
                RecipientName = o.RecipientName,
                DeliveryPriority = o.DeliveryPriority.ToString()
            })
            .ToListAsync();
    }

    public async Task AddAsync(Order order)
    {
        await _db.Orders.AddAsync(order);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(Order order)
    {
        _db.Orders.Update(order);
        await _db.SaveChangesAsync();
    }

    public async Task<string> GetNextOrderNumberAsync(Guid companyId)
    {
        var today = DateTime.UtcNow.Date;
        var prefix = $"ORD-{today:yyyyMMdd}-";
        
        var lastOrder = await _db.Orders
            .Where(o => o.CompanyId == companyId && o.OrderNumber.StartsWith(prefix))
            .OrderByDescending(o => o.OrderNumber)
            .FirstOrDefaultAsync();

        if (lastOrder == null)
        {
            return $"{prefix}0001";
        }

        var lastNum = int.Parse(lastOrder.OrderNumber.Replace(prefix, ""));
        return $"{prefix}{(lastNum + 1):D4}";
    }

    public async Task<int> GetTodaysOrderCountAsync(Guid companyId)
    {
        var today = DateTime.UtcNow.Date;
        return await _db.Orders
            .CountAsync(o => o.CompanyId == companyId && o.IsActive && o.OrderDate.Date == today);
    }

    public async Task<decimal> GetTodaysSalesAsync(Guid companyId)
    {
        var today = DateTime.UtcNow.Date;
        return await _db.Orders
            .Where(o => o.CompanyId == companyId && o.IsActive && o.OrderDate.Date == today)
            .SumAsync(o => o.TotalAmount);
    }

    public async Task<int> GetPendingDeliveriesCountAsync(Guid companyId, DateTime date)
    {
        return await _db.Orders
            .CountAsync(o => o.CompanyId == companyId && 
                            o.IsActive && 
                            o.DeliveryDate.Date == date.Date &&
                            o.Status != OrderStatus.Delivered &&
                            o.Status != OrderStatus.Cancelled);
    }

    public async Task<int> GetOrderCountByStaffAsync(Guid companyId, Guid staffId, DateTime from, DateTime to)
    {
        return await _db.Orders
            .CountAsync(o => o.CompanyId == companyId &&
                            o.IsActive &&
                            o.AssignedToUserId == staffId &&
                            o.OrderDate >= from && o.OrderDate <= to);
    }

    public async Task<decimal> GetRevenueByCashierAsync(Guid companyId, Guid staffId, DateTime from, DateTime to)
    {
        return await _db.Orders
            .Where(o => o.CompanyId == companyId &&
                        o.IsActive &&
                        o.AssignedToUserId == staffId &&
                        o.OrderDate >= from && o.OrderDate <= to &&
                        o.Status != OrderStatus.Cancelled)
            .SumAsync(o => o.TotalAmount);
    }
}
