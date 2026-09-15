using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Accounting;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/accounting")]
[Authorize(Policy = "CompanyOnly")]
public class MobileFinanceController : ControllerBase
{
    private readonly SumpoojDbContext _db;
    private readonly ITenantContext _tenant;

    public MobileFinanceController(SumpoojDbContext db, ITenantContext tenant)
    {
        _db = db;
        _tenant = tenant;
    }

    private Guid CompanyId => _tenant.CompanyId
        ?? throw new UnauthorizedAccessException("Company context required");

    [HttpGet("expense-categories")]
    public async Task<IActionResult> GetCategories([FromQuery] string? group, [FromQuery] bool includeInactive = false)
    {
        var query = _db.ExpenseCategories.Where(c => c.CompanyId == CompanyId);
        if (!includeInactive) query = query.Where(c => c.IsActive);
        if (!string.IsNullOrWhiteSpace(group)) query = query.Where(c => c.GroupName == group);
        return Ok((await query.OrderBy(c => c.GroupName).ThenBy(c => c.Name).ToListAsync()).Select(ToDto));
    }

    [HttpGet("expense-categories/{id:guid}")]
    public async Task<IActionResult> GetCategory(Guid id)
    {
        var category = await _db.ExpenseCategories.FirstOrDefaultAsync(c => c.CompanyId == CompanyId && c.Id == id);
        return category == null ? NotFound() : Ok(ToDto(category));
    }

    [HttpPost("expense-categories")]
    public async Task<IActionResult> CreateCategory([FromBody] SaveExpenseCategoryRequest request)
    {
        var normalized = request.Name.Trim().ToLower();
        if (await _db.ExpenseCategories.AnyAsync(c => c.CompanyId == CompanyId && c.Name.ToLower() == normalized))
            return Conflict(new { message = "Expense category already exists." });
        try
        {
            var category = new ExpenseCategory(CompanyId, request.Name, request.Emoji, request.GroupName);
            _db.ExpenseCategories.Add(category);
            await _db.SaveChangesAsync();
            return CreatedAtAction(nameof(GetCategory), new { id = category.Id }, ToDto(category));
        }
        catch (InvalidOperationException ex) { return BadRequest(new { message = ex.Message }); }
    }

    [HttpPut("expense-categories/{id:guid}")]
    public async Task<IActionResult> UpdateCategory(Guid id, [FromBody] SaveExpenseCategoryRequest request)
    {
        var category = await _db.ExpenseCategories.FirstOrDefaultAsync(c => c.CompanyId == CompanyId && c.Id == id);
        if (category == null) return NotFound();
        try { category.Update(request.Name, request.Emoji, request.GroupName); }
        catch (InvalidOperationException ex) { return BadRequest(new { message = ex.Message }); }
        await _db.SaveChangesAsync();
        return Ok(ToDto(category));
    }

    [HttpPut("expense-categories/{id:guid}/deactivate")]
    public Task<IActionResult> DeactivateCategory(Guid id) => SetCategoryActive(id, false);

    [HttpPut("expense-categories/{id:guid}/reactivate")]
    public Task<IActionResult> ReactivateCategory(Guid id) => SetCategoryActive(id, true);

    private static DateTime ToCalendarDateUtc(DateTime date) =>
        DateTime.SpecifyKind(date.Date, DateTimeKind.Utc);

    private static DateTime ToBusinessDateUtc(DateTime date)
    {
        var utcValue = date.Kind switch
        {
            DateTimeKind.Unspecified => DateTime.SpecifyKind(date.Date, DateTimeKind.Utc),
            DateTimeKind.Local => date.ToUniversalTime(),
            _ => date
        };

        if (TimeZoneInfo.TryFindSystemTimeZoneById("Asia/Kolkata", out var tz) ||
            TimeZoneInfo.TryFindSystemTimeZoneById("India Standard Time", out tz))
        {
            var localDate = TimeZoneInfo.ConvertTimeFromUtc(utcValue, tz).Date;
            return DateTime.SpecifyKind(localDate, DateTimeKind.Utc);
        }

        return ToCalendarDateUtc(utcValue);
    }

    [HttpGet("opening-cash")]
    public async Task<IActionResult> GetOpeningCash([FromQuery] DateTime date)
    {
        var day = ToCalendarDateUtc(date);
        var entry = await _db.OpeningCashEntries.FirstOrDefaultAsync(o => o.CompanyId == CompanyId && o.Date == day);
        return entry == null ? NotFound() : Ok(ToDto(entry));
    }

    [HttpPost("opening-cash")]
    public async Task<IActionResult> CreateOpeningCash([FromBody] SaveOpeningCashRequest request)
    {
        var day = ToCalendarDateUtc(request.Date);
        if (await _db.OpeningCashEntries.AnyAsync(o => o.CompanyId == CompanyId && o.Date == day))
            return Conflict(new { message = "Opening cash already exists for this date." });
        try
        {
            var entry = new OpeningCash(CompanyId, day, request.Amount);
            _db.OpeningCashEntries.Add(entry);
            await _db.SaveChangesAsync();
            return Ok(ToDto(entry));
        }
        catch (InvalidOperationException ex) { return BadRequest(new { message = ex.Message }); }
    }

    [HttpPut("opening-cash/{id:guid}")]
    public async Task<IActionResult> UpdateOpeningCash(Guid id, [FromBody] SaveOpeningCashRequest request)
    {
        var entry = await _db.OpeningCashEntries.FirstOrDefaultAsync(o => o.CompanyId == CompanyId && o.Id == id);
        if (entry == null) return NotFound();
        if (await _db.CashBookEntries.AnyAsync(e => e.CompanyId == CompanyId && e.Date == entry.Date))
            return Conflict(new { message = "Opening cash cannot be changed after cash transactions exist." });
        try { entry.SetAmount(request.Amount); }
        catch (InvalidOperationException ex) { return BadRequest(new { message = ex.Message }); }
        await _db.SaveChangesAsync();
        return Ok(ToDto(entry));
    }

    [HttpGet("cash-book")]
    public async Task<IActionResult> GetCashBook([FromQuery] DateTime? date, [FromQuery] DateTime? from,
        [FromQuery] DateTime? to, [FromQuery] string? query)
    {
        var targetDate = date.HasValue ? ToBusinessDateUtc(date.Value) : default;
        var fromDate = from.HasValue ? ToBusinessDateUtc(from.Value) : targetDate;
        var toDate = to.HasValue ? ToBusinessDateUtc(to.Value) : targetDate;

        if (date.HasValue)
        {
            var nextDay = targetDate.AddDays(1);
            var unlinkedPayments = await _db.Payments
                .Where(p => p.CompanyId == CompanyId &&
                            p.CreatedAtUtc >= targetDate && p.CreatedAtUtc < nextDay &&
                            p.Method == PaymentMethod.Cash &&
                            p.Status == PaymentTransactionStatus.Approved)
                .ToListAsync();

            if (unlinkedPayments.Count > 0)
            {
                var existingDesc = await _db.CashBookEntries
                    .Where(e => e.CompanyId == CompanyId && e.Date == targetDate)
                    .Select(e => e.Description)
                    .ToListAsync();

                bool addedAny = false;
                foreach (var payment in unlinkedPayments)
                {
                    var paymentIdStr = payment.Id.ToString();
                    if (!existingDesc.Any(d => d.Contains(paymentIdStr)))
                    {
                        var order = await _db.Orders.AsNoTracking().FirstOrDefaultAsync(o => o.Id == payment.OrderId);
                        var orderNo = order?.OrderNumber ?? payment.OrderId.ToString();
                        if (existingDesc.Any(d => d.Contains(orderNo)))
                            continue;

                        var currentBal = await _db.CashBookEntries
                            .Where(e => e.CompanyId == CompanyId && e.Date == targetDate)
                            .OrderByDescending(e => e.CreatedAtUtc)
                            .Select(e => (decimal?)e.RunningBalance)
                            .FirstOrDefaultAsync() ?? 0m;

                        var newEntry = new CashBookEntry(
                            CompanyId,
                            targetDate,
                            CashBookTransactionType.CashSale,
                            $"Cash payment for order {orderNo} [{payment.Id}]",
                            payment.Amount,
                            payment.Amount,
                            0m,
                            currentBal + payment.Amount);
                        _db.CashBookEntries.Add(newEntry);
                        addedAny = true;
                    }
                }
                if (addedAny)
                {
                    await _db.SaveChangesAsync();
                }
            }
        }

        var entries = _db.CashBookEntries.Where(e => e.CompanyId == CompanyId);
        if (date.HasValue)
        {
            entries = entries.Where(e => e.Date == targetDate);
        }
        else
        {
            if (from.HasValue) entries = entries.Where(e => e.Date >= fromDate);
            if (to.HasValue) entries = entries.Where(e => e.Date <= toDate);
        }
        if (!string.IsNullOrWhiteSpace(query))
        {
            var trimmed = query.Trim().ToLower();
            entries = entries.Where(e => e.Description.ToLower().Contains(trimmed));
        }
        return Ok((await entries.OrderBy(e => e.CreatedAtUtc).ToListAsync()).Select(ToDto));
    }

    [HttpGet("cash-book/balance")]
    public async Task<IActionResult> GetCashBookBalance([FromQuery] DateTime date)
    {
        var day = ToCalendarDateUtc(date);
        var balance = await _db.CashBookEntries.Where(e => e.CompanyId == CompanyId && e.Date == day)
            .OrderByDescending(e => e.CreatedAtUtc).Select(e => (decimal?)e.RunningBalance).FirstOrDefaultAsync() ?? 0;
        return Ok(new { balance });
    }

    [HttpGet("expense-summary")]
    public async Task<IActionResult> GetExpenseSummary([FromQuery] DateTime? date, [FromQuery] DateTime? from, [FromQuery] DateTime? to)
    {
        var providedDate = date.HasValue ? ToBusinessDateUtc(date.Value) : (DateTime?)null;
        var providedFrom = from.HasValue ? ToBusinessDateUtc(from.Value) : (DateTime?)null;
        var providedTo = to.HasValue ? ToBusinessDateUtc(to.Value) : (DateTime?)null;

        var businessFromDate = providedDate ?? providedFrom ?? Sumpooj.API.Services.Mobile.PosSaleSyncService.GetServerLocalBusinessDate();
        var businessToDate = providedDate ?? providedTo ?? businessFromDate;

        var (utcFromStart, utcToEnd) = GetUtcRangeForBusinessDates(businessFromDate, businessToDate);
        if (utcToEnd < utcFromStart)
        {
            (utcFromStart, utcToEnd) = (utcToEnd, utcFromStart);
        }

        var expenses = await _db.Expenses
            .AsNoTracking()
            .Where(e =>
                e.CompanyId == CompanyId &&
                e.IsActive &&
                e.ExpenseDate >= utcFromStart &&
                e.ExpenseDate <= utcToEnd)
            .ToListAsync();

        var summary = new ExpenseSummaryDto
        {
            TotalAmount = expenses.Sum(e => e.Amount),
            CashAmount = expenses.Where(e => e.PaymentMode == ExpensePaymentMode.Cash).Sum(e => e.Amount),
            UpiAmount = expenses.Where(e => e.PaymentMode == ExpensePaymentMode.Upi).Sum(e => e.Amount),
            CardAmount = expenses.Where(e => e.PaymentMode == ExpensePaymentMode.Card).Sum(e => e.Amount),
            ExpenseCount = expenses.Count,
        };

        return Ok(summary);
    }

    [HttpGet("top-customers")]
    public async Task<IActionResult> GetTopCustomers(
        [FromQuery] DateTime? date,
        [FromQuery] DateTime? from,
        [FromQuery] DateTime? to,
        [FromQuery] int limit = 10)
    {
        var providedDate = date.HasValue ? ToBusinessDateUtc(date.Value) : (DateTime?)null;
        var providedFrom = from.HasValue ? ToBusinessDateUtc(from.Value) : (DateTime?)null;
        var providedTo = to.HasValue ? ToBusinessDateUtc(to.Value) : (DateTime?)null;
        var businessFromDate = providedDate ?? providedFrom ?? Sumpooj.API.Services.Mobile.PosSaleSyncService.GetServerLocalBusinessDate();
        var businessToDate = providedDate ?? providedTo ?? businessFromDate;
        var (utcFromStart, utcToEnd) = GetUtcRangeForBusinessDates(businessFromDate, businessToDate);
        if (utcToEnd < utcFromStart)
        {
            (utcFromStart, utcToEnd) = (utcToEnd, utcFromStart);
        }

        var includedStatuses = new[]
        {
            OrderStatus.Confirmed,
            OrderStatus.Processing,
            OrderStatus.ReadyForDelivery,
            OrderStatus.OutForDelivery,
            OrderStatus.Delivered,
        };
        var resultLimit = Math.Clamp(limit, 1, 100);

        var customers = await (
                from order in _db.Orders.AsNoTracking()
                join customer in _db.Customers.AsNoTracking() on order.CustomerId equals customer.Id
                where order.CompanyId == CompanyId &&
                      customer.CompanyId == CompanyId &&
                      order.IsActive &&
                      customer.IsActive &&
                      includedStatuses.Contains(order.Status) &&
                      order.CreatedAtUtc >= utcFromStart &&
                      order.CreatedAtUtc <= utcToEnd
                group order by new { customer.Id, customer.Name } into orders
                select new TopCustomerDto
                {
                    CustomerId = orders.Key.Id,
                    CustomerName = orders.Key.Name,
                    TotalAmount = orders.Sum(order => order.TotalAmount),
                    OrderCount = orders.Count(),
                })
            .OrderByDescending(customer => customer.TotalAmount)
            .ThenByDescending(customer => customer.OrderCount)
            .ThenBy(customer => customer.CustomerName.ToLower())
            .Take(resultLimit)
            .ToListAsync();

        return Ok(customers);
    }

    [HttpGet("rewards-summary")]
    public async Task<IActionResult> GetRewardsSummary()
    {
        var customerTotals = await _db.Customers
            .AsNoTracking()
            .Where(customer => customer.CompanyId == CompanyId && customer.IsActive)
            .GroupBy(_ => 1)
            .Select(customers => new
            {
                CurrentPoints = customers.Sum(customer => customer.RewardPoints),
                LifetimePoints = customers.Sum(customer => customer.LifetimeRewardPoints),
                RedeemedPoints = customers.Sum(customer => customer.RedeemedRewardPoints),
            })
            .FirstOrDefaultAsync();

        var orderTotals = await _db.Orders
            .AsNoTracking()
            .Where(order =>
                order.CompanyId == CompanyId &&
                order.IsActive &&
                (order.RewardPointsRedeemed > 0 || order.RewardPointsEarned > 0))
            .GroupBy(_ => 1)
            .Select(orders => new
            {
                RewardOrders = orders.Count(),
                DiscountAmount = orders.Sum(order => order.RewardDiscountAmount),
            })
            .FirstOrDefaultAsync();

        var customers = await _db.Customers
            .AsNoTracking()
            .Where(customer =>
                customer.CompanyId == CompanyId &&
                customer.IsActive &&
                (customer.RewardPoints > 0 ||
                 customer.LifetimeRewardPoints > 0 ||
                 customer.RedeemedRewardPoints > 0))
            .OrderByDescending(customer => customer.RewardPoints)
            .ThenByDescending(customer => customer.LifetimeRewardPoints)
            .Take(25)
            .Select(customer => new RewardCustomerDto
            {
                CustomerId = customer.Id,
                CustomerName = customer.Name,
                Phone = customer.Phone,
                RewardPoints = customer.RewardPoints,
                LifetimeRewardPoints = customer.LifetimeRewardPoints,
                RedeemedRewardPoints = customer.RedeemedRewardPoints,
                LastRewardActivityAtUtc = customer.LastRewardActivityAtUtc,
            })
            .ToListAsync();

        return Ok(new RewardsReportDto
        {
            CurrentPoints = customerTotals?.CurrentPoints ?? 0,
            LifetimePoints = customerTotals?.LifetimePoints ?? 0,
            RedeemedPoints = customerTotals?.RedeemedPoints ?? 0,
            RewardOrders = orderTotals?.RewardOrders ?? 0,
            DiscountAmount = orderTotals?.DiscountAmount ?? 0m,
            Customers = customers,
        });
    }

    [HttpGet("top-products")]
    public async Task<IActionResult> GetTopProducts(
        [FromQuery] DateTime? date,
        [FromQuery] DateTime? from,
        [FromQuery] DateTime? to,
        [FromQuery] int limit = 10)
    {
        var providedDate = date.HasValue ? ToBusinessDateUtc(date.Value) : (DateTime?)null;
        var providedFrom = from.HasValue ? ToBusinessDateUtc(from.Value) : (DateTime?)null;
        var providedTo = to.HasValue ? ToBusinessDateUtc(to.Value) : (DateTime?)null;
        var businessFromDate = providedDate ?? providedFrom ?? Sumpooj.API.Services.Mobile.PosSaleSyncService.GetServerLocalBusinessDate();
        var businessToDate = providedDate ?? providedTo ?? businessFromDate;
        var (utcFromStart, utcToEnd) = GetUtcRangeForBusinessDates(businessFromDate, businessToDate);
        if (utcToEnd < utcFromStart)
        {
            (utcFromStart, utcToEnd) = (utcToEnd, utcFromStart);
        }

        var resultLimit = Math.Clamp(limit, 1, 100);
        var products = await (
                from order in _db.Orders.AsNoTracking()
                from item in order.Items
                join product in _db.Products.AsNoTracking() on item.ProductId equals product.Id
                where order.CompanyId == CompanyId &&
                      product.CompanyId == CompanyId &&
                      order.IsActive &&
                      product.IsActive &&
                      order.CreatedAtUtc >= utcFromStart &&
                      order.CreatedAtUtc <= utcToEnd
                group item by new { product.Id, product.Name } into items
                select new TopProductDto
                {
                    ProductId = items.Key.Id,
                    ProductName = items.Key.Name,
                    QuantitySold = items.Sum(item => item.Quantity),
                    TotalRevenue = items.Sum(item => item.TotalPrice),
                })
            .OrderByDescending(product => product.TotalRevenue)
            .Take(resultLimit)
            .ToListAsync();

        return Ok(products);
    }

    // Mirrors MobileDashboardController's boundary conversion: ExpenseDate is a full
    // timestamp (not a per-day column like CashBookEntry.Date), so the IST business
    // day must be converted to a UTC start/end range rather than compared for equality.
    private static (DateTime utcStart, DateTime utcEnd) GetUtcRangeForBusinessDates(DateTime businessDateFrom, DateTime businessDateTo)
    {
        if (TimeZoneInfo.TryFindSystemTimeZoneById("Asia/Kolkata", out var tz) ||
            TimeZoneInfo.TryFindSystemTimeZoneById("India Standard Time", out tz))
        {
            var istFromMidnight = new DateTime(businessDateFrom.Year, businessDateFrom.Month, businessDateFrom.Day, 0, 0, 0);
            var istToMidnight = new DateTime(businessDateTo.Year, businessDateTo.Month, businessDateTo.Day).AddDays(1).AddTicks(-1);

            var utcStart = TimeZoneInfo.ConvertTimeToUtc(istFromMidnight, tz);
            var utcEnd = TimeZoneInfo.ConvertTimeToUtc(istToMidnight, tz);

            return (utcStart, utcEnd);
        }

        return (
            DateTime.SpecifyKind(businessDateFrom.Date, DateTimeKind.Utc),
            DateTime.SpecifyKind(businessDateTo.Date.AddDays(1).AddTicks(-1), DateTimeKind.Utc)
        );
    }

    [HttpPost("cash-book")]
    public async Task<IActionResult> CreateCashBookEntry([FromBody] CreateCashBookEntryRequest request)
    {
        if (!Enum.TryParse<CashBookTransactionType>(request.TransactionType, true, out var type))
            return BadRequest(new { message = "Invalid cash-book transaction type." });
        var day = ToCalendarDateUtc(request.Date);
        var current = await _db.CashBookEntries.Where(e => e.CompanyId == CompanyId && e.Date == day)
            .OrderByDescending(e => e.CreatedAtUtc).Select(e => (decimal?)e.RunningBalance).FirstOrDefaultAsync() ?? 0;
        try
        {
            var entry = new CashBookEntry(CompanyId, day, type, request.Description, request.Amount,
                request.CashIn, request.CashOut, current + request.CashIn - request.CashOut);
            _db.CashBookEntries.Add(entry);
            await _db.SaveChangesAsync();
            return Ok(ToDto(entry));
        }
        catch (InvalidOperationException ex) { return BadRequest(new { message = ex.Message }); }
    }

    [HttpDelete("cash-book/{id:guid}")]
    public async Task<IActionResult> DeleteCashBookEntry(Guid id)
    {
        var entry = await _db.CashBookEntries.FirstOrDefaultAsync(e => e.CompanyId == CompanyId && e.Id == id);
        if (entry == null) return NotFound();
        _db.CashBookEntries.Remove(entry);
        await _db.SaveChangesAsync();
        return NoContent();
    }

    private async Task<IActionResult> SetCategoryActive(Guid id, bool active)
    {
        var category = await _db.ExpenseCategories.FirstOrDefaultAsync(c => c.CompanyId == CompanyId && c.Id == id);
        if (category == null) return NotFound();
        if (active) category.Reactivate(); else category.Deactivate();
        await _db.SaveChangesAsync();
        return NoContent();
    }

    private static ExpenseCategoryDto ToDto(ExpenseCategory category) => new()
    {
        Id = category.Id, Name = category.Name, Emoji = category.Emoji, GroupName = category.GroupName,
        Active = category.IsActive, CreatedAtUtc = category.CreatedAtUtc, UpdatedAtUtc = category.UpdatedAtUtc
    };

    private static OpeningCashDto ToDto(OpeningCash entry) => new()
    {
        Id = entry.Id, Date = entry.Date.ToString("yyyy-MM-dd"), Amount = entry.Amount,
        CreatedAtUtc = entry.CreatedAtUtc, UpdatedAtUtc = entry.UpdatedAtUtc
    };

    private static CashBookEntryDto ToDto(CashBookEntry entry) => new()
    {
        Id = entry.Id, Date = entry.Date.ToString("yyyy-MM-dd"), TransactionType = entry.TransactionType.ToString(),
        Description = entry.Description, Amount = entry.Amount, CashIn = entry.CashIn, CashOut = entry.CashOut,
        RunningBalance = entry.RunningBalance, CreatedAtUtc = entry.CreatedAtUtc
    };
}