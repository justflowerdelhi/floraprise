using Floraprise.License.Api.Entities;

namespace Floraprise.License.Api.DTOs;

public sealed record LicenseCheckResponse(
    LicenseStatus Status,
    LicensePlan Plan,
    DateTime? Expiry,
    int RemainingDays);