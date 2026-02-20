namespace Sumpooj.Application.Purchases;

public class PurchaseOrderDto
{
    public Guid Id { get; set; }
    public string OrderNumber { get; set; } = default!;
    public Guid SupplierId { get; set; }
    public string SupplierName { get; set; } = default!;
    public DateTime OrderDate { get; set; }
    public DateTime ExpectedDeliveryDate { get; set; }
    public DateTime? ActualDeliveryDate { get; set; }
    public string Status { get; set; } = default!;
    public bool IsActive { get; set; }
    public decimal SubTotal { get; set; }
    public decimal TaxAmount { get; set; }
    public decimal ShippingCost { get; set; }
    public decimal TotalAmount { get; set; }
    public string? Notes { get; set; }
    public string? InvoiceNumber { get; set; }
    public string? PaymentTerms { get; set; }
    public string? Location { get; set; }
    public List<PurchaseOrderItemDto> Items { get; set; } = new();
    public DateTime CreatedAtUtc { get; set; }
}

public class PurchaseOrderItemDto
{
    public Guid Id { get; set; }
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = default!;
    public string? Sku { get; set; }
    public string? Unit { get; set; }
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal TotalPrice { get; set; }
    public int ReceivedQuantity { get; set; }
    public bool IsPerishable { get; set; }
    public int ShelfLifeDays { get; set; }
    public string? BatchNumber { get; set; }
    public DateTime? ExpiryDate { get; set; }
    public string? StorageLocation { get; set; }
}

public class PurchaseOrderListDto
{
    public Guid Id { get; set; }
    public string OrderNumber { get; set; } = default!;
    public string SupplierName { get; set; } = default!;
    public DateTime OrderDate { get; set; }
    public DateTime ExpectedDeliveryDate { get; set; }
    public string Status { get; set; } = default!;
    public decimal TotalAmount { get; set; }
    public int ItemCount { get; set; }
}
