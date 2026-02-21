using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Payments;

/// <summary>
/// Common interface for all payment gateways
/// </summary>
public interface IPaymentGateway
{
    /// <summary>
    /// Gateway type this implementation handles
    /// </summary>
    PaymentGatewayType GatewayType { get; }
    
    /// <summary>
    /// Initialize the gateway with configuration
    /// </summary>
    Task InitializeAsync(PaymentGatewayConfig config);
    
    /// <summary>
    /// Create a new payment/order
    /// </summary>
    Task<CreatePaymentResultDto> CreatePaymentAsync(CreatePaymentDto request, PaymentTransaction transaction);
    
    /// <summary>
    /// Verify payment completion (callback verification)
    /// </summary>
    Task<VerifyPaymentResultDto> VerifyPaymentAsync(VerifyPaymentDto request);
    
    /// <summary>
    /// Process refund
    /// </summary>
    Task<RefundResultDto> RefundAsync(PaymentTransaction transaction, decimal amount, string? reason);
    
    /// <summary>
    /// Parse and validate webhook payload
    /// </summary>
    Task<WebhookEventDto?> ParseWebhookAsync(string payload, string? signature, Dictionary<string, string>? headers);
    
    /// <summary>
    /// Test gateway credentials
    /// </summary>
    Task<PaymentGatewayTestResultDto> TestConnectionAsync();
    
    /// <summary>
    /// Get payment status from gateway
    /// </summary>
    Task<GatewayPaymentStatus> GetPaymentStatusAsync(string gatewayPaymentId);
}
