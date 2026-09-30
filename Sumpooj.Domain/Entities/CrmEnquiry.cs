namespace Sumpooj.Domain.Entities;

public class CrmEnquiry : BaseEntity
{
    private CrmEnquiry() { } // EF Core

    public CrmEnquiry(
        Guid companyId,
        Guid customerId,
        string clientSyncId,
        string category,
        string requirement,
        DateTime? eventDate = null,
        decimal? budgetAmount = null,
        string? location = null,
        string? notes = null,
        string? nextAction = null,
        DateTime? nextFollowUpAtUtc = null)
    {
        if (companyId == Guid.Empty) throw new ArgumentException("Company ID is required.", nameof(companyId));
        if (customerId == Guid.Empty) throw new ArgumentException("Customer ID is required.", nameof(customerId));
        if (string.IsNullOrWhiteSpace(clientSyncId)) throw new ArgumentException("Client Sync ID is required.", nameof(clientSyncId));
        if (string.IsNullOrWhiteSpace(requirement)) throw new ArgumentException("Requirement is required.", nameof(requirement));

        CompanyId = companyId;
        CustomerId = customerId;
        ClientSyncId = clientSyncId.Trim();
        Category = string.IsNullOrWhiteSpace(category) ? "Flowers" : category.Trim();
        Requirement = requirement.Trim();
        EventDate = EnsureUtc(eventDate);
        BudgetAmount = budgetAmount;
        Location = string.IsNullOrWhiteSpace(location) ? null : location.Trim();
        Notes = string.IsNullOrWhiteSpace(notes) ? null : notes.Trim();
        Status = "new";
        NextAction = string.IsNullOrWhiteSpace(nextAction) ? "Follow-up with customer" : nextAction.Trim();
        NextFollowUpAtUtc = EnsureUtc(nextFollowUpAtUtc);
    }

    public Guid CompanyId { get; private set; }
    public Guid CustomerId { get; private set; }
    public string ClientSyncId { get; private set; } = default!;
    public string Category { get; private set; } = "Flowers";
    public string Requirement { get; private set; } = default!;
    public DateTime? EventDate { get; private set; }
    public decimal? BudgetAmount { get; private set; }
    public string? Location { get; private set; }
    public string? Notes { get; private set; }
    public string Status { get; private set; } = "new";
    public string NextAction { get; private set; } = "Follow-up with customer";
    public DateTime? NextFollowUpAtUtc { get; private set; }
    public Guid? LinkedTaskId { get; private set; }
    public Guid? QuoteOrderId { get; private set; }
    public Guid? ConvertedOrderId { get; private set; }
    public string? LostReason { get; private set; }
    public DateTime? DeletedAtUtc { get; private set; }

    public void Update(
        string category,
        string requirement,
        DateTime? eventDate,
        decimal? budgetAmount,
        string? location,
        string? notes,
        string? nextAction,
        DateTime? nextFollowUpAtUtc)
    {
        if (string.IsNullOrWhiteSpace(requirement)) throw new ArgumentException("Requirement is required.", nameof(requirement));

        Category = string.IsNullOrWhiteSpace(category) ? "Flowers" : category.Trim();
        Requirement = requirement.Trim();
        EventDate = EnsureUtc(eventDate);
        BudgetAmount = budgetAmount;
        Location = string.IsNullOrWhiteSpace(location) ? null : location.Trim();
        Notes = string.IsNullOrWhiteSpace(notes) ? null : notes.Trim();
        if (!string.IsNullOrWhiteSpace(nextAction))
        {
            NextAction = nextAction.Trim();
        }
        NextFollowUpAtUtc = EnsureUtc(nextFollowUpAtUtc);
        MarkUpdated();
    }

    public static readonly HashSet<string> ValidStatuses = new(StringComparer.OrdinalIgnoreCase)
    {
        "new",
        "follow_up",
        "quote_sent",
        "won",
        "lost"
    };

    public void SetStatus(
        string status,
        string? nextAction = null,
        Guid? quoteOrderId = null,
        Guid? convertedOrderId = null,
        string? lostReason = null)
    {
        if (string.IsNullOrWhiteSpace(status)) throw new ArgumentException("Status is required.", nameof(status));

        var normalized = status.Trim().ToLowerInvariant();
        if (!ValidStatuses.Contains(normalized))
        {
            throw new ArgumentException($"Invalid status '{status}'. Allowed statuses: {string.Join(", ", ValidStatuses)}", nameof(status));
        }

        Status = normalized;
        if (!string.IsNullOrWhiteSpace(nextAction)) NextAction = nextAction.Trim();
        if (quoteOrderId.HasValue) QuoteOrderId = quoteOrderId.Value;
        if (convertedOrderId.HasValue) ConvertedOrderId = convertedOrderId.Value;
        if (!string.IsNullOrWhiteSpace(lostReason)) LostReason = lostReason.Trim();
        MarkUpdated();
    }

    public void SetLinkedTask(Guid? taskId, DateTime? followUpAtUtc = null)
    {
        LinkedTaskId = taskId;
        if (followUpAtUtc.HasValue)
        {
            NextFollowUpAtUtc = EnsureUtc(followUpAtUtc);
        }
        MarkUpdated();
    }

    public void Delete()
    {
        DeletedAtUtc = DateTime.UtcNow;
        MarkUpdated();
    }
}
