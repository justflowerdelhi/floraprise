namespace Sumpooj.Domain.Entities;

public enum MobileUserStatus
{
    Active = 1,
    Suspended = 2,
    Disabled = 3
}

public enum MobileDeviceStatus
{
    Active = 1,
    Disabled = 2,
    Revoked = 3
}

public enum MobileSubscriptionStatus
{
    Trial = 1,
    Active = 2,
    Grace = 3,
    Suspended = 4,
    Cancelled = 5,
    Expired = 6
}

public enum MobileLicenseStatus
{
    Active = 1,
    Suspended = 2,
    Revoked = 3,
    Expired = 4
}

public enum MobilePlanType
{
    Basic = 1,
    Pro = 2,
    Enterprise = 3,
    Lifetime = 4
}

public enum MobilePaymentStatus
{
    Pending = 1,
    Paid = 2,
    Failed = 3,
    Refunded = 4
}

public enum MobilePaymentType
{
    Purchase = 1,
    Renewal = 2,
    Upgrade = 3,
    Downgrade = 4,
    Refund = 5
}

public enum DeviceSessionStatus
{
    Active = 1,
    LoggedOut = 2,
    Expired = 3,
    Revoked = 4
}

public enum TrialActionType
{
    Activated = 1,
    Extended = 2,
    Expired = 3,
    Converted = 4,
    Revoked = 5
}

public sealed class WhatsAppAccount : BaseEntity
{
    private WhatsAppAccount() { }

    public WhatsAppAccount(int memberId, string businessName, string phoneNumber, string phoneNumberId, string wabaId, string accessToken, string verifyToken)
    {
        MemberId = memberId;
        BusinessName = businessName.Trim();
        PhoneNumber = phoneNumber.Trim();
        PhoneNumberId = phoneNumberId.Trim();
        WabaId = wabaId.Trim();
        AccessToken = accessToken.Trim();
        VerifyToken = verifyToken.Trim();
    }

    public int MemberId { get; private set; }
    public string BusinessName { get; private set; } = string.Empty;
    public string PhoneNumber { get; private set; } = string.Empty;
    public string PhoneNumberId { get; private set; } = string.Empty;
    public string WabaId { get; private set; } = string.Empty;
    public string AccessToken { get; private set; } = string.Empty;
    public string VerifyToken { get; private set; } = string.Empty;
    public bool IsActive { get; private set; } = true;

    public void UpdateTokens(string accessToken, string verifyToken)
    {
        AccessToken = accessToken.Trim();
        VerifyToken = verifyToken.Trim();
        MarkUpdated();
    }

    public void Activate()
    {
        IsActive = true;
        MarkUpdated();
    }

    public void Deactivate()
    {
        IsActive = false;
        MarkUpdated();
    }
}

public abstract class MobileAuditableEntity : BaseEntity
{
    public bool IsDeleted { get; protected set; }
    public DateTime? DeletedAtUtc { get; protected set; }
    public Guid? CreatedBy { get; protected set; }
    public Guid? UpdatedBy { get; protected set; }
    public byte[] RowVersion { get; protected set; } = Array.Empty<byte>();

    public void SetCreatedBy(Guid? userId)
    {
        CreatedBy = userId;
    }

    public void SetUpdatedBy(Guid? userId)
    {
        UpdatedBy = userId;
        MarkUpdated();
    }

    public void SoftDelete(Guid? userId)
    {
        if (IsDeleted)
            return;

        IsDeleted = true;
        DeletedAtUtc = DateTime.UtcNow;
        UpdatedBy = userId;
        MarkUpdated();
    }
}

public sealed class MobileCustomer : MobileAuditableEntity
{
    private MobileCustomer() { }

    public MobileCustomer(Guid companyId, string businessName, string ownerName, string mobile)
    {
        CompanyId = companyId;
        BusinessName = businessName.Trim();
        OwnerName = ownerName.Trim();
        Mobile = mobile.Trim();
    }

    public Guid CompanyId { get; private set; }
    public string BusinessName { get; private set; } = string.Empty;
    public string OwnerName { get; private set; } = string.Empty;
    public string Mobile { get; private set; } = string.Empty;
    public string? Email { get; private set; }
    public string? City { get; private set; }
    public string? State { get; private set; }
    public string? Country { get; private set; }

    public ICollection<MobileUser> MobileUsers { get; } = new List<MobileUser>();

    public void UpdateProfile(string? email, string? city, string? state, string? country, Guid? updatedBy)
    {
        Email = string.IsNullOrWhiteSpace(email) ? null : email.Trim();
        City = string.IsNullOrWhiteSpace(city) ? null : city.Trim();
        State = string.IsNullOrWhiteSpace(state) ? null : state.Trim();
        Country = string.IsNullOrWhiteSpace(country) ? null : country.Trim();
        SetUpdatedBy(updatedBy);
    }
}

public sealed class MobileUser : MobileAuditableEntity
{
    private MobileUser() { }

    public MobileUser(Guid companyId, Guid mobileCustomerId, string fullName, string mobile, string? email)
    {
        CompanyId = companyId;
        MobileCustomerId = mobileCustomerId;
        FullName = fullName.Trim();
        Mobile = mobile.Trim();
        Email = string.IsNullOrWhiteSpace(email) ? null : email.Trim();
        Status = MobileUserStatus.Active;
        PreferredLanguage = "en-IN";
        PreferredTheme = "system";
    }

    public Guid CompanyId { get; private set; }
    public Guid MobileCustomerId { get; private set; }
    public string FullName { get; private set; } = string.Empty;
    public string Mobile { get; private set; } = string.Empty;
    public string? Email { get; private set; }
    public MobileUserStatus Status { get; private set; }
    public string PreferredLanguage { get; private set; } = "en-IN";
    public string PreferredTheme { get; private set; } = "system";

    public MobileCustomer? MobileCustomer { get; private set; }
    public Company? Company { get; private set; }
    public ICollection<MobileDevice> Devices { get; } = new List<MobileDevice>();
    public MobileSubscription? Subscription { get; private set; }

    public void Suspend(Guid? updatedBy)
    {
        Status = MobileUserStatus.Suspended;
        SetUpdatedBy(updatedBy);
    }

    public void Activate(Guid? updatedBy)
    {
        Status = MobileUserStatus.Active;
        SetUpdatedBy(updatedBy);
    }

    public void Disable(Guid? updatedBy)
    {
        Status = MobileUserStatus.Disabled;
        SetUpdatedBy(updatedBy);
    }
}

public sealed class MobileDevice : MobileAuditableEntity
{
    private MobileDevice() { }

    public MobileDevice(
        Guid companyId,
        Guid mobileUserId,
        Guid identityUserId,
        string deviceId,
        string? manufacturer,
        string? model,
        string platform,
        string? osVersion,
        string appVersion,
        string? pushToken)
    {
        CompanyId = companyId;
        MobileUserId = mobileUserId;
        DeviceId = deviceId.Trim();
        Manufacturer = string.IsNullOrWhiteSpace(manufacturer) ? null : manufacturer.Trim();
        Model = string.IsNullOrWhiteSpace(model) ? null : model.Trim();
        Platform = platform.Trim();
        LegacyUserId = identityUserId;
        DeviceFingerprintHash = DeviceId;
        DeviceName = Model ?? Manufacturer ?? Platform;
        OsVersion = string.IsNullOrWhiteSpace(osVersion) ? null : osVersion.Trim();
        AppVersion = appVersion.Trim();
        PushToken = string.IsNullOrWhiteSpace(pushToken) ? null : pushToken.Trim();
        Status = MobileDeviceStatus.Active;
        LastLoginAtUtc = DateTime.UtcNow;
        LastHeartbeatAtUtc = DateTime.UtcNow;
    }

    public Guid CompanyId { get; private set; }
    public Guid MobileUserId { get; private set; }
    public Guid LegacyUserId { get; private set; }
    public string DeviceId { get; private set; } = string.Empty;
    public string DeviceFingerprintHash { get; private set; } = string.Empty;
    public string DeviceName { get; private set; } = string.Empty;
    public string? Manufacturer { get; private set; }
    public string? Model { get; private set; }
    public string Platform { get; private set; } = string.Empty;
    public string? OsVersion { get; private set; }
    public string AppVersion { get; private set; } = string.Empty;
    public string? PushToken { get; private set; }
    public string? LastIpAddress { get; private set; }
    public DateTime? LastLoginAtUtc { get; private set; }
    public DateTime? LastHeartbeatAtUtc { get; private set; }
    public DateTime? LastSyncAtUtc { get; private set; }
    public MobileDeviceStatus Status { get; private set; }

    public MobileUser? MobileUser { get; private set; }
    public Company? Company { get; private set; }
    public MobileLicense? License { get; private set; }
    public ICollection<DeviceSession> Sessions { get; } = new List<DeviceSession>();

    public void UpdateHeartbeat(string appVersion, string? ipAddress, DateTime? lastSyncUtc, Guid? updatedBy)
    {
        AppVersion = appVersion.Trim();
        LastIpAddress = string.IsNullOrWhiteSpace(ipAddress) ? null : ipAddress.Trim();
        LastHeartbeatAtUtc = DateTime.UtcNow;
        LastSyncAtUtc = EnsureUtc(lastSyncUtc);
        SetUpdatedBy(updatedBy);
    }

    public void MarkLogin(string? ipAddress, Guid? updatedBy)
    {
        LastIpAddress = string.IsNullOrWhiteSpace(ipAddress) ? null : ipAddress.Trim();
        LastLoginAtUtc = DateTime.UtcNow;
        SetUpdatedBy(updatedBy);
    }

    public void UpdatePushToken(string? pushToken, Guid? updatedBy)
    {
        PushToken = string.IsNullOrWhiteSpace(pushToken) ? null : pushToken.Trim();
        SetUpdatedBy(updatedBy);
    }

    public void Disable(Guid? updatedBy)
    {
        Status = MobileDeviceStatus.Disabled;
        SetUpdatedBy(updatedBy);
    }

    public void Revoke(Guid? updatedBy)
    {
        Status = MobileDeviceStatus.Revoked;
        SetUpdatedBy(updatedBy);
    }

    public void Activate(Guid? updatedBy)
    {
        Status = MobileDeviceStatus.Active;
        SetUpdatedBy(updatedBy);
    }
}

public sealed class SubscriptionPlan : MobileAuditableEntity
{
    private SubscriptionPlan() { }

    public SubscriptionPlan(
        string code,
        string name,
        MobilePlanType planType,
        decimal monthlyPrice,
        decimal annualPrice,
        decimal lifetimePrice,
        int trialDays,
        int offlineDays,
        int graceDays,
        int maximumDevices,
        int maximumStaff,
        string includedModulesJson)
    {
        Code = code.Trim().ToUpperInvariant();
        Name = name.Trim();
        PlanType = planType;
        MonthlyPrice = monthlyPrice;
        AnnualPrice = annualPrice;
        LifetimePrice = lifetimePrice;
        TrialDays = trialDays;
        OfflineDays = offlineDays;
        GraceDays = graceDays;
        MaximumDevices = maximumDevices;
        MaximumStaff = maximumStaff;
        IncludedModulesJson = includedModulesJson;
        IsActive = true;
    }

    public string Code { get; private set; } = string.Empty;
    public string Name { get; private set; } = string.Empty;
    public MobilePlanType PlanType { get; private set; }
    public decimal MonthlyPrice { get; private set; }
    public decimal AnnualPrice { get; private set; }
    public decimal LifetimePrice { get; private set; }
    public int TrialDays { get; private set; }
    public int OfflineDays { get; private set; }
    public int GraceDays { get; private set; }
    public int MaximumDevices { get; private set; }
    public int MaximumStaff { get; private set; }
    public string IncludedModulesJson { get; private set; } = "[]";
    public bool IsActive { get; private set; }

    public ICollection<MobileSubscription> Subscriptions { get; } = new List<MobileSubscription>();

    public void UpdateCatalog(
        string name,
        MobilePlanType planType,
        decimal monthlyPrice,
        decimal annualPrice,
        decimal lifetimePrice,
        int trialDays,
        int offlineDays,
        int graceDays,
        int maximumDevices,
        int maximumStaff,
        string includedModulesJson,
        bool isActive,
        Guid? updatedBy)
    {
        Name = name.Trim();
        PlanType = planType;
        MonthlyPrice = monthlyPrice;
        AnnualPrice = annualPrice;
        LifetimePrice = lifetimePrice;
        TrialDays = trialDays;
        OfflineDays = offlineDays;
        GraceDays = graceDays;
        MaximumDevices = maximumDevices;
        MaximumStaff = maximumStaff;
        IncludedModulesJson = includedModulesJson;
        IsActive = isActive;
        SetUpdatedBy(updatedBy);
    }
}

public sealed class MobileSubscription : MobileAuditableEntity
{
    private MobileSubscription() { }

    public MobileSubscription(Guid companyId, Guid mobileUserId, Guid subscriptionPlanId, DateTime trialStartUtc, DateTime trialEndUtc)
    {
        CompanyId = companyId;
        MobileUserId = mobileUserId;
        SubscriptionPlanId = subscriptionPlanId;
        TrialStartUtc = EnsureUtc(trialStartUtc);
        TrialEndUtc = EnsureUtc(trialEndUtc);
        Status = MobileSubscriptionStatus.Trial;
        AutoRenew = false;
    }

    public Guid CompanyId { get; private set; }
    public Guid MobileUserId { get; private set; }
    public Guid SubscriptionPlanId { get; private set; }
    public MobileSubscriptionStatus Status { get; private set; }
    public DateTime TrialStartUtc { get; private set; }
    public DateTime TrialEndUtc { get; private set; }
    public DateTime? StartUtc { get; private set; }
    public DateTime? EndUtc { get; private set; }
    public DateTime? GraceEndUtc { get; private set; }
    public DateTime? LastValidatedUtc { get; private set; }
    public bool AutoRenew { get; private set; }

    public Company? Company { get; private set; }
    public MobileUser? MobileUser { get; private set; }
    public SubscriptionPlan? SubscriptionPlan { get; private set; }
    public ICollection<MobilePaymentTransaction> PaymentTransactions { get; } = new List<MobilePaymentTransaction>();
    public ICollection<FeatureEntitlement> FeatureEntitlements { get; } = new List<FeatureEntitlement>();
    public ICollection<TrialHistory> TrialHistoryEntries { get; } = new List<TrialHistory>();

    public int RemainingDays(DateTime utcNow)
    {
        var now = EnsureUtc(utcNow);
        var expiry = Status == MobileSubscriptionStatus.Trial ? TrialEndUtc : EndUtc;
        if (!expiry.HasValue || expiry.Value <= now)
            return 0;

        return Math.Max(0, (int)Math.Ceiling((expiry.Value - now).TotalDays));
    }

    public void Activate(DateTime startUtc, DateTime endUtc, bool autoRenew, Guid? updatedBy)
    {
        StartUtc = EnsureUtc(startUtc);
        EndUtc = EnsureUtc(endUtc);
        AutoRenew = autoRenew;
        GraceEndUtc = null;
        Status = MobileSubscriptionStatus.Active;
        SetUpdatedBy(updatedBy);
    }

    public void MoveToGrace(DateTime graceEndUtc, Guid? updatedBy)
    {
        GraceEndUtc = EnsureUtc(graceEndUtc);
        Status = MobileSubscriptionStatus.Grace;
        SetUpdatedBy(updatedBy);
    }

    public void Suspend(Guid? updatedBy)
    {
        Status = MobileSubscriptionStatus.Suspended;
        SetUpdatedBy(updatedBy);
    }

    public void Cancel(Guid? updatedBy)
    {
        Status = MobileSubscriptionStatus.Cancelled;
        SetUpdatedBy(updatedBy);
    }

    public void Expire(Guid? updatedBy)
    {
        Status = MobileSubscriptionStatus.Expired;
        SetUpdatedBy(updatedBy);
    }

    public void MarkValidated(DateTime validatedAtUtc, Guid? updatedBy)
    {
        LastValidatedUtc = EnsureUtc(validatedAtUtc);
        SetUpdatedBy(updatedBy);
    }

    public void ChangePlan(Guid subscriptionPlanId, Guid? updatedBy)
    {
        SubscriptionPlanId = subscriptionPlanId;
        SetUpdatedBy(updatedBy);
    }
}

public sealed class MobileLicense : MobileAuditableEntity
{
    private MobileLicense() { }

    public MobileLicense(Guid companyId, Guid mobileDeviceId, Guid mobileSubscriptionId, DateTime issuedAtUtc)
    {
        CompanyId = companyId;
        MobileDeviceId = mobileDeviceId;
        MobileSubscriptionId = mobileSubscriptionId;
        IssuedAtUtc = EnsureUtc(issuedAtUtc);
        Status = MobileLicenseStatus.Active;
    }

    public Guid CompanyId { get; private set; }
    public Guid MobileDeviceId { get; private set; }
    public Guid MobileSubscriptionId { get; private set; }
    public MobileLicenseStatus Status { get; private set; }
    public DateTime IssuedAtUtc { get; private set; }
    public DateTime? ExpiryUtc { get; private set; }
    public DateTime? RevokedAtUtc { get; private set; }

    public Company? Company { get; private set; }
    public MobileDevice? MobileDevice { get; private set; }
    public MobileSubscription? MobileSubscription { get; private set; }

    public void SetExpiry(DateTime? expiryUtc, Guid? updatedBy)
    {
        ExpiryUtc = EnsureUtc(expiryUtc);
        SetUpdatedBy(updatedBy);
    }

    public void Suspend(Guid? updatedBy)
    {
        Status = MobileLicenseStatus.Suspended;
        SetUpdatedBy(updatedBy);
    }

    public void Activate(Guid? updatedBy)
    {
        Status = MobileLicenseStatus.Active;
        SetUpdatedBy(updatedBy);
    }

    public void Revoke(Guid? updatedBy)
    {
        Status = MobileLicenseStatus.Revoked;
        RevokedAtUtc = DateTime.UtcNow;
        SetUpdatedBy(updatedBy);
    }

    public void Expire(Guid? updatedBy)
    {
        Status = MobileLicenseStatus.Expired;
        SetUpdatedBy(updatedBy);
    }
}

public sealed class DeviceSession : MobileAuditableEntity
{
    private DeviceSession() { }

    public DeviceSession(Guid companyId, Guid mobileDeviceId, string refreshToken, DateTime expiresAtUtc)
    {
        CompanyId = companyId;
        MobileDeviceId = mobileDeviceId;
        RefreshToken = refreshToken;
        ExpiresAtUtc = EnsureUtc(expiresAtUtc);
        LastSeenAtUtc = DateTime.UtcNow;
        Status = DeviceSessionStatus.Active;
    }

    public Guid CompanyId { get; private set; }
    public Guid MobileDeviceId { get; private set; }
    public string RefreshToken { get; private set; } = string.Empty;
    public DateTime ExpiresAtUtc { get; private set; }
    public DateTime LastSeenAtUtc { get; private set; }
    public DeviceSessionStatus Status { get; private set; }

    public Company? Company { get; private set; }
    public MobileDevice? MobileDevice { get; private set; }

    public bool IsActive(DateTime utcNow) =>
        Status == DeviceSessionStatus.Active && ExpiresAtUtc > EnsureUtc(utcNow);

    public void Touch(Guid? updatedBy)
    {
        LastSeenAtUtc = DateTime.UtcNow;
        SetUpdatedBy(updatedBy);
    }

    public void Logout(Guid? updatedBy)
    {
        Status = DeviceSessionStatus.LoggedOut;
        SetUpdatedBy(updatedBy);
    }

    public void Revoke(Guid? updatedBy)
    {
        Status = DeviceSessionStatus.Revoked;
        SetUpdatedBy(updatedBy);
    }
}

public sealed class MobilePaymentTransaction : MobileAuditableEntity
{
    private MobilePaymentTransaction() { }

    public MobilePaymentTransaction(
        Guid companyId,
        Guid mobileSubscriptionId,
        MobilePaymentType paymentType,
        string transactionRef,
        decimal amount,
        string currency)
    {
        CompanyId = companyId;
        MobileSubscriptionId = mobileSubscriptionId;
        PaymentType = paymentType;
        TransactionRef = transactionRef.Trim();
        Amount = amount;
        Currency = currency.Trim().ToUpperInvariant();
        PaymentStatus = MobilePaymentStatus.Pending;
    }

    public Guid CompanyId { get; private set; }
    public Guid MobileSubscriptionId { get; private set; }
    public MobilePaymentType PaymentType { get; private set; }
    public MobilePaymentStatus PaymentStatus { get; private set; }
    public string TransactionRef { get; private set; } = string.Empty;
    public string? GatewayOrderId { get; private set; }
    public string? GatewayPaymentId { get; private set; }
    public decimal Amount { get; private set; }
    public string Currency { get; private set; } = "INR";
    public DateTime? PaidAtUtc { get; private set; }
    public DateTime? FailedAtUtc { get; private set; }
    public DateTime? RefundedAtUtc { get; private set; }
    public string? FailureReason { get; private set; }

    public Company? Company { get; private set; }
    public MobileSubscription? MobileSubscription { get; private set; }

    public void MarkPaid(string gatewayOrderId, string gatewayPaymentId, Guid? updatedBy)
    {
        GatewayOrderId = gatewayOrderId.Trim();
        GatewayPaymentId = gatewayPaymentId.Trim();
        PaymentStatus = MobilePaymentStatus.Paid;
        PaidAtUtc = DateTime.UtcNow;
        SetUpdatedBy(updatedBy);
    }

    public void SetGatewayOrder(string gatewayOrderId, Guid? updatedBy)
    {
        GatewayOrderId = gatewayOrderId.Trim();
        SetUpdatedBy(updatedBy);
    }

    public void MarkFailed(string reason, Guid? updatedBy)
    {
        PaymentStatus = MobilePaymentStatus.Failed;
        FailureReason = reason;
        FailedAtUtc = DateTime.UtcNow;
        SetUpdatedBy(updatedBy);
    }

    public void MarkRefunded(Guid? updatedBy)
    {
        PaymentStatus = MobilePaymentStatus.Refunded;
        RefundedAtUtc = DateTime.UtcNow;
        SetUpdatedBy(updatedBy);
    }
}

public sealed class FeatureEntitlement : MobileAuditableEntity
{
    private FeatureEntitlement() { }

    public FeatureEntitlement(Guid companyId, Guid mobileSubscriptionId, string featureKey, bool isEnabled)
    {
        CompanyId = companyId;
        MobileSubscriptionId = mobileSubscriptionId;
        FeatureKey = featureKey.Trim();
        IsEnabled = isEnabled;
    }

    public Guid CompanyId { get; private set; }
    public Guid MobileSubscriptionId { get; private set; }
    public string FeatureKey { get; private set; } = string.Empty;
    public bool IsEnabled { get; private set; }

    public Company? Company { get; private set; }
    public MobileSubscription? MobileSubscription { get; private set; }

    public void SetEnabled(bool enabled, Guid? updatedBy)
    {
        IsEnabled = enabled;
        SetUpdatedBy(updatedBy);
    }
}

public sealed class TrialHistory : MobileAuditableEntity
{
    private TrialHistory() { }

    public TrialHistory(Guid companyId, Guid mobileSubscriptionId, TrialActionType actionType, DateTime actionAtUtc, string? notes)
    {
        CompanyId = companyId;
        MobileSubscriptionId = mobileSubscriptionId;
        ActionType = actionType;
        ActionAtUtc = EnsureUtc(actionAtUtc);
        Notes = string.IsNullOrWhiteSpace(notes) ? null : notes.Trim();
    }

    public Guid CompanyId { get; private set; }
    public Guid MobileSubscriptionId { get; private set; }
    public TrialActionType ActionType { get; private set; }
    public DateTime ActionAtUtc { get; private set; }
    public string? Notes { get; private set; }

    public Company? Company { get; private set; }
    public MobileSubscription? MobileSubscription { get; private set; }
}