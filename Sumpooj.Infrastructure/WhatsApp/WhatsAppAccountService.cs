using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Sumpooj.Application.WhatsApp;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.WhatsApp;

public class WhatsAppAccountService : IWhatsAppAccountService
{
    private readonly SumpoojDbContext _db;
    private readonly ILogger<WhatsAppAccountService> _logger;

    public WhatsAppAccountService(SumpoojDbContext db, ILogger<WhatsAppAccountService> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task<WhatsAppAccountResponse> CreateAccountAsync(CreateWhatsAppAccountRequest request, CancellationToken cancellationToken = default)
    {
        // Check if member already has a WhatsApp account
        var existing = await _db.WhatsAppAccounts
            .AsNoTracking()
            .FirstOrDefaultAsync(w => w.MemberId == request.MemberId, cancellationToken);

        if (existing != null)
        {
            throw new InvalidOperationException($"Member {request.MemberId} already has a WhatsApp account registered.");
        }

        // Check if phone number ID is already registered
        var existingByPhoneId = await _db.WhatsAppAccounts
            .AsNoTracking()
            .FirstOrDefaultAsync(w => w.PhoneNumberId == request.PhoneNumberId, cancellationToken);

        if (existingByPhoneId != null)
        {
            throw new InvalidOperationException($"Phone Number ID {request.PhoneNumberId} is already registered to another member.");
        }

        var account = new WhatsAppAccount(
            request.MemberId,
            request.BusinessName,
            request.PhoneNumber,
            request.PhoneNumberId,
            request.WabaId,
            request.AccessToken,
            request.VerifyToken
        );

        _db.WhatsAppAccounts.Add(account);
        await _db.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Created WhatsApp account for MemberId {MemberId} with PhoneNumberId {PhoneNumberId}", 
            request.MemberId, request.PhoneNumberId);

        return MapToResponse(account);
    }

    public async Task<WhatsAppAccountResponse?> GetAccountByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var account = await _db.WhatsAppAccounts
            .AsNoTracking()
            .FirstOrDefaultAsync(w => w.Id == id, cancellationToken);

        return account == null ? null : MapToResponse(account);
    }

    public async Task<WhatsAppAccountResponse?> GetAccountByPhoneNumberIdAsync(string phoneNumberId, CancellationToken cancellationToken = default)
    {
        var account = await _db.WhatsAppAccounts
            .AsNoTracking()
            .FirstOrDefaultAsync(w => w.PhoneNumberId == phoneNumberId && w.IsActive, cancellationToken);

        return account == null ? null : MapToResponse(account);
    }

    public async Task<WhatsAppAccountResponse?> GetAccountByMemberIdAsync(int memberId, CancellationToken cancellationToken = default)
    {
        var account = await _db.WhatsAppAccounts
            .AsNoTracking()
            .FirstOrDefaultAsync(w => w.MemberId == memberId, cancellationToken);

        return account == null ? null : MapToResponse(account);
    }

    public async Task<WhatsAppAccountResponse?> UpdateAccountAsync(Guid id, UpdateWhatsAppAccountRequest request, CancellationToken cancellationToken = default)
    {
        var account = await _db.WhatsAppAccounts
            .FirstOrDefaultAsync(w => w.Id == id, cancellationToken);

        if (account == null)
        {
            return null;
        }

        if (!string.IsNullOrWhiteSpace(request.AccessToken) || !string.IsNullOrWhiteSpace(request.VerifyToken))
        {
            account.UpdateTokens(
                request.AccessToken ?? account.AccessToken,
                request.VerifyToken ?? account.VerifyToken
            );
        }

        await _db.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Updated WhatsApp account {AccountId}", id);

        return MapToResponse(account);
    }

    public async Task<bool> DeactivateAccountAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var account = await _db.WhatsAppAccounts
            .FirstOrDefaultAsync(w => w.Id == id, cancellationToken);

        if (account == null)
        {
            return false;
        }

        account.Deactivate();
        await _db.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Deactivated WhatsApp account {AccountId}", id);

        return true;
    }

    public async Task<bool> ActivateAccountAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var account = await _db.WhatsAppAccounts
            .FirstOrDefaultAsync(w => w.Id == id, cancellationToken);

        if (account == null)
        {
            return false;
        }

        account.Activate();
        await _db.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Activated WhatsApp account {AccountId}", id);

        return true;
    }

    public async Task<WhatsAppAccountResolveResponse?> ResolveCompanyAsync(string phoneNumberId, CancellationToken cancellationToken = default)
    {
        var account = await _db.WhatsAppAccounts
            .AsNoTracking()
            .FirstOrDefaultAsync(w => w.PhoneNumberId == phoneNumberId && w.IsActive, cancellationToken);

        if (account == null)
        {
            _logger.LogInformation("Unknown WhatsApp Phone Number ID: {PhoneNumberId}", phoneNumberId);
            return null;
        }

        _logger.LogInformation("WhatsApp Phone Number ID {PhoneNumberId} resolved to MemberId {MemberId}", 
            phoneNumberId, account.MemberId);

        return new WhatsAppAccountResolveResponse(
            account.MemberId,
            account.BusinessName
        );
    }

    private static WhatsAppAccountResponse MapToResponse(WhatsAppAccount account)
    {
        return new WhatsAppAccountResponse(
            account.Id,
            account.MemberId,
            account.BusinessName,
            account.PhoneNumber,
            account.PhoneNumberId,
            account.WabaId,
            account.IsActive,
            account.CreatedAtUtc,
            account.UpdatedAtUtc
        );
    }
}
