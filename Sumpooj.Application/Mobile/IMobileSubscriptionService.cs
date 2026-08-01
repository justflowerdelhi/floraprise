namespace Sumpooj.Application.Mobile;

public interface IMobileSubscriptionService
{
    Task<RegisterMobileCustomerResult> RegisterOrStartTrialAsync(RegisterMobileCustomerRequest request, CancellationToken cancellationToken = default);
    Task<MobileLicenseCheckResult> CheckLicenseAsync(MobileLicenseCheckRequest request, CancellationToken cancellationToken = default);
    Task<MobileLicenseCheckResult> HeartbeatAsync(MobileHeartbeatRequest request, CancellationToken cancellationToken = default);
    Task<List<MobileSubscriptionPlanDto>> GetActivePlansAsync(CancellationToken cancellationToken = default);
}
