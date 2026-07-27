using System.ComponentModel.DataAnnotations;

namespace Floraprise.License.Api.DTOs;

public sealed class RegisterLicenseRequest
{
    [Required]
    [StringLength(160, MinimumLength = 2)]
    public string BusinessName { get; init; } = string.Empty;

    [Required]
    [StringLength(120, MinimumLength = 2)]
    public string OwnerName { get; init; } = string.Empty;

    [Required]
    [Phone]
    [StringLength(32, MinimumLength = 8)]
    public string Mobile { get; init; } = string.Empty;

    [EmailAddress]
    [StringLength(160)]
    public string? Email { get; init; }

    [StringLength(100)]
    public string? City { get; init; }

    [StringLength(100)]
    public string? State { get; init; }

    [StringLength(100)]
    public string? Country { get; init; }

    [Required]
    [StringLength(120, MinimumLength = 6)]
    public string DeviceId { get; init; } = string.Empty;

    [Required]
    [StringLength(40, MinimumLength = 2)]
    public string Platform { get; init; } = string.Empty;

    [StringLength(120)]
    public string? Model { get; init; }

    [StringLength(80)]
    public string? AndroidVersion { get; init; }

    [Required]
    [StringLength(40, MinimumLength = 1)]
    public string AppVersion { get; init; } = string.Empty;
}