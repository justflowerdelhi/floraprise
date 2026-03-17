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

    public DayCloseService(
        IDayCloseRepository dayCloseRepository,
        IOrderRepository orderRepository,
        IPaymentRepository paymentRepository,
        ILocationRepository locationRepository)
    {
        _dayCloseRepository = dayCloseRepository;
        _orderRepository = orderRepository;
        _paymentRepository = paymentRepository;
        _locationRepository = locationRepository;
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
        var orders = locationId != Guid.Empty
            ? allOrders.Where(o => o.LocationId == locationId).ToList()
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

        var cashSales = payments.Where(p => p.Method == PaymentMethod.Cash).Sum(p => p.Amount);
        var cardSales = payments.Where(p => p.Method == PaymentMethod.Card).Sum(p => p.Amount);
        var upiSales = payments.Where(p => p.Method == PaymentMethod.Upi).Sum(p => p.Amount);
        var otherPayments = payments
            .Where(p => p.Method != PaymentMethod.Cash && p.Method != PaymentMethod.Card && p.Method != PaymentMethod.Upi)
            .Sum(p => p.Amount);

        var refundCount = 0;
        var totalRefunds = 0m;

        return new
        {
            date = date.ToString("yyyy-MM-dd"),

            totalOrders,
            totalSales,

            walkInOrders,
            phoneOrders,
            onlineOrders,

            walkInSales,
            phoneOrdersAmount,
            onlineOrdersAmount,

            cashSales,
            cardSales,
            upiSales,
            otherPayments,

            expectedCash = cashSales,

            refundCount,
            totalRefunds,

            status = "OPEN"
        };
    }

    public async Task<List<DayCloseDto>> GetHistoryAsync(Guid companyId, Guid locationId, int days = 30)
    {
        return await _dayCloseRepository.GetHistoryAsync(companyId, locationId, days);
    }

    public async Task<Guid> CloseAsync(Guid companyId, CloseDayRequest request, Guid userId)
    {
        var isClosed = await _dayCloseRepository.IsDayClosedAsync(companyId, request.LocationId, request.BusinessDate);
        if (isClosed)
            throw new InvalidOperationException("Day is already closed for this location");

        var summary = await GetSummaryAsync(companyId, request.LocationId, request.BusinessDate);

        // Extract values from dynamic summary
        var totalOrders = (int)(summary.GetType().GetProperty("totalOrders")?.GetValue(summary) ?? 0);
        var totalSales = (decimal)(summary.GetType().GetProperty("totalSales")?.GetValue(summary) ?? 0m);
        var totalRefunds = (decimal)(summary.GetType().GetProperty("totalRefunds")?.GetValue(summary) ?? 0m);
        var cashSales = (decimal)(summary.GetType().GetProperty("cashSales")?.GetValue(summary) ?? 0m);
        var cardSales = (decimal)(summary.GetType().GetProperty("cardSales")?.GetValue(summary) ?? 0m);
        var upiSales = (decimal)(summary.GetType().GetProperty("upiSales")?.GetValue(summary) ?? 0m);
        var otherPaymentsVal = (decimal)(summary.GetType().GetProperty("otherPayments")?.GetValue(summary) ?? 0m);

        var dayClose = new Domain.Entities.DayClose(
            companyId,
            request.LocationId,
            request.BusinessDate,
            userId);

        dayClose.SetSalesSummary(totalOrders, totalSales, totalRefunds);
        dayClose.SetPaymentBreakdown(cashSales, cardSales, upiSales, 0m, otherPaymentsVal);
        dayClose.SetCashCount(request.ActualCash);

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
        ExpectedCash = dc.ExpectedCash,
        ActualCash = dc.ActualCash,
        CashVariance = dc.CashVariance,
        Notes = dc.Notes
    };
}