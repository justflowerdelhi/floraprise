using Floraprise.License.Api.Entities;

namespace Floraprise.License.Api.DTOs;

public sealed record LicenseRegistrationResponse(
    Guid CustomerId,
    LicenseStatus LicenseStatus,
    DateTime TrialExpiry,
    int RemainingDays);