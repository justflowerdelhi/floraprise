namespace Sumpooj.API.Models;

/// <summary>
/// Standardized API response wrapper for all endpoints.
/// Provides consistent structure for success and error responses.
/// </summary>
/// <typeparam name="T">Type of the data payload</typeparam>
public sealed class ApiResponse<T>
{
    /// <summary>
    /// Indicates whether the request was successful.
    /// </summary>
    public bool Success { get; set; }

    /// <summary>
    /// The response data payload. Null for error responses.
    /// </summary>
    public T? Data { get; set; }

    /// <summary>
    /// Error message. Null for successful responses.
    /// </summary>
    public string? Message { get; set; }

    /// <summary>
    /// Error code for programmatic error handling. Null for successful responses.
    /// </summary>
    public string? ErrorCode { get; set; }

    /// <summary>
    /// Correlation ID for tracing the request through the system.
    /// </summary>
    public string? CorrelationId { get; set; }

    /// <summary>
    /// Timestamp of the response in UTC.
    /// </summary>
    public DateTime TimestampUtc { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// Creates a successful response with data.
    /// </summary>
    public static ApiResponse<T> Ok(T data, string? correlationId = null)
    {
        return new ApiResponse<T>
        {
            Success = true,
            Data = data,
            CorrelationId = correlationId
        };
    }

    /// <summary>
    /// Creates a successful response without data.
    /// </summary>
    public static ApiResponse<T> Ok(string? correlationId = null)
    {
        return new ApiResponse<T>
        {
            Success = true,
            CorrelationId = correlationId
        };
    }

    /// <summary>
    /// Creates an error response.
    /// </summary>
    public static ApiResponse<T> Error(string message, string? errorCode = null, string? correlationId = null)
    {
        return new ApiResponse<T>
        {
            Success = false,
            Message = message,
            ErrorCode = errorCode,
            CorrelationId = correlationId
        };
    }
}

/// <summary>
/// Non-generic version of ApiResponse for responses without typed data.
/// </summary>
public sealed class ApiResponse
{
    /// <summary>
    /// Indicates whether the request was successful.
    /// </summary>
    public bool Success { get; set; }

    /// <summary>
    /// The response data payload. Null for error responses.
    /// </summary>
    public object? Data { get; set; }

    /// <summary>
    /// Error message. Null for successful responses.
    /// </summary>
    public string? Message { get; set; }

    /// <summary>
    /// Error code for programmatic error handling. Null for successful responses.
    /// </summary>
    public string? ErrorCode { get; set; }

    /// <summary>
    /// Correlation ID for tracing the request through the system.
    /// </summary>
    public string? CorrelationId { get; set; }

    /// <summary>
    /// Timestamp of the response in UTC.
    /// </summary>
    public DateTime TimestampUtc { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// Creates a successful response without data.
    /// </summary>
    public static ApiResponse Ok(string? correlationId = null)
    {
        return new ApiResponse
        {
            Success = true,
            CorrelationId = correlationId
        };
    }

    /// <summary>
    /// Creates an error response.
    /// </summary>
    public static ApiResponse Error(string message, string? errorCode = null, string? correlationId = null)
    {
        return new ApiResponse
        {
            Success = false,
            Message = message,
            ErrorCode = errorCode,
            CorrelationId = correlationId
        };
    }
}
