namespace Sumpooj.Application.WhatsApp;

public record CreateWhatsAppAccountRequest(
    int MemberId,
    string BusinessName,
    string PhoneNumber,
    string PhoneNumberId,
    string WabaId,
    string AccessToken,
    string VerifyToken
);

public record UpdateWhatsAppAccountRequest(
    string? AccessToken,
    string? VerifyToken
);

public record WhatsAppAccountResponse(
    Guid Id,
    int MemberId,
    string BusinessName,
    string PhoneNumber,
    string PhoneNumberId,
    string WabaId,
    bool IsActive,
    DateTime CreatedAtUtc,
    DateTime? UpdatedAtUtc
);

public record WhatsAppAccountResolveResponse(
    int MemberId,
    string BusinessName
);
