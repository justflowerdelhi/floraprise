using Microsoft.Extensions.Logging;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Payments;

/// <summary>
/// Service for processing payments via configured gateways
/// </summary>
public class GatewayPaymentService
{
    private readonly IPaymentGatewayConfigRepository _configRepository;
    private readonly IPaymentTransactionRepository _transactionRepository;
    private readonly IPaymentGatewayFactory _gatewayFactory;
    private readonly ITenantContext _tenantContext;
    private readonly ILogger<GatewayPaymentService> _logger;

    public GatewayPaymentService(
        IPaymentGatewayConfigRepository configRepository,
        IPaymentTransactionRepository transactionRepository,
        IPaymentGatewayFactory gatewayFactory,
        ITenantContext tenantContext,
        ILogger<GatewayPaymentService> logger)
    {
        _configRepository = configRepository;
        _transactionRepository = transactionRepository;
        _gatewayFactory = gatewayFactory;
        _tenantContext = tenantContext;
        _logger = logger;
    }

    /// <summary>
    /// Create a new payment
    /// </summary>
    public async Task<CreatePaymentResultDto> CreatePaymentAsync(CreatePaymentDto request, Guid? gatewayConfigId = null)
    {
        // Get gateway configuration
        var config = gatewayConfigId.HasValue
            ? await _configRepository.GetByIdAsync(gatewayConfigId.Value)
            : await _configRepository.GetDefaultForCompanyAsync(_tenantContext.CompanyId.Value);

        if (config == null || !config.IsActive)
        {
            throw new PaymentGatewayException("No active payment gateway configured");
        }

        // Generate transaction reference
        var transactionRef = GenerateTransactionRef();

        // Create transaction record
        var transaction = new PaymentTransaction(
            companyId: _tenantContext.CompanyId.Value,
            paymentGatewayConfigId: config.Id,
            transactionRef: transactionRef,
            amount: request.Amount,
            currency: request.Currency,
            orderId: request.OrderId
        );

        transaction.SetCustomerInfo(request.CustomerEmail, request.CustomerPhone);
        transaction.MarkProcessing();

        await _transactionRepository.AddAsync(transaction);

        try
        {
            // Create payment with gateway
            var gateway = await _gatewayFactory.CreateAsync(config);
            var result = await gateway.CreatePaymentAsync(request, transaction);

            // Update transaction with gateway IDs
            transaction.SetGatewayIds(result.GatewayOrderId, result.GatewayOrderId);
            await _transactionRepository.UpdateAsync(transaction);

            _logger.LogInformation("Payment created: {TransactionRef} via {GatewayType}", 
                transactionRef, config.GatewayType);

            return result;
        }
        catch (Exception ex)
        {
            transaction.MarkFailed(ex.Message);
            await _transactionRepository.UpdateAsync(transaction);
            
            _logger.LogError(ex, "Payment creation failed for {TransactionRef}", transactionRef);
            throw;
        }
    }

    /// <summary>
    /// Verify payment completion
    /// </summary>
    public async Task<VerifyPaymentResultDto> VerifyPaymentAsync(VerifyPaymentDto request)
    {
        var transaction = await _transactionRepository.GetByTransactionRefAsync(request.TransactionRef);
        if (transaction == null)
        {
            return new VerifyPaymentResultDto(false, GatewayPaymentStatus.Failed, "Transaction not found", null);
        }

        var config = await _configRepository.GetByIdAsync(transaction.PaymentGatewayConfigId);
        if (config == null)
        {
            return new VerifyPaymentResultDto(false, GatewayPaymentStatus.Failed, "Gateway config not found", null);
        }

        try
        {
            var gateway = await _gatewayFactory.CreateAsync(config);
            var result = await gateway.VerifyPaymentAsync(request);

            // Update transaction based on verification result
            if (result.Success)
            {
                transaction.SetGatewayIds(request.GatewayPaymentId, transaction.GatewayOrderId);
                transaction.MarkCompleted();
            }
            else if (result.Status == GatewayPaymentStatus.Failed)
            {
                transaction.MarkFailed(result.Message);
            }

            await _transactionRepository.UpdateAsync(transaction);

            _logger.LogInformation("Payment verified: {TransactionRef} = {Status}", 
                transaction.TransactionRef, result.Status);

            return result with { Transaction = MapToDto(transaction, config.GatewayType) };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Payment verification failed for {TransactionRef}", request.TransactionRef);
            throw;
        }
    }

    /// <summary>
    /// Process refund
    /// </summary>
    public async Task<RefundResultDto> RefundAsync(RefundPaymentDto request)
    {
        var transaction = await _transactionRepository.GetByIdAsync(request.TransactionId);
        if (transaction == null || transaction.CompanyId != _tenantContext.CompanyId.Value)
        {
            return new RefundResultDto(false, null, 0, "Transaction not found");
        }

        if (transaction.Status != GatewayPaymentStatus.Completed)
        {
            return new RefundResultDto(false, null, 0, "Only completed payments can be refunded");
        }

        var refundAmount = request.Amount ?? transaction.Amount - transaction.RefundedAmount;
        if (refundAmount <= 0)
        {
            return new RefundResultDto(false, null, 0, "Invalid refund amount");
        }

        if (refundAmount > transaction.Amount - transaction.RefundedAmount)
        {
            return new RefundResultDto(false, null, 0, "Refund amount exceeds available balance");
        }

        var config = await _configRepository.GetByIdAsync(transaction.PaymentGatewayConfigId);
        if (config == null)
        {
            return new RefundResultDto(false, null, 0, "Gateway configuration not found");
        }

        try
        {
            var gateway = await _gatewayFactory.CreateAsync(config);
            var result = await gateway.RefundAsync(transaction, refundAmount, request.Reason);

            if (result.Success)
            {
                transaction.MarkRefunded(refundAmount);
                await _transactionRepository.UpdateAsync(transaction);
            }

            _logger.LogInformation("Refund processed: {TransactionId} amount={Amount} success={Success}", 
                request.TransactionId, refundAmount, result.Success);

            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Refund failed for transaction {TransactionId}", request.TransactionId);
            return new RefundResultDto(false, null, 0, $"Refund failed: {ex.Message}");
        }
    }

    /// <summary>
    /// Process webhook event
    /// </summary>
    public async Task ProcessWebhookAsync(PaymentGatewayType gatewayType, Guid companyId, string payload, string? signature, Dictionary<string, string>? headers)
    {
        var config = await _configRepository.GetByCompanyAndTypeAsync(companyId, gatewayType);
        if (config == null || !config.IsActive)
        {
            _logger.LogWarning("Webhook received for unconfigured gateway: {GatewayType} company={CompanyId}", 
                gatewayType, companyId);
            return;
        }

        try
        {
            var gateway = await _gatewayFactory.CreateAsync(config);
            var webhookEvent = await gateway.ParseWebhookAsync(payload, signature, headers);

            if (webhookEvent == null)
            {
                _logger.LogWarning("Failed to parse webhook for {GatewayType}", gatewayType);
                return;
            }

            // Find and update transaction
            PaymentTransaction? transaction = null;
            
            if (!string.IsNullOrEmpty(webhookEvent.PaymentId))
            {
                transaction = await _transactionRepository.GetByGatewayPaymentIdAsync(companyId, webhookEvent.PaymentId);
            }

            if (transaction != null && webhookEvent.NewStatus.HasValue)
            {
                switch (webhookEvent.NewStatus.Value)
                {
                    case GatewayPaymentStatus.Completed:
                        transaction.MarkCompleted();
                        break;
                    case GatewayPaymentStatus.Failed:
                        transaction.MarkFailed("Payment failed via webhook");
                        break;
                    case GatewayPaymentStatus.Cancelled:
                        transaction.MarkCancelled();
                        break;
                    case GatewayPaymentStatus.Refunded:
                        transaction.MarkRefunded(webhookEvent.Amount ?? transaction.Amount);
                        break;
                }

                await _transactionRepository.UpdateAsync(transaction);
                
                _logger.LogInformation("Webhook processed: {EventType} transaction={TransactionRef} newStatus={Status}", 
                    webhookEvent.EventType, transaction.TransactionRef, webhookEvent.NewStatus);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Webhook processing failed for {GatewayType} company={CompanyId}", 
                gatewayType, companyId);
        }
    }

    /// <summary>
    /// Get transaction by ID
    /// </summary>
    public async Task<PaymentTransactionDto?> GetTransactionAsync(Guid id)
    {
        var transaction = await _transactionRepository.GetByIdAsync(id);
        if (transaction == null || transaction.CompanyId != _tenantContext.CompanyId.Value)
            return null;

        var config = await _configRepository.GetByIdAsync(transaction.PaymentGatewayConfigId);
        return MapToDto(transaction, config?.GatewayType ?? PaymentGatewayType.Stripe);
    }

    /// <summary>
    /// Get transactions for an order
    /// </summary>
    public async Task<IReadOnlyList<PaymentTransactionDto>> GetTransactionsByOrderAsync(Guid orderId)
    {
        var transactions = await _transactionRepository.GetByOrderIdAsync(orderId);
        var result = new List<PaymentTransactionDto>();

        foreach (var txn in transactions)
        {
            if (txn.CompanyId != _tenantContext.CompanyId.Value) continue;
            
            var config = await _configRepository.GetByIdAsync(txn.PaymentGatewayConfigId);
            result.Add(MapToDto(txn, config?.GatewayType ?? PaymentGatewayType.Stripe));
        }

        return result;
    }

    /// <summary>
    /// Search transactions
    /// </summary>
    public async Task<(IReadOnlyList<PaymentTransactionDto> Items, int TotalCount)> SearchTransactionsAsync(
        GatewayPaymentStatus? status = null,
        DateTime? fromDate = null,
        DateTime? toDate = null,
        int page = 1,
        int pageSize = 20)
    {
        var transactions = await _transactionRepository.SearchAsync(
            _tenantContext.CompanyId.Value, status, fromDate, toDate, page, pageSize);
        var count = await _transactionRepository.GetCountAsync(_tenantContext.CompanyId.Value, status);

        var configs = await _configRepository.GetByCompanyAsync(_tenantContext.CompanyId.Value);
        var configDict = configs.ToDictionary(c => c.Id, c => c.GatewayType);

        var items = transactions.Select(txn =>
            MapToDto(txn, configDict.TryGetValue(txn.PaymentGatewayConfigId, out var gt) 
                ? gt : PaymentGatewayType.Stripe)).ToList();

        return (items, count);
    }

    private static string GenerateTransactionRef()
    {
        return $"TXN{DateTime.UtcNow:yyyyMMdd}{Guid.NewGuid().ToString("N")[..8].ToUpperInvariant()}";
    }

    private static PaymentTransactionDto MapToDto(PaymentTransaction txn, PaymentGatewayType gatewayType) => new(
        Id: txn.Id,
        TransactionRef: txn.TransactionRef,
        GatewayPaymentId: txn.GatewayPaymentId,
        GatewayOrderId: txn.GatewayOrderId,
        Amount: txn.Amount,
        Currency: txn.Currency,
        Status: txn.Status,
        StatusName: txn.Status.ToString(),
        PaymentMethod: txn.PaymentMethod,
        PaymentMethodName: txn.PaymentMethod?.ToString(),
        CardLast4: txn.CardLast4,
        CardBrand: txn.CardBrand,
        BankName: txn.BankName,
        UpiId: txn.UpiId,
        WalletName: txn.WalletName,
        CustomerEmail: txn.CustomerEmail,
        CustomerPhone: txn.CustomerPhone,
        FailureReason: txn.FailureReason,
        RefundedAmount: txn.RefundedAmount,
        GatewayFee: txn.GatewayFee,
        NetAmount: txn.NetAmount,
        CreatedAt: txn.CreatedAtUtc,
        CompletedAt: txn.CompletedAt,
        OrderId: txn.OrderId,
        GatewayType: gatewayType,
        GatewayTypeName: gatewayType.ToString()
    );
}
