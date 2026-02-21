using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Refunds;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.UseCases;

public class RefundService
{
    private readonly IRefundRepository _refundRepository;
    private readonly IOrderRepository _orderRepository;
    private readonly IProductRepository _productRepository;

    public RefundService(
        IRefundRepository refundRepository,
        IOrderRepository orderRepository,
        IProductRepository productRepository)
    {
        _refundRepository = refundRepository;
        _orderRepository = orderRepository;
        _productRepository = productRepository;
    }

    public async Task<RefundDto?> GetByIdAsync(Guid companyId, Guid id)
    {
        var refund = await _refundRepository.GetByIdAsync(companyId, id);
        return refund == null ? null : MapToDto(refund);
    }

    public async Task<List<RefundDto>> GetByOrderIdAsync(Guid orderId)
    {
        return await _refundRepository.GetByOrderIdAsync(orderId);
    }

    public async Task<RefundDto> CreateAsync(Guid companyId, CreateRefundRequest request, Guid userId)
    {
        // Validate order
        var order = await _orderRepository.GetByIdAsync(companyId, request.OrderId)
            ?? throw new KeyNotFoundException("Order not found");

        // Validate refund amount doesn't exceed what's paid
        var totalRefunded = await _refundRepository.GetTotalRefundedForOrderAsync(request.OrderId);
        var maxRefundable = order.TotalAmount - totalRefunded;
        var requestedAmount = request.Items.Sum(i => i.Quantity * i.UnitPrice);

        if (requestedAmount > maxRefundable)
            throw new InvalidOperationException($"Refund amount exceeds maximum refundable: {maxRefundable:C}");

        if (!Enum.TryParse<RefundMethod>(request.Method, true, out var method))
            method = RefundMethod.Original;

        var refund = new Refund(companyId, request.OrderId, method, request.Reason, userId);

        foreach (var item in request.Items)
        {
            refund.AddItem(item.ProductId, item.ProductName, item.Quantity, item.UnitPrice, item.Restock);

            // Restock inventory if applicable
            if (item.Restock)
            {
                var product = await _productRepository.GetByIdAsync(item.ProductId);
                if (product != null && product.TrackInventory)
                {
                    product.AdjustStock(item.Quantity);
                    await _productRepository.UpdateAsync(product);
                }
            }
        }

        // Auto-process the refund
        refund.Process();

        await _refundRepository.AddAsync(refund);

        // Update order status
        var newTotalRefunded = totalRefunded + refund.RefundedAmount;
        if (newTotalRefunded >= order.TotalAmount - 0.01m)
        {
            // Fully refunded - update order status as needed
        }

        return MapToDto(refund);
    }

    private static RefundDto MapToDto(Refund refund) => new()
    {
        Id = refund.Id,
        OrderId = refund.OrderId,
        RefundNumber = refund.RefundNumber,
        Method = refund.Method.ToString(),
        Status = refund.Status.ToString(),
        Reason = refund.Reason,
        RefundedAmount = refund.RefundedAmount,
        TransactionId = refund.TransactionId,
        Notes = refund.Notes,
        Items = refund.Items.Select(i => new RefundItemDto
        {
            ProductId = i.ProductId,
            ProductName = i.ProductName,
            Quantity = i.Quantity,
            UnitPrice = i.UnitPrice,
            RefundAmount = i.RefundAmount,
            Restock = i.Restock
        }).ToList(),
        CreatedAtUtc = refund.CreatedAtUtc
    };
}
