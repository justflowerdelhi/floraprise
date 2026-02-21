namespace Sumpooj.Application.DeliveryZones;

public class DeliveryZoneDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = default!;
    public string Code { get; set; } = default!;
    public string MatchType { get; set; } = "ZIP";
    public List<string> MatchValues { get; set; } = new();
    public List<string> ZipCodes { get; set; } = new();
    public List<string> Cities { get; set; } = new();
    public Guid? LocationId { get; set; }
    public decimal? FreeDeliveryThreshold { get; set; }
    public decimal DeliveryFee { get; set; }
    public decimal SameDayFee { get; set; }
    public decimal ExpressFee { get; set; }
    public int EstimatedMinutes { get; set; }
    public decimal? DistanceKm { get; set; }
    public int Priority { get; set; }
    public bool IsServiceable { get; set; } = true;
    public bool IsActive { get; set; }
    public string? Notes { get; set; }
    public string? Color { get; set; }
    public DateTime CreatedAtUtc { get; set; }
}

public class CreateDeliveryZoneRequest
{
    public string Name { get; set; } = default!;
    public string Code { get; set; } = default!;
    public string MatchType { get; set; } = "ZIP";
    public List<string> MatchValues { get; set; } = new();
    public Guid? LocationId { get; set; }
    public decimal? FreeDeliveryThreshold { get; set; }
    public decimal DeliveryFee { get; set; }
    public decimal SameDayFee { get; set; }
    public decimal ExpressFee { get; set; }
    public int EstimatedMinutes { get; set; }
    public decimal? DistanceKm { get; set; }
    public int Priority { get; set; }
    public bool IsServiceable { get; set; } = true;
    public string? Notes { get; set; }
    public string? Color { get; set; }
}

public class UpdateDeliveryZoneRequest : CreateDeliveryZoneRequest
{
}

public class CalculateDeliveryFeeRequest
{
    public string? ZipCode { get; set; }
    public string? City { get; set; }
    public string? Area { get; set; }
    public bool IsSameDay { get; set; }
    public bool IsExpress { get; set; }
    public decimal OrderAmount { get; set; }
    public Guid? LocationId { get; set; }
}

public class DeliveryFeeResult
{
    public Guid? ZoneId { get; set; }
    public string? ZoneName { get; set; }
    public decimal BaseFee { get; set; }
    public decimal SameDayFee { get; set; }
    public decimal ExpressFee { get; set; }
    public decimal TotalFee { get; set; }
    public bool IsFreeDelivery { get; set; }
    public bool IsServiceable { get; set; } = true;
    public int EstimatedMinutes { get; set; }
    public string? Message { get; set; }
}
