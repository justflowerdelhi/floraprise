namespace Sumpooj.Application.Locations;

public class LocationDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = default!;
    public string Code { get; set; } = default!;
    public string LocationType { get; set; } = default!;
    public string? Address { get; set; }
    public bool IsActive { get; set; }
    public bool IsDefault { get; set; }
}

public class CreateLocationRequest
{
    public string Name { get; set; } = default!;
    public string Code { get; set; } = default!;
    public string LocationType { get; set; } = "Store";
    public string? Address { get; set; }
    public bool IsDefault { get; set; }
}

public class UpdateLocationRequest
{
    public string? Name { get; set; }
    public string? Address { get; set; }
    public bool? IsDefault { get; set; }
}
