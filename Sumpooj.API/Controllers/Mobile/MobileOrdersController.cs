using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Mobile;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.API.Controllers.Mobile;

[Route("api/v1/mobile/orders")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme, Policy = PolicyNames.CompanyOnly)]
public sealed class MobileOrdersController : MobileApiControllerBase
{
    private readonly SumpoojDbContext _db;

    public MobileOrdersController(SumpoojDbContext db, ITenantContext tenantContext)
        : base(tenantContext)
    {
        _db = db;
    }

    [HttpGet("status-report")]
    public async Task<IActionResult> GetStatusReport(
        [FromQuery] DateTime? fromDate,
        [FromQuery] DateTime? toDate,
        CancellationToken cancellationToken)
    {
        try
        {
            var companyId = GetCompanyId();
            var query = _db.Orders
                .AsNoTracking()
                .Where(o => o.CompanyId == companyId && o.IsActive);

            if (fromDate.HasValue)
            {
                var utcFrom = EnsureUtc(fromDate.Value);
                query = query.Where(o => o.OrderDate >= utcFrom);
            }

            if (toDate.HasValue)
            {
                var utcTo = EnsureUtc(toDate.Value);
                if (utcTo.TimeOfDay == TimeSpan.Zero)
                    utcTo = utcTo.AddDays(1).AddSeconds(-1);
                query = query.Where(o => o.OrderDate <= utcTo);
            }

            var orders = await query
                .Select(o => new
                {
                    o.Id,
                    o.Status,
                    o.DeliveryAddress,
                    o.TimeSlot,
                    o.DeliveryDate,
                    o.OrderDate
                })
                .ToListAsync(cancellationToken);

            if (orders.Count == 0)
            {
                return Ok(new MobileOrderStatusReportDto(
                    0, 0, 0, 0, 0, 0,
                    new MobileOrderFulfillmentCountsDto(0, 0, 0),
                    fromDate,
                    toDate));
            }

            var orderIds = orders.Select(o => o.Id).ToList();
            var deliveryOrderIds = await _db.Deliveries
                .AsNoTracking()
                .Where(d => d.CompanyId == companyId && orderIds.Contains(d.SalesOrderId))
                .Select(d => d.SalesOrderId)
                .Distinct()
                .ToHashSetAsync(cancellationToken);

            int pendingCount = 0;
            int inProgressCount = 0;
            int readyCount = 0;
            int completedCount = 0;
            int cancelledCount = 0;

            int deliveryCount = 0;
            int pickupCount = 0;
            int takeAwayCount = 0;

            foreach (var order in orders)
            {
                switch (order.Status)
                {
                    case OrderStatus.Pending:
                    case OrderStatus.AutoCreated:
                        pendingCount++;
                        break;
                    case OrderStatus.Confirmed:
                    case OrderStatus.Processing:
                        inProgressCount++;
                        break;
                    case OrderStatus.ReadyForDelivery:
                    case OrderStatus.OutForDelivery:
                        readyCount++;
                        break;
                    case OrderStatus.Delivered:
                        completedCount++;
                        break;
                    case OrderStatus.Cancelled:
                    case OrderStatus.Failed:
                        cancelledCount++;
                        break;
                    default:
                        inProgressCount++;
                        break;
                }

                var hasDelivery = deliveryOrderIds.Contains(order.Id) || !string.IsNullOrWhiteSpace(order.DeliveryAddress);
                if (hasDelivery)
                {
                    deliveryCount++;
                }
                else if (!string.IsNullOrWhiteSpace(order.TimeSlot) || order.DeliveryDate.Date > order.OrderDate.Date)
                {
                    pickupCount++;
                }
                else
                {
                    takeAwayCount++;
                }
            }

            var fulfillment = new MobileOrderFulfillmentCountsDto(deliveryCount, pickupCount, takeAwayCount);
            var report = new MobileOrderStatusReportDto(
                pendingCount,
                inProgressCount,
                readyCount,
                completedCount,
                cancelledCount,
                orders.Count,
                fulfillment,
                fromDate,
                toDate);

            return Ok(report);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    [HttpGet("workspace")]
    public async Task<IActionResult> Workspace([FromQuery] MobileOrderWorkspaceRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var companyId = GetCompanyId();
            var page = Math.Max(1, request.Page);
            var pageSize = Math.Clamp(request.PageSize, 1, 200);
            var query = _db.Orders
                .AsNoTracking()
                .Include(o => o.Customer)
                .Where(o => o.CompanyId == companyId && o.IsActive);

            if (!string.IsNullOrWhiteSpace(request.Query))
            {
                var term = request.Query.Trim().ToLowerInvariant();
                query = query.Where(o =>
                    o.OrderNumber.ToLower().Contains(term) ||
                    (o.Customer != null && o.Customer.Name.ToLower().Contains(term)) ||
                    (o.Customer != null && o.Customer.Phone != null && o.Customer.Phone.Contains(term)) ||
                    (o.RecipientName != null && o.RecipientName.ToLower().Contains(term)) ||
                    (o.RecipientPhone != null && o.RecipientPhone.Contains(term)));
            }

            if (!string.IsNullOrWhiteSpace(request.Status) && Enum.TryParse<OrderStatus>(NormalizePascal(request.Status), true, out var status))
                query = query.Where(o => o.Status == status);

            if (!string.IsNullOrWhiteSpace(request.PaymentStatus) && Enum.TryParse<PaymentStatus>(NormalizePascal(request.PaymentStatus), true, out var paymentStatus))
                query = query.Where(o => o.PaymentStatus == paymentStatus);

            if (request.FromDate.HasValue)
                query = query.Where(o => o.OrderDate >= EnsureUtc(request.FromDate.Value));

            if (request.ToDate.HasValue)
                query = query.Where(o => o.OrderDate <= EnsureUtc(request.ToDate.Value));

            if (request.DeliveryDate.HasValue)
            {
                var dayStart = EnsureUtc(request.DeliveryDate.Value.Date);
                var dayEnd = dayStart.AddDays(1);
                query = query.Where(o => o.DeliveryDate >= dayStart && o.DeliveryDate < dayEnd);
            }

            var totalCount = await query.CountAsync(cancellationToken);
            var orders = await query
                .OrderByDescending(o => o.DeliveryDate)
                .ThenByDescending(o => o.OrderDate)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync(cancellationToken);

            var helpers = await LoadHelpersAsync(companyId, orders, cancellationToken);
            var items = orders
                .Select(order => ToListItem(order, helpers))
                .Where(item => string.IsNullOrWhiteSpace(request.FulfilmentType) ||
                    string.Equals(item.FulfilmentType, NormalizeFulfilmentFilter(request.FulfilmentType), StringComparison.OrdinalIgnoreCase))
                .ToList();

            return Ok(new MobileOrderWorkspaceResponse(items, totalCount, page, pageSize));
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id, CancellationToken cancellationToken)
    {
        try
        {
            var detail = await LoadDetailAsync(GetCompanyId(), id, cancellationToken);
            return detail == null ? NotFound() : Ok(detail);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    [HttpGet("by-number/{orderNumber}")]
    public async Task<IActionResult> GetByOrderNumber(string orderNumber, CancellationToken cancellationToken)
    {
        try
        {
            var normalized = orderNumber.Trim();
            var companyId = GetCompanyId();
            var orderId = await _db.Orders
                .AsNoTracking()
                .Where(o => o.CompanyId == companyId && o.OrderNumber == normalized)
                .Select(o => (Guid?)o.Id)
                .FirstOrDefaultAsync(cancellationToken);
            if (orderId == null) return NotFound();

            var detail = await LoadDetailAsync(companyId, orderId.Value, cancellationToken);
            return detail == null ? NotFound() : Ok(detail);
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    private async Task<MobileOrderDetailDto?> LoadDetailAsync(Guid companyId, Guid orderId, CancellationToken cancellationToken)
    {
        var order = await _db.Orders
            .AsNoTracking()
            .Include(o => o.Customer)
            .Include(o => o.Location)
            .Include(o => o.Items)
            .FirstOrDefaultAsync(o => o.CompanyId == companyId && o.Id == orderId && o.IsActive, cancellationToken);
        if (order == null) return null;

        var helpers = await LoadHelpersAsync(companyId, new[] { order }, cancellationToken);
        var payments = helpers.PaymentsByOrder.GetValueOrDefault(order.Id, new List<Payment>());
        var delivery = helpers.DeliveriesByOrder.GetValueOrDefault(order.Id);
        var timeline = BuildTimeline(order, payments, delivery, helpers.DeliveryTimelineByDeliveryId.GetValueOrDefault(delivery?.Id ?? Guid.Empty, new List<DeliveryTimeline>()));
        var paidAmount = PaidAmount(payments);

        return new MobileOrderDetailDto(
            order.Id,
            order.OrderNumber,
            order.CustomerId,
            order.Customer?.Name ?? "Unknown",
            order.Customer?.Phone,
            order.RecipientName,
            order.RecipientPhone,
            NormalizedFulfilmentType(order, delivery),
            NormalizedStatus(order),
            order.PaymentStatus.ToString(),
            order.FulfillmentStatus.ToString(),
            order.OrderSource.ToString(),
            order.SubTotal,
            order.DeliveryFee,
            order.TaxAmount,
            order.DiscountAmount,
            order.TotalAmount,
            paidAmount,
            BalanceDue(order.TotalAmount, paidAmount),
            order.RewardPointsEarned,
            order.RewardPointsRedeemed,
            order.AssignedToUserId,
            order.AssignedDesignerStaffId,
            StaffName(order.AssignedDesignerStaffId ?? order.AssignedToUserId, helpers),
            order.DeliveryPersonId,
            StaffName(order.DeliveryPersonId ?? delivery?.DeliveryPersonId, helpers),
            order.LocationId,
            order.Location?.Name,
            order.OrderDate,
            order.DeliveryDate,
            order.DeliveryAddress,
            order.DeliveryPincode,
            order.CardMessage,
            order.TimeSlot,
            order.InternalNotes,
            order.Items.OrderBy(i => i.ProductName).Select(ToItemDto).ToList(),
            payments.OrderByDescending(p => p.CreatedAtUtc).Select(ToPaymentDto).ToList(),
            delivery == null ? null : ToDeliverySummary(delivery, helpers),
            timeline,
            order.CreatedAtUtc);
    }

    private async Task<MobileOrderHelpers> LoadHelpersAsync(Guid companyId, IReadOnlyCollection<Order> orders, CancellationToken cancellationToken)
    {
        var orderIds = orders.Select(o => o.Id).Distinct().ToList();
        var staffIds = orders
            .SelectMany(o => new[] { o.AssignedDesignerStaffId, o.AssignedToUserId, o.DeliveryPersonId })
            .Where(id => id.HasValue)
            .Select(id => id!.Value)
            .ToHashSet();

        var payments = await _db.Payments
            .AsNoTracking()
            .Where(p => p.CompanyId == companyId && orderIds.Contains(p.OrderId))
            .ToListAsync(cancellationToken);
        var deliveries = await _db.Deliveries
            .AsNoTracking()
            .Where(d => d.CompanyId == companyId && orderIds.Contains(d.SalesOrderId))
            .ToListAsync(cancellationToken);
        foreach (var delivery in deliveries)
        {
            if (delivery.DeliveryPersonId.HasValue) staffIds.Add(delivery.DeliveryPersonId.Value);
        }

        var staff = await _db.Staff
            .AsNoTracking()
            .Where(s => s.CompanyId == companyId &&
                (staffIds.Contains(s.Id) ||
                 (s.UserId.HasValue && staffIds.Contains(s.UserId.Value)) ||
                 (s.IdentityUserId.HasValue && staffIds.Contains(s.IdentityUserId.Value))))
            .ToListAsync(cancellationToken);
        var deliveryIds = deliveries.Select(d => d.Id).ToList();
        var deliveryTimeline = await _db.DeliveryTimelines
            .AsNoTracking()
            .Where(t => deliveryIds.Contains(t.DeliveryId))
            .ToListAsync(cancellationToken);

        return new MobileOrderHelpers(
            payments.GroupBy(p => p.OrderId).ToDictionary(g => g.Key, g => g.ToList()),
            deliveries.GroupBy(d => d.SalesOrderId).ToDictionary(g => g.Key, g => g.OrderByDescending(d => d.CreatedAtUtc).First()),
            staff.ToDictionary(s => s.Id),
            staff.Where(s => s.UserId.HasValue).ToDictionary(s => s.UserId!.Value),
            staff.Where(s => s.IdentityUserId.HasValue).ToDictionary(s => s.IdentityUserId!.Value),
            deliveryTimeline.GroupBy(t => t.DeliveryId).ToDictionary(g => g.Key, g => g.OrderByDescending(t => t.RecordedAt).ToList()));
    }

    private static MobileOrderListItemDto ToListItem(Order order, MobileOrderHelpers helpers)
    {
        var payments = helpers.PaymentsByOrder.GetValueOrDefault(order.Id, new List<Payment>());
        var paidAmount = PaidAmount(payments);
        var delivery = helpers.DeliveriesByOrder.GetValueOrDefault(order.Id);
        return new MobileOrderListItemDto(
            order.Id,
            order.OrderNumber,
            order.Customer?.Name ?? "Unknown",
            order.Customer?.Phone,
            order.RecipientName,
            order.RecipientPhone,
            NormalizedFulfilmentType(order, delivery),
            NormalizedStatus(order),
            order.PaymentStatus.ToString(),
            order.TotalAmount,
            paidAmount,
            BalanceDue(order.TotalAmount, paidAmount),
            order.OrderDate,
            order.DeliveryDate,
            StaffName(order.AssignedDesignerStaffId ?? order.AssignedToUserId, helpers),
            StaffName(order.DeliveryPersonId ?? delivery?.DeliveryPersonId, helpers));
    }

    private static MobileOrderItemDto ToItemDto(OrderItem item) => new(
        item.Id,
        item.ProductId,
        item.ProductName,
        item.Quantity,
        item.UnitPrice,
        item.TotalPrice,
        item.DiscountAmount,
        item.TaxRatePercent,
        item.LineSubtotal,
        item.LineTaxAmount,
        (item.LineSubtotal ?? item.TotalPrice) + (item.LineTaxAmount ?? 0),
        item.SpecialInstructions,
        item.ClientOrderLineId);

    private static MobileOrderPaymentDto ToPaymentDto(Payment payment) => new(
        payment.Id,
        payment.OrderId,
        payment.LocationId,
        payment.Method.ToString(),
        payment.Amount,
        payment.Status.ToString(),
        payment.Reference,
        payment.ClientPaymentId,
        payment.TransactionId,
        payment.CreatedAtUtc);

    private static MobileOrderDeliverySummaryDto ToDeliverySummary(Delivery delivery, MobileOrderHelpers helpers) => new(
        delivery.Id,
        delivery.Status.ToString(),
        delivery.DeliveryDate,
        delivery.TimeSlot,
        delivery.DeliveryAddress,
        delivery.PostalCode,
        delivery.DeliveryPersonId,
        StaffName(delivery.DeliveryPersonId, helpers),
        delivery.StartedAtUtc,
        delivery.CompletedAtUtc,
        delivery.LastLocationUtc);

    private static List<MobileOrderTimelineItemDto> BuildTimeline(Order order, List<Payment> payments, Delivery? delivery, List<DeliveryTimeline> deliveryTimeline)
    {
        var rows = new List<MobileOrderTimelineItemDto>
        {
            new("order", "created", null, order.CreatedAtUtc),
            new("order", NormalizedStatus(order), order.InternalNotes, order.UpdatedAtUtc ?? order.CreatedAtUtc)
        };
        rows.AddRange(payments.Select(p => new MobileOrderTimelineItemDto("payment", p.Status.ToString(), $"{p.Method} {p.Amount:0.##}", p.CreatedAtUtc)));
        if (delivery != null)
            rows.Add(new MobileOrderTimelineItemDto("delivery", delivery.Status.ToString(), null, delivery.UpdatedAtUtc ?? delivery.CreatedAtUtc));
        rows.AddRange(deliveryTimeline.Select(t => new MobileOrderTimelineItemDto("delivery", t.Status, t.Note, t.RecordedAt)));
        return rows.OrderByDescending(t => t.CreatedAtUtc).ToList();
    }

    private static decimal PaidAmount(IEnumerable<Payment> payments) => payments
        .Where(p => p.Status == PaymentTransactionStatus.Approved)
        .Sum(p => p.Amount);

    private static decimal BalanceDue(decimal totalAmount, decimal paidAmount) => Math.Max(0, totalAmount - paidAmount);

    private static string? StaffName(Guid? id, MobileOrderHelpers helpers)
    {
        if (!id.HasValue) return null;
        if (helpers.ById.TryGetValue(id.Value, out var staff)) return staff.Name;
        if (helpers.ByUserId.TryGetValue(id.Value, out staff)) return staff.Name;
        if (helpers.ByIdentityUserId.TryGetValue(id.Value, out staff)) return staff.Name;
        return null;
    }

    private static string NormalizedStatus(Order order) => order.Status switch
    {
        OrderStatus.Pending => "confirmed",
        OrderStatus.AutoCreated => "confirmed",
        OrderStatus.Confirmed => "confirmed",
        OrderStatus.Processing => "preparing",
        OrderStatus.ReadyForDelivery => "ready",
        OrderStatus.OutForDelivery => "out_for_delivery",
        OrderStatus.Delivered => "delivered",
        OrderStatus.Cancelled => "cancelled",
        _ => order.Status.ToString().ToLowerInvariant()
    };

    private static string NormalizedFulfilmentType(Order order, Delivery? delivery)
    {
        if (delivery != null || !string.IsNullOrWhiteSpace(order.DeliveryAddress)) return "delivery";
        if (!string.IsNullOrWhiteSpace(order.TimeSlot) || order.DeliveryDate.Date > order.OrderDate.Date) return "pickup_later";
        return "take_away";
    }

    private static string NormalizeFulfilmentFilter(string? value) => (value ?? string.Empty).Trim().ToLowerInvariant().Replace("-", "_");

    private static string NormalizePascal(string value) => string.Concat(value.Trim().Replace("-", "_").Split('_', StringSplitOptions.RemoveEmptyEntries).Select(part => char.ToUpperInvariant(part[0]) + part[1..].ToLowerInvariant()));

    private static DateTime EnsureUtc(DateTime value) => value.Kind == DateTimeKind.Utc ? value : DateTime.SpecifyKind(value, DateTimeKind.Utc);

    private sealed record MobileOrderHelpers(
        Dictionary<Guid, List<Payment>> PaymentsByOrder,
        Dictionary<Guid, Delivery> DeliveriesByOrder,
        Dictionary<Guid, Staff> ById,
        Dictionary<Guid, Staff> ByUserId,
        Dictionary<Guid, Staff> ByIdentityUserId,
        Dictionary<Guid, List<DeliveryTimeline>> DeliveryTimelineByDeliveryId);
}