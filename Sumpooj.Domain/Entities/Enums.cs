namespace Sumpooj.Domain.Entities;

public enum ProductType
{
    SingleFlower,
    Bouquet,
    Arrangement,
    Plant,
    Gift,
    Accessory
}

public enum ProductCategory
{
    Roses,
    Lilies,
    Tulips,
    Orchids,
    Carnations,
    MixedFlowers,
    Seasonal,
    Exotic,
    WeddingFlowers,
    SymPathyFlowers,
    CelebrationFlowers,
    IndoorPlants,
    OutdoorPlants,
    Vases,
    Ribbons,
    Cards,
    ChocolatesAndGifts,
    Other
}

public enum SeasonalAvailability
{
    YearRound,
    Spring,
    Summer,
    Fall,
    Winter,
    SpringSummer,
    FallWinter
}

public enum OrderStatus
{
    Pending,
    Confirmed,
    Processing,
    ReadyForDelivery,
    OutForDelivery,
    Delivered,
    Cancelled,
    Failed
}

public enum PaymentStatus
{
    Unpaid,
    PartiallyPaid,
    Paid,
    Refunded
}

public enum DeliveryPriority
{
    Standard,
    Express,
    SameDay,
    Scheduled
}

public enum SupplierRating
{
    NotRated,
    Poor,
    Fair,
    Good,
    Excellent
}

public enum PurchaseOrderStatus
{
    Draft,
    Submitted,
    Approved,
    Received,
    Completed,
    Cancelled
}

public enum DeliveryStatus
{
    Scheduled,
    InProgress,
    Completed,
    Failed,
    Rescheduled
}

public enum StockMovementType
{
    Purchase,
    Sale,
    Adjustment,
    Damaged,
    Expired,
    Return
}

public enum AdjustmentType
{
    Damaged,
    Spoiled,
    Expired,
    UsedForEvent,
    UsedForSample,
    Lost,
    Found,
    Theft,
    TransferOut,
    TransferIn,
    Correction,
    Other
}

public enum LocationType
{
    Store,
    Warehouse,
    ColdRoom,
    DisplayCooler,
    DryStorage,
    Workshop
}

public enum UnitOfMeasure
{
    Stem,
    Bunch,
    Box,
    Piece,
    Kilogram,
    Gram,
    Liter,
    Milliliter,
    Roll,
    Pack,
    Set,
    Meter
}

public enum TaxCategory
{
    None,
    Standard,
    Reduced,
    Zero
}

public enum FlowerGrade
{
    Standard,
    Select,
    Premium,
    Luxury
}

// Staff & Role Enums
public enum StaffRole
{
    Admin,
    Manager,
    Designer,
    Cashier,
    Driver,
    Staff
}

public enum CommissionType
{
    Revenue,
    Profit
}

// Event Enums
public enum EventType
{
    Wedding,
    Corporate,
    Funeral,
    Party,
    Other
}

public enum EventStatus
{
    Inquiry,
    ProposalSent,
    Confirmed,
    InProduction,
    Completed,
    Cancelled
}

// Payment Enums
public enum PaymentMethod
{
    Cash,
    Card,
    GiftCard,
    ExternalTerminal,
    Upi,
    BankTransfer
}

public enum PaymentTransactionStatus
{
    Pending,
    Approved,
    Declined,
    Voided,
    Refunded
}

// Task Enums
public enum TaskStatus
{
    Pending,
    InProgress,
    Completed
}

public enum TaskPriority
{
    Low,
    Medium,
    High
}

public enum RelatedEntityType
{
    Order,
    Event,
    Delivery
}

// Refund Enums
public enum RefundMethod
{
    Original,
    StoreCredit
}

public enum RefundStatus
{
    Pending,
    Processed,
    Failed
}

// Gift Card Enums
public enum GiftCardStatus
{
    Active,
    Inactive,
    FullyRedeemed,
    Expired
}

// Day Close Enums
public enum DayCloseStatus
{
    Completed,
    Adjusted
}

// Order Source
public enum OrderSource
{
    WalkIn,
    Phone,
    Website,
    BloomNation,
    Ftd,
    Other
}

// Fulfillment Status (for order production tracking)
public enum FulfillmentStatus
{
    Draft,
    Confirmed,
    InDesign,
    Ready,
    OutForDelivery,
    Completed,
    Cancelled
}
