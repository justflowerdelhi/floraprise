namespace Sumpooj.Domain.Entities;

public abstract class BaseEntity
{
    public Guid Id { get; protected set; } = Guid.NewGuid();

    public DateTime CreatedAtUtc { get; protected set; } = DateTime.UtcNow;
    public DateTime? UpdatedAtUtc { get; protected set; }

    public void MarkUpdated()
    {
        UpdatedAtUtc = DateTime.UtcNow;
    }

    /// <summary>
    /// Ensures a DateTime has Kind=Utc. Treats Unspecified as UTC.
    /// Required because PostgreSQL timestamptz columns reject Kind=Unspecified.
    /// </summary>
    protected static DateTime EnsureUtc(DateTime dt) =>
        dt.Kind == DateTimeKind.Unspecified ? DateTime.SpecifyKind(dt, DateTimeKind.Utc) : dt.ToUniversalTime();

    /// <summary>
    /// Ensures a nullable DateTime has Kind=Utc.
    /// </summary>
    protected static DateTime? EnsureUtc(DateTime? dt) =>
        dt.HasValue ? EnsureUtc(dt.Value) : null;
}
