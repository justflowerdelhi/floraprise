using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Common;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/crm")]
[Authorize(Policy = PolicyNames.CompanyOnly)]
public class CrmController : ControllerBase
{
    private readonly SumpoojDbContext _db;
    private readonly ITenantContext _tenantContext;

    public CrmController(SumpoojDbContext db, ITenantContext tenantContext)
    {
        _db = db;
        _tenantContext = tenantContext;
    }

    private Guid CompanyId => _tenantContext.CompanyId
        ?? throw new UnauthorizedAccessException("Company context required");

    [HttpGet("customers")]
    public async Task<IActionResult> GetCustomers([FromQuery] CrmCustomerListRequest request)
    {
        var page = request.Page <= 0 ? 1 : request.Page;
        var pageSize = request.PageSize <= 0 ? 50 : Math.Min(request.PageSize, 500);

        var query = _db.Customers
            .AsNoTracking()
            .Where(c => c.CompanyId == CompanyId && c.IsActive);

        if (!string.IsNullOrWhiteSpace(request.Query))
        {
            var search = request.Query.Trim().ToLower();
            query = query.Where(c =>
                c.Name.ToLower().Contains(search) ||
                (c.Phone != null && c.Phone.ToLower().Contains(search)) ||
                (c.Email != null && c.Email.ToLower().Contains(search)));
        }

        var totalCount = await query.CountAsync();

        var customers = await query
            .OrderByDescending(c => c.CreatedAtUtc)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(c => new CustomerListProjection(
                c.Id,
                c.CompanyId,
                c.Name,
                c.Phone,
                c.Email,
                c.Notes,
                c.CreatedAtUtc))
            .ToListAsync();

        var customerIds = customers.Select(c => c.Id).ToList();
        var orderMetrics = await GetOrderMetricsAsync(customerIds);
        var eventMatches = await GetCustomerEventMatchesAsync(customers);

        var items = customers
            .Select(customer =>
            {
                var metrics = orderMetrics.GetValueOrDefault(customer.Id) ?? CustomerMetrics.Empty;
                var matchingEvents = eventMatches.GetValueOrDefault(customer.Id) ?? [];
                return ToCrmCustomerDto(customer, metrics, matchingEvents);
            })
            .ToList();

        return Ok(new PagedResult<CrmCustomerDto>(items, totalCount, page, pageSize));
    }

    [HttpGet("customers/{id:guid}")]
    public async Task<IActionResult> GetCustomer360(Guid id)
    {
        var customer = await _db.Customers
            .AsNoTracking()
            .Where(c => c.CompanyId == CompanyId && c.IsActive && c.Id == id)
            .Select(c => new CustomerListProjection(
                c.Id,
                c.CompanyId,
                c.Name,
                c.Phone,
                c.Email,
                c.Notes,
                c.CreatedAtUtc))
            .FirstOrDefaultAsync();

        if (customer == null)
            return NotFound();

        var orderMetrics = await GetOrderMetricsAsync([customer.Id]);
        var metrics = orderMetrics.GetValueOrDefault(customer.Id) ?? CustomerMetrics.Empty;
        var matchingEvents = await GetCustomerEventsAsync(customer);

        var orders = await _db.Orders
            .AsNoTracking()
            .Where(o => o.CompanyId == CompanyId && o.CustomerId == customer.Id && o.IsActive)
            .OrderByDescending(o => o.OrderDate)
            .Select(o => new CrmCustomerOrderDto(
                o.Id,
                o.OrderNumber,
                o.OrderDate,
                o.OrderSource.ToString().ToUpperInvariant(),
                o.FulfillmentStatus.ToString().ToUpperInvariant(),
                o.PaymentStatus.ToString().ToUpperInvariant(),
                o.TotalAmount,
                0m,
                o.Items.Count))
            .ToListAsync();

        var loyaltyTransactions = BuildLoyaltyTransactions(customer.Id, orders);
        var crmCustomer = ToCrmCustomerDto(customer, metrics, matchingEvents);
        var eventDtos = matchingEvents
            .OrderByDescending(e => e.EventDate)
            .Select(e => new CrmCustomerEventDto(
                e.Id,
                e.EventName,
                e.EventType.ToString().ToUpperInvariant(),
                e.EventDate,
                e.Status.ToString().ToUpperInvariant(),
                e.TotalProposedAmount,
                e.TotalPaidAmount))
            .ToList();

        return Ok(new CrmCustomer360Response(crmCustomer, orders, eventDtos, loyaltyTransactions));
    }

    [HttpGet("reminders")]
    public async Task<IActionResult> GetReminders()
    {
        var customers = await _db.Customers
            .AsNoTracking()
            .Where(c => c.CompanyId == CompanyId && c.IsActive)
            .Select(c => new CustomerListProjection(
                c.Id,
                c.CompanyId,
                c.Name,
                c.Phone,
                c.Email,
                c.Notes,
                c.CreatedAtUtc))
            .ToListAsync();

        var customerIds = customers.Select(c => c.Id).ToList();
        var orderMetrics = await GetOrderMetricsAsync(customerIds);
        var allEvents = await _db.Events
            .AsNoTracking()
            .Where(e => e.CompanyId == CompanyId && e.IsActive)
            .ToListAsync();

        var now = DateTime.UtcNow;
        var reminders = new List<CrmReminderDto>();

        foreach (var customer in customers)
        {
            var metrics = orderMetrics.GetValueOrDefault(customer.Id) ?? CustomerMetrics.Empty;
            var daysSinceLastOrder = metrics.LastOrderDate.HasValue
                ? (int)(now.Date - metrics.LastOrderDate.Value.Date).TotalDays
                : (int?)null;
            var lifetimeValue = metrics.LifetimeValue;

            if (daysSinceLastOrder is > 90)
            {
                reminders.Add(new CrmReminderDto(
                    $"reengagement-{customer.Id}",
                    "RE_ENGAGEMENT",
                    "URGENT",
                    customer.Id,
                    customer.Name,
                    customer.Phone ?? string.Empty,
                    "Re-engage inactive customer",
                    $"{customer.Name} has not placed an order in {daysSinceLastOrder} days.",
                    now.Date,
                    false,
                    now));
            }
            else if (daysSinceLastOrder is > 60)
            {
                reminders.Add(new CrmReminderDto(
                    $"atrisk-{customer.Id}",
                    "AT_RISK",
                    "HIGH",
                    customer.Id,
                    customer.Name,
                    customer.Phone ?? string.Empty,
                    "Customer at risk",
                    $"{customer.Name} has not ordered in {daysSinceLastOrder} days.",
                    now.Date,
                    false,
                    now));
            }

            if (lifetimeValue >= 50000m && daysSinceLastOrder is > 30)
            {
                reminders.Add(new CrmReminderDto(
                    $"vip-{customer.Id}",
                    "VIP_FOLLOWUP",
                    "HIGH",
                    customer.Id,
                    customer.Name,
                    customer.Phone ?? string.Empty,
                    "VIP follow-up",
                    $"High-value customer {customer.Name} has been inactive for {daysSinceLastOrder} days.",
                    now.Date,
                    false,
                    now));
            }

            var recentCompletedEvent = allEvents
                .Where(e => IsEventMatch(customer, e) && e.Status == EventStatus.Completed)
                .OrderByDescending(e => e.EventDate)
                .FirstOrDefault();

            if (recentCompletedEvent != null)
            {
                var daysSinceEvent = (now.Date - recentCompletedEvent.EventDate.Date).TotalDays;
                if (daysSinceEvent >= 0 && daysSinceEvent <= 7)
                {
                    reminders.Add(new CrmReminderDto(
                        $"event-followup-{recentCompletedEvent.Id}",
                        "EVENT_FOLLOWUP",
                        "MEDIUM",
                        customer.Id,
                        customer.Name,
                        customer.Phone ?? string.Empty,
                        "Follow up after event",
                        $"Check in with {customer.Name} after event '{recentCompletedEvent.EventName}'.",
                        recentCompletedEvent.EventDate.Date.AddDays(2),
                        false,
                        now));
                }
            }
        }

        return Ok(reminders
            .OrderByDescending(r => PriorityRank(r.Priority))
            .ThenBy(r => r.DueDate)
            .ToList());
    }

    private async Task<Dictionary<Guid, CustomerMetrics>> GetOrderMetricsAsync(List<Guid> customerIds)
    {
        if (customerIds.Count == 0)
            return [];

        var metrics = await _db.Orders
            .AsNoTracking()
            .Where(o => o.CompanyId == CompanyId && o.IsActive && customerIds.Contains(o.CustomerId))
            .GroupBy(o => o.CustomerId)
            .Select(g => new CustomerMetrics(
                g.Key,
                g.Count(),
                g.Sum(x => x.TotalAmount),
                g.Min(x => x.OrderDate),
                g.Max(x => x.OrderDate)))
            .ToListAsync();

        return metrics.ToDictionary(x => x.CustomerId);
    }

    private async Task<Dictionary<Guid, List<Event>>> GetCustomerEventMatchesAsync(List<CustomerListProjection> customers)
    {
        if (customers.Count == 0)
            return [];

        var events = await _db.Events
            .AsNoTracking()
            .Where(e => e.CompanyId == CompanyId && e.IsActive)
            .ToListAsync();

        return customers.ToDictionary(
            customer => customer.Id,
            customer => events.Where(e => IsEventMatch(customer, e)).ToList());
    }

    private async Task<List<Event>> GetCustomerEventsAsync(CustomerListProjection customer)
    {
        var events = await _db.Events
            .AsNoTracking()
            .Where(e => e.CompanyId == CompanyId && e.IsActive)
            .ToListAsync();

        return events.Where(e => IsEventMatch(customer, e)).ToList();
    }

    private static bool IsEventMatch(CustomerListProjection customer, Event e)
    {
        var matchesPhone = !string.IsNullOrWhiteSpace(customer.Phone) && customer.Phone == e.ClientPhone;
        var matchesEmail = !string.IsNullOrWhiteSpace(customer.Email) && customer.Email == e.ClientEmail;
        var matchesName = customer.Name.Equals(e.ClientName, StringComparison.OrdinalIgnoreCase);
        return matchesPhone || matchesEmail || matchesName;
    }

    private static CrmCustomerDto ToCrmCustomerDto(
        CustomerListProjection customer,
        CustomerMetrics metrics,
        List<Event> matchingEvents)
    {
        var loyaltyPoints = CalculateLoyaltyPoints(metrics.LifetimeValue);
        var tags = BuildTags(customer, metrics, matchingEvents);
        var averageOrderValue = metrics.TotalOrders > 0
            ? decimal.Round(metrics.LifetimeValue / metrics.TotalOrders, 2)
            : 0m;

        return new CrmCustomerDto(
            customer.Id,
            customer.CompanyId,
            null,
            customer.Name,
            customer.Phone ?? string.Empty,
            customer.Email,
            null,
            customer.Notes,
            null,
            null,
            customer.CreatedAtUtc,
            tags,
            metrics.LifetimeValue,
            metrics.TotalOrders,
            averageOrderValue,
            metrics.LastOrderDate,
            metrics.FirstOrderDate,
            loyaltyPoints,
            GetLoyaltyTier(loyaltyPoints),
            loyaltyPoints,
            0,
            0m,
            0m,
            true,
            null,
            null,
            0);
    }

    private static List<CrmLoyaltyTransactionDto> BuildLoyaltyTransactions(Guid customerId, List<CrmCustomerOrderDto> orders)
    {
        var orderedAscending = orders
            .OrderBy(o => o.OrderDate)
            .ToList();

        var balance = 0;
        var transactions = new List<CrmLoyaltyTransactionDto>();
        foreach (var order in orderedAscending)
        {
            var points = CalculateLoyaltyPoints(order.Total);
            if (points <= 0)
                continue;

            balance += points;
            transactions.Add(new CrmLoyaltyTransactionDto(
                $"earn-{order.OrderId}",
                customerId,
                "EARN",
                points,
                balance,
                $"Earned from order {order.OrderNumber}",
                order.OrderId,
                order.OrderDate));
        }

        return transactions
            .OrderByDescending(t => t.CreatedAt)
            .ToList();
    }

    private static List<string> BuildTags(CustomerListProjection customer, CustomerMetrics metrics, List<Event> matchingEvents)
    {
        var tags = new List<string>();
        var now = DateTime.UtcNow;
        var daysSinceCreated = (now.Date - customer.CreatedAtUtc.Date).TotalDays;
        var daysSinceLastOrder = metrics.LastOrderDate.HasValue
            ? (now.Date - metrics.LastOrderDate.Value.Date).TotalDays
            : (double?)null;

        if (metrics.LifetimeValue >= 50000m) tags.Add("VIP");
        if (metrics.TotalOrders > 3) tags.Add("REPEAT_CUSTOMER");
        if (daysSinceCreated <= 30) tags.Add("NEW_CUSTOMER");
        if (daysSinceLastOrder is > 60 and <= 90) tags.Add("AT_RISK");
        if (daysSinceLastOrder is > 90) tags.Add("LOST");
        if (matchingEvents.Any(e => e.EventType == EventType.Wedding)) tags.Add("WEDDING_CLIENT");
        if (matchingEvents.Any(e => e.EventType == EventType.Corporate)) tags.Add("CORPORATE");

        return tags;
    }

    private static int CalculateLoyaltyPoints(decimal amount)
        => (int)Math.Floor(amount / 100m);

    private static string GetLoyaltyTier(int points)
        => points >= 2000 ? "PLATINUM" : points >= 500 ? "GOLD" : "SILVER";

    private static int PriorityRank(string priority)
        => priority switch
        {
            "URGENT" => 3,
            "HIGH" => 2,
            "MEDIUM" => 1,
            _ => 0,
        };
}

public sealed record CrmCustomerListRequest(string? Query, int Page = 1, int PageSize = 50);

public sealed record CrmCustomer360Response(
    CrmCustomerDto Customer,
    List<CrmCustomerOrderDto> Orders,
    List<CrmCustomerEventDto> Events,
    List<CrmLoyaltyTransactionDto> LoyaltyTransactions);

public sealed record CrmCustomerDto(
    Guid Id,
    Guid TenantId,
    Guid? LocationId,
    string Name,
    string Phone,
    string? Email,
    string? PreferredAddress,
    string? Notes,
    string? Birthday,
    string? Anniversary,
    DateTime CreatedAt,
    List<string> Tags,
    decimal LifetimeValue,
    int TotalOrders,
    decimal AverageOrderValue,
    DateTime? LastOrderDate,
    DateTime? FirstOrderDate,
    int LoyaltyPoints,
    string LoyaltyTier,
    int LoyaltyPointsEarned,
    int LoyaltyPointsRedeemed,
    decimal TotalProfit,
    decimal ProfitMargin,
    bool MarketingConsent,
    string? PreferredContactMethod,
    string? ReferredBy,
    int ReferralCount);

public sealed record CrmCustomerOrderDto(
    Guid OrderId,
    string OrderNumber,
    DateTime OrderDate,
    string OrderSource,
    string FulfillmentStatus,
    string PaymentStatus,
    decimal Total,
    decimal Profit,
    int Items);

public sealed record CrmCustomerEventDto(
    Guid EventId,
    string EventName,
    string EventType,
    DateTime EventDate,
    string Status,
    decimal EstimatedValue,
    decimal TotalPaid);

public sealed record CrmLoyaltyTransactionDto(
    string Id,
    Guid CustomerId,
    string Type,
    int Points,
    int Balance,
    string Description,
    Guid? OrderId,
    DateTime CreatedAt);

public sealed record CrmReminderDto(
    string Id,
    string Type,
    string Priority,
    Guid CustomerId,
    string CustomerName,
    string CustomerPhone,
    string Title,
    string Description,
    DateTime DueDate,
    bool Dismissed,
    DateTime CreatedAt);

public sealed record CustomerListProjection(
    Guid Id,
    Guid CompanyId,
    string Name,
    string? Phone,
    string? Email,
    string? Notes,
    DateTime CreatedAtUtc);

public sealed record CustomerMetrics(
    Guid CustomerId,
    int TotalOrders,
    decimal LifetimeValue,
    DateTime? FirstOrderDate,
    DateTime? LastOrderDate)
{
    public static CustomerMetrics Empty => new(Guid.Empty, 0, 0m, null, null);
}