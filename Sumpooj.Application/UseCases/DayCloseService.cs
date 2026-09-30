using Sumpooj.Application.DayClose;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.UseCases;

public class DayCloseService
{
    private readonly IDayCloseRepository _dayCloseRepository;
    private readonly IOrderRepository _orderRepository;
    private readonly IPaymentRepository _paymentRepository;
    private readonly ILocationRepository _locationRepository;
    private readonly ICashDrawerRepository _cashDrawerRepository;

    public DayCloseService(
        IDayCloseRepository dayCloseRepository,
        IOrderRepository orderRepository,
        IPaymentRepository paymentRepository,
        ILocationRepository locationRepository,
        ICashDrawerRepository cashDrawerRepository)
    {
        _dayCloseRepository = dayCloseRepository;
        _orderRepository = orderRepository;
        _paymentRepository = paymentRepository;
        _locationRepository = locationRepository;
        _cashDrawerRepository = cashDrawerRepository;
    }

    public async Task<DayCloseDto?> GetByIdAsync(Guid companyId, Guid id)
    {
        var dc = await _dayCloseRepository.GetByIdAsync(companyId, id);
        return dc == null ? null : MapToDto(dc);
    }

    public async Task<bool> IsDayClosedAsync(Guid companyId, Guid locationId, DateTime date)
    {
        return await _dayCloseRepository.IsDayClosedAsync(companyId, locationId, date);
    }

    public async Task<object> GetSummaryAsync(Guid companyId, Guid locationId, DateTime date)
    {
        var allOrders = await _orderRepository.GetByDateAsync(companyId, date);

        // Filter by location if provided (Guid.Empty = all locations)
        // Include orders with no location (phone orders) in all-location view
        var orders = locationId != Guid.Empty
            ? allOrders.Where(o => o.LocationId == locationId || o.LocationId == null).ToList()
            : allOrders;

        var totalOrders = orders.Count;
        var totalSales = orders.Sum(o => o.TotalAmount);

        var walkInOrders = orders.Count(o => o.OrderSource == "WALK_IN" || o.OrderSource == "WalkIn");
        var phoneOrders = orders.Count(o => o.OrderSource == "PHONE" || o.OrderSource == "Phone");
        var onlineOrders = orders.Count(o => o.OrderSource == "WEBSITE" || o.OrderSource == "Online");

        var walkInSales = orders
            .Where(o => o.OrderSource == "WALK_IN" || o.OrderSource == "WalkIn")
            .Sum(o => o.TotalAmount);

        var phoneOrdersAmount = orders
            .Where(o => o.OrderSource == "PHONE" || o.OrderSource == "Phone")
            .Sum(o => o.TotalAmount);

        var onlineOrdersAmount = orders
            .Where(o => o.OrderSource == "WEBSITE" || o.OrderSource == "Online")
            .Sum(o => o.TotalAmount);

        var payments = await _paymentRepository.GetByDateAsync(companyId, locationId, date);
        var orderIds = orders.Select(o => o.Id).ToHashSet();

        var saleTendersForTodayOrders = payments
            .Where(p => p.Status == PaymentTransactionStatus.Approved && p.PaymentType == PaymentType.SaleTender && orderIds.Contains(p.OrderId))
            .ToList();

        var collectionsToday = payments
            .Where(p => p.Status == PaymentTransactionStatus.Approved && p.PaymentType == PaymentType.CreditCollection)
            .ToList();

        var cashSales = saleTendersForTodayOrders.Where(p => p.Method == PaymentMethod.Cash).Sum(p => p.Amount);
        var cardSales = saleTendersForTodayOrders.Where(p => p.Method == PaymentMethod.Card).Sum(p => p.Amount);
        var upiSales = saleTendersForTodayOrders.Where(p => p.Method == PaymentMethod.Upi).Sum(p => p.Amount);
        var bankTransferSales = saleTendersForTodayOrders.Where(p => p.Method == PaymentMethod.BankTransfer).Sum(p => p.Amount);
        var otherPayments = saleTendersForTodayOrders
            .Where(p => p.Method != PaymentMethod.Cash && p.Method != PaymentMethod.Card && p.Method != PaymentMethod.Upi && p.Method != PaymentMethod.BankTransfer)
            .Sum(p => p.Amount);

        var creditSales = orders.Sum(o => Math.Max(0m, o.TotalAmount - saleTendersForTodayOrders.Where(p => p.OrderId == o.Id).Sum(p => p.Amount)));

        var cashCollections = collectionsToday.Where(p => p.Method == PaymentMethod.Cash).Sum(p => p.Amount);
        var upiCollections = collectionsToday.Where(p => p.Method == PaymentMethod.Upi).Sum(p => p.Amount);
        var cardCollections = collectionsToday.Where(p => p.Method == PaymentMethod.Card).Sum(p => p.Amount);
        var otherCollections = collectionsToday.Where(p => p.Method != PaymentMethod.Cash && p.Method != PaymentMethod.Upi && p.Method != PaymentMethod.Card).Sum(p => p.Amount);
        var totalCollections = collectionsToday.Sum(p => p.Amount);

        var cashDrawer = await _cashDrawerRepository.GetSummaryAsync(companyId, date);

        var refundCount = 0;
        var totalRefunds = 0m;
        var netSales = totalSales - totalRefunds;

        var openingCash = cashDrawer.OpeningCash;
        var cashExpenses = cashDrawer.CashExpenses;
        var cashReceived = cashDrawer.CashReceived;
        var cashPaid = cashDrawer.CashPaid;
        var expectedCash = openingCash + cashSales + cashCollections + cashReceived - cashExpenses - cashPaid - totalRefunds;

        return new
        {
            date = date.ToString("yyyy-MM-dd"),

            totalOrders,
            totalSales,
            grossSales = totalSales,
            netSales,

            walkInOrders,
            phoneOrders,
            onlineOrders,

            walkInSales,
            phoneOrdersAmount,
            onlineOrdersAmount,

            cashSales,
            cardSales,
            upiSales,
            bankTransferSales,
            otherPayments,
            creditSales,
            creditTotal = creditSales,

            cashCollections,
            upiCollections,
            cardCollections,
            otherCollections,
            totalCollections,

            openingCash,
            cashExpenses,
            cashReceived,
            cashPaid,
            expectedCash,

            refundCount,
            totalRefunds,

            status = "OPEN"
        };
    }

    public async Task<List<DayCloseDto>> GetHistoryAsync(
        Guid companyId,
        Guid? locationId,
        DateTime? startDate = null,
        DateTime? endDate = null,
        int days = 30)
    {
        if (!locationId.HasValue || locationId.Value == Guid.Empty)
        {
            var defaultLoc = await _locationRepository.GetDefaultAsync(companyId);
            locationId = defaultLoc?.Id;
        }

        return await _dayCloseRepository.GetHistoryAsync(companyId, locationId, startDate, endDate, days);
    }

    public async Task<Guid> CloseAsync(Guid companyId, CloseDayRequest request, Guid userId)
    {
        if (request.LocationId == Guid.Empty)
            throw new InvalidOperationException("Please select a specific location before closing the day.");

        var location = await _locationRepository.GetByIdAsync(companyId, request.LocationId);
        if (location == null)
            throw new InvalidOperationException("Selected location is invalid or not accessible for this company.");

        var businessDateUtc = DateTime.SpecifyKind(request.BusinessDate.Date, DateTimeKind.Utc);

        var isClosed = await _dayCloseRepository.IsDayClosedAsync(companyId, request.LocationId, businessDateUtc);
        if (isClosed)
            throw new InvalidOperationException("Day is already closed for this location");

        var summary = await GetSummaryAsync(companyId, request.LocationId, businessDateUtc);

        // Extract values from summary
        var totalOrders = (int)(summary.GetType().GetProperty("totalOrders")?.GetValue(summary) ?? 0);
        var totalSales = (decimal)(summary.GetType().GetProperty("totalSales")?.GetValue(summary) ?? 0m);
        var totalRefunds = (decimal)(summary.GetType().GetProperty("totalRefunds")?.GetValue(summary) ?? 0m);
        var cashSales = (decimal)(summary.GetType().GetProperty("cashSales")?.GetValue(summary) ?? 0m);
        var cardSales = (decimal)(summary.GetType().GetProperty("cardSales")?.GetValue(summary) ?? 0m);
        var upiSales = (decimal)(summary.GetType().GetProperty("upiSales")?.GetValue(summary) ?? 0m);
        var bankTransferSales = (decimal)(summary.GetType().GetProperty("bankTransferSales")?.GetValue(summary) ?? 0m);
        var otherPaymentsVal = (decimal)(summary.GetType().GetProperty("otherPayments")?.GetValue(summary) ?? 0m);
        var expectedCash = (decimal)(summary.GetType().GetProperty("expectedCash")?.GetValue(summary) ?? 0m);
        var cashExpenses = (decimal)(summary.GetType().GetProperty("cashExpenses")?.GetValue(summary) ?? 0m);

        var dayClose = new Domain.Entities.DayClose(
            companyId,
            request.LocationId,
            businessDateUtc,
            userId);

        dayClose.SetSalesSummary(totalOrders, totalSales, totalRefunds);
        dayClose.SetPaymentBreakdown(cashSales, cardSales, upiSales, 0m, otherPaymentsVal + bankTransferSales);
        dayClose.SetExpectedCash(expectedCash);
        dayClose.SetCashCount(request.ActualCash);
        dayClose.SetCashExpenses(cashExpenses);

        if (!string.IsNullOrEmpty(request.Notes))
            dayClose.AddNotes(request.Notes);

        await _dayCloseRepository.AddAsync(dayClose);
        return dayClose.Id;
    }

    private static DayCloseDto MapToDto(Domain.Entities.DayClose dc) => new()
    {
        Id = dc.Id,
        LocationId = dc.LocationId,
        BusinessDate = dc.BusinessDate,
        Status = dc.Status.ToString(),
        ClosedAt = dc.ClosedAt,
        ClosedByUserId = dc.ClosedByUserId,
        TotalOrders = dc.TotalOrders,
        TotalSales = dc.TotalSales,
        TotalRefunds = dc.TotalRefunds,
        NetSales = dc.NetSales,
        CashTotal = dc.CashTotal,
        CardTotal = dc.CardTotal,
        UpiTotal = dc.UpiTotal,
        GiftCardTotal = dc.GiftCardTotal,
        OtherPaymentsTotal = dc.OtherPaymentsTotal,
        CreditTotal = Math.Max(0m, dc.TotalSales - (dc.CashTotal + dc.CardTotal + dc.UpiTotal + dc.GiftCardTotal + dc.OtherPaymentsTotal)),
        ExpectedCash = dc.ExpectedCash,
        ActualCash = dc.ActualCash,
        CashVariance = dc.CashVariance,
        CashExpenses = dc.CashExpenses,
        Notes = dc.Notes
    };
}