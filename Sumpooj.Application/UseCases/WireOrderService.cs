using Sumpooj.Application.Common;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.WireOrders;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.UseCases;

public class WireOrderService
{
    private readonly IWireOrderRepository _repository;

    public WireOrderService(IWireOrderRepository repository)
    {
        _repository = repository;
    }

    public async Task<PagedResult<WireOrderDto>> SearchAsync(Guid companyId, WireOrderSearchRequest request)
    {
        return await _repository.SearchAsync(companyId, request);
    }

    public async Task<WireOrderDto?> GetByIdAsync(Guid companyId, Guid id)
    {
        var order = await _repository.GetByIdAsync(companyId, id);
        return order == null ? null : MapToDto(order);
    }

    public async Task<List<WireOrderDto>> GetTodaysOrdersAsync(Guid companyId)
    {
        return await _repository.GetTodaysOrdersAsync(companyId);
    }

    public async Task<List<WireOrderDto>> GetPendingOrdersAsync(Guid companyId)
    {
        return await _repository.GetPendingOrdersAsync(companyId);
    }

    public async Task<WireOrderSummaryDto> GetSummaryAsync(Guid companyId, DateTime fromDate, DateTime toDate)
    {
        return await _repository.GetSummaryAsync(companyId, fromDate, toDate);
    }

    public async Task<WireOrderDto> CreateAsync(Guid companyId, CreateWireOrderRequest request)
    {
        var order = new WireOrder(
            companyId,
            request.WireService,
            request.WireOrderNumber,
            request.ReceivedDate,
            request.DeliveryDate);

        order.SetRecipientInfo(
            request.RecipientName,
            request.RecipientPhone,
            request.DeliveryAddress,
            request.DeliveryCity,
            request.DeliveryZipCode);

        order.SetSenderInfo(request.SenderName, request.SenderPhone, request.SenderEmail);
        order.SetPricing(request.GrossAmount, request.Commission);
        order.SetProductInfo(request.ProductDescription, request.WireProductCode, null);
        order.SetCardMessage(request.CardMessage);
        order.SetDeliveryInstructions(request.DeliveryInstructions);
        order.SetTimeSlot(request.TimeSlot);

        await _repository.AddAsync(order);
        return MapToDto(order);
    }

    public async Task<WireOrderDto?> AcceptAsync(Guid companyId, Guid id)
    {
        var order = await _repository.GetByIdAsync(companyId, id);
        if (order == null) return null;

        order.Accept();
        await _repository.UpdateAsync(order);
        return MapToDto(order);
    }

    public async Task<WireOrderDto?> StartProcessingAsync(Guid companyId, Guid id)
    {
        var order = await _repository.GetByIdAsync(companyId, id);
        if (order == null) return null;

        order.StartProcessing();
        await _repository.UpdateAsync(order);
        return MapToDto(order);
    }

    public async Task<WireOrderDto?> AssignAsync(Guid companyId, Guid id, Guid userId)
    {
        var order = await _repository.GetByIdAsync(companyId, id);
        if (order == null) return null;

        order.AssignTo(userId);
        await _repository.UpdateAsync(order);
        return MapToDto(order);
    }

    public async Task<WireOrderDto?> SetFulfillmentCostAsync(Guid companyId, Guid id, decimal cost)
    {
        var order = await _repository.GetByIdAsync(companyId, id);
        if (order == null) return null;

        order.SetFulfillmentCost(cost);
        await _repository.UpdateAsync(order);
        return MapToDto(order);
    }

    public async Task<WireOrderDto?> SetSubstitutionNotesAsync(Guid companyId, Guid id, string notes)
    {
        var order = await _repository.GetByIdAsync(companyId, id);
        if (order == null) return null;

        order.SetProductInfo(order.ProductDescription, order.WireProductCode, notes);
        await _repository.UpdateAsync(order);
        return MapToDto(order);
    }

    public async Task<WireOrderDto?> LinkToOrderAsync(Guid companyId, Guid id, Guid orderId)
    {
        var order = await _repository.GetByIdAsync(companyId, id);
        if (order == null) return null;

        order.LinkToOrder(orderId);
        await _repository.UpdateAsync(order);
        return MapToDto(order);
    }

    public async Task<WireOrderDto?> MarkFulfilledAsync(Guid companyId, Guid id, string? confirmationCode)
    {
        var order = await _repository.GetByIdAsync(companyId, id);
        if (order == null) return null;

        order.MarkFulfilled(confirmationCode);
        await _repository.UpdateAsync(order);
        return MapToDto(order);
    }

    public async Task<WireOrderDto?> RejectAsync(Guid companyId, Guid id, string reason)
    {
        var order = await _repository.GetByIdAsync(companyId, id);
        if (order == null) return null;

        order.Reject(reason);
        await _repository.UpdateAsync(order);
        return MapToDto(order);
    }

    public async Task<WireOrderDto?> CancelAsync(Guid companyId, Guid id, string reason)
    {
        var order = await _repository.GetByIdAsync(companyId, id);
        if (order == null) return null;

        order.Cancel(reason);
        await _repository.UpdateAsync(order);
        return MapToDto(order);
    }

    private static WireOrderDto MapToDto(WireOrder order) => new()
    {
        Id = order.Id,
        ExternalOrderId = order.WireOrderNumber,
        Platform = order.WireService.ToString(),
        WireService = order.WireService,
        WireOrderNumber = order.WireOrderNumber,
        ReceivedDate = order.ReceivedDate,
        DeliveryDate = order.DeliveryDate,
        TimeSlot = order.TimeSlot,
        Status = order.Status,
        SenderName = order.SenderName,
        SenderPhone = order.SenderPhone,
        SenderEmail = order.SenderEmail,
        RecipientName = order.RecipientName,
        RecipientPhone = order.RecipientPhone,
        DeliveryAddress = order.DeliveryAddress,
        DeliveryCity = order.DeliveryCity,
        DeliveryZipCode = order.DeliveryZipCode,
        DeliveryInstructions = order.DeliveryInstructions,
        CardMessage = order.CardMessage,
        GrossAmount = order.WireAmount,
        Commission = order.WireServiceFee,
        Fees = 0,
        NetPayout = order.NetAmount,
        FulfillmentCost = order.FulfillmentCost,
        ProductDescription = order.ProductDescription,
        WireProductCode = order.WireProductCode,
        SubstitutionNotes = order.SubstitutionNotes,
        LinkedOrderId = order.LinkedOrderId,
        AssignedToUserId = order.AssignedToUserId,
        InternalNotes = order.InternalNotes,
        ConfirmationCode = order.ConfirmationCode,
        FulfilledAt = order.FulfilledAt,
        RejectionReason = order.RejectionReason,
        CreatedAtUtc = order.CreatedAtUtc
    };
}
