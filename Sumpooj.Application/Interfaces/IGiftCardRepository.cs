using Sumpooj.Application.Common;
using Sumpooj.Application.GiftCards;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IGiftCardRepository
{
    Task<GiftCard?> GetByIdAsync(Guid companyId, Guid id);
    Task<GiftCard?> GetByCodeAsync(Guid companyId, string code);
    Task<PagedResult<GiftCardDto>> SearchAsync(Guid companyId, GiftCardSearchRequest request);
    Task AddAsync(GiftCard giftCard);
    Task UpdateAsync(GiftCard giftCard);
    Task<string> GenerateUniqueCodeAsync(Guid companyId);
}
