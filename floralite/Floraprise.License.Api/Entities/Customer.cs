namespace Floraprise.License.Api.Entities;

public sealed class Customer
{
    public Guid Id { get; set; }
    public string BusinessName { get; set; } = string.Empty;
    public string OwnerName { get; set; } = string.Empty;
    public string Mobile { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? City { get; set; }
    public string State { get; set; } = string.Empty;
    public string Country { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }

    public ICollection<Device> Devices { get; } = new List<Device>();
    public License? License { get; set; }
}