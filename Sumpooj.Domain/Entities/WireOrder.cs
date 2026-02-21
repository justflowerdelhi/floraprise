namespace Sumpooj.Domain.Entities;

/// <summary>
/// Represents a wire order from FTD, Teleflora, BloomNation, etc.
/// </summary>
public class WireOrder : BaseEntity
{
    private WireOrder() { }

    public WireOrder(
        Guid companyId,
        WireServiceType wireService,
        string wireOrderNumber,
        DateTime receivedDate,
        DateTime deliveryDate)
    {
        CompanyId = companyId;
        WireService = wireService;
        WireOrderNumber = wireOrderNumber;
        ReceivedDate = receivedDate;
        DeliveryDate = deliveryDate;
        Status = WireOrderStatus.Received;
        IsActive = true;
    }

    public Guid CompanyId { get; private set; }
    
    /// <summary>
    /// Wire service provider (FTD, Teleflora, BloomNation, etc.)
    /// </summary>
    public WireServiceType WireService { get; private set; }
    
    /// <summary>
    /// Order number from the wire service
    /// </summary>
    public string WireOrderNumber { get; private set; } = default!;
    
    /// <summary>
    /// When the order was received from wire service
    /// </summary>
    public DateTime ReceivedDate { get; private set; }
    
    /// <summary>
    /// Required delivery date
    /// </summary>
    public DateTime DeliveryDate { get; private set; }
    
    /// <summary>
    /// Time slot for delivery (e.g., "Morning", "Afternoon", "2PM-4PM")
    /// </summary>
    public string? TimeSlot { get; private set; }
    
    public WireOrderStatus Status { get; private set; }
    
    // Sender Info
    public string? SenderName { get; private set; }
    public string? SenderPhone { get; private set; }
    public string? SenderEmail { get; private set; }
    
    // Recipient Info
    public string RecipientName { get; private set; } = default!;
    public string RecipientPhone { get; private set; } = default!;
    public string DeliveryAddress { get; private set; } = default!;
    public string? DeliveryCity { get; private set; }
    public string? DeliveryZipCode { get; private set; }
    
    /// <summary>
    /// Card message from sender
    /// </summary>
    public string? CardMessage { get; private set; }
    
    /// <summary>
    /// Special delivery instructions
    /// </summary>
    public string? DeliveryInstructions { get; private set; }
    
    // Pricing
    /// <summary>
    /// Amount received from wire service
    /// </summary>
    public decimal WireAmount { get; private set; }
    
    /// <summary>
    /// Wire service fee/commission
    /// </summary>
    public decimal WireServiceFee { get; private set; }
    
    /// <summary>
    /// Net amount after wire service fee
    /// </summary>
    public decimal NetAmount { get; private set; }
    
    /// <summary>
    /// Our cost to fulfill the order
    /// </summary>
    public decimal? FulfillmentCost { get; private set; }
    
    // Product Info
    /// <summary>
    /// Product description from wire service
    /// </summary>
    public string? ProductDescription { get; private set; }
    
    /// <summary>
    /// Wire service product code
    /// </summary>
    public string? WireProductCode { get; private set; }
    
    /// <summary>
    /// Our substitution notes
    /// </summary>
    public string? SubstitutionNotes { get; private set; }
    
    /// <summary>
    /// Link to our internal order (once created)
    /// </summary>
    public Guid? LinkedOrderId { get; private set; }
    
    /// <summary>
    /// Assigned designer
    /// </summary>
    public Guid? AssignedToUserId { get; private set; }
    
    public string? InternalNotes { get; private set; }
    
    /// <summary>
    /// Confirmation code sent back to wire service
    /// </summary>
    public string? ConfirmationCode { get; private set; }
    
    /// <summary>
    /// Date/time when order was fulfilled
    /// </summary>
    public DateTime? FulfilledAt { get; private set; }
    
    /// <summary>
    /// Rejection reason if declined
    /// </summary>
    public string? RejectionReason { get; private set; }
    
    public bool IsActive { get; private set; }

    public void SetRecipientInfo(
        string recipientName,
        string recipientPhone,
        string deliveryAddress,
        string? deliveryCity,
        string? deliveryZipCode)
    {
        RecipientName = recipientName;
        RecipientPhone = recipientPhone;
        DeliveryAddress = deliveryAddress;
        DeliveryCity = deliveryCity;
        DeliveryZipCode = deliveryZipCode;
        MarkUpdated();
    }

    public void SetSenderInfo(string? name, string? phone, string? email)
    {
        SenderName = name;
        SenderPhone = phone;
        SenderEmail = email;
        MarkUpdated();
    }

    public void SetPricing(decimal wireAmount, decimal wireServiceFee)
    {
        WireAmount = wireAmount;
        WireServiceFee = wireServiceFee;
        NetAmount = wireAmount - wireServiceFee;
        MarkUpdated();
    }

    public void SetProductInfo(string? description, string? wireProductCode, string? substitutionNotes)
    {
        ProductDescription = description;
        WireProductCode = wireProductCode;
        SubstitutionNotes = substitutionNotes;
        MarkUpdated();
    }

    public void SetCardMessage(string? message) => CardMessage = message;
    public void SetDeliveryInstructions(string? instructions) => DeliveryInstructions = instructions;
    public void SetTimeSlot(string? timeSlot) => TimeSlot = timeSlot;
    public void SetInternalNotes(string? notes) => InternalNotes = notes;
    public void SetFulfillmentCost(decimal cost) => FulfillmentCost = cost;

    public void AssignTo(Guid userId)
    {
        AssignedToUserId = userId;
        MarkUpdated();
    }

    public void Accept()
    {
        Status = WireOrderStatus.Accepted;
        MarkUpdated();
    }

    public void StartProcessing()
    {
        Status = WireOrderStatus.InProgress;
        MarkUpdated();
    }

    public void LinkToOrder(Guid orderId)
    {
        LinkedOrderId = orderId;
        MarkUpdated();
    }

    public void MarkFulfilled(string? confirmationCode = null)
    {
        Status = WireOrderStatus.Fulfilled;
        FulfilledAt = DateTime.UtcNow;
        ConfirmationCode = confirmationCode;
        MarkUpdated();
    }

    public void Reject(string reason)
    {
        Status = WireOrderStatus.Rejected;
        RejectionReason = reason;
        MarkUpdated();
    }

    public void Cancel(string reason)
    {
        Status = WireOrderStatus.Cancelled;
        RejectionReason = reason;
        MarkUpdated();
    }
}

public enum WireServiceType
{
    Ftd,
    Teleflora,
    BloomNation,
    FloristOne,
    Lovingly,
    Other
}

public enum WireOrderStatus
{
    Received,
    Accepted,
    InProgress,
    Fulfilled,
    Rejected,
    Cancelled
}
