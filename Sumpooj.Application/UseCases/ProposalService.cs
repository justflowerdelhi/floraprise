using Sumpooj.Application.Common;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Proposals;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.UseCases;

public class ProposalService
{
    private readonly IProposalRepository _repository;

    public ProposalService(IProposalRepository repository)
    {
        _repository = repository;
    }

    public async Task<PagedResult<ProposalDto>> SearchAsync(Guid companyId, ProposalSearchRequest request)
    {
        return await _repository.SearchAsync(companyId, request);
    }

    public async Task<ProposalDto?> GetByIdAsync(Guid companyId, Guid id)
    {
        var proposal = await _repository.GetByIdAsync(companyId, id);
        return proposal == null ? null : MapToDto(proposal);
    }

    public async Task<List<ProposalDto>> GetByEventAsync(Guid companyId, Guid eventId)
    {
        return await _repository.GetByEventAsync(companyId, eventId);
    }

    public async Task<ProposalDto> CreateAsync(Guid companyId, Guid userId, CreateProposalRequest request)
    {
        var proposalNumber = await _repository.GenerateProposalNumberAsync(companyId);

        var proposal = new Proposal(
            companyId,
            request.EventId,
            proposalNumber,
            request.Title);

        proposal.SetClientInfo(request.ClientName, request.ClientEmail, request.ClientPhone);
        proposal.SetContent(request.Introduction, request.TermsAndConditions, request.PaymentTerms, request.Notes);
        proposal.SetInternalNotes(request.InternalNotes);
        proposal.SetValidUntil(request.ValidUntil);

        foreach (var item in request.Items)
        {
            var proposalItem = new ProposalItem(
                proposal.Id,
                item.Category,
                item.Name,
                item.Quantity,
                item.UnitPrice);

            if (item.LinkedProductId.HasValue)
            {
                proposalItem.LinkToProduct(item.LinkedProductId.Value);
            }

            proposalItem.Update(
                item.Category,
                item.Name,
                item.Quantity,
                item.UnitPrice,
                item.Notes,
                item.SortOrder);

            proposal.AddItem(proposalItem);
        }

        // Calculate deposit
        proposal.SetDeposit(proposal.TotalAmount * request.DepositPercent / 100, request.DepositPercent);

        await _repository.AddAsync(proposal);
        return MapToDto(proposal);
    }

    public async Task<ProposalDto?> UpdateAsync(Guid companyId, Guid id, UpdateProposalRequest request)
    {
        var proposal = await _repository.GetByIdAsync(companyId, id);
        if (proposal == null) return null;

        proposal.SetClientInfo(request.ClientName, request.ClientEmail, request.ClientPhone);
        proposal.SetContent(request.Introduction, request.TermsAndConditions, request.PaymentTerms, request.Notes);
        proposal.SetInternalNotes(request.InternalNotes);
        proposal.SetValidUntil(request.ValidUntil);

        var discountAmount = request.DiscountType == "PERCENTAGE" 
            ? proposal.SubTotal * request.DiscountValue / 100 
            : request.DiscountValue;
        var discountPercent = request.DiscountType == "PERCENTAGE" 
            ? request.DiscountValue 
            : 0;
        proposal.SetDiscount(discountAmount, discountPercent);
        proposal.SetTax(proposal.SubTotal * request.TaxRate);

        // Clear and re-add items
        proposal.ClearItems();
        foreach (var item in request.Items)
        {
            var proposalItem = new ProposalItem(
                proposal.Id,
                item.Category,
                item.Name,
                item.Quantity,
                item.UnitPrice);

            if (item.LinkedProductId.HasValue)
            {
                proposalItem.LinkToProduct(item.LinkedProductId.Value);
            }

            proposalItem.Update(
                item.Category,
                item.Name,
                item.Quantity,
                item.UnitPrice,
                item.Notes,
                item.SortOrder);

            proposal.AddItem(proposalItem);
        }

        proposal.SetDeposit(proposal.TotalAmount * request.DepositPercent / 100, request.DepositPercent);

        await _repository.UpdateAsync(proposal);
        return MapToDto(proposal);
    }

    public async Task<ProposalDto?> SendAsync(Guid companyId, Guid id)
    {
        var proposal = await _repository.GetByIdAsync(companyId, id);
        if (proposal == null) return null;

        proposal.Send();
        await _repository.UpdateAsync(proposal);
        return MapToDto(proposal);
    }

    public async Task<ProposalDto?> MarkViewedAsync(Guid companyId, Guid id)
    {
        var proposal = await _repository.GetByIdAsync(companyId, id);
        if (proposal == null) return null;

        proposal.MarkViewed();
        await _repository.UpdateAsync(proposal);
        return MapToDto(proposal);
    }

    public async Task<ProposalDto?> AcceptAsync(Guid companyId, Guid id, string? feedback)
    {
        var proposal = await _repository.GetByIdAsync(companyId, id);
        if (proposal == null) return null;

        proposal.Accept(feedback);
        await _repository.UpdateAsync(proposal);
        return MapToDto(proposal);
    }

    public async Task<ProposalDto?> DeclineAsync(Guid companyId, Guid id, string reason, string? feedback)
    {
        var proposal = await _repository.GetByIdAsync(companyId, id);
        if (proposal == null) return null;

        proposal.Decline(reason, feedback);
        await _repository.UpdateAsync(proposal);
        return MapToDto(proposal);
    }

    public async Task<ProposalDto?> RequestRevisionAsync(Guid companyId, Guid id, string feedback)
    {
        var proposal = await _repository.GetByIdAsync(companyId, id);
        if (proposal == null) return null;

        proposal.RequestRevision(feedback);
        await _repository.UpdateAsync(proposal);
        return MapToDto(proposal);
    }

    public async Task<ProposalDto?> CreateRevisionAsync(Guid companyId, Guid id)
    {
        var proposal = await _repository.GetByIdAsync(companyId, id);
        if (proposal == null) return null;

        var revision = proposal.CreateRevision();
        await _repository.AddAsync(revision);
        return MapToDto(revision);
    }

    private static ProposalDto MapToDto(Proposal proposal) => new()
    {
        Id = proposal.Id,
        EventId = proposal.EventId,
        ProposalNumber = proposal.ProposalNumber,
        Title = proposal.Title,
        VersionName = $"Version {proposal.Version}",
        VersionNumber = proposal.Version,
        Status = proposal.Status,
        ValidUntil = proposal.ValidUntil,
        SentAt = proposal.SentAt,
        RespondedAt = proposal.RespondedAt,
        ClientName = proposal.ClientName,
        ClientEmail = proposal.ClientEmail,
        ClientPhone = proposal.ClientPhone,
        Introduction = proposal.Introduction,
        TermsAndConditions = proposal.TermsAndConditions,
        PaymentTerms = proposal.PaymentTerms,
        Notes = proposal.ClientNotes,
        InternalNotes = proposal.InternalNotes,
        Subtotal = proposal.SubTotal,
        DiscountType = proposal.DiscountPercent > 0 ? "PERCENTAGE" : "FIXED",
        DiscountValue = proposal.DiscountPercent > 0 ? proposal.DiscountPercent : proposal.DiscountAmount,
        Discount = proposal.DiscountAmount,
        TaxRate = 0,
        Tax = proposal.TaxAmount,
        GrandTotal = proposal.TotalAmount,
        TotalCost = 0,
        GrossProfit = proposal.TotalAmount,
        MarginPercentage = 100,
        DepositAmount = proposal.DepositAmount,
        DepositPercent = proposal.DepositPercent,
        ClientFeedback = proposal.ClientFeedback,
        DeclineReason = proposal.DeclineReason,
        Items = proposal.Items.Select(i => new ProposalItemDto
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
        }).ToList(),
        CreatedAtUtc = proposal.CreatedAtUtc,
        UpdatedAtUtc = proposal.UpdatedAtUtc ?? proposal.CreatedAtUtc
    };
}
