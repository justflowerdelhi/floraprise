namespace Sumpooj.Domain.Entities;

public class Location : BaseEntity
{
    private Location() { }

    public Location(
        Guid companyId,
        string name,
        string code,
        LocationType locationType,
        string? address)
    {
        CompanyId = companyId;
        Name = name;
        Code = code;
        LocationType = locationType;
        Address = address;
        IsActive = true;
    }

    public Guid CompanyId { get; private set; }
    public string Name { get; private set; }
    public string Code { get; private set; }
    public LocationType LocationType { get; private set; }
    public string? Address { get; private set; }
    public bool IsActive { get; private set; }
    public bool IsDefault { get; private set; }

    public void UpdateDetails(string name, string? address)
    {
        Name = name;
        Address = address;
        MarkUpdated();
    }

    public void SetAsDefault()
    {
        IsDefault = true;
        MarkUpdated();
    }

    public void ClearDefault()
    {
        IsDefault = false;
        MarkUpdated();
    }

    public void Deactivate()
    {
        IsActive = false;
        MarkUpdated();
    }

    public void Activate()
    {
        IsActive = true;
        MarkUpdated();
    }
}
