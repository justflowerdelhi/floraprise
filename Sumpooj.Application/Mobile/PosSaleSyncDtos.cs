using System.Text.Json;
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
    [JsonPropertyName("business_date")]
    public DateTime? BusinessDate { get; set; }
    [JsonPropertyName("subtotal_paise")]
    [JsonConverter(typeof(PosSalePaiseIntConverter))]
    public int SubtotalPaise { get; set; }
    [JsonPropertyName("gst_total_paise")]
    [JsonConverter(typeof(PosSalePaiseIntConverter))]
    public int GstTotalPaise { get; set; }
    [JsonPropertyName("discount_total_paise")]
    [JsonConverter(typeof(PosSalePaiseIntConverter))]
    public int DiscountTotalPaise { get; set; }
    [JsonPropertyName("grand_total_paise")]
    [JsonConverter(typeof(PosSalePaiseIntConverter))]
    public int GrandTotalPaise { get; set; }
    [JsonPropertyName("round_off_paise")]
    [JsonConverter(typeof(PosSalePaiseIntConverter))]
    public int RoundOffPaise { get; set; }
    [JsonPropertyName("reward_discount_amount_paise")]
    [JsonConverter(typeof(PosSalePaiseIntConverter))]
    public int RewardDiscountAmountPaise { get; set; }
    [JsonPropertyName("reward_points_earned")]
    public int RewardPointsEarned { get; set; }
    [JsonPropertyName("reward_points_redeemed")]
    public int RewardPointsRedeemed { get; set; }
    [JsonPropertyName("is_paid")]
    public int IsPaid { get; set; }
}

public sealed class PosSalePaiseIntConverter : JsonConverter<int>
{
    public override int Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        if (reader.TokenType == JsonTokenType.Null)
            return 0;

        if (reader.TokenType == JsonTokenType.Number)
        {
            if (reader.TryGetInt32(out var intVal))
                return intVal;
            if (reader.TryGetDouble(out var dblVal))
                return (int)Math.Round(dblVal, MidpointRounding.AwayFromZero);
            if (reader.TryGetDecimal(out var decVal))
                return (int)Math.Round(decVal, MidpointRounding.AwayFromZero);
            return 0;
        }

        if (reader.TokenType == JsonTokenType.String)
        {
            var str = reader.GetString();
            if (string.IsNullOrWhiteSpace(str))
                return 0;
            if (int.TryParse(str, out var intVal))
                return intVal;
            if (double.TryParse(str, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out var dblVal))
                return (int)Math.Round(dblVal, MidpointRounding.AwayFromZero);
            return 0;
        }

        return 0;
    }

    public override void Write(Utf8JsonWriter writer, int value, JsonSerializerOptions options)
    {
        writer.WriteNumberValue(value);
    }
}

public sealed class PosSaleProductIdConverter : JsonConverter<int?>
{
    public override int? Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        if (reader.TokenType == JsonTokenType.Null)
            return null;

        if (reader.TokenType == JsonTokenType.Number && reader.TryGetInt32(out var intVal))
            return intVal;

        if (reader.TokenType == JsonTokenType.String)
        {
            var str = reader.GetString();
            if (string.IsNullOrWhiteSpace(str))
                return null;
            if (int.TryParse(str, out var parsedInt))
                return parsedInt;
            // Guid string passed as product_id in cloud/web mode;
            // LocalProductId remains null (not fabricated).
            return null;
        }

        return null;
    }

    public override void Write(Utf8JsonWriter writer, int? value, JsonSerializerOptions options)
    {
        if (value.HasValue)
            writer.WriteNumberValue(value.Value);
        else
            writer.WriteNullValue();
    }
}

public sealed class PosSaleLineSnapshot
{
    [JsonPropertyName("id")]
    public int? Id { get; set; }
    [JsonPropertyName("product_id")]
    [JsonConverter(typeof(PosSaleProductIdConverter))]
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
    [JsonConverter(typeof(PosSalePaiseIntConverter))]
    public int Qty { get; set; }
    [JsonPropertyName("unit_price_paise")]
    [JsonConverter(typeof(PosSalePaiseIntConverter))]
    public int UnitPricePaise { get; set; }
    [JsonPropertyName("gst_percent")]
    public int GstPercent { get; set; }
    [JsonPropertyName("discount_type")]
    public string? DiscountType { get; set; }
    [JsonPropertyName("discount_value")]
    public int? DiscountValue { get; set; }
    [JsonPropertyName("discount_paise")]
    [JsonConverter(typeof(PosSalePaiseIntConverter))]
    public int DiscountPaise { get; set; }
    [JsonPropertyName("line_subtotal_paise")]
    [JsonConverter(typeof(PosSalePaiseIntConverter))]
    public int LineSubtotalPaise { get; set; }
    [JsonPropertyName("line_gst_paise")]
    [JsonConverter(typeof(PosSalePaiseIntConverter))]
    public int LineGstPaise { get; set; }
    [JsonPropertyName("line_total_paise")]
    [JsonConverter(typeof(PosSalePaiseIntConverter))]
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
    [JsonConverter(typeof(PosSalePaiseIntConverter))]
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
    [JsonConverter(typeof(PosSaleProductIdConverter))]
    public int? ProductId { get; set; }
    [JsonPropertyName("localProductId")]
    public int? LocalProductId { get; set; }
    [JsonPropertyName("cloudProductId")]
    public Guid? CloudProductId { get; set; }
    [JsonPropertyName("qty")]
    [JsonConverter(typeof(PosSalePaiseIntConverter))]
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