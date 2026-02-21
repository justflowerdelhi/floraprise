using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Payments;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.UseCases;

public class PaymentService
{
    private readonly IPaymentRepository _paymentRepository;
    private readonly IOrderRepository _orderRepository;

    public PaymentService(IPaymentRepository paymentRepository, IOrderRepository orderRepository)
    {
        _paymentRepository = paymentRepository;
        _orderRepository = orderRepository;
    }

    public async Task<PaymentDto?> GetByIdAsync(Guid id)
    {
        var payment = await _paymentRepository.GetByIdAsync(id);
        return payment == null ? null : MapToDto(payment);
    }

    public async Task<List<PaymentDto>> GetByOrderIdAsync(Guid orderId)
    {
        return await _paymentRepository.GetByOrderIdAsync(orderId);
    }

    public async Task<PaymentDto> CreateAsync(Guid companyId, CreatePaymentRequest request, Guid userId)
    {
        // Validate order
        var order = await _orderRepository.GetByIdAsync(companyId, request.OrderId)
            ?? throw new KeyNotFoundException("Order not found");

        if (!Enum.TryParse<PaymentMethod>(request.Method, true, out var method))
            throw new ArgumentException($"Invalid payment method: {request.Method}");

        var payment = new Payment(companyId, request.OrderId, method, request.Amount);
        
        if (request.LocationId.HasValue)
            payment.SetLocation(request.LocationId.Value);
        
        payment.SetProcessedBy(userId);

        // For cash payments, auto-approve
        if (method == PaymentMethod.Cash)
        {
            payment.Approve(null, null);
        }

        await _paymentRepository.AddAsync(payment);

        // Update order payment status
        await UpdateOrderPaymentStatusAsync(companyId, request.OrderId);

        return MapToDto(payment);
    }

    public async Task ApproveAsync(Guid id, string? transactionId, string? authorizationCode)
    {
        var payment = await _paymentRepository.GetByIdAsync(id)
            ?? throw new KeyNotFoundException("Payment not found");

        payment.Approve(transactionId, authorizationCode);
        await _paymentRepository.UpdateAsync(payment);

        // Update order payment status
        await UpdateOrderPaymentStatusAsync(payment.CompanyId, payment.OrderId);
    }

    public async Task SetCardDetailsAsync(Guid id, string cardBrand, string last4)
    {
        var payment = await _paymentRepository.GetByIdAsync(id)
            ?? throw new KeyNotFoundException("Payment not found");

        payment.SetCardDetails(cardBrand, last4);
        await _paymentRepository.UpdateAsync(payment);
    }

    public async Task SetTerminalResponseAsync(Guid id, TerminalResponseDto response)
    {
        var payment = await _paymentRepository.GetByIdAsync(id)
            ?? throw new KeyNotFoundException("Payment not found");

        payment.SetTerminalResponse(
            response.TerminalId,
            response.ResponseCode,
            response.Message,
            response.ReceiptData);

        await _paymentRepository.UpdateAsync(payment);
    }

    public async Task DeclineAsync(Guid id)
    {
        var payment = await _paymentRepository.GetByIdAsync(id)
            ?? throw new KeyNotFoundException("Payment not found");

        payment.Decline();
        await _paymentRepository.UpdateAsync(payment);
    }

    public async Task VoidAsync(Guid id)
    {
        var payment = await _paymentRepository.GetByIdAsync(id)
            ?? throw new KeyNotFoundException("Payment not found");

        payment.Void();
        await _paymentRepository.UpdateAsync(payment);

        // Update order payment status
        await UpdateOrderPaymentStatusAsync(payment.CompanyId, payment.OrderId);
    }

    private async Task UpdateOrderPaymentStatusAsync(Guid companyId, Guid orderId)
    {
        var order = await _orderRepository.GetByIdAsync(companyId, orderId);
        if (order == null) return;

        var totalPaid = await _paymentRepository.GetTotalPaidForOrderAsync(orderId);

        if (totalPaid >= order.TotalAmount)
        {
            order.MarkPaid();
        }
        else if (totalPaid > 0)
        {
            order.MarkPartiallyPaid(totalPaid);
        }

        await _orderRepository.UpdateAsync(order);
    }

    private static PaymentDto MapToDto(Payment payment) => new()
    {
        Id = payment.Id,
        OrderId = payment.OrderId,
        LocationId = payment.LocationId,
        Method = payment.Method.ToString(),
        Amount = payment.Amount,
        Status = payment.Status.ToString(),
        TransactionId = payment.TransactionId,
        AuthorizationCode = payment.AuthorizationCode,
        CardBrand = payment.CardBrand,
        Last4 = payment.Last4,
        TerminalId = payment.TerminalId,
        CreatedAtUtc = payment.CreatedAtUtc
    };
}
