namespace Sumpooj.Application.Payments;

/// <summary>
/// Exception thrown by payment gateway operations
/// </summary>
public class PaymentGatewayException : Exception
{
    public string? GatewayError { get; }
    public string? ErrorCode { get; }

    public PaymentGatewayException(string message) : base(message) { }

    public PaymentGatewayException(string message, string? gatewayError, string? errorCode = null) 
        : base(message)
    {
        GatewayError = gatewayError;
        ErrorCode = errorCode;
    }

    public PaymentGatewayException(string message, Exception innerException) 
        : base(message, innerException) { }
}
