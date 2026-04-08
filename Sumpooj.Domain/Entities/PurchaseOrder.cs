using System.ComponentModel.DataAnnotations.Schema;

namespace Sumpooj.Domain.Entities;

public class PurchaseOrder : BaseEntity
{
    private readonly List<PurchaseOrderItem> _items = new();
    private PurchaseOrder() { }

    public PurchaseOrder(
        Guid companyId,
        Guid supplierId,
        DateTime expectedDeliveryDate)
    {
        CompanyId = companyId;
        SupplierId = supplierId;
        OrderNumber = GeneratePurchaseOrderNumber();
        OrderDate = DateTime.UtcNow;
        ExpectedDeliveryDate = EnsureUtc(expectedDeliveryDate);
        Status = PurchaseOrderStatus.Draft;
        IsActive = true;
    }

    public Guid CompanyId { get; private set; }
    public Guid SupplierId { get; private set; }
    public string OrderNumber { get; private set; }
    public DateTime OrderDate { get; private set; }
    public DateTime ExpectedDeliveryDate { get; private set; }
    public DateTime? ActualDeliveryDate { get; private set; }
    public PurchaseOrderStatus Status { get; private set; }
    public bool IsActive { get; private set; }
    public bool IsInventoryProcessed { get; private set; }

    public decimal TotalAmount { get; private set; }
    public string? Notes { get; private set; }
    [NotMapped]
    public string? InvoiceNumber { get; private set; }

    public IReadOnlyCollection<PurchaseOrderItem> Items => _items.AsReadOnly();

    private static string GeneratePurchaseOrderNumber()
    {
        return $"PO-{DateTime.UtcNow:yyyyMMdd}-{Guid.NewGuid().ToString()[..8].ToUpper()}";
    }

    public void AddItem(Guid productId, string productName, int quantity, decimal unitPrice)
    {
        if (Status != PurchaseOrderStatus.Draft)
            throw new InvalidOperationException("Cannot modify items for purchase orders in current status");

        var item = new PurchaseOrderItem(productId, productName, quantity, unitPrice);
        _items.Add(item);
        RecalculateTotal();
    }

    public void RemoveItem(Guid productId)
    {
        if (Status != PurchaseOrderStatus.Draft)
            throw new InvalidOperationException("Cannot modify items for purchase orders in current status");

        var item = _items.FirstOrDefault(i => i.ProductId == productId);
        if (item != null)
        {
            _items.Remove(item);
            RecalculateTotal();
        }
    }

    private void RecalculateTotal()
    {
        TotalAmount = _items.Sum(i => i.TotalPrice);
        MarkUpdated();
    }

    public void UpdateExpectedDeliveryDate(DateTime date)
    {
        ExpectedDeliveryDate = EnsureUtc(date);
        MarkUpdated();
    }

    public void AddNotes(string notes)
    {
        Notes = string.IsNullOrEmpty(Notes)
            ? notes
            : $"{Notes}\n{notes}";
        MarkUpdated();
    }

    public void Submit()
    {
        if (Status != PurchaseOrderStatus.Draft)
            throw new InvalidOperationException("Only draft purchase orders can be submitted");

        if (!_items.Any())
            throw new InvalidOperationException("Cannot submit purchase order without items");

        Status = PurchaseOrderStatus.Submitted;
        MarkUpdated();
    }

    public void Approve()
    {
        if (Status != PurchaseOrderStatus.Submitted)
            throw new InvalidOperationException("Only submitted purchase orders can be approved");

        Status = PurchaseOrderStatus.Approved;
        MarkUpdated();
    }

    public void MarkReceived(DateTime? actualDeliveryDate = null)
    {
        if (Status != PurchaseOrderStatus.Approved)
            throw new InvalidOperationException("Only approved purchase orders can be marked as received");

        Status = PurchaseOrderStatus.Received;
        ActualDeliveryDate = actualDeliveryDate.HasValue ? EnsureUtc(actualDeliveryDate.Value) : DateTime.UtcNow;
        MarkUpdated();
    }

    public void SetInvoiceNumber(string? invoiceNumber)
    {
        var normalized = string.IsNullOrWhiteSpace(invoiceNumber)
            ? null
            : invoiceNumber.Trim();

        InvoiceNumber = normalized;

        const string marker = "[InvoiceNumber]";
        var lines = (Notes ?? string.Empty)
            .Split('\n', StringSplitOptions.RemoveEmptyEntries)
            .Where(line => !line.StartsWith(marker, StringComparison.OrdinalIgnoreCase))
            .ToList();

        if (!string.IsNullOrWhiteSpace(normalized))
        {
            lines.Add($"{marker}{normalized}");
        }

        Notes = lines.Count == 0 ? null : string.Join("\n", lines);
        MarkUpdated();
    }

    public void MarkInventoryProcessed()
    {
        if (!IsInventoryProcessed)
        {
            IsInventoryProcessed = true;
            MarkUpdated();
        }
    }

    public void RecalculateTotalsFromItems()
    {
        RecalculateTotal();
    }

    public void Complete()
    {
        if (Status != PurchaseOrderStatus.Received)
            throw new InvalidOperationException("Only received purchase orders can be completed");

        Status = PurchaseOrderStatus.Completed;
        MarkUpdated();
    }

    public void Cancel(string? reason = null)
    {
        if (Status == PurchaseOrderStatus.Completed || Status == PurchaseOrderStatus.Cancelled)
            throw new InvalidOperationException("Cannot cancel completed or already cancelled purchase orders");

        Status = PurchaseOrderStatus.Cancelled;
        if (!string.IsNullOrEmpty(reason))
            Notes = reason;
        MarkUpdated();
    }

    public void Deactivate()
    {
        IsActive = false;
        MarkUpdated();
    }
}

public class PurchaseOrderItem
{
    private PurchaseOrderItem() { }

    public PurchaseOrderItem(Guid productId, string productName, int quantity, decimal expectedPrice)
    {
        Id = Guid.NewGuid();
        ProductId = productId;
        ProductName = productName;
        Quantity = quantity;
        UnitPrice = expectedPrice;
        TotalPrice = quantity * expectedPrice;
    }

    public Guid Id { get; private set; }
    public Guid ProductId { get; private set; }
    public string ProductName { get; private set; }
    public int Quantity { get; private set; }
    public decimal UnitPrice { get; private set; }
    [NotMapped]
    public decimal ExpectedPrice
    {
        get => UnitPrice;
        private set => UnitPrice = value;
    }
    public decimal TotalPrice { get; private set; }
    public int ReceivedQuantity { get; private set; }
    [NotMapped]
    public decimal ActualUnitPrice => ReceivedQuantity > 0
        ? TotalPrice / ReceivedQuantity
        : UnitPrice;
    public string? Sku { get; private set; }
    public string? Unit { get; private set; }
    public bool IsPerishable { get; private set; }
    public int ShelfLifeDays { get; private set; }
    public bool? IsQuantityMismatch { get; private set; }
    public bool? IsPriceMismatch { get; private set; }

    public void SetProductDetails(string? sku, string? unit, bool isPerishable, int shelfLifeDays)
    {
        Sku = sku;
        Unit = unit;
        IsPerishable = isPerishable;
        ShelfLifeDays = shelfLifeDays;
    }

    public void UpdateReceivedQuantity(int receivedQuantity)
    {
        if (receivedQuantity < 0)
            throw new ArgumentException("Received quantity cannot be negative");

        ReceivedQuantity = receivedQuantity;
    }

    public void ApplyReceive(int receivedQuantity, decimal actualUnitPrice)
    {
        if (receivedQuantity < 0)
            throw new ArgumentException("Received quantity cannot be negative");
        if (actualUnitPrice < 0)
            throw new ArgumentException("Actual unit price cannot be negative");

        ReceivedQuantity = receivedQuantity;
        TotalPrice = receivedQuantity * actualUnitPrice;
    }

    public void MarkReceived(int quantity)
    {
        if (quantity < 0 || quantity > Quantity)
            throw new ArgumentException("Invalid received quantity");

        ReceivedQuantity = quantity;
    }

    public void SetMismatchFlags(bool isQuantityMismatch, bool isPriceMismatch)
    {
        IsQuantityMismatch = isQuantityMismatch;
        IsPriceMismatch = isPriceMismatch;
    }

    public bool IsFullyReceived() => ReceivedQuantity >= Quantity;
}
