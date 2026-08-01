using Sumpooj.Application.Mobile;

namespace Sumpooj.API.Services.Mobile;

public interface IMobileClientService
{
    Task<MobileAuthTokenResponse> LoginAsync(MobileApiLoginRequest request, CancellationToken cancellationToken = default);
    Task<MobileAuthTokenResponse> RefreshAsync(MobileApiRefreshRequest request, CancellationToken cancellationToken = default);
    Task LogoutAsync(Guid companyId, Guid mobileUserId, string deviceId, MobileApiLogoutRequest request, CancellationToken cancellationToken = default);

    Task<MobileOtpStatusResponse> RequestOtpAsync(MobileOtpRequest request, CancellationToken cancellationToken = default);
    Task<MobileOtpStatusResponse> VerifyOtpAsync(MobileOtpVerifyRequest request, CancellationToken cancellationToken = default);

    Task<MobileDeviceResponse> RegisterDeviceAsync(Guid companyId, Guid mobileUserId, MobileDeviceRegisterRequest request, CancellationToken cancellationToken = default);
    Task<MobileLicenseCheckResult> HeartbeatAsync(Guid companyId, Guid mobileUserId, MobileDeviceHeartbeatRequest request, CancellationToken cancellationToken = default);

    Task<MobileBootstrapResponse> GetBootstrapAsync(Guid companyId, Guid mobileUserId, string deviceId, CancellationToken cancellationToken = default);

    Task<MobileSubscriptionStateResponse> GetCurrentSubscriptionAsync(Guid companyId, Guid mobileUserId, CancellationToken cancellationToken = default);
    Task<List<MobileSubscriptionPlanDto>> GetAvailablePlansAsync(CancellationToken cancellationToken = default);
    Task<MobileSubscriptionActionResponse> UpgradeAsync(Guid companyId, Guid mobileUserId, MobilePlanChangeRequest request, CancellationToken cancellationToken = default);
    Task<MobileSubscriptionActionResponse> DowngradeAsync(Guid companyId, Guid mobileUserId, MobilePlanChangeRequest request, CancellationToken cancellationToken = default);
    Task<MobileSubscriptionActionResponse> CancelAsync(Guid companyId, Guid mobileUserId, CancellationToken cancellationToken = default);
    Task<MobileSubscriptionActionResponse> RenewAsync(Guid companyId, Guid mobileUserId, MobileRenewRequest request, CancellationToken cancellationToken = default);
    Task<MobileTrialStatusResponse> GetTrialStatusAsync(Guid companyId, Guid mobileUserId, CancellationToken cancellationToken = default);
    Task<MobileGraceStatusResponse> GetGraceStatusAsync(Guid companyId, Guid mobileUserId, CancellationToken cancellationToken = default);

    Task<MobileDeviceResponse> GetCurrentDeviceAsync(Guid companyId, Guid mobileUserId, string deviceId, CancellationToken cancellationToken = default);
    Task<List<MobileDeviceResponse>> GetDevicesAsync(Guid companyId, Guid mobileUserId, string currentDeviceId, CancellationToken cancellationToken = default);
    Task<MobileDeviceResponse> UpdateLastSyncAsync(Guid companyId, Guid mobileUserId, string deviceId, MobileDeviceLastSyncRequest request, CancellationToken cancellationToken = default);
    Task<MobileDeviceResponse> UpdatePushTokenAsync(Guid companyId, Guid mobileUserId, string deviceId, MobileDevicePushTokenRequest request, CancellationToken cancellationToken = default);

    Task<MobileLicenseStatusResponse> ValidateLicenseAsync(Guid companyId, Guid mobileUserId, MobileLicenseValidateRequest request, CancellationToken cancellationToken = default);
    Task<MobileLicenseStatusResponse> GetLicenseStatusAsync(Guid companyId, Guid mobileUserId, string deviceId, CancellationToken cancellationToken = default);
    Task<MobileOfflineValidationResponse> GetOfflineValidationStatusAsync(Guid companyId, Guid mobileUserId, string deviceId, CancellationToken cancellationToken = default);
    Task<MobileDeviceAuthorizationResponse> AuthorizeDeviceAsync(Guid companyId, Guid mobileUserId, string deviceId, string requestedDeviceId, CancellationToken cancellationToken = default);

    Task<CreateSubscriptionOrderResponse> CreateSubscriptionOrderAsync(Guid companyId, Guid mobileUserId, CreateSubscriptionOrderRequest request, CancellationToken cancellationToken = default);
    Task<PaymentCallbackResponse> PaymentCallbackAsync(Guid companyId, Guid mobileUserId, PaymentCallbackRequest request, CancellationToken cancellationToken = default);
    Task<PaymentVerificationResponse> VerifyPaymentAsync(Guid companyId, Guid mobileUserId, PaymentVerificationRequest request, CancellationToken cancellationToken = default);
    Task<List<MobilePaymentHistoryItem>> GetPaymentHistoryAsync(Guid companyId, Guid mobileUserId, CancellationToken cancellationToken = default);
}