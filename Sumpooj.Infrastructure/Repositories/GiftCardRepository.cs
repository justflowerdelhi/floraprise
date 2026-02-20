using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Common;
using Sumpooj.Application.GiftCards;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class GiftCardRepository : IGiftCardRepository
{
    private readonly SumpoojDbContext _db;

    public GiftCardRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public async Task<GiftCard?> GetByIdAsync(Guid companyId, Guid id)
    {
        return await _db.GiftCards
            .FirstOrDefaultAsync(g => g.CompanyId == companyId && g.Id == id);
    }

    public async Task<GiftCard?> GetByCodeAsync(Guid companyId, string code)
    {
        return await _db.GiftCards
            .FirstOrDefaultAsync(g => g.CompanyId == companyId && g.Code == code);
    }

    public async Task<PagedResult<GiftCardDto>> SearchAsync(Guid companyId, GiftCardSearchRequest request)
    {
        var query = _db.GiftCards.Where(g => g.CompanyId == companyId);

        if (!string.IsNullOrWhiteSpace(request.Query))
        {
            var q = request.Query.ToLower();
            query = query.Where(g =>
                g.Code.ToLower().Contains(q) ||
                (g.RecipientName != null && g.RecipientName.ToLower().Contains(q)) ||
                (g.RecipientEmail != null && g.RecipientEmail.ToLower().Contains(q)));
        }

        if (!string.IsNullOrWhiteSpace(request.Status) && Enum.TryParse<GiftCardStatus>(request.Status, true, out var status))
        {
            query = query.Where(g => g.Status == status);
        }

        if (request.MinBalance.HasValue)
        {
            query = query.Where(g => g.CurrentBalance >= request.MinBalance.Value);
        }

        var total = await query.CountAsync();

        var items = await query
            .OrderByDescending(g => g.IssuedAt)
            .Skip((request.Page - 1) * request.PageSize)
            .Take(request.PageSize)
            .Select(g => new GiftCardDto
            {
                Id = g.Id,
                Code = g.Code,
                InitialBalance = g.InitialBalance,
                CurrentBalance = g.CurrentBalance,
                Status = g.Status.ToString(),
                IssuedAt = g.IssuedAt,
                ExpiresAt = g.ExpiresAt,
                LastUsedAt = g.LastUsedAt,
                RecipientName = g.RecipientName,
                RecipientEmail = g.RecipientEmail,
                SenderName = g.SenderName,
                PersonalMessage = g.PersonalMessage,
                DesignTheme = g.DesignTheme
            })
            .ToListAsync();

        return new PagedResult<GiftCardDto>(items, total, request.Page, request.PageSize);
    }

    public async Task AddAsync(GiftCard giftCard)
    {
        await _db.GiftCards.AddAsync(giftCard);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(GiftCard giftCard)
    {
        _db.GiftCards.Update(giftCard);
        await _db.SaveChangesAsync();
    }

    public async Task<string> GenerateUniqueCodeAsync(Guid companyId)
    {
        string code;
        do
        {
            code = GenerateCode();
        } while (await _db.GiftCards.AnyAsync(g => g.CompanyId == companyId && g.Code == code));

        return code;
    }

    private static string GenerateCode()
    {
        const string chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
        var random = new Random();
        var code = new char[16];
        
        for (int i = 0; i < 16; i++)
        {
            code[i] = chars[random.Next(chars.Length)];
        }
        
        // Format: XXXX-XXXX-XXXX-XXXX
        return $"{new string(code, 0, 4)}-{new string(code, 4, 4)}-{new string(code, 8, 4)}-{new string(code, 12, 4)}";
    }
}
