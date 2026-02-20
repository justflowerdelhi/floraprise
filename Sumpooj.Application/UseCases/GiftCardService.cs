using Sumpooj.Application.Common;
using Sumpooj.Application.GiftCards;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.UseCases;

public class GiftCardService
{
    private readonly IGiftCardRepository _giftCardRepository;

    public GiftCardService(IGiftCardRepository giftCardRepository)
    {
        _giftCardRepository = giftCardRepository;
    }

    public async Task<GiftCardDto?> GetByIdAsync(Guid companyId, Guid id)
    {
        var card = await _giftCardRepository.GetByIdAsync(companyId, id);
        return card == null ? null : MapToDto(card);
    }

    public async Task<PagedResult<GiftCardDto>> SearchAsync(Guid companyId, GiftCardSearchRequest request)
    {
        return await _giftCardRepository.SearchAsync(companyId, request);
    }

    public async Task<GiftCardBalanceDto> CheckBalanceAsync(Guid companyId, string code)
    {
        var card = await _giftCardRepository.GetByCodeAsync(companyId, code);

        if (card == null)
        {
            return new GiftCardBalanceDto
            {
                Code = code,
                CurrentBalance = 0,
                IsValid = false,
                Message = "Gift card not found"
            };
        }

        return new GiftCardBalanceDto
        {
            Code = card.Code,
            CurrentBalance = card.CurrentBalance,
            IsValid = card.IsValid(),
            Message = card.IsExpired() ? "Gift card has expired" :
                      card.Status != GiftCardStatus.Active ? $"Gift card is {card.Status}" :
                      card.CurrentBalance <= 0 ? "No balance remaining" :
                      null
        };
    }

    public async Task<GiftCardDto> CreateAsync(Guid companyId, CreateGiftCardRequest request)
    {
        var code = await _giftCardRepository.GenerateUniqueCodeAsync(companyId);

        var card = new GiftCard(
            companyId,
            code,
            request.Amount,
            request.RecipientName,
            request.RecipientEmail,
            request.SenderName,
            request.PersonalMessage);

        if (request.DesignTheme != null)
        {
            card.SetDesignTheme(request.DesignTheme);
        }

        if (request.ExpiresAt.HasValue)
        {
            card.SetExpiry(request.ExpiresAt.Value);
        }

        await _giftCardRepository.AddAsync(card);
        return MapToDto(card);
    }

    public async Task<GiftCardBalanceDto> RedeemAsync(Guid companyId, RedeemGiftCardRequest request)
    {
        var card = await _giftCardRepository.GetByCodeAsync(companyId, request.Code)
            ?? throw new KeyNotFoundException("Gift card not found");

        if (!card.IsValid())
        {
            return new GiftCardBalanceDto
            {
                Code = card.Code,
                CurrentBalance = card.CurrentBalance,
                IsValid = false,
                Message = card.IsExpired() ? "Gift card has expired" : "Gift card is not active"
            };
        }

        if (request.Amount > card.CurrentBalance)
        {
            return new GiftCardBalanceDto
            {
                Code = card.Code,
                CurrentBalance = card.CurrentBalance,
                IsValid = false,
                Message = $"Insufficient balance. Available: {card.CurrentBalance:C}"
            };
        }

        card.Redeem(request.Amount);
        await _giftCardRepository.UpdateAsync(card);

        return new GiftCardBalanceDto
        {
            Code = card.Code,
            CurrentBalance = card.CurrentBalance,
            IsValid = card.IsValid(),
            Message = $"Successfully redeemed {request.Amount:C}"
        };
    }

    public async Task AddBalanceAsync(Guid companyId, Guid id, decimal amount)
    {
        var card = await _giftCardRepository.GetByIdAsync(companyId, id)
            ?? throw new KeyNotFoundException("Gift card not found");

        card.AddBalance(amount);
        await _giftCardRepository.UpdateAsync(card);
    }

    public async Task DeactivateAsync(Guid companyId, Guid id)
    {
        var card = await _giftCardRepository.GetByIdAsync(companyId, id)
            ?? throw new KeyNotFoundException("Gift card not found");

        card.Deactivate();
        await _giftCardRepository.UpdateAsync(card);
    }

    private static GiftCardDto MapToDto(GiftCard card) => new()
    {
        Id = card.Id,
        Code = card.Code,
        InitialBalance = card.InitialBalance,
        CurrentBalance = card.CurrentBalance,
        Status = card.Status.ToString(),
        IssuedAt = card.IssuedAt,
        ExpiresAt = card.ExpiresAt,
        LastUsedAt = card.LastUsedAt,
        RecipientName = card.RecipientName,
        RecipientEmail = card.RecipientEmail,
        SenderName = card.SenderName,
        PersonalMessage = card.PersonalMessage,
        DesignTheme = card.DesignTheme
    };
}
