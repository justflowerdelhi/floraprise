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
