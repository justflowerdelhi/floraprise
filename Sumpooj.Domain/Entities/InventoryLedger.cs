namespace Sumpooj.Domain.Entities;

public class InventoryLedger : BaseEntity
{
    private InventoryLedger() { }

    public InventoryLedger(
        Guid companyId,
        Guid productId,
        string reference,
        string referenceType,
        int quantityChange,
        int balanceAfter,
        string? notes)
    {
        CompanyId = companyId;
        ProductId = productId;
        Reference = reference;
        ReferenceType = referenceType;
        QuantityChange = quantityChange;
        BalanceAfter = balanceAfter;
        Notes = notes;
        CreatedAtUtc = DateTime.UtcNow;
    }

    public Guid CompanyId { get; private set; }
    public Guid ProductId { get; private set; }

    public string Reference { get; private set; } = default!;
    public string ReferenceType { get; private set; } = default!;

    /// <summary>Alias for ReferenceType. Values: "SALE", "PURCHASE", "ADJUSTMENT", "DAMAGED"</summary>
    public string Type => ReferenceType;

    public int QuantityChange { get; private set; }
    public int BalanceAfter { get; private set; }

    public string? Notes { get; private set; }
}

public class PosSaleSyncReceipt : BaseEntity
{
    private PosSaleSyncReceipt() { }
    public PosSaleSyncReceipt(Guid companyId, string clientSyncId, int localOrderId, string deviceId,
        Guid cloudOrderId, Guid? cloudCustomerId, string payloadHash, DateTime completedAtUtc)
    {
        CompanyId = companyId;
        ClientSyncId = clientSyncId.Trim();
        LocalOrderId = localOrderId;
        DeviceId = deviceId.Trim();
        CloudOrderId = cloudOrderId;
        CloudCustomerId = cloudCustomerId;
        PayloadHash = payloadHash.Trim();
        CompletedAtUtc = EnsureUtc(completedAtUtc);
    }
    public Guid CompanyId { get; private set; }
    public string ClientSyncId { get; private set; } = default!;
    public int LocalOrderId { get; private set; }
    public string DeviceId { get; private set; } = default!;
    public Guid CloudOrderId { get; private set; }
    public Guid? CloudCustomerId { get; private set; }
    public string PayloadHash { get; private set; } = default!;
    public DateTime CompletedAtUtc { get; private set; }
}

public class PosSaleSyncInventoryTransaction : BaseEntity
{
    private PosSaleSyncInventoryTransaction() { }
    public PosSaleSyncInventoryTransaction(Guid companyId, Guid receiptId, string clientInventoryTransactionId,
        Guid cloudOrderId, Guid productId, int quantity, DateTime occurredAtUtc)
    {
        CompanyId = companyId;
        PosSaleSyncReceiptId = receiptId;
        ClientInventoryTransactionId = clientInventoryTransactionId.Trim();
        CloudOrderId = cloudOrderId;
        ProductId = productId;
        Quantity = quantity;
        OccurredAtUtc = EnsureUtc(occurredAtUtc);
    }
    public Guid CompanyId { get; private set; }
    public Guid PosSaleSyncReceiptId { get; private set; }
    public string ClientInventoryTransactionId { get; private set; } = default!;
    public Guid CloudOrderId { get; private set; }
    public Guid ProductId { get; private set; }
    public int Quantity { get; private set; }
    public DateTime OccurredAtUtc { get; private set; }
}