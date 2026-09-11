namespace Sumpooj.Application.Common;

/// <summary>
/// Thrown when a request specifies an Idempotency-Key that was already processed
/// with a different payload or request parameters.
/// </summary>
public class IdempotencyConflictException : Exception
{
    public IdempotencyConflictException(string message, Exception? inner = null) : base(message, inner) { }
}
