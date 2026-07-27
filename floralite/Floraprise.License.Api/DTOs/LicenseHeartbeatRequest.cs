using System.ComponentModel.DataAnnotations;

namespace Floraprise.License.Api.DTOs;

public sealed class LicenseHeartbeatRequest
{
    [Required]
    public Guid CustomerId { get; init; }

    [Required]
    [StringLength(120, MinimumLength = 6)]
    public string DeviceId { get; init; } = string.Empty;

    [Required]
    [StringLength(40, MinimumLength = 1)]
    public string AppVersion { get; init; } = string.Empty;
}