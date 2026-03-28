using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/admin/data-cleanup")]
[Authorize(Policy = PolicyNames.CompanyAdmin)]
public sealed class DataCleanupController : ControllerBase
{
    private readonly SumpoojDbContext _db;
    private readonly ITenantContext _tenantContext;

    public DataCleanupController(SumpoojDbContext db, ITenantContext tenantContext)
    {
        _db = db;
        _tenantContext = tenantContext;
    }

    private Guid CompanyId => _tenantContext.CompanyId
        ?? throw new UnauthorizedAccessException("Company context required");

    [HttpPost("incomplete-orders/preview")]
    public async Task<ActionResult<CleanupPreviewResponse>> PreviewIncompleteOrders(
        [FromBody] CleanupRequest? request,
        CancellationToken cancellationToken)
    {
        var targets = NormalizeOrderNumbers(request?.OrderNumbers);
        var candidates = await GetIncompleteOrdersAsync(CompanyId, targets, cancellationToken);

        var response = new CleanupPreviewResponse
        {
            TotalIncompleteOrders = candidates.Count,
            SelectedOrders = candidates.Count,
            TargetedOrderNumbers = targets.ToArray(),
            NotFoundOrderNumbers = targets
                .Where(t => !candidates.Any(c => string.Equals(c.OrderNumber, t, StringComparison.OrdinalIgnoreCase)))
                .ToArray(),
            Candidates = candidates,
        };

        return Ok(response);
    }

    [HttpPost("incomplete-orders/delete")]
    public async Task<ActionResult<CleanupDeleteResponse>> DeleteIncompleteOrders(
        [FromBody] CleanupRequest? request,
        CancellationToken cancellationToken)
    {
        var targets = NormalizeOrderNumbers(request?.OrderNumbers);
        var candidates = await GetIncompleteOrdersAsync(CompanyId, targets, cancellationToken);

        var response = new CleanupDeleteResponse
        {
            TotalIncompleteOrders = candidates.Count,
            SelectedOrders = candidates.Count,
            TargetedOrderNumbers = targets.ToArray(),
            NotFoundOrderNumbers = targets
                .Where(t => !candidates.Any(c => string.Equals(c.OrderNumber, t, StringComparison.OrdinalIgnoreCase)))
                .ToArray(),
            Candidates = candidates,
        };

        if (candidates.Count == 0)
        {
            return Ok(response);
        }

        var orderIds = candidates.Select(c => c.OrderId).ToArray();
        var orderNumbers = candidates.Select(c => c.OrderNumber).Distinct(StringComparer.OrdinalIgnoreCase).ToArray();

        await using var tx = await _db.Database.BeginTransactionAsync(cancellationToken);

        response.InventoryLedgersDeleted = await _db.InventoryLedgers
            .Where(l => l.CompanyId == CompanyId && orderNumbers.Contains(l.Reference))
            .ExecuteDeleteAsync(cancellationToken);

        response.JournalEntriesDeleted = await _db.JournalEntries
            .Where(j => j.CompanyId == CompanyId && orderNumbers.Contains(j.Reference))
            .ExecuteDeleteAsync(cancellationToken);

        response.PaymentTransactionsDeleted = await _db.PaymentTransactions
            .Where(pt => pt.OrderId.HasValue && orderIds.Contains(pt.OrderId.Value))
            .ExecuteDeleteAsync(cancellationToken);

        response.PaymentsDeleted = await _db.Payments
            .Where(p => orderIds.Contains(p.OrderId))
            .ExecuteDeleteAsync(cancellationToken);

        response.OrderItemsDeleted = await _db.OrderItems
            .Where(oi => orderIds.Contains(EF.Property<Guid>(oi, "OrderId")))
            .ExecuteDeleteAsync(cancellationToken);

        response.OrdersDeleted = await _db.Orders
            .Where(o => o.CompanyId == CompanyId && orderIds.Contains(o.Id))
            .ExecuteDeleteAsync(cancellationToken);

        await tx.CommitAsync(cancellationToken);

        return Ok(response);
    }

    private async Task<List<CleanupCandidateDto>> GetIncompleteOrdersAsync(
        Guid companyId,
        HashSet<string> targetOrderNumbers,
        CancellationToken cancellationToken)
    {
        var completedPaidOrders = await _db.Orders
            .AsNoTracking()
            .Where(o => o.CompanyId == companyId && o.Status == OrderStatus.Delivered && o.PaymentStatus == PaymentStatus.Paid)
            .Select(o => new OrderSnapshot
            {
                Id = o.Id,
                OrderNumber = o.OrderNumber,
                OrderDate = o.OrderDate,
                TotalAmount = o.TotalAmount,
            })
            .ToListAsync(cancellationToken);

        if (targetOrderNumbers.Count > 0)
        {
            completedPaidOrders = completedPaidOrders
                .Where(o => targetOrderNumbers.Contains(o.OrderNumber))
                .ToList();
        }

        if (completedPaidOrders.Count == 0)
        {
            return [];
        }

        var orderNumbers = completedPaidOrders
            .Select(o => o.OrderNumber)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToArray();

        var journalRollups = await _db.JournalEntries
            .AsNoTracking()
            .Where(j => j.CompanyId == companyId && orderNumbers.Contains(j.Reference))
            .GroupBy(j => j.Reference)
            .Select(g => new JournalRollup
            {
                OrderNumber = g.Key,
                PaymentEntries = g.Count(j => EF.Functions.ILike(j.Description, "%payment%")),
                RevenueEntries = g.Count(j => EF.Functions.ILike(j.Description, "%revenue%")),
                CogsEntries = g.Count(j => EF.Functions.ILike(j.Description, "%cogs%")),
                InventoryReductionEntries = g.Count(j => EF.Functions.ILike(j.Description, "%inventory reduction%")),
            })
            .ToListAsync(cancellationToken);

        var rollupByOrder = journalRollups.ToDictionary(
            x => x.OrderNumber,
            x => x,
            StringComparer.OrdinalIgnoreCase);

        var candidates = new List<CleanupCandidateDto>();

        foreach (var order in completedPaidOrders)
        {
            var rollup = rollupByOrder.GetValueOrDefault(order.OrderNumber);

            var paymentEntries = rollup?.PaymentEntries ?? 0;
            var revenueEntries = rollup?.RevenueEntries ?? 0;
            var cogsEntries = rollup?.CogsEntries ?? 0;
            var inventoryReductionEntries = rollup?.InventoryReductionEntries ?? 0;

            if (paymentEntries == 0 || revenueEntries == 0 || cogsEntries == 0 || inventoryReductionEntries == 0)
            {
                candidates.Add(new CleanupCandidateDto
                {
                    OrderId = order.Id,
                    OrderNumber = order.OrderNumber,
                    OrderDate = order.OrderDate,
                    TotalAmount = order.TotalAmount,
                    PaymentEntries = paymentEntries,
                    RevenueEntries = revenueEntries,
                    CogsEntries = cogsEntries,
                    InventoryReductionEntries = inventoryReductionEntries,
                });
            }
        }

        return candidates
            .OrderBy(x => x.OrderNumber)
            .ToList();
    }

    private static HashSet<string> NormalizeOrderNumbers(IEnumerable<string>? orderNumbers)
    {
        if (orderNumbers is null)
        {
            return new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        }

        return orderNumbers
            .SelectMany(static value => value.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
            .Where(static value => !string.IsNullOrWhiteSpace(value))
            .Select(static value => value.Trim())
            .ToHashSet(StringComparer.OrdinalIgnoreCase);
    }

    private sealed class OrderSnapshot
    {
        public Guid Id { get; init; }
        public string OrderNumber { get; init; } = string.Empty;
        public DateTime OrderDate { get; init; }
        public decimal TotalAmount { get; init; }
    }

    private sealed class JournalRollup
    {
        public string OrderNumber { get; init; } = string.Empty;
        public int PaymentEntries { get; init; }
        public int RevenueEntries { get; init; }
        public int CogsEntries { get; init; }
        public int InventoryReductionEntries { get; init; }
    }
}

public sealed class CleanupRequest
{
    public List<string>? OrderNumbers { get; init; }
}

public sealed class CleanupCandidateDto
{
    public Guid OrderId { get; init; }
    public string OrderNumber { get; init; } = string.Empty;
    public DateTime OrderDate { get; init; }
    public decimal TotalAmount { get; init; }
    public int PaymentEntries { get; init; }
    public int RevenueEntries { get; init; }
    public int CogsEntries { get; init; }
    public int InventoryReductionEntries { get; init; }
}

public class CleanupPreviewResponse
{
    public int TotalIncompleteOrders { get; init; }
    public int SelectedOrders { get; init; }
    public string[] TargetedOrderNumbers { get; init; } = [];
    public string[] NotFoundOrderNumbers { get; init; } = [];
    public IReadOnlyList<CleanupCandidateDto> Candidates { get; init; } = [];
}

public sealed class CleanupDeleteResponse : CleanupPreviewResponse
{
    public int InventoryLedgersDeleted { get; set; }
    public int JournalEntriesDeleted { get; set; }
    public int PaymentTransactionsDeleted { get; set; }
    public int PaymentsDeleted { get; set; }
    public int OrderItemsDeleted { get; set; }
    public int OrdersDeleted { get; set; }
}
