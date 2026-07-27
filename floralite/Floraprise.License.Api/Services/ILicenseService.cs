using Floraprise.License.Api.DTOs;

namespace Floraprise.License.Api.Services;

public interface ILicenseService
{
    Task<LicenseRegistrationResponse> RegisterAsync(
        RegisterLicenseRequest request,
        CancellationToken cancellationToken);

    Task<LicenseCheckResponse?> CheckAsync(
        Guid customerId,
        string deviceId,
        CancellationToken cancellationToken);

    Task<bool> HeartbeatAsync(
        LicenseHeartbeatRequest request,
        CancellationToken cancellationToken);
}