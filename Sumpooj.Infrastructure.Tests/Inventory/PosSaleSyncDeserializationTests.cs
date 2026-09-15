using System.Text.Json;
using Sumpooj.Application.Mobile;
using Xunit;

namespace Sumpooj.Infrastructure.Tests.Inventory;

public class PosSaleSyncDeserializationTests
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    [Fact]
    public void RoundOffPaise_Zero_DeserializesAsIntegerZero()
    {
        const string json = """
        {
            "clientSyncId": "sync-zero",
            "localOrderId": 100,
            "order": {
                "subtotal_paise": 50000,
                "gst_total_paise": 0,
                "grand_total_paise": 50000,
                "round_off_paise": 0
            }
        }
        """;

        var request = JsonSerializer.Deserialize<PosSaleSyncRequest>(json, JsonOptions);
        Assert.NotNull(request);
        Assert.Equal(0, request.Order.RoundOffPaise);
        Assert.Equal(50000, request.Order.SubtotalPaise);
        Assert.Equal(50000, request.Order.GrandTotalPaise);
    }

    [Fact]
    public void RoundOffPaise_NegativeZeroFloat_DeserializesAsIntegerZero()
    {
        // This reproduces the exact production failure payload token: "round_off_paise": -0.0
        const string json = """
        {
            "clientSyncId": "sync-neg-zero",
            "localOrderId": 101,
            "order": {
                "subtotal_paise": 50000,
                "gst_total_paise": 0,
                "grand_total_paise": 50000,
                "round_off_paise": -0.0
            }
        }
        """;

        var request = JsonSerializer.Deserialize<PosSaleSyncRequest>(json, JsonOptions);
        Assert.NotNull(request);
        Assert.Equal(0, request.Order.RoundOffPaise);
    }

    [Fact]
    public void RoundOffPaise_PositiveZeroFloat_DeserializesAsIntegerZero()
    {
        const string json = """
        {
            "clientSyncId": "sync-pos-zero",
            "localOrderId": 102,
            "order": {
                "round_off_paise": 0.0
            }
        }
        """;

        var request = JsonSerializer.Deserialize<PosSaleSyncRequest>(json, JsonOptions);
        Assert.NotNull(request);
        Assert.Equal(0, request.Order.RoundOffPaise);
    }

    [Fact]
    public void RoundOffPaise_PositiveRoundOff_DeserializesCorrectly()
    {
        const string json = """
        {
            "clientSyncId": "sync-pos-round",
            "localOrderId": 103,
            "order": {
                "subtotal_paise": 49960,
                "round_off_paise": 40,
                "grand_total_paise": 50000
            }
        }
        """;

        var request = JsonSerializer.Deserialize<PosSaleSyncRequest>(json, JsonOptions);
        Assert.NotNull(request);
        Assert.Equal(40, request.Order.RoundOffPaise);
    }

    [Fact]
    public void RoundOffPaise_NegativeRoundOff_DeserializesCorrectly()
    {
        const string json = """
        {
            "clientSyncId": "sync-neg-round",
            "localOrderId": 104,
            "order": {
                "subtotal_paise": 50020,
                "round_off_paise": -20,
                "grand_total_paise": 50000
            }
        }
        """;

        var request = JsonSerializer.Deserialize<PosSaleSyncRequest>(json, JsonOptions);
        Assert.NotNull(request);
        Assert.Equal(-20, request.Order.RoundOffPaise);
    }

    [Fact]
    public void RoundOffPaise_NullOrMissing_DefaultsToZero()
    {
        const string jsonWithNull = """
        {
            "clientSyncId": "sync-null",
            "localOrderId": 105,
            "order": {
                "round_off_paise": null
            }
        }
        """;

        var request1 = JsonSerializer.Deserialize<PosSaleSyncRequest>(jsonWithNull, JsonOptions);
        Assert.NotNull(request1);
        Assert.Equal(0, request1.Order.RoundOffPaise);

        const string jsonMissing = """
        {
            "clientSyncId": "sync-missing",
            "localOrderId": 106,
            "order": {}
        }
        """;

        var request2 = JsonSerializer.Deserialize<PosSaleSyncRequest>(jsonMissing, JsonOptions);
        Assert.NotNull(request2);
        Assert.Equal(0, request2.Order.RoundOffPaise);
    }

    [Fact]
    public void CompleteProWebPosPayload_DeserializesAllInt32PaiseAndGuidProducts()
    {
        var cloudProductId = Guid.NewGuid();
        var json = $$"""
        {
            "clientSyncId": "web_pos_sync_test_001",
            "localOrderId": 1726272000,
            "order": {
                "order_no": "ORD-1726272000000",
                "customer_phone": "9876543210",
                "customer_name": "Walkin Customer",
                "source": "pos",
                "channel": "walkin",
                "fulfilment_type": "takeAway",
                "confirmed_at": "2026-09-14T12:00:00.000Z",
                "business_date": "2026-09-14T00:00:00.000Z",
                "subtotal_paise": 50000,
                "gst_total_paise": 0,
                "discount_total_paise": 0,
                "grand_total_paise": 50000,
                "round_off_paise": 0,
                "reward_discount_amount_paise": 0,
                "reward_points_earned": 0,
                "reward_points_redeemed": 0,
                "is_paid": 1
            },
            "lines": [
                {
                    "id": 1,
                    "product_id": "{{cloudProductId}}",
                    "cloudProductId": "{{cloudProductId}}",
                    "description": "Red Roses Bouquet",
                    "qty": 2,
                    "unit_price_paise": 25000,
                    "gst_percent": 0,
                    "discount_paise": 0,
                    "line_subtotal_paise": 50000,
                    "line_gst_paise": 0,
                    "line_total_paise": 50000,
                    "source": "product"
                }
            ],
            "payments": [
                {
                    "id": 1,
                    "method": "cash",
                    "amount_paise": 50000,
                    "created_at": "2026-09-14T12:00:00.000Z"
                }
            ],
            "inventoryTransactions": [
                {
                    "id": 1,
                    "product_id": "{{cloudProductId}}",
                    "cloudProductId": "{{cloudProductId}}",
                    "qty": 2,
                    "created_at": "2026-09-14T12:00:00.000Z"
                }
            ]
        }
        """;

        var request = JsonSerializer.Deserialize<PosSaleSyncRequest>(json, JsonOptions);
        Assert.NotNull(request);
        Assert.Equal("web_pos_sync_test_001", request.ClientSyncId);
        Assert.Equal(1726272000, request.LocalOrderId);

        // Order financials
        Assert.Equal(50000, request.Order.SubtotalPaise);
        Assert.Equal(0, request.Order.GstTotalPaise);
        Assert.Equal(0, request.Order.DiscountTotalPaise);
        Assert.Equal(50000, request.Order.GrandTotalPaise);
        Assert.Equal(0, request.Order.RoundOffPaise);
        Assert.Equal(0, request.Order.RewardDiscountAmountPaise);
        Assert.Equal(1, request.Order.IsPaid);

        // Lines
        var line = Assert.Single(request.Lines);
        Assert.Equal(1, line.Id);
        Assert.Null(line.ProductId); // String Guid does not fabricate local int ProductId
        Assert.Equal(cloudProductId, line.CloudProductId);
        Assert.Equal(2, line.Qty);
        Assert.Equal(25000, line.UnitPricePaise);
        Assert.Equal(50000, line.LineSubtotalPaise);
        Assert.Equal(50000, line.LineTotalPaise);

        // Payments
        var payment = Assert.Single(request.Payments);
        Assert.Equal("cash", payment.Method);
        Assert.Equal(50000, payment.AmountPaise);

        // Inventory transactions
        var inventory = Assert.Single(request.InventoryTransactions);
        Assert.Null(inventory.ProductId);
        Assert.Equal(cloudProductId, inventory.CloudProductId);
        Assert.Equal(2, inventory.Qty);
    }

    [Fact]
    public void AndroidCloudPayload_PreservesLocalIntegerProductIdAndCloudGuid()
    {
        var cloudProductId = Guid.NewGuid();
        var json = $$"""
        {
            "clientSyncId": "android_pos_sync_001",
            "localOrderId": 42,
            "order": {
                "subtotal_paise": 20000,
                "gst_total_paise": 0,
                "discount_total_paise": 0,
                "grand_total_paise": 20000,
                "round_off_paise": 0,
                "is_paid": 1
            },
            "lines": [
                {
                    "id": 1,
                    "product_id": 99,
                    "localProductId": 99,
                    "cloudProductId": "{{cloudProductId}}",
                    "qty": 1,
                    "unit_price_paise": 20000,
                    "line_subtotal_paise": 20000,
                    "line_total_paise": 20000
                }
            ],
            "payments": [
                {
                    "id": 1,
                    "method": "cash",
                    "amount_paise": 20000
                }
            ],
            "inventoryTransactions": [
                {
                    "id": 1,
                    "product_id": 99,
                    "localProductId": 99,
                    "cloudProductId": "{{cloudProductId}}",
                    "qty": 1
                }
            ]
        }
        """;

        var request = JsonSerializer.Deserialize<PosSaleSyncRequest>(json, JsonOptions);
        Assert.NotNull(request);
        var line = Assert.Single(request.Lines);
        Assert.Equal(99, line.ProductId);
        Assert.Equal(99, line.LocalProductId);
        Assert.Equal(cloudProductId, line.CloudProductId);

        var inventory = Assert.Single(request.InventoryTransactions);
        Assert.Equal(99, inventory.ProductId);
        Assert.Equal(99, inventory.LocalProductId);
        Assert.Equal(cloudProductId, inventory.CloudProductId);
    }
}
