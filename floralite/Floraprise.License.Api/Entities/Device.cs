namespace Floraprise.License.Api.Entities;

public sealed class Device
{
    public Guid Id { get; set; }
    public Guid CustomerId { get; set; }
    public string DeviceId { get; set; } = string.Empty;
    public string Platform { get; set; } = string.Empty;
    public string? Model { get; set; }
    public string? AndroidVersion { get; set; }
    public string AppVersion { get; set; } = string.Empty;
    public DateTime RegisteredAt { get; set; }
    public DateTime LastSeen { get; set; }

    public Customer? Customer { get; set; }
}