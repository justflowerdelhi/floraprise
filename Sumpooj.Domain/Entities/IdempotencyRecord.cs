namespace Sumpooj.Domain.Entities;

/// <summary>
/// Persists idempotent request execution results for API requests (such as web POS order creation).
/// Guarantees that repeating a request with the same Idempotency-Key returns the cached result
/// without performing duplicate transactions, and prevents duplicate sales/inventory consumption.
/// </summary>
public class IdempotencyRecord : BaseEntity
{
    private IdempotencyRecord() { } // EF Core

    public IdempotencyRecord(
        Guid companyId,
        string idempotencyKey,
        string requestPath,
        string requestHash,
        int responseStatusCode,
        string responsePayload,
        Guid? orderId = null,
        DateTime? expiresAtUtc = null)
    {
        CompanyId = companyId;
        IdempotencyKey = idempotencyKey.Trim();
        RequestPath = requestPath.Trim();
        RequestHash = requestHash.Trim();
        ResponseStatusCode = responseStatusCode;
        ResponsePayload = responsePayload;
        OrderId = orderId;
        ExpiresAtUtc = EnsureUtc(expiresAtUtc);
    }

    public Guid CompanyId { get; private set; }
    public string IdempotencyKey { get; private set; } = default!;
    public string RequestPath { get; private set; } = default!;
    public string RequestHash { get; private set; } = default!;
    public int ResponseStatusCode { get; private set; }
    public string ResponsePayload { get; private set; } = default!;
    public Guid? OrderId { get; private set; }
    public DateTime? ExpiresAtUtc { get; private set; }
}
