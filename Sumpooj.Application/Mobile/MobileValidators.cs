namespace Sumpooj.Application.Mobile;

public static class MobileValidators
{
    public static void Validate(RegisterMobileCustomerRequest request)
    {
        if (request.CompanyId == Guid.Empty)
            throw new ArgumentException("CompanyId is required.", nameof(request.CompanyId));

        ArgumentException.ThrowIfNullOrWhiteSpace(request.BusinessName);
        ArgumentException.ThrowIfNullOrWhiteSpace(request.OwnerName);
        ArgumentException.ThrowIfNullOrWhiteSpace(request.FullName);
        ArgumentException.ThrowIfNullOrWhiteSpace(request.Mobile);
        ArgumentException.ThrowIfNullOrWhiteSpace(request.DeviceId);
        ArgumentException.ThrowIfNullOrWhiteSpace(request.Platform);
        ArgumentException.ThrowIfNullOrWhiteSpace(request.AppVersion);
    }

    public static void Validate(MobileLicenseCheckRequest request)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(request.DeviceId);
        ArgumentException.ThrowIfNullOrWhiteSpace(request.AppVersion);

        if (request.CompanyId == Guid.Empty)
            throw new ArgumentException("CompanyId is required.", nameof(request.CompanyId));

        if (request.MobileUserId == Guid.Empty)
            throw new ArgumentException("MobileUserId is required.", nameof(request.MobileUserId));
    }

    public static void Validate(MobileHeartbeatRequest request)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(request.DeviceId);
        ArgumentException.ThrowIfNullOrWhiteSpace(request.AppVersion);

        if (request.CompanyId == Guid.Empty)
            throw new ArgumentException("CompanyId is required.", nameof(request.CompanyId));

        if (request.MobileUserId == Guid.Empty)
            throw new ArgumentException("MobileUserId is required.", nameof(request.MobileUserId));
    }

    public static void Validate(MobileAuthLoginRequest request)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(request.Identifier);
        ArgumentException.ThrowIfNullOrWhiteSpace(request.Password);
        ArgumentException.ThrowIfNullOrWhiteSpace(request.DeviceId);
        ArgumentException.ThrowIfNullOrWhiteSpace(request.Platform);
        ArgumentException.ThrowIfNullOrWhiteSpace(request.AppVersion);

        if (request.CompanyId == Guid.Empty)
            throw new ArgumentException("CompanyId is required.", nameof(request.CompanyId));
    }
}
