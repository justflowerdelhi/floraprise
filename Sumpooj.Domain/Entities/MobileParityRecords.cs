namespace Sumpooj.Domain.Entities;

public class OccasionContact : BaseEntity
{
    private OccasionContact() { }
    public OccasionContact(Guid companyId, Guid customerId) { CompanyId = companyId; CustomerId = customerId; }
    public Guid CompanyId { get; private set; }
    public Guid CustomerId { get; private set; }
    public string RecipientName { get; private set; } = default!;
    public string Relationship { get; private set; } = default!;
    public string Occasion { get; private set; } = default!;
    public DateTime OccasionDate { get; private set; }
    public string RecipientPhone { get; private set; } = string.Empty;
    public string Company { get; private set; } = string.Empty;
    public string Notes { get; private set; } = string.Empty;
    public bool ReminderEnabled { get; private set; } = true;
    public string Source { get; private set; } = "Manual";
    public DateTime? DeletedAtUtc { get; private set; }
    public void Update(string recipientName, string relationship, string occasion, DateTime occasionDate,
        string? recipientPhone, string? company, string? notes, bool reminderEnabled, string source)
    {
        if (string.IsNullOrWhiteSpace(recipientName) || string.IsNullOrWhiteSpace(occasion))
            throw new InvalidOperationException("Recipient and occasion are required.");
        RecipientName = recipientName.Trim(); Relationship = relationship.Trim(); Occasion = occasion.Trim();
        OccasionDate = EnsureUtc(occasionDate); RecipientPhone = recipientPhone?.Trim() ?? string.Empty;
        Company = company?.Trim() ?? string.Empty; Notes = notes?.Trim() ?? string.Empty;
        ReminderEnabled = reminderEnabled; Source = string.IsNullOrWhiteSpace(source) ? "Manual" : source.Trim(); MarkUpdated();
    }
    public void Delete() { DeletedAtUtc = DateTime.UtcNow; MarkUpdated(); }
}

public class OccasionFollowUpAction : BaseEntity
{
    private OccasionFollowUpAction() { }
    public OccasionFollowUpAction(Guid companyId, string sourceType, Guid sourceId, DateTime occurrenceDate)
    { CompanyId = companyId; SourceType = sourceType; SourceId = sourceId; OccurrenceDate = EnsureUtc(occurrenceDate).Date; }
    public Guid CompanyId { get; private set; }
    public string SourceType { get; private set; } = default!;
    public Guid SourceId { get; private set; }
    public DateTime OccurrenceDate { get; private set; }
    public string Status { get; private set; } = "pending";
    public DateTime? SnoozedTo { get; private set; }
    public void Complete() { Status = "done"; SnoozedTo = null; MarkUpdated(); }
    public void Snooze(DateTime date) { Status = "snoozed"; SnoozedTo = EnsureUtc(date).Date; MarkUpdated(); }
    public void Delete() { Status = "deleted"; SnoozedTo = null; MarkUpdated(); }
}

public class SchedulerRecord : BaseEntity
{
    private SchedulerRecord() { }
    public SchedulerRecord(Guid companyId, string producer, string sourceRef) { CompanyId = companyId; Producer = producer; SourceRef = sourceRef; }
    public Guid CompanyId { get; private set; }
    public string Title { get; private set; } = default!;
    public string Type { get; private set; } = default!;
    public string Category { get; private set; } = default!;
    public string Priority { get; private set; } = "normal";
    public string Status { get; private set; } = "pending";
    public DateTime ScheduledAt { get; private set; }
    public DateTime? NextReminderAt { get; private set; }
    public DateTime? DeadlineAt { get; private set; }
    public string Notes { get; private set; } = string.Empty;
    public Guid? LinkedCustomerId { get; private set; }
    public Guid? LinkedOrderId { get; private set; }
    public Guid? AssignedStaffId { get; private set; }
    public string Producer { get; private set; } = default!;
    public string SourceRef { get; private set; } = default!;
    public bool RequiresConfirmation { get; private set; }
    public bool RequiresAlarm { get; private set; }
    public DateTime? StartedAt { get; private set; }
    public DateTime? CompletedAt { get; private set; }
    public DateTime? DeletedAtUtc { get; private set; }
    public void Update(string title, string type, string category, string priority, DateTime scheduledAt,
        DateTime? nextReminderAt, DateTime? deadlineAt, string? notes, Guid? customerId, Guid? orderId,
        Guid? staffId, bool requiresConfirmation, bool requiresAlarm)
    {
        if (string.IsNullOrWhiteSpace(title)) throw new InvalidOperationException("Title is required.");
        Title = title.Trim(); Type = type; Category = category; Priority = priority; ScheduledAt = EnsureUtc(scheduledAt);
        NextReminderAt = EnsureUtc(nextReminderAt); DeadlineAt = EnsureUtc(deadlineAt); Notes = notes?.Trim() ?? string.Empty;
        LinkedCustomerId = customerId; LinkedOrderId = orderId; AssignedStaffId = staffId;
        RequiresConfirmation = requiresConfirmation; RequiresAlarm = requiresAlarm; MarkUpdated();
    }
    public void SetStatus(string status) { Status = status; if (status == "inProgress") StartedAt = DateTime.UtcNow;
        if (status == "completed") CompletedAt = DateTime.UtcNow; MarkUpdated(); }
    public void Delete() { DeletedAtUtc = DateTime.UtcNow; MarkUpdated(); }
}

public class CloudDesign : BaseEntity
{
    private CloudDesign() { }
    public CloudDesign(Guid companyId, string bouquetId) { CompanyId = companyId; BouquetId = bouquetId; }
    public Guid CompanyId { get; private set; }
    public string BouquetId { get; private set; } = default!;
    public string? ImageReference { get; private set; }
    public string Description { get; private set; } = default!;
    public int? SellingPricePaise { get; private set; }
    public string Flowers { get; private set; } = string.Empty;
    public string Occasion { get; private set; } = string.Empty;
    public string Color { get; private set; } = string.Empty;
    public string Collection { get; private set; } = string.Empty;
    public string Notes { get; private set; } = string.Empty;
    public string Status { get; private set; } = "needs_review";
    public bool IsFavorite { get; private set; }
    public DateTime? DeletedAtUtc { get; private set; }
        public void Update(string description, string? imageReference, int? sellingPricePaise, string? flowers,
                string? occasion, string? color, string? collection, string? notes, bool favorite)
        { Description = description.Trim(); ImageReference = imageReference; SellingPricePaise = sellingPricePaise; Flowers = flowers ?? "";
      Occasion = occasion ?? ""; Color = color ?? ""; Collection = collection ?? ""; Notes = notes ?? "";
            Status = !string.IsNullOrWhiteSpace(ImageReference) && Description.Length > 0 && SellingPricePaise > 0 ? "ready" : "needs_review";
            IsFavorite = favorite; MarkUpdated(); }
    public void Delete() { DeletedAtUtc = DateTime.UtcNow; MarkUpdated(); }
}

public class ReadyBouquetRecord : BaseEntity
{
    private ReadyBouquetRecord() { }
        public ReadyBouquetRecord(Guid companyId, Guid finishedProductId, Guid? recipeId, Guid? productionId,
                int initialQuantity, DateTime producedAt, int shelfLifeDays, int refreshAfterDays, DateTime expiryAt,
                string? location, string? note)
    { CompanyId = companyId; FinishedProductId = finishedProductId; InitialQuantity = initialQuantity; RemainingQuantity = initialQuantity;
            RecipeId = recipeId; ProductionId = productionId; ProducedAt = EnsureUtc(producedAt); ShelfLifeDays = shelfLifeDays;
            RefreshAfterDays = refreshAfterDays; ExpiryAt = EnsureUtc(expiryAt); Location = string.IsNullOrWhiteSpace(location) ? "Store" : location.Trim(); Note = note; }
    public Guid CompanyId { get; private set; }
    public Guid FinishedProductId { get; private set; }
    public Guid? RecipeId { get; private set; }
    public Guid? ProductionId { get; private set; }
    public int InitialQuantity { get; private set; }
    public int RemainingQuantity { get; private set; }
    public int ShelfLifeDays { get; private set; }
    public int RefreshAfterDays { get; private set; }
    public DateTime ProducedAt { get; private set; }
    public DateTime? LastRefreshAt { get; private set; }
    public DateTime ExpiryAt { get; private set; }
    public string Location { get; private set; } = "Store";
    public string Status { get; private set; } = "fresh";
    public string? Note { get; private set; }
    public string ComputeStatus(DateTime now)
    {
        if (now >= ExpiryAt || RemainingQuantity == 0) return "expired";
        var ageDays = (now - (LastRefreshAt ?? ProducedAt)).Days;
        if (ShelfLifeDays > 0 && ageDays >= ShelfLifeDays - 1) return "nearExpiry";
        if (RefreshAfterDays > 0 && ageDays >= RefreshAfterDays) return "needsRefresh";
        return "fresh";
    }
    public void Refresh() { LastRefreshAt = DateTime.UtcNow; Status = ComputeStatus(DateTime.UtcNow); MarkUpdated(); }
    public void Expire(int quantity) { if (quantity <= 0 || quantity > RemainingQuantity) throw new InvalidOperationException("Invalid expiry quantity.");
            RemainingQuantity -= quantity; if (RemainingQuantity == 0) Status = "expired"; MarkUpdated(); }
}

public class ReadyBouquetRefreshEvent : BaseEntity
{
    private ReadyBouquetRefreshEvent() { }
    public ReadyBouquetRefreshEvent(Guid companyId, Guid batchId, string actionType, Guid productId, int quantity,
        int wastageQuantity, string? reason, string? note)
    { CompanyId = companyId; BatchId = batchId; ActionType = actionType; ProductId = productId; Quantity = quantity;
      WastageQuantity = wastageQuantity; Reason = reason; Note = note; }
    public Guid CompanyId { get; private set; }
    public Guid BatchId { get; private set; }
    public string ActionType { get; private set; } = default!;
    public Guid ProductId { get; private set; }
    public int Quantity { get; private set; }
    public int WastageQuantity { get; private set; }
    public string? Reason { get; private set; }
    public string? Note { get; private set; }
}