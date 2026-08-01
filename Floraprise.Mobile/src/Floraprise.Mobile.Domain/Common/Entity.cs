namespace Floraprise.Mobile.Domain.Common;

public abstract class Entity
{
    public Guid Id { get; protected set; } = Guid.NewGuid();

    public DateTimeOffset CreatedAtUtc { get; protected set; } = DateTimeOffset.UtcNow;

    public DateTimeOffset UpdatedAtUtc { get; protected set; } = DateTimeOffset.UtcNow;

    public string? CreatedBy { get; protected set; }

    public string? UpdatedBy { get; protected set; }

    public void SetAudit(string? createdBy, string? updatedBy)
    {
        CreatedBy = createdBy;
        UpdatedBy = updatedBy;
    }

    public void MarkUpdated(string? updatedBy)
    {
        UpdatedAtUtc = DateTimeOffset.UtcNow;
        UpdatedBy = updatedBy;
    }
}
