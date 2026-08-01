using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Mobile;

public sealed record MobileApiLoginRequest(
    Guid CompanyId,
    string Identifier,
    string Password,
    string DeviceId,
    string Platform,
    string? Manufacturer,
    string? Model,
    string? OsVersion,
    string AppVersion,
    string? PushToken,
    string? IpAddress);

public sealed record MobileApiRegisterRequest(
    string CompanyName,
    string OwnerName,
    string Mobile,
    string Address,
    string City,
    string Email,
    string Password,
    string DeviceId,
    string Platform,
    string? Manufacturer,
    string? Model,
    string? OsVersion,
    string AppVersion,
    string? PushToken,
    string? IpAddress);

public sealed record MobileApiRefreshRequest(string RefreshToken);

public sealed record MobileApiLogoutRequest(string? RefreshToken);

public sealed record MobileAuthTokenResponse(
    string AccessToken,
    string RefreshToken,
    DateTime ExpiresAtUtc,
    Guid CompanyId,
    Guid MobileUserId,
    Guid MobileDeviceId,
    MobileBootstrapResponse Bootstrap);

public sealed record MobileOtpRequest(string MobileOrEmail);
public sealed record MobileOtpVerifyRequest(string MobileOrEmail, string Otp);
public sealed record MobileOtpStatusResponse(bool Enabled, string Message);

public sealed record MobileBootstrapResponse(
    MobileBootstrapCompanyDto Company,
    MobileBootstrapUserDto User,
    List<MobileBootstrapBranchDto> Branches,
    MobileBootstrapSubscriptionDto Subscription,
    MobileBootstrapLicenseDto License,
    MobileBootstrapTrialDto Trial,
    MobileBootstrapTaxSettingsDto TaxSettings,
    MobileBootstrapPrinterSettingsDto PrinterSettings,
    List<string> Permissions,
    string Language,
    string Theme,
    string AppVersion,
    string MinimumSupportedVersion,
    bool ForceUpdate,
    List<MobileFeatureFlagDto> FeatureFlags,
    DateTime GeneratedAtUtc);

public sealed record MobileBootstrapCompanyDto(
    Guid Id,
    string Name,
    string Currency,
    string Region,
    string TimeZone,
    string? TaxIdentifier);

public sealed record MobileBootstrapUserDto(
    Guid Id,
    string FullName,
    string Mobile,
    string? Email,
    MobileUserStatus Status);

public sealed record MobileBootstrapBranchDto(Guid Id, string Name, string Code, bool IsDefault);

public sealed record MobileBootstrapSubscriptionDto(
    Guid Id,
    string PlanCode,
    string PlanName,
    MobileSubscriptionStatus Status,
    bool AutoRenew,
    DateTime? StartUtc,
    DateTime? EndUtc,
    DateTime? GraceEndUtc,
    int RemainingDays,
    int OfflineValidationDays,
    int GraceDays);

public sealed record MobileBootstrapLicenseDto(
    Guid Id,
    MobileLicenseStatus Status,
    DateTime IssuedAtUtc,
    DateTime? ExpiryUtc,
    bool AllowsAccess,
    string DeviceId);

public sealed record MobileBootstrapTrialDto(
    bool IsTrial,
    DateTime? TrialStartUtc,
    DateTime? TrialEndUtc,
    int RemainingDays,
    bool IsExpired);

public sealed record MobileBootstrapTaxSettingsDto(
    string TaxSystem,
    string? TaxIdentifier,
    bool TaxEnabled);

public sealed record MobileBootstrapPrinterSettingsDto(
    bool AutoPrintInvoice,
    bool AutoPrintKot,
    int Copies,
    string PaperSize,
    string? PreferredPrinter);

public sealed record MobileFeatureFlagDto(string Key, bool Enabled);

public sealed record MobileSubscriptionStateResponse(
    Guid SubscriptionId,
    string PlanCode,
    string PlanName,
    MobileSubscriptionStatus Status,
    bool IsTrial,
    DateTime? TrialEndUtc,
    DateTime? EndUtc,
    DateTime? GraceEndUtc,
    int RemainingDays,
    int OfflineValidationDays,
    int GraceDays,
    bool AutoRenew);

public sealed record MobilePlanChangeRequest(Guid PlanId, string BillingCycle);
public sealed record MobileRenewRequest(string BillingCycle, bool AutoRenew);
public sealed record MobileSubscriptionActionResponse(string Action, MobileSubscriptionStateResponse Subscription);

public sealed record MobileTrialStatusResponse(bool IsTrial, bool IsExpired, DateTime? TrialEndUtc, int RemainingDays);
public sealed record MobileGraceStatusResponse(bool InGrace, DateTime? GraceEndUtc, int RemainingGraceDays);

public sealed record MobileDeviceRegisterRequest(
    string DeviceId,
    string Platform,
    string? Manufacturer,
    string? Model,
    string? OsVersion,
    string AppVersion,
    string? PushToken,
    string? IpAddress);

public sealed record MobileDeviceHeartbeatRequest(
    string DeviceId,
    string AppVersion,
    DateTime? LastSyncUtc,
    string? IpAddress);

public sealed record MobileDeviceLastSyncRequest(DateTime LastSyncUtc, string? IpAddress);
public sealed record MobileDevicePushTokenRequest(string PushToken, string? AppVersion);

public sealed record MobileDeviceResponse(
    Guid Id,
    string DeviceId,
    string Platform,
    string? Manufacturer,
    string? Model,
    string? OsVersion,
    string AppVersion,
    string? PushToken,
    MobileDeviceStatus Status,
    DateTime? LastLoginAtUtc,
    DateTime? LastHeartbeatAtUtc,
    DateTime? LastSyncAtUtc,
    string? LastIpAddress,
    bool IsCurrentDevice);

public sealed record MobileLicenseValidateRequest(string DeviceId, string AppVersion, DateTime? LastSyncUtc, string? IpAddress);

public sealed record MobileLicenseStatusResponse(
    MobileLicenseStatus LicenseStatus,
    MobileSubscriptionStatus SubscriptionStatus,
    string PlanCode,
    DateTime? ExpiryUtc,
    int RemainingDays,
    bool OfflineValid,
    int OfflineValidationDays,
    int GraceDays,
    bool AllowsAccess);

public sealed record MobileOfflineValidationResponse(bool OfflineValid, DateTime? LastSyncUtc, int AllowedOfflineDays, int DaysSinceLastSync);
public sealed record MobileDeviceAuthorizationResponse(string DeviceId, bool Authorized, string Reason);

public enum MobilePaymentGatewayType
{
    Razorpay = 1,
    Stripe = 2
}

public sealed record CreateSubscriptionOrderRequest(
    MobilePaymentGatewayType Gateway,
    Guid SubscriptionId,
    decimal Amount,
    string Currency,
    string PlanCode,
    string BillingCycle,
    string? ReturnUrl);

public sealed record CreateSubscriptionOrderResponse(
    Guid TransactionId,
    string TransactionRef,
    MobilePaymentGatewayType Gateway,
    string GatewayOrderId,
    string PaymentStatus,
    decimal Amount,
    string Currency,
    Dictionary<string, string> ClientPayload);

public sealed record PaymentCallbackRequest(
    MobilePaymentGatewayType Gateway,
    string TransactionRef,
    string GatewayOrderId,
    string? GatewayPaymentId,
    string Status,
    string? Signature,
    string? PlanCode,
    string? BillingCycle,
    Dictionary<string, string>? Metadata);

public sealed record PaymentVerificationRequest(
    MobilePaymentGatewayType Gateway,
    string TransactionRef,
    string GatewayOrderId,
    string GatewayPaymentId,
    string? Signature,
    string? PlanCode,
    string? BillingCycle);

public sealed record PaymentCallbackResponse(string TransactionRef, string Status, bool Updated);
public sealed record PaymentVerificationResponse(string TransactionRef, bool Verified, string Status);

public sealed record MobilePaymentHistoryItem(
    Guid Id,
    string TransactionRef,
    MobilePaymentType PaymentType,
    MobilePaymentStatus PaymentStatus,
    decimal Amount,
    string Currency,
    DateTime CreatedAtUtc,
    DateTime? PaidAtUtc,
    string? GatewayOrderId,
    string? GatewayPaymentId,
    string? FailureReason);

public interface ISubscriptionPaymentGateway
{
    MobilePaymentGatewayType GatewayType { get; }
    Task<(string GatewayOrderId, Dictionary<string, string> ClientPayload)> CreateOrderAsync(CreateSubscriptionOrderRequest request, CancellationToken cancellationToken = default);
    Task<bool> VerifyPaymentAsync(PaymentVerificationRequest request, CancellationToken cancellationToken = default);
    Task<string> NormalizeCallbackStatusAsync(PaymentCallbackRequest request, CancellationToken cancellationToken = default);
}

public interface ISubscriptionPaymentGatewayFactory
{
    ISubscriptionPaymentGateway Resolve(MobilePaymentGatewayType gatewayType);
}