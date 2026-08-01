using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Mobile;

public sealed record RegisterMobileCustomerRequest(
    Guid CompanyId,
    string BusinessName,
    string OwnerName,
    string Mobile,
    string? Email,
    string? City,
    string? State,
    string? Country,
    string FullName,
    string DeviceId,
    string Platform,
    string? Manufacturer,
    string? Model,
    string? OsVersion,
    string AppVersion,
    string? PushToken,
    string? IpAddress,
    Guid? ActorUserId);

public sealed record RegisterMobileCustomerResult(
    Guid MobileCustomerId,
    Guid MobileUserId,
    Guid MobileDeviceId,
    Guid SubscriptionId,
    Guid LicenseId,
    MobileLicenseStatus LicenseStatus,
    MobileSubscriptionStatus SubscriptionStatus,
    DateTime TrialExpiryUtc,
    int RemainingDays);

public sealed record MobileLicenseCheckRequest(
    Guid CompanyId,
    Guid MobileUserId,
    string DeviceId,
    string AppVersion,
    string? IpAddress,
    DateTime? LastSyncUtc,
    Guid? ActorUserId);

public sealed record MobileLicenseCheckResult(
    MobileLicenseStatus LicenseStatus,
    MobileSubscriptionStatus SubscriptionStatus,
    string PlanCode,
    DateTime? ExpiryUtc,
    int RemainingDays,
    bool RequiresForceUpdate,
    bool AllowsAccess,
    int OfflineValidationDays,
    int GraceDays);

public sealed record MobileHeartbeatRequest(
    Guid CompanyId,
    Guid MobileUserId,
    string DeviceId,
    string AppVersion,
    string? IpAddress,
    DateTime? LastSyncUtc,
    Guid? ActorUserId);

public sealed record MobileAuthLoginRequest(
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

public sealed record MobileRefreshRequest(string RefreshToken);

public sealed record MobileAuthResult(
    string AccessToken,
    string RefreshToken,
    DateTime ExpiresAtUtc,
    Guid MobileUserId,
    MobileBootstrapPayload Bootstrap);

public sealed record MobileBootstrapPayload(
    MobileBootstrapCompany Company,
    MobileBootstrapUser User,
    MobileBootstrapSubscription Subscription,
    MobileBootstrapLicense License,
    List<string> Permissions,
    List<MobileBootstrapFeature> FeatureEntitlements,
    MobileBootstrapAppConfig AppConfig);

public sealed record MobileBootstrapCompany(
    Guid Id,
    string Name,
    string Currency,
    string TaxSystem,
    string TimeZone,
    List<MobileBootstrapBranch> Branches);

public sealed record MobileBootstrapBranch(Guid Id, string Name, bool IsDefault);

public sealed record MobileBootstrapUser(
    Guid Id,
    string FullName,
    string Mobile,
    string? Email,
    string Language,
    string Theme);

public sealed record MobileBootstrapSubscription(
    Guid Id,
    string PlanCode,
    MobileSubscriptionStatus Status,
    bool IsTrial,
    DateTime? TrialEndUtc,
    DateTime? EndUtc,
    int RemainingDays,
    bool AutoRenew,
    int OfflineValidationDays,
    int GraceDays);

public sealed record MobileBootstrapLicense(
    Guid Id,
    MobileLicenseStatus Status,
    DateTime? ExpiryUtc,
    bool AllowsAccess);

public sealed record MobileBootstrapFeature(string Key, bool Enabled);

public sealed record MobileBootstrapAppConfig(
    string Language,
    string Theme,
    string LatestAppVersion,
    bool ForceUpdate,
    Dictionary<string, object?> PrinterSettings);

public sealed record MobileSubscriptionPlanDto(
    Guid Id,
    string Code,
    string Name,
    MobilePlanType PlanType,
    decimal MonthlyPrice,
    decimal AnnualPrice,
    decimal LifetimePrice,
    int TrialDays,
    int OfflineDays,
    int GraceDays,
    int MaximumDevices,
    int MaximumStaff,
    bool IsActive,
    string IncludedModulesJson);

/// <summary>
/// Standard Mobile API response envelope.
/// All Mobile API endpoints should return responses wrapped in this contract.
/// </summary>
public sealed record MobileApiResponse<T>(
    bool Success,
    T? Data,
    string? Message,
    string? ErrorCode,
    string? CorrelationId,
    DateTime TimestampUtc);
