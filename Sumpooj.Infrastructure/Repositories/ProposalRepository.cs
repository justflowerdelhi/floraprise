using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Common;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Proposals;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class ProposalRepository : IProposalRepository
{
    private readonly SumpoojDbContext _db;

    public ProposalRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public async Task<Proposal?> GetByIdAsync(Guid companyId, Guid id)
    {
        return await _db.Proposals
            .Include(p => p.Items)
            .FirstOrDefaultAsync(p => p.CompanyId == companyId && p.Id == id);
    }

    public async Task<Proposal?> GetByNumberAsync(Guid companyId, string proposalNumber)
    {
        return await _db.Proposals
            .Include(p => p.Items)
            .FirstOrDefaultAsync(p => p.CompanyId == companyId && p.ProposalNumber == proposalNumber);
    }

    public async Task<PagedResult<ProposalDto>> SearchAsync(Guid companyId, ProposalSearchRequest request)
    {
        var query = _db.Proposals
            .Include(p => p.Items)
            .Where(p => p.CompanyId == companyId && p.IsActive);

        if (request.EventId.HasValue)
        {
            query = query.Where(p => p.EventId == request.EventId.Value);
        }

        if (request.Status.HasValue)
        {
            query = query.Where(p => p.Status == request.Status.Value);
        }

        if (!string.IsNullOrWhiteSpace(request.Query))
        {
            var q = request.Query.ToLower();
            query = query.Where(p =>
                p.ProposalNumber.ToLower().Contains(q) ||
                p.Title.ToLower().Contains(q) ||
                p.ClientName.ToLower().Contains(q) ||
                p.ClientEmail.ToLower().Contains(q));
        }

        var total = await query.CountAsync();

        var proposals = await query
            .OrderByDescending(p => p.CreatedAtUtc)
            .Skip((request.Page - 1) * request.PageSize)
            .Take(request.PageSize)
            .ToListAsync();

        var items = proposals.Select(p => MapToDto(p)).ToList();

        return new PagedResult<ProposalDto>(items, total, request.Page, request.PageSize);
    }

    public async Task<List<ProposalDto>> GetByEventAsync(Guid companyId, Guid eventId)
    {
        var proposals = await _db.Proposals
            .Include(p => p.Items)
            .Where(p => p.CompanyId == companyId && p.EventId == eventId && p.IsActive)
            .OrderByDescending(p => p.Version)
            .ToListAsync();

        return proposals.Select(p => MapToDto(p)).ToList();
    }

    public async Task<string> GenerateProposalNumberAsync(Guid companyId)
    {
        var year = DateTime.UtcNow.Year;
        var prefix = $"PROP-{year}-";

        var lastNumber = await _db.Proposals
            .Where(p => p.CompanyId == companyId && p.ProposalNumber.StartsWith(prefix))
            .OrderByDescending(p => p.ProposalNumber)
            .Select(p => p.ProposalNumber)
            .FirstOrDefaultAsync();

        var nextNumber = 1;
        if (lastNumber != null)
        {
            var lastNumStr = lastNumber.Replace(prefix, "");
            if (int.TryParse(lastNumStr, out var lastNum))
            {
                nextNumber = lastNum + 1;
            }
        }

        return $"{prefix}{nextNumber:D4}";
    }

    public async Task AddAsync(Proposal proposal)
    {
        await _db.Proposals.AddAsync(proposal);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(Proposal proposal)
    {
        _db.Proposals.Update(proposal);
        await _db.SaveChangesAsync();
    }

    private static ProposalDto MapToDto(Proposal p) => new()
    {
        Id = p.Id,
        EventId = p.EventId,
        ProposalNumber = p.ProposalNumber,
        Title = p.Title,
        VersionName = $"Version {p.Version}",
        VersionNumber = p.Version,
        Status = p.Status,
        ValidUntil = p.ValidUntil,
        SentAt = p.SentAt,
        RespondedAt = p.RespondedAt,
        ClientName = p.ClientName,
        ClientEmail = p.ClientEmail,
        ClientPhone = p.ClientPhone,
        Introduction = p.Introduction,
        TermsAndConditions = p.TermsAndConditions,
        PaymentTerms = p.PaymentTerms,
        Notes = p.ClientNotes,
        InternalNotes = p.InternalNotes,
        Subtotal = p.SubTotal,
        DiscountType = p.DiscountPercent > 0 ? "PERCENTAGE" : "FIXED",
        DiscountValue = p.DiscountPercent > 0 ? p.DiscountPercent : p.DiscountAmount,
        Discount = p.DiscountAmount,
        TaxRate = 0,
        Tax = p.TaxAmount,
        GrandTotal = p.TotalAmount,
        TotalCost = 0,
        GrossProfit = p.TotalAmount,
        MarginPercentage = 100,
        DepositAmount = p.DepositAmount,
        DepositPercent = p.DepositPercent,
        ClientFeedback = p.ClientFeedback,
        DeclineReason = p.DeclineReason,
        CreatedAtUtc = p.CreatedAtUtc,
        UpdatedAtUtc = p.UpdatedAtUtc ?? p.CreatedAtUtc,
        Items = p.Items.Select(i => new ProposalItemDto
        {
            Id = i.Id,
            Type = "PRODUCT",
            Name = i.Description,
            Category = i.Category,
            Description = i.Notes,
            LinkedProductId = i.ProductId,
            Quantity = i.Quantity,
            UnitPrice = i.UnitPrice,
            UnitCost = 0,
            TotalPrice = i.TotalPrice,
            TotalCost = 0,
            MarginPercentage = 100,
            Notes = i.Notes,
            SortOrder = i.SortOrder
        }).ToList()
    };
}
