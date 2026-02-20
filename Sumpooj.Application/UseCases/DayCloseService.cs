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
        var dayClose = await _dayCloseRepository.GetByIdAsync(companyId, id);
        return dayClose == null ? null : MapToDto(dayClose);
    }

    public async Task<bool> IsDayClosedAsync(Guid companyId, Guid locationId, DateTime date)
    {
        return await _dayCloseRepository.IsDayClosedAsync(companyId, locationId, date);
    }

    public async Task<DayCloseSummaryDto> GetSummaryAsync(Guid companyId, Guid locationId, DateTime date)
    {
        var location = await _locationRepository.GetByIdAsync(locationId);
        var orders = await _orderRepository.GetByDateAsync(companyId, date);

        // Calculate totals (simplified - would need actual payment data per location)
        var totalOrders = orders.Count;
        var totalSales = orders.Sum(o => o.TotalAmount);
        var completedOrders = orders.Count(o => o.Status == "Delivered");
        var cancelledOrders = orders.Count(o => o.Status == "Cancelled");
        var pendingOrders = totalOrders - completedOrders - cancelledOrders;

        // Check if can close
        var isClosed = await _dayCloseRepository.IsDayClosedAsync(companyId, locationId, date);
        var canClose = !isClosed && date.Date <= DateTime.UtcNow.Date;

        return new DayCloseSummaryDto
        {
            BusinessDate = date,
            LocationId = locationId,
            LocationName = location?.Name ?? "Unknown",
            TotalOrders = totalOrders,
            TotalSales = totalSales,
            TotalRefunds = 0, // Would need refund calculation
            NetSales = totalSales,
            CompletedOrders = completedOrders,
            CancelledOrders = cancelledOrders,
            PendingOrders = pendingOrders,
            Payments = new PaymentBreakdownDto
            {
                Cash = 0, // Would need actual payment breakdown
                Card = 0,
                Upi = 0,
                GiftCard = 0,
                Other = 0
            },
            CanClose = canClose
        };
    }

    public async Task<List<DayCloseDto>> GetHistoryAsync(Guid companyId, Guid locationId, int days = 30)
    {
        return await _dayCloseRepository.GetHistoryAsync(companyId, locationId, days);
    }

    public async Task<Guid> CloseAsync(Guid companyId, CloseDayRequest request, Guid userId)
    {
        // Check if already closed
        var isClosed = await _dayCloseRepository.IsDayClosedAsync(companyId, request.LocationId, request.BusinessDate);
        if (isClosed)
            throw new InvalidOperationException("Day is already closed for this location");

        // Get summary data
        var summary = await GetSummaryAsync(companyId, request.LocationId, request.BusinessDate);

        var dayClose = new Domain.Entities.DayClose(
            companyId,
            request.LocationId,
            request.BusinessDate,
            userId);

        dayClose.SetSalesSummary(
            summary.TotalOrders,
            summary.TotalSales,
            summary.TotalRefunds);

        dayClose.SetPaymentBreakdown(
            summary.Payments.Cash,
            summary.Payments.Card,
            summary.Payments.Upi,
            summary.Payments.GiftCard,
            summary.Payments.Other);

        dayClose.SetCashCount(request.ActualCash);

        if (!string.IsNullOrEmpty(request.Notes))
        {
            dayClose.AddNotes(request.Notes);
        }

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
