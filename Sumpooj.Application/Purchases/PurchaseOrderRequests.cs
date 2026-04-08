namespace Sumpooj.Application.Purchases;

public class CreatePurchaseOrderRequest
{
    public Guid SupplierId { get; set; }
    public DateTime ExpectedDeliveryDate { get; set; }
    public string? Notes { get; set; }
    public List<PurchaseOrderItemRequest> Items { get; set; } = new();

    // Backward-compatible legacy fields. These are ignored for PO planning flow.
    public string? InvoiceNumber { get; set; }
    public DateTime PurchaseDate { get; set; } = DateTime.UtcNow;
    public string? PaymentTerms { get; set; }
    public string? Location { get; set; }
    public decimal ShippingCost { get; set; }
    public decimal TaxRate { get; set; }
}

public class PurchaseOrderItemRequest
{
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = default!;
    public string? Sku { get; set; }
    public string? Unit { get; set; }
    public int Quantity { get; set; }
    public decimal ExpectedCostPerUnit { get; set; }

    // Backward-compatible legacy aliases
    public decimal? CostPerUnit { get; set; }
    public bool IsPerishable { get; set; }
    public int ShelfLifeDays { get; set; }
    public string? BatchNumber { get; set; }
    public DateTime? ExpiryDate { get; set; }
    public string? StorageLocation { get; set; }
    public decimal? SellingPrice { get; set; }

    public decimal ResolveExpectedCostPerUnit()
    {
        if (ExpectedCostPerUnit > 0) return ExpectedCostPerUnit;
        return CostPerUnit ?? 0;
    }
}

public class ReceivePurchaseOrderRequest
{
    public DateTime ActualDeliveryDate { get; set; } = DateTime.UtcNow;
    public string? InvoiceNumber { get; set; }
    public List<ReceiveItemRequest> Items { get; set; } = new();
}

public class ReceiveItemRequest
{
    public Guid ProductId { get; set; }
    public int ReceivedQuantity { get; set; }
    public decimal? ActualCostPerUnit { get; set; }
    public string? BatchNumber { get; set; }
    public DateTime? ExpiryDate { get; set; }
    public string? StorageLocation { get; set; }
}

public class PurchaseOrderSearchRequest
{
    public string? Query { get; set; }
    public Guid? SupplierId { get; set; }
    public string? Status { get; set; }
    public DateTime? FromDate { get; set; }
    public DateTime? ToDate { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}
