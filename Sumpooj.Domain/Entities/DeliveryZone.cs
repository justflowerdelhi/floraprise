namespace Sumpooj.Domain.Entities;

/// <summary>
/// Represents a delivery zone with pricing rules
/// </summary>
public class DeliveryZone : BaseEntity
{
    private DeliveryZone() { }

    public DeliveryZone(
        Guid companyId,
        string name,
        string code,
        decimal deliveryFee,
        int estimatedMinutes)
    {
        CompanyId = companyId;
        Name = name;
        Code = code;
        DeliveryFee = deliveryFee;
        EstimatedMinutes = estimatedMinutes;
        IsActive = true;
    }

    public Guid CompanyId { get; private set; }
    public string Name { get; private set; } = default!;
    public string Code { get; private set; } = default!;
    
    /// <summary>
    /// Zip codes or postal codes covered by this zone (comma-separated)
    /// </summary>
    public string? ZipCodes { get; private set; }
    
    /// <summary>
    /// City names covered by this zone (comma-separated)
    /// </summary>
    public string? Cities { get; private set; }
    
    /// <summary>
    /// Minimum order amount for free delivery (null = no free delivery)
    /// </summary>
    public decimal? FreeDeliveryThreshold { get; private set; }
    
    /// <summary>
    /// Base delivery fee for this zone
    /// </summary>
    public decimal DeliveryFee { get; private set; }
    
    /// <summary>
    /// Additional fee for same-day delivery
    /// </summary>
    public decimal SameDayFee { get; private set; }
    
    /// <summary>
    /// Additional fee for express delivery
    /// </summary>
    public decimal ExpressFee { get; private set; }
    
    /// <summary>
    /// Estimated delivery time in minutes
    /// </summary>
    public int EstimatedMinutes { get; private set; }
    
    /// <summary>
    /// Distance in kilometers (for sorting/display)
    /// </summary>
    public decimal? DistanceKm { get; private set; }
    
    /// <summary>
    /// Sort order for display
    /// </summary>
    public int SortOrder { get; private set; }
    
    public bool IsActive { get; private set; }
    
    /// <summary>
    /// Notes about this zone (e.g., "Hills area - call before delivery")
    /// </summary>
    public string? Notes { get; private set; }

    public void Update(
        string name,
        string code,
        string? zipCodes,
        string? cities,
        decimal deliveryFee,
        decimal? freeDeliveryThreshold,
        decimal sameDayFee,
        decimal expressFee,
        int estimatedMinutes,
        decimal? distanceKm,
        int sortOrder,
        string? notes)
    {
        Name = name;
        Code = code;
        ZipCodes = zipCodes;
        Cities = cities;
        DeliveryFee = deliveryFee;
        FreeDeliveryThreshold = freeDeliveryThreshold;
        SameDayFee = sameDayFee;
        ExpressFee = expressFee;
        EstimatedMinutes = estimatedMinutes;
        DistanceKm = distanceKm;
        SortOrder = sortOrder;
        Notes = notes;
        MarkUpdated();
    }

    public void Activate() => IsActive = true;
    public void Deactivate() => IsActive = false;
}
