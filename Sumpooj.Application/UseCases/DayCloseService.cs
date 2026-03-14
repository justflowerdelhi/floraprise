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

    public async Task<object> GetSummaryAsync(Guid companyId, Guid locationId, DateTime date)
    {
        var orders = await _orderRepository.GetByDateAsync(companyId, date);

        orders = orders
            .Where(o => o.LocationId == locationId)
            .ToList();

        var totalOrders = orders.Count;
        var totalSales = orders.Sum(o => o.TotalAmount ?? 0);

        var walkInOrders = orders.Count(o => o.Source == "WALK_IN");
        var phoneOrders = orders.Count(o => o.Source == "PHONE");
        var onlineOrders = orders.Count(o => o.Source == "WEBSITE");

        var walkInSales = orders
            .Where(o => o.Source == "WALK_IN")
            .Sum(o => o.TotalAmount ?? 0);

        var phoneOrdersAmount = orders
            .Where(o => o.Source == "PHONE")
            .Sum(o => o.TotalAmount ?? 0);

        var onlineOrdersAmount = orders
            .Where(o => o.Source == "WEBSITE")
            .Sum(o => o.TotalAmount ?? 0);

        var payments = await _paymentRepository.GetByDateAsync(companyId, locationId, date);

        var cashSales = payments.Where(p => p.Method == "CASH").Sum(p => p.Amount);
        var cardSales = payments.Where(p => p.Method == "CARD").Sum(p => p.Amount);
        var upiSales = payments.Where(p => p.Method == "UPI").Sum(p => p.Amount);
        var otherPayments = payments
            .Where(p => p.Method != "CASH" && p.Method != "CARD" && p.Method != "UPI")
            .Sum(p => p.Amount);

        var totalRefunds = orders.Sum(o => o.TotalRefunded ?? 0);
        var refundCount = orders.Count(o => (o.TotalRefunded ?? 0) > 0);

        return new
        {
            date = date.ToString("yyyy-MM-dd"),

            totalOrders = totalOrders,
            totalSales = totalSales,

            walkInOrders = walkInOrders,
            phoneOrders = phoneOrders,
            onlineOrders = onlineOrders,

            walkInSales = walkInSales,
            phoneOrdersAmount = phoneOrdersAmount,
            onlineOrdersAmount = onlineOrdersAmount,

            cashSales = payments.Cash,
            cardSales = payments.Card,
            upiSales = payments.Upi,
            otherPayments = payments.Other,

            expectedCash = payments.Cash,

            refundCount = refundCount,
            totalRefunds = totalRefunds,

            status = "OPEN"
        };
    }
}