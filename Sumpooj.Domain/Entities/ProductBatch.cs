namespace Sumpooj.Domain.Entities;

public class ProductBatch : BaseEntity
{
    private ProductBatch() { }

    public ProductBatch(
        Guid companyId,
        Guid productId,
        string batchNumber,
        int quantityReceived,
        decimal costPerUnit,
        DateTime receivedDate,
        DateTime? expiryDate,
        Guid? supplierId,
        Guid? locationId,
        string? storageLocation)
    {
        CompanyId = companyId;
        ProductId = productId;
        BatchNumber = batchNumber;
        QuantityReceived = quantityReceived;
        QuantityRemaining = quantityReceived;
        CostPerUnit = costPerUnit;
        ReceivedDate = receivedDate;
        ExpiryDate = expiryDate;
        SupplierId = supplierId;
        LocationId = locationId;
        StorageLocation = storageLocation;
        IsActive = true;
    }

    public Guid CompanyId { get; private set; }
    public Guid ProductId { get; private set; }
    public string BatchNumber { get; private set; }
    public int QuantityReceived { get; private set; }
    public int QuantityRemaining { get; private set; }
    public decimal CostPerUnit { get; private set; }
    public decimal SellingPricePerUnit { get; private set; }
    public DateTime ReceivedDate { get; private set; }
    public DateTime? ExpiryDate { get; private set; }
    public Guid? SupplierId { get; private set; }
    public Guid? LocationId { get; private set; }
    public string? StorageLocation { get; private set; }
    public Guid? PurchaseOrderId { get; private set; }
    public bool IsActive { get; private set; }

    // Multi-unit flower support
    public int StemsInStock { get; private set; }
    public int UsedUnits { get; private set; }
    public int DamagedUnits { get; private set; }

    // Reservation support
    public int ReservedUnits { get; private set; }

    public void SetSellingPrice(decimal price)
    {
        if (price < 0)
            throw new ArgumentException("Price cannot be negative");
        SellingPricePerUnit = price;
        MarkUpdated();
    }

    public void DeductQuantity(int quantity)
    {
        if (quantity > QuantityRemaining)
            throw new InvalidOperationException("Insufficient quantity in batch");

        QuantityRemaining -= quantity;
        MarkUpdated();
    }

    public void AddQuantity(int quantity)
    {
        QuantityRemaining += quantity;
        MarkUpdated();
    }

    public void UpdateStorageLocation(string? storageLocation)
    {
        StorageLocation = storageLocation;
        MarkUpdated();
    }

    public void LinkToPurchaseOrder(Guid purchaseOrderId)
    {
        PurchaseOrderId = purchaseOrderId;
        MarkUpdated();
    }

    // ── Multi-unit derived calculations ──────────────────────────────────

    /// <summary>
    /// Returns the total logical units in this batch.
    /// For multi-unit products a single stem yields multiple usable units.
    /// </summary>
    public int GetTotalUnits(Product product)
    {
        if (product == null) throw new ArgumentNullException(nameof(product));
        return product.IsMultiUnit
            ? StemsInStock * product.AvgUnitsPerStem
            : StemsInStock;
    }

    /// <summary>
    /// Returns the number of units still available for use
    /// (total minus used and damaged).
    /// </summary>
    public int GetAvailableUnits(Product product)
    {
        return GetTotalUnits(product) - UsedUnits - DamagedUnits;
    }

    /// <summary>
    /// Returns the number of stems that have been consumed based on UsedUnits.
    /// For multi-unit products, calculates how many stems were needed to yield the used units.
    /// </summary>
    public int GetConsumedStems(Product product)
    {
        if (!product.IsMultiUnit)
            return UsedUnits;

        return (int)Math.Ceiling((double)UsedUnits / product.AvgUnitsPerStem);
    }

    /// <summary>
    /// Returns the number of stems remaining after accounting for consumed stems.
    /// </summary>
    public int GetRemainingStems(Product product)
    {
        return StemsInStock - GetConsumedStems(product);
    }

    /// <summary>
    /// Returns how many units are used in the last partially consumed stem.
    /// For non-multi-unit products, returns 0.
    /// </summary>
    public int GetPartialUsedUnits(Product product)
    {
        if (!product.IsMultiUnit)
            return 0;

        var remainder = UsedUnits % product.AvgUnitsPerStem;
        return remainder;
    }

    /// <summary>
    /// Returns the effective remaining units (total minus used and damaged).
    /// </summary>
    public int GetEffectiveRemainingUnits(Product product)
    {
        return GetTotalUnits(product) - UsedUnits - DamagedUnits;
    }

    /// <summary>
    /// Returns the number of usable whole stems remaining.
    /// For non-multi-unit products, returns stems minus used and damaged.
    /// For multi-unit products, calculates how many whole stems can still be derived.
    /// </summary>
    public int GetEffectiveRemainingStems(Product product)
    {
        if (!product.IsMultiUnit)
            return StemsInStock - UsedUnits - DamagedUnits;

        var effectiveUnits = GetEffectiveRemainingUnits(product);
        return (int)Math.Floor((double)effectiveUnits / product.AvgUnitsPerStem);
    }

    // ── Mutators for multi-unit fields ───────────────────────────────────

    public void SetStemsInStock(int stems)
    {
        if (stems < 0)
            throw new ArgumentException("StemsInStock cannot be negative.");
        StemsInStock = stems;
        MarkUpdated();
    }

    /// <summary>
    /// Record units that have been consumed from this batch.
    /// Validates that used + damaged never exceeds total units.
    /// </summary>
    public void RecordUsedUnits(int units, Product product)
    {
        if (units < 0)
            throw new ArgumentException("UsedUnits cannot be negative.");
        int newUsed = UsedUnits + units;
        ValidateUnitConsumption(newUsed, DamagedUnits, product);
        UsedUnits = newUsed;
        MarkUpdated();
        ValidateIntegrity(product);
    }

    /// <summary>
    /// Record units that have been damaged in this batch.
    /// Validates that used + damaged never exceeds total units.
    /// </summary>
    public void RecordDamagedUnits(int units, Product product)
    {
        if (units < 0)
            throw new ArgumentException("DamagedUnits cannot be negative.");
        int newDamaged = DamagedUnits + units;
        ValidateUnitConsumption(UsedUnits, newDamaged, product);
        DamagedUnits = newDamaged;
        MarkUpdated();
        ValidateIntegrity(product);
    }

    /// <summary>
    /// Atomically records a damaged unit and its replacement.
    /// Use when a designer damages a bud and replaces it with another.
    /// Increments both DamagedUnits and UsedUnits by the specified count.
    /// </summary>
    public void RecordDamagedAndReplaced(int units, Product product)
    {
        if (units < 0)
            throw new ArgumentException("Units cannot be negative.");
        int newUsed = UsedUnits + units;
        int newDamaged = DamagedUnits + units;
        ValidateUnitConsumption(newUsed, newDamaged, product);
        UsedUnits = newUsed;
        DamagedUnits = newDamaged;
        MarkUpdated();
    }

    /// <summary>
    /// Convenience method to record a single damaged unit and its replacement.
    /// Uses existing validation from RecordDamagedUnits and RecordUsedUnits.
    /// </summary>
    public void ReplaceDamagedUnit(Product product)
    {
        RecordDamagedUnits(1, product);
        RecordUsedUnits(1, product);
    }

    private void ValidateUnitConsumption(int usedUnits, int damagedUnits, Product product)
    {
        int totalUnits = GetTotalUnits(product);
        if (usedUnits + damagedUnits > totalUnits)
            throw new InvalidOperationException(
                $"UsedUnits ({usedUnits}) + DamagedUnits ({damagedUnits}) cannot exceed TotalUnits ({totalUnits}).");
    }

    /// <summary>
    /// Validates that overall inventory integrity is maintained.
    /// Used + Damaged + Reserved must not exceed TotalUnits.
    /// </summary>
    public void ValidateIntegrity(Product product)
    {
        var totalUnits = GetTotalUnits(product);

        if (UsedUnits + DamagedUnits + ReservedUnits > totalUnits)
            throw new InvalidOperationException("Inventory integrity violated.");
    }

    // ── Reservation logic ────────────────────────────────────────────

    /// <summary>
    /// Returns the number of units available for new reservations
    /// (available minus already reserved).
    /// </summary>
    public int GetAvailableForReservation(Product product)
    {
        return GetAvailableUnits(product) - ReservedUnits;
    }

    /// <summary>
    /// Reserve a number of units from the available pool.
    /// Does NOT deduct stems or record usage.
    /// </summary>
    public void ReserveUnits(int quantity, Product product)
    {
        if (quantity <= 0)
            throw new ArgumentException("Reservation quantity must be greater than zero.");

        int availableForReservation = GetAvailableForReservation(product);
        if (quantity > availableForReservation)
            throw new InvalidOperationException(
                $"Cannot reserve {quantity} units. Only {availableForReservation} available for reservation.");

        ReservedUnits += quantity;
        MarkUpdated();
        ValidateIntegrity(product);
    }

    /// <summary>
    /// Release previously reserved units back to the available pool.
    /// </summary>
    public void ReleaseReservedUnits(int quantity)
    {
        if (quantity <= 0)
            throw new ArgumentException("Release quantity must be greater than zero.");
        if (quantity > ReservedUnits)
            throw new InvalidOperationException(
                $"Cannot release {quantity} units. Only {ReservedUnits} currently reserved.");

        ReservedUnits -= quantity;
        MarkUpdated();
    }

    /// <summary>
    /// Convert a reservation into actual usage.
    /// Decreases ReservedUnits and records the units as used.
    /// </summary>
    public void ConvertReservationToUsage(int quantity, Product product)
    {
        if (quantity <= 0)
            throw new ArgumentException("Conversion quantity must be greater than zero.");
        if (quantity > ReservedUnits)
            throw new InvalidOperationException(
                $"Cannot convert {quantity} units. Only {ReservedUnits} currently reserved.");

        ReservedUnits -= quantity;
        RecordUsedUnits(quantity, product);
        ValidateIntegrity(product);
    }

    // ────────────────────────────────────────────────────────────────────

    public bool IsExpired() => ExpiryDate.HasValue && ExpiryDate.Value.Date <= DateTime.UtcNow.Date;

    public bool IsExpiringSoon(int daysThreshold)
    {
        if (!ExpiryDate.HasValue) return false;
        var threshold = DateTime.UtcNow.AddDays(daysThreshold).Date;
        return ExpiryDate.Value.Date <= threshold && !IsExpired();
    }

    public void Deactivate()
    {
        IsActive = false;
        MarkUpdated();
    }
}
