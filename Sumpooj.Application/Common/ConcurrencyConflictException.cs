namespace Sumpooj.Application.Common;

/// <summary>
/// Thrown by Infrastructure repositories when a database-level uniqueness
/// constraint is violated by a concurrent write (e.g. two requests generating
/// the same barcode value at the same time). Callers should retry with a new
/// candidate value rather than treat this as a permanent failure.
/// </summary>
public class ConcurrencyConflictException : Exception
{
    public ConcurrencyConflictException(string message, Exception? inner = null) : base(message, inner) { }
}
