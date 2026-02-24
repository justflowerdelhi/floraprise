namespace Sumpooj.Domain.Entities;

public class SalesOrder : BaseEntity
{
    private readonly List<SalesOrderItem> _items = new();
    private SalesOrder() { }

    public SalesOrder(
        Guid companyId,
        Guid customerId,
        OrderType orderType,
        string deliveryAddressLine1,
        string? deliveryAddressLine2,
        string city,
        string postalCode,
        string? state)
    {
        CompanyId = companyId;
        CustomerId = customerId;
        OrderType = orderType;
        OrderNumber = GenerateSalesOrderNumber();
        Status = SalesOrderStatus.Draft;
        DeliveryAddressLine1 = deliveryAddressLine1;
        DeliveryAddressLine2 = deliveryAddressLine2;
        City = city;
        PostalCode = postalCode;
        State = state;
    }

    public string DeliveryAddressLine1 { get; private set; }
    public string? DeliveryAddressLine2 { get; private set; }
    public string City { get; private set; }
    public string PostalCode { get; private set; }
    public string? State { get; private set; }

    public Guid CompanyId { get; private set; }
    public Guid CustomerId { get; private set; }
    public string OrderNumber { get; private set; }
    public OrderType OrderType { get; private set; }
    public SalesOrderStatus Status { get; private set; }
    public string? InvoiceNumber { get; private set; }

    public IReadOnlyCollection<SalesOrderItem> Items => _items.AsReadOnly();

    // ── Item management ──────────────────────────────────────────────────

    public void AddItem(Guid productId, string productName, int quantity, decimal unitPrice)
    {
        if (Status != SalesOrderStatus.Draft)
            throw new InvalidOperationException("Items can only be added while the order is in Draft status.");

        var item = new SalesOrderItem(productId, productName, quantity, unitPrice);
        _items.Add(item);
        MarkUpdated();
    }

    public void RemoveItem(Guid itemId)
    {
        if (Status != SalesOrderStatus.Draft)
            throw new InvalidOperationException("Items can only be removed while the order is in Draft status.");

        var item = _items.FirstOrDefault(i => i.Id == itemId);
        if (item != null)
        {
            _items.Remove(item);
            MarkUpdated();
        }
    }

    // ── Status transitions ───────────────────────────────────────────────

    /// <summary>
    /// Confirm a draft order.
    /// </summary>
    public void Confirm()
    {
        if (Status != SalesOrderStatus.Draft)
            throw new InvalidOperationException("Only Draft orders can be confirmed.");

        Status = SalesOrderStatus.Confirmed;
        MarkUpdated();
    }

    /// <summary>
    /// Move a confirmed local order into production.
    /// Only allowed for PhoneLocal orders.
    /// </summary>
    public void MarkInProduction()
    {
        if (OrderType != OrderType.PhoneLocal)
            throw new InvalidOperationException("Only PhoneLocal orders can be marked InProduction.");
        if (Status != SalesOrderStatus.Confirmed)
            throw new InvalidOperationException("Only Confirmed orders can be moved to InProduction.");

        Status = SalesOrderStatus.InProduction;
        MarkUpdated();
    }

    /// <summary>
    /// Mark a confirmed outstation order as sent to vendor.
    /// Only allowed for PhoneOutstation orders.
    /// </summary>
    public void MarkSentToVendor()
    {
        if (OrderType != OrderType.PhoneOutstation)
            throw new InvalidOperationException("Only PhoneOutstation orders can be marked SentToVendor.");
        if (Status != SalesOrderStatus.Confirmed)
            throw new InvalidOperationException("Only Confirmed orders can be sent to vendor.");

        Status = SalesOrderStatus.SentToVendor;
        MarkUpdated();
    }

    /// <summary>
    /// Cancel the order. Not allowed once delivered.
    /// </summary>
    public void Cancel()
    {
        if (Status == SalesOrderStatus.Delivered)
            throw new InvalidOperationException("Cannot cancel a Delivered order.");
        if (Status == SalesOrderStatus.Cancelled)
            throw new InvalidOperationException("Order is already Cancelled.");

        Status = SalesOrderStatus.Cancelled;
        MarkUpdated();
    }

    /// <summary>
    /// Sets the invoice number for this order.
    /// </summary>
    public void SetInvoiceNumber(string invoiceNumber)
    {
        InvoiceNumber = invoiceNumber;
        MarkUpdated();
    }

    private static string GenerateSalesOrderNumber()
    {
        return $"SO-{DateTime.UtcNow:yyyyMMdd}-{Guid.NewGuid().ToString()[..8].ToUpper()}";
    }

    /// <summary>
    /// Generates a new invoice number with format INV-yyyyMMdd-XXXXXX.
    /// </summary>
    public static string GenerateInvoiceNumber()
    {
        var random = new Random();
        var digits = random.Next(100000, 999999);
        return $"INV-{DateTime.UtcNow:yyyyMMdd}-{digits}";
    }
}

public class SalesOrderItem
{
    private SalesOrderItem() { }

    public SalesOrderItem(Guid productId, string productName, int quantity, decimal unitPrice)
    {
        if (quantity <= 0)
            throw new ArgumentException("Quantity must be greater than zero.");
        if (unitPrice < 0)
            throw new ArgumentException("Unit price cannot be negative.");

        Id = Guid.NewGuid();
        ProductId = productId;
        ProductName = productName;
        Quantity = quantity;
        UnitPrice = unitPrice;
        TotalPrice = quantity * unitPrice;
    }

    public Guid Id { get; private set; }
    public Guid ProductId { get; private set; }
    public string ProductName { get; private set; }
    public int Quantity { get; private set; }
    public decimal UnitPrice { get; private set; }
    public decimal TotalPrice { get; private set; }
}
