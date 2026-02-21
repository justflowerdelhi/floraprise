namespace Sumpooj.Domain.Entities;

/// <summary>
/// Represents a proposal/quote for events (weddings, corporate, etc.)
/// </summary>
public class Proposal : BaseEntity
{
    private readonly List<ProposalItem> _items = new();
    
    private Proposal() { }

    public Proposal(
        Guid companyId,
        Guid eventId,
        string proposalNumber,
        string title)
    {
        CompanyId = companyId;
        EventId = eventId;
        ProposalNumber = proposalNumber;
        Title = title;
        Status = ProposalStatus.Draft;
        Version = 1;
        IsActive = true;
    }

    public Guid CompanyId { get; private set; }
    public Guid EventId { get; private set; }
    
    /// <summary>
    /// Unique proposal number (e.g., "PROP-2024-001")
    /// </summary>
    public string ProposalNumber { get; private set; } = default!;
    
    /// <summary>
    /// Proposal title (e.g., "Smith Wedding - Floral Package")
    /// </summary>
    public string Title { get; private set; } = default!;
    
    /// <summary>
    /// Version number (incremented on revisions)
    /// </summary>
    public int Version { get; private set; }
    
    public ProposalStatus Status { get; private set; }
    
    /// <summary>
    /// Date proposal is valid until
    /// </summary>
    public DateTime? ValidUntil { get; private set; }
    
    /// <summary>
    /// Date proposal was sent to client
    /// </summary>
    public DateTime? SentAt { get; private set; }
    
    /// <summary>
    /// Client's response date
    /// </summary>
    public DateTime? RespondedAt { get; private set; }
    
    // Client Info (copied from Event or custom)
    public string ClientName { get; private set; } = default!;
    public string ClientEmail { get; private set; } = default!;
    public string? ClientPhone { get; private set; }
    
    /// <summary>
    /// Introduction/cover letter
    /// </summary>
    public string? Introduction { get; private set; }
    
    /// <summary>
    /// Terms and conditions
    /// </summary>
    public string? TermsAndConditions { get; private set; }
    
    /// <summary>
    /// Payment terms (e.g., "50% deposit, balance due 1 week before event")
    /// </summary>
    public string? PaymentTerms { get; private set; }
    
    /// <summary>
    /// Notes visible to client
    /// </summary>
    public string? ClientNotes { get; private set; }
    
    /// <summary>
    /// Internal notes (not visible to client)
    /// </summary>
    public string? InternalNotes { get; private set; }
    
    // Pricing
    public decimal SubTotal { get; private set; }
    public decimal DiscountAmount { get; private set; }
    public decimal DiscountPercent { get; private set; }
    public decimal TaxAmount { get; private set; }
    public decimal TotalAmount { get; private set; }
    
    /// <summary>
    /// Required deposit amount
    /// </summary>
    public decimal DepositAmount { get; private set; }
    
    /// <summary>
    /// Deposit percentage
    /// </summary>
    public decimal DepositPercent { get; private set; }
    
    /// <summary>
    /// Client's feedback/comments on the proposal
    /// </summary>
    public string? ClientFeedback { get; private set; }
    
    /// <summary>
    /// Reason if proposal was declined
    /// </summary>
    public string? DeclineReason { get; private set; }
    
    /// <summary>
    /// Created by user
    /// </summary>
    public Guid CreatedByUserId { get; private set; }
    
    public bool IsActive { get; private set; }
    
    public IReadOnlyCollection<ProposalItem> Items => _items.AsReadOnly();

    public void SetClientInfo(string name, string email, string? phone)
    {
        ClientName = name;
        ClientEmail = email;
        ClientPhone = phone;
        MarkUpdated();
    }

    public void SetContent(string? introduction, string? termsAndConditions, string? paymentTerms, string? clientNotes)
    {
        Introduction = introduction;
        TermsAndConditions = termsAndConditions;
        PaymentTerms = paymentTerms;
        ClientNotes = clientNotes;
        MarkUpdated();
    }

    public void SetInternalNotes(string? notes) => InternalNotes = notes;

    public void SetValidUntil(DateTime? date)
    {
        ValidUntil = date;
        MarkUpdated();
    }

    public void SetDeposit(decimal amount, decimal percent)
    {
        DepositAmount = amount;
        DepositPercent = percent;
        MarkUpdated();
    }

    public void SetDiscount(decimal amount, decimal percent)
    {
        DiscountAmount = amount;
        DiscountPercent = percent;
        RecalculateTotals();
        MarkUpdated();
    }

    public void AddItem(ProposalItem item)
    {
        _items.Add(item);
        RecalculateTotals();
        MarkUpdated();
    }

    public void RemoveItem(Guid itemId)
    {
        var item = _items.FirstOrDefault(i => i.Id == itemId);
        if (item != null)
        {
            _items.Remove(item);
            RecalculateTotals();
            MarkUpdated();
        }
    }

    public void ClearItems()
    {
        _items.Clear();
        RecalculateTotals();
        MarkUpdated();
    }

    private void RecalculateTotals()
    {
        SubTotal = _items.Sum(i => i.TotalPrice);
        TotalAmount = SubTotal - DiscountAmount + TaxAmount;
    }

    public void SetTax(decimal taxAmount)
    {
        TaxAmount = taxAmount;
        RecalculateTotals();
        MarkUpdated();
    }

    public void Send()
    {
        Status = ProposalStatus.Sent;
        SentAt = DateTime.UtcNow;
        MarkUpdated();
    }

    public void MarkViewed()
    {
        if (Status == ProposalStatus.Sent)
        {
            Status = ProposalStatus.Viewed;
            MarkUpdated();
        }
    }

    public void Accept(string? feedback = null)
    {
        Status = ProposalStatus.Accepted;
        RespondedAt = DateTime.UtcNow;
        ClientFeedback = feedback;
        MarkUpdated();
    }

    public void Decline(string reason, string? feedback = null)
    {
        Status = ProposalStatus.Declined;
        RespondedAt = DateTime.UtcNow;
        DeclineReason = reason;
        ClientFeedback = feedback;
        MarkUpdated();
    }

    public void RequestRevision(string feedback)
    {
        Status = ProposalStatus.RevisionRequested;
        RespondedAt = DateTime.UtcNow;
        ClientFeedback = feedback;
        MarkUpdated();
    }

    public Proposal CreateRevision()
    {
        var revision = new Proposal(CompanyId, EventId, ProposalNumber, Title)
        {
            Version = Version + 1,
            ClientName = ClientName,
            ClientEmail = ClientEmail,
            ClientPhone = ClientPhone,
            Introduction = Introduction,
            TermsAndConditions = TermsAndConditions,
            PaymentTerms = PaymentTerms,
            ClientNotes = ClientNotes,
            InternalNotes = InternalNotes,
            DepositAmount = DepositAmount,
            DepositPercent = DepositPercent,
            CreatedByUserId = CreatedByUserId
        };
        
        // Copy items
        foreach (var item in _items)
        {
            revision._items.Add(new ProposalItem(
                revision.Id,
                item.Category,
                item.Description,
                item.Quantity,
                item.UnitPrice));
        }
        
        revision.RecalculateTotals();
        return revision;
    }

    public void Expire()
    {
        Status = ProposalStatus.Expired;
        MarkUpdated();
    }
}

public class ProposalItem : BaseEntity
{
    private ProposalItem() { }

    public ProposalItem(
        Guid proposalId,
        string category,
        string description,
        int quantity,
        decimal unitPrice)
    {
        ProposalId = proposalId;
        Category = category;
        Description = description;
        Quantity = quantity;
        UnitPrice = unitPrice;
        TotalPrice = quantity * unitPrice;
    }

    public Guid ProposalId { get; private set; }
    
    /// <summary>
    /// Category (e.g., "Ceremony", "Reception", "Bouquets", "Centerpieces")
    /// </summary>
    public string Category { get; private set; } = default!;
    
    /// <summary>
    /// Item description
    /// </summary>
    public string Description { get; private set; } = default!;
    
    /// <summary>
    /// Optional link to product
    /// </summary>
    public Guid? ProductId { get; private set; }
    
    public int Quantity { get; private set; }
    public decimal UnitPrice { get; private set; }
    public decimal TotalPrice { get; private set; }
    
    /// <summary>
    /// Optional notes for this item
    /// </summary>
    public string? Notes { get; private set; }
    
    /// <summary>
    /// Sort order within the proposal
    /// </summary>
    public int SortOrder { get; private set; }

    public void Update(string category, string description, int quantity, decimal unitPrice, string? notes, int sortOrder)
    {
        Category = category;
        Description = description;
        Quantity = quantity;
        UnitPrice = unitPrice;
        TotalPrice = quantity * unitPrice;
        Notes = notes;
        SortOrder = sortOrder;
        MarkUpdated();
    }

    public void LinkToProduct(Guid productId) => ProductId = productId;
}

public enum ProposalStatus
{
    Draft,
    Sent,
    Viewed,
    RevisionRequested,
    Accepted,
    Declined,
    Expired
}
