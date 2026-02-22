using Sumpooj.Application.Common;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Orders;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.UseCases;

public class OrderService
{
    private readonly IOrderRepository _orderRepository;
    private readonly ICustomerRepository _customerRepository;
    private readonly IProductRepository _productRepository;
    private readonly ILocationRepository _locationRepository;
    private readonly IShiftRepository _shiftRepository;

    public OrderService(
        IOrderRepository orderRepository,
        ICustomerRepository customerRepository,
        IProductRepository productRepository,
        ILocationRepository locationRepository,
        IShiftRepository shiftRepository)
    {
        _orderRepository = orderRepository;
        _customerRepository = customerRepository;
        _productRepository = productRepository;
        _locationRepository = locationRepository;
        _shiftRepository = shiftRepository;
    }

    public async Task<OrderDto?> GetByIdAsync(Guid companyId, Guid id)
    {
        var order = await _orderRepository.GetByIdAsync(companyId, id);
        return order == null ? null : MapToDto(order);
    }

    public async Task<OrderDto?> GetByOrderNumberAsync(Guid companyId, string orderNumber)
    {
        var order = await _orderRepository.GetByOrderNumberAsync(companyId, orderNumber);
        return order == null ? null : MapToDto(order);
    }

    public async Task<PagedResult<OrderListDto>> SearchAsync(Guid companyId, OrderSearchRequest request)
    {
        return await _orderRepository.SearchAsync(companyId, request);
    }

    public async Task<List<OrderListDto>> GetTodaysOrdersAsync(Guid companyId, Guid? locationId = null)
    {
        return await _orderRepository.GetTodaysOrdersAsync(companyId, locationId);
    }

    public async Task<List<OrderListDto>> GetByDeliveryDateAsync(Guid companyId, DateTime date)
    {
        return await _orderRepository.GetByDateAsync(companyId, date);
    }

    public async Task<List<OrderListDto>> GetByCustomerAsync(Guid companyId, Guid customerId)
    {
        return await _orderRepository.GetByCustomerAsync(companyId, customerId);
    }

    public async Task<Guid> CreateAsync(Guid companyId, CreateOrderRequest request)
    {
        // Validate LocationId is provided
        if (request.LocationId == Guid.Empty)
            throw new InvalidOperationException("LocationId is required when creating an order.");

        // Validate Location exists and belongs to the same company
        var location = await _locationRepository.GetByIdAsync(request.LocationId)
            ?? throw new InvalidOperationException($"Location '{request.LocationId}' not found.");

        if (location.CompanyId != companyId)
            throw new InvalidOperationException("Location does not belong to this company.");

        if (!location.IsActive)
            throw new InvalidOperationException("Cannot create an order for an inactive location.");

        // Validate an active shift exists for this location
        var activeShift = await _shiftRepository.GetActiveShiftAsync(companyId, request.LocationId);
        if (activeShift == null)
            throw new InvalidOperationException("No active shift for this location. Please open a shift before creating orders.");

        // Validate customer exists
        var customer = await _customerRepository.GetByIdAsync(request.CustomerId)
            ?? throw new KeyNotFoundException("Customer not found");

        var order = new Order(
            companyId,
            request.CustomerId,
            request.DeliveryDate,
            request.DeliveryAddress,
            request.RecipientName,
            request.RecipientPhone);

        // Assign location
        order.LocationId = request.LocationId;

        // Set optional fields
        if (!string.IsNullOrEmpty(request.CardMessage))
            order.SetCardMessage(request.CardMessage);

        if (Enum.TryParse<DeliveryPriority>(request.DeliveryPriority, true, out var priority))
            order.SetDeliveryPriority(priority);

        if (Enum.TryParse<OrderSource>(request.OrderSource, true, out var source))
            order.SetOrderSource(source);

        if (!string.IsNullOrEmpty(request.TimeSlot))
            order.SetTimeSlot(request.TimeSlot);

        if (request.DeliveryFee > 0)
            order.SetDeliveryFee(request.DeliveryFee);

        if (request.DiscountAmount > 0)
            order.ApplyDiscount(request.DiscountAmount);

        if (!string.IsNullOrEmpty(request.InternalNotes))
            order.AddInternalNote(request.InternalNotes);

        // Add items
        foreach (var item in request.Items)
        {
            order.AddItem(item.ProductId, item.ProductName, item.Quantity, item.UnitPrice);
        }

        await _orderRepository.AddAsync(order);
        return order.Id;
    }

    public async Task UpdateStatusAsync(Guid companyId, Guid id, string status)
    {
        var order = await _orderRepository.GetByIdAsync(companyId, id)
            ?? throw new KeyNotFoundException("Order not found");

        if (!Enum.TryParse<OrderStatus>(status, true, out var orderStatus))
            throw new ArgumentException($"Invalid status: {status}");

        switch (orderStatus)
        {
            case OrderStatus.Confirmed:
                order.Confirm();
                break;
            case OrderStatus.Cancelled:
                order.Cancel("Cancelled by user");
                break;
            case OrderStatus.ReadyForDelivery:
                order.MarkReadyForDelivery();
                break;
            case OrderStatus.OutForDelivery:
                order.MarkOutForDelivery();
                break;
            case OrderStatus.Delivered:
                order.MarkDelivered();
                break;
        }

        await _orderRepository.UpdateAsync(order);
    }

    public async Task UpdateFulfillmentStatusAsync(Guid companyId, Guid id, string status)
    {
        var order = await _orderRepository.GetByIdAsync(companyId, id)
            ?? throw new KeyNotFoundException("Order not found");

        if (Enum.TryParse<FulfillmentStatus>(status, true, out var fulfillmentStatus))
        {
            order.SetFulfillmentStatus(fulfillmentStatus);
            await _orderRepository.UpdateAsync(order);
        }
    }

    public async Task AssignDesignerAsync(Guid companyId, Guid orderId, Guid designerId)
    {
        var order = await _orderRepository.GetByIdAsync(companyId, orderId)
            ?? throw new KeyNotFoundException("Order not found");

        order.StartProcessing(designerId);
        await _orderRepository.UpdateAsync(order);
    }

    public async Task AssignDriverAsync(Guid companyId, Guid orderId, Guid driverId)
    {
        var order = await _orderRepository.GetByIdAsync(companyId, orderId)
            ?? throw new KeyNotFoundException("Order not found");

        order.AssignDeliveryPerson(driverId);
        await _orderRepository.UpdateAsync(order);
    }

    public async Task CancelAsync(Guid companyId, Guid id, string? reason)
    {
        var order = await _orderRepository.GetByIdAsync(companyId, id)
            ?? throw new KeyNotFoundException("Order not found");

        order.Cancel(reason);
        await _orderRepository.UpdateAsync(order);
    }

    private static OrderDto MapToDto(Order order) => new()
    {
        Id = order.Id,
        OrderNumber = order.OrderNumber,
        CustomerId = order.CustomerId,
        CustomerName = order.Customer?.Name ?? "Unknown",
        OrderDate = order.OrderDate,
        DeliveryDate = order.DeliveryDate,
        Status = order.Status.ToString(),
        PaymentStatus = order.PaymentStatus.ToString(),
        FulfillmentStatus = order.FulfillmentStatus.ToString(),
        OrderSource = order.OrderSource.ToString(),
        IsActive = order.IsActive,
        DeliveryAddress = order.DeliveryAddress,
        RecipientName = order.RecipientName,
        RecipientPhone = order.RecipientPhone,
        CardMessage = order.CardMessage,
        DeliveryPriority = order.DeliveryPriority.ToString(),
        TimeSlot = order.TimeSlot,
        SubTotal = order.SubTotal,
        DeliveryFee = order.DeliveryFee,
        TaxAmount = order.TaxAmount,
        DiscountAmount = order.DiscountAmount,
        TotalAmount = order.TotalAmount,
        AssignedDesignerId = order.AssignedToUserId,
        DeliveryPersonId = order.DeliveryPersonId,
        LocationId = order.LocationId,
        LocationName = order.Location?.Name,
        InternalNotes = order.InternalNotes,
        Items = order.Items.Select(i => new OrderItemDto
        {
            Id = i.Id,
            ProductId = i.ProductId,
            ProductName = i.ProductName,
            Quantity = i.Quantity,
            UnitPrice = i.UnitPrice,
            TotalPrice = i.TotalPrice
        }).ToList(),
        CreatedAtUtc = order.CreatedAtUtc
    };
}
