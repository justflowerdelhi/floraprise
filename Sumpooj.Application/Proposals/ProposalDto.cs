using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Proposals;

public class ProposalDto
{
    public Guid Id { get; set; }
    public Guid EventId { get; set; }
    public string? EventName { get; set; }
    public string ProposalNumber { get; set; } = default!;
    public string Title { get; set; } = default!;
    public string VersionName { get; set; } = default!;
    public int VersionNumber { get; set; }
    public ProposalStatus Status { get; set; }
    public string StatusName => Status.ToString();
    public DateTime? ValidUntil { get; set; }
    public DateTime? SentAt { get; set; }
    public DateTime? RespondedAt { get; set; }
    
    public string ClientName { get; set; } = default!;
    public string ClientEmail { get; set; } = default!;
    public string? ClientPhone { get; set; }
    
    public string? Introduction { get; set; }
    public string? TermsAndConditions { get; set; }
    public string? PaymentTerms { get; set; }
    public string? Notes { get; set; }
    public string? InternalNotes { get; set; }
    
    public decimal Subtotal { get; set; }
    public string DiscountType { get; set; } = "FIXED";
    public decimal DiscountValue { get; set; }
    public decimal Discount { get; set; }
    public decimal TaxRate { get; set; }
    public decimal Tax { get; set; }
    public decimal GrandTotal { get; set; }
    public decimal TotalCost { get; set; }
    public decimal GrossProfit { get; set; }
    public decimal MarginPercentage { get; set; }
    public decimal DepositAmount { get; set; }
    public decimal DepositPercent { get; set; }
    
    public string? ClientFeedback { get; set; }
    public string? DeclineReason { get; set; }
    
    public List<ProposalItemDto> Items { get; set; } = new();
    
    public DateTime CreatedAtUtc { get; set; }
    public DateTime UpdatedAtUtc { get; set; }
}

public class ProposalItemDto
{
    public Guid Id { get; set; }
    public string Type { get; set; } = "PRODUCT";
    public string Name { get; set; } = default!;
    public string Category { get; set; } = default!;
    public string? Description { get; set; }
    public Guid? LinkedProductId { get; set; }
    public string? LinkedProductSku { get; set; }
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal UnitCost { get; set; }
    public decimal TotalPrice { get; set; }
    public decimal TotalCost { get; set; }
    public decimal MarginPercentage { get; set; }
    public string? Notes { get; set; }
    public int SortOrder { get; set; }
}

public class CreateProposalRequest
{
    public Guid EventId { get; set; }
    public string Title { get; set; } = default!;
    public string VersionName { get; set; } = "Initial Proposal";
    public string ClientName { get; set; } = default!;
    public string ClientEmail { get; set; } = default!;
    public string? ClientPhone { get; set; }
    public DateTime? ValidUntil { get; set; }
    public string? Introduction { get; set; }
    public string? TermsAndConditions { get; set; }
    public string? PaymentTerms { get; set; }
    public string? Notes { get; set; }
    public string? InternalNotes { get; set; }
    public string DiscountType { get; set; } = "FIXED";
    public decimal DiscountValue { get; set; }
    public decimal TaxRate { get; set; }
    public decimal DepositPercent { get; set; }
    public List<CreateProposalItemRequest> Items { get; set; } = new();
}

public class CreateProposalItemRequest
{
    public string Type { get; set; } = "PRODUCT";
    public string Name { get; set; } = default!;
    public string Category { get; set; } = default!;
    public string? Description { get; set; }
    public Guid? LinkedProductId { get; set; }
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal UnitCost { get; set; }
    public string? Notes { get; set; }
    public int SortOrder { get; set; }
}

public class UpdateProposalRequest : CreateProposalRequest
{
}

public class ProposalSearchRequest
{
    public Guid? EventId { get; set; }
    public ProposalStatus? Status { get; set; }
    public string? Query { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}
