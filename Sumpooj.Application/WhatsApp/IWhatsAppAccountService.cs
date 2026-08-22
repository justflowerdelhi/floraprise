namespace Sumpooj.Application.WhatsApp;

public interface IWhatsAppAccountService
{
    Task<WhatsAppAccountResponse> CreateAccountAsync(CreateWhatsAppAccountRequest request, CancellationToken cancellationToken = default);
    Task<WhatsAppAccountResponse?> GetAccountByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<WhatsAppAccountResponse?> GetAccountByPhoneNumberIdAsync(string phoneNumberId, CancellationToken cancellationToken = default);
    Task<WhatsAppAccountResponse?> GetAccountByMemberIdAsync(int memberId, CancellationToken cancellationToken = default);
    Task<WhatsAppAccountResponse?> UpdateAccountAsync(Guid id, UpdateWhatsAppAccountRequest request, CancellationToken cancellationToken = default);
    Task<bool> DeactivateAccountAsync(Guid id, CancellationToken cancellationToken = default);
    Task<bool> ActivateAccountAsync(Guid id, CancellationToken cancellationToken = default);
    Task<WhatsAppAccountResolveResponse?> ResolveCompanyAsync(string phoneNumberId, CancellationToken cancellationToken = default);
}
