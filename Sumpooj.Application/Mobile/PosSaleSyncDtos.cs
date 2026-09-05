using System.Text.Json.Serialization;

namespace Sumpooj.Application.Mobile;

public sealed class PosSaleSyncRequest
{
    [JsonPropertyName("clientSyncId")]
    public string ClientSyncId { get; set; } = string.Empty;

    [JsonPropertyName("localOrderId")]
    public int LocalOrderId { get; set; }

    [JsonPropertyName("order")]
    public PosSaleOrderSnapshot Order { get; set; } = new();

    [JsonPropertyName("lines")]
    public List<PosSaleLineSnapshot> Lines { get; set; } = new();

    [JsonPropertyName("payments")]
    public List<PosSalePaymentSnapshot> Payments { get; set; } = new();

    [JsonPropertyName("inventoryTransactions")]
    public List<PosSaleInventoryTransactionSnapshot> InventoryTransactions { get; set; } = new();
}

public sealed class PosSaleOrderSnapshot
{
    [JsonPropertyName("order_no")]
    public string? OrderNo { get; set; }
    [JsonPropertyName("customer_id")]
    public int? CustomerId { get; set; }
    [JsonPropertyName("cloudCustomerId")]
    public Guid? CloudCustomerId { get; set; }
    [JsonPropertyName("customer_phone")]
    public string? CustomerPhone { get; set; }
    [JsonPropertyName("customer_name")]
    public string? CustomerName { get; set; }
    [JsonPropertyName("source")]
    public string? Source { get; set; }
    [JsonPropertyName("channel")]
    public string? Channel { get; set; }
    [JsonPropertyName("fulfilment_type")]
    public string? FulfilmentType { get; set; }
    [JsonPropertyName("recipient_name")]
    public string? RecipientName { get; set; }
    [JsonPropertyName("recipient_phone")]
    public string? RecipientPhone { get; set; }
    [JsonPropertyName("delivery_address")]
    public string? DeliveryAddress { get; set; }
    [JsonPropertyName("delivery_pincode")]
    public string? DeliveryPincode { get; set; }
    [JsonPropertyName("card_message")]
    public string? CardMessage { get; set; }
    [JsonPropertyName("delivery_slot")]
    public string? DeliverySlot { get; set; }
    [JsonPropertyName("scheduled_at")]
    public DateTime? ScheduledAt { get; set; }
    [JsonPropertyName("confirmed_at")]
    public DateTime? ConfirmedAt { get; set; }
    [JsonPropertyName("subtotal_paise")]
    public int SubtotalPaise { get; set; }
    [JsonPropertyName("gst_total_paise")]
    public int GstTotalPaise { get; set; }
    [JsonPropertyName("discount_total_paise")]
    public int DiscountTotalPaise { get; set; }
    [JsonPropertyName("grand_total_paise")]
    public int GrandTotalPaise { get; set; }
    [JsonPropertyName("round_off_paise")]
    public int RoundOffPaise { get; set; }
    [JsonPropertyName("reward_discount_amount_paise")]
    public int RewardDiscountAmountPaise { get; set; }
    [JsonPropertyName("reward_points_earned")]
    public int RewardPointsEarned { get; set; }
    [JsonPropertyName("reward_points_redeemed")]
    public int RewardPointsRedeemed { get; set; }
    [JsonPropertyName("is_paid")]
    public int IsPaid { get; set; }
}

public sealed class PosSaleLineSnapshot
{
    [JsonPropertyName("id")]
    public int? Id { get; set; }
    [JsonPropertyName("product_id")]
    public int? ProductId { get; set; }
    [JsonPropertyName("localProductId")]
    public int? LocalProductId { get; set; }
    [JsonPropertyName("cloudProductId")]
    public Guid? CloudProductId { get; set; }
    [JsonPropertyName("design_ref")]
    public string? DesignRef { get; set; }
    [JsonPropertyName("description")]
    public string? Description { get; set; }
    [JsonPropertyName("qty")]
    public int Qty { get; set; }
    [JsonPropertyName("unit_price_paise")]
    public int UnitPricePaise { get; set; }
    [JsonPropertyName("gst_percent")]
    public int GstPercent { get; set; }
    [JsonPropertyName("discount_type")]
    public string? DiscountType { get; set; }
    [JsonPropertyName("discount_value")]
    public int? DiscountValue { get; set; }
    [JsonPropertyName("discount_paise")]
    public int DiscountPaise { get; set; }
    [JsonPropertyName("line_subtotal_paise")]
    public int LineSubtotalPaise { get; set; }
    [JsonPropertyName("line_gst_paise")]
    public int LineGstPaise { get; set; }
    [JsonPropertyName("line_total_paise")]
    public int LineTotalPaise { get; set; }
    [JsonPropertyName("source")]
    public string? Source { get; set; }
}

public sealed class PosSalePaymentSnapshot
{
    [JsonPropertyName("id")]
    public int? Id { get; set; }
    [JsonPropertyName("method")]
    public string? Method { get; set; }
    [JsonPropertyName("amount_paise")]
    public int AmountPaise { get; set; }
    [JsonPropertyName("reference")]
    public string? Reference { get; set; }
    [JsonPropertyName("created_at")]
    public DateTime? CreatedAt { get; set; }
}

public sealed class PosSaleInventoryTransactionSnapshot
{
    [JsonPropertyName("id")]
    public int? Id { get; set; }
    [JsonPropertyName("product_id")]
    public int? ProductId { get; set; }
    [JsonPropertyName("localProductId")]
    public int? LocalProductId { get; set; }
    [JsonPropertyName("cloudProductId")]
    public Guid? CloudProductId { get; set; }
    [JsonPropertyName("qty")]
    public int Qty { get; set; }
    [JsonPropertyName("created_at")]
    public DateTime? CreatedAt { get; set; }
}

public sealed record PosSaleSyncResponse(
    string ClientSyncId,
    Guid CloudOrderId,
    Guid? CloudCustomerId,
    string SyncStatus,
    PosSaleSyncReceiptResponse Receipt);

public sealed record PosSaleSyncReceiptResponse(
    Guid ReceiptId,
    int LocalOrderId,
    string DeviceId,
    string PayloadHash,
    DateTime CompletedAtUtc);