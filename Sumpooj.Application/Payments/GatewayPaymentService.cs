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
    private readonly IPaymentRepository _paymentRepository;
    private readonly IOrderRepository _orderRepository;
    private readonly IJournalEntryRepository _journalEntryRepository;
    private readonly IIdempotencyRecordRepository? _idempotencyRecordRepository;
    private readonly ILogger<GatewayPaymentService> _logger;

    public GatewayPaymentService(
        IPaymentGatewayConfigRepository configRepository,
        IPaymentTransactionRepository transactionRepository,
        IPaymentGatewayFactory gatewayFactory,
        ITenantContext tenantContext,
        IPaymentRepository paymentRepository,
        IOrderRepository orderRepository,
        IJournalEntryRepository journalEntryRepository,
        ILogger<GatewayPaymentService> logger,
        IIdempotencyRecordRepository? idempotencyRecordRepository = null)
    {
        _configRepository = configRepository;
        _transactionRepository = transactionRepository;
        _gatewayFactory = gatewayFactory;
        _tenantContext = tenantContext;
        _paymentRepository = paymentRepository;
        _orderRepository = orderRepository;
        _journalEntryRepository = journalEntryRepository;
        _logger = logger;
        _idempotencyRecordRepository = idempotencyRecordRepository;
    }

    /// <summary>
    /// Create a new payment
    /// </summary>
    public async Task<CreatePaymentResultDto> CreatePaymentAsync(CreatePaymentDto request, Guid? gatewayConfigId = null)
    {
        var companyId = _tenantContext.CompanyId 
            ?? throw new UnauthorizedAccessException("Company context required for payment creation");

        // Get gateway configuration
        var config = gatewayConfigId.HasValue
            ? await _configRepository.GetByIdAsync(gatewayConfigId.Value)
            : await _configRepository.GetDefaultForCompanyAsync(companyId);

        if (config == null || !config.IsActive)
        {
            throw new PaymentGatewayException("No active payment gateway configured");
        }

        // Generate transaction reference
        var transactionRef = GenerateTransactionRef();

        // Create transaction record
        var transaction = new PaymentTransaction(
            companyId: companyId,
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
        if (transaction == null && !string.IsNullOrEmpty(request.GatewayPaymentId))
        {
            var companyId = _tenantContext.CompanyId;
            if (companyId.HasValue)
            {
                transaction = await _transactionRepository.GetByGatewayPaymentIdAsync(companyId.Value, request.GatewayPaymentId);
            }
        }

        if (transaction == null)
        {
            return new VerifyPaymentResultDto(false, GatewayPaymentStatus.Failed, "Transaction not found", null);
        }

        if (_tenantContext.CompanyId.HasValue && transaction.CompanyId != _tenantContext.CompanyId.Value)
        {
            _logger.LogWarning("Tenant mismatch during payment verification for {TxRef}", request.TransactionRef);
            return new VerifyPaymentResultDto(false, GatewayPaymentStatus.Failed, "Transaction not found or tenant mismatch", null);
        }

        var config = await _configRepository.GetByIdAsync(transaction.PaymentGatewayConfigId);
        if (config == null)
        {
            return new VerifyPaymentResultDto(false, GatewayPaymentStatus.Failed, "Gateway config not found", null);
        }

        // Idempotency: If already completed, ensure order payment is synced and return existing transaction
        if (transaction.Status == GatewayPaymentStatus.Completed)
        {
            await CompleteOrderPaymentAsync(transaction, config, request.GatewayPaymentId, transaction.GatewayFee);
            return new VerifyPaymentResultDto(
                Success: true,
                Status: GatewayPaymentStatus.Completed,
                Message: "Payment already verified",
                Transaction: MapToDto(transaction, config.GatewayType)
            );
        }

        try
        {
            var gateway = await _gatewayFactory.CreateAsync(config);
            var result = await gateway.VerifyPaymentAsync(request);

            if (result.Success)
            {
                // Extract optional fee from additional data if present
                decimal? fee = null;
                if (request.AdditionalData != null && request.AdditionalData.TryGetValue("fee", out var feeStr) && decimal.TryParse(feeStr, out var parsedFee))
                {
                    fee = parsedFee;
                }

                await CompleteOrderPaymentAsync(transaction, config, request.GatewayPaymentId, fee);

                _logger.LogInformation("Payment verified: {TransactionRef} = {Status}", 
                    transaction.TransactionRef, result.Status);

                return result with { Transaction = MapToDto(transaction, config.GatewayType) };
            }
            else if (result.Status == GatewayPaymentStatus.Failed)
            {
                transaction.MarkFailed(result.Message);
                await _transactionRepository.UpdateAsync(transaction);
                return result with { Transaction = MapToDto(transaction, config.GatewayType) };
            }

            return result with { Transaction = MapToDto(transaction, config.GatewayType) };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Payment verification failed for {TransactionRef}", request.TransactionRef);
            throw;
        }
    }

    /// <summary>
    /// Completes the payment transaction, instantiates approved Payment entity, updates Order.PaymentStatus, and posts accounting receipt
    /// </summary>
    private async Task CompleteOrderPaymentAsync(
        PaymentTransaction transaction,
        PaymentGatewayConfig config,
        string? gatewayPaymentId,
        decimal? gatewayFee,
        Dictionary<string, object>? paymentDetails = null)
    {
        if (!string.IsNullOrEmpty(gatewayPaymentId))
        {
            transaction.SetGatewayIds(gatewayPaymentId, transaction.GatewayOrderId);
        }

        // Update payment method info from details if present
        if (paymentDetails != null)
        {
            if (paymentDetails.TryGetValue("method", out var methodObj) && methodObj is string methodStr)
            {
                if (methodStr.Equals("upi", StringComparison.OrdinalIgnoreCase))
                {
                    var vpa = paymentDetails.TryGetValue("vpa", out var v) ? v?.ToString() : null;
                    transaction.SetPaymentMethodUpi(vpa);
                }
                else if (methodStr.Equals("card", StringComparison.OrdinalIgnoreCase))
                {
                    var last4 = paymentDetails.TryGetValue("card_last4", out var l) ? l?.ToString() : null;
                    var brand = paymentDetails.TryGetValue("card_brand", out var b) ? b?.ToString() : null;
                    transaction.SetPaymentMethodCard(last4, brand);
                }
                else if (methodStr.Equals("netbanking", StringComparison.OrdinalIgnoreCase))
                {
                    var bank = paymentDetails.TryGetValue("bank", out var bk) ? bk?.ToString() : null;
                    transaction.SetPaymentMethodNetBanking(bank);
                }
                else if (methodStr.Equals("wallet", StringComparison.OrdinalIgnoreCase))
                {
                    var wallet = paymentDetails.TryGetValue("wallet", out var w) ? w?.ToString() : null;
                    transaction.SetPaymentMethodWallet(wallet);
                }
            }
        }

        transaction.MarkCompleted(gatewayFee);
        await _transactionRepository.UpdateAsync(transaction);

        // Link to Floraprise Order & Payment if OrderId is present
        if (transaction.OrderId.HasValue)
        {
            var order = await _orderRepository.GetByIdAsync(transaction.CompanyId, transaction.OrderId.Value);
            if (order != null)
            {
                var existingPayments = await _paymentRepository.GetByOrderIdAsync(order.Id);
                var existingPayment = existingPayments.FirstOrDefault(p =>
                    p.TransactionId == transaction.GatewayPaymentId ||
                    p.TransactionId == transaction.TransactionRef);

                if (existingPayment == null)
                {
                    var paymentMethod = MapGatewayMethodToPaymentMethod(transaction.PaymentMethod);
                    var payment = new Payment(
                        transaction.CompanyId,
                        order.Id,
                        paymentMethod,
                        transaction.Amount);

                    if (order.LocationId.HasValue)
                        payment.SetLocation(order.LocationId.Value);

                    payment.SetPosReference(transaction.TransactionRef, $"Gateway: {config.GatewayType}");
                    payment.Approve(transaction.GatewayPaymentId ?? transaction.TransactionRef, transaction.GatewayOrderId);

                    if (!string.IsNullOrWhiteSpace(transaction.CardBrand) || !string.IsNullOrWhiteSpace(transaction.CardLast4))
                    {
                        payment.SetCardDetails(transaction.CardBrand, transaction.CardLast4);
                    }

                    await _paymentRepository.AddAsync(payment);
                    _logger.LogInformation("Created and approved Payment {PaymentId} for Order {OrderId}", payment.Id, order.Id);
                }

                // Recalculate Order.PaymentStatus from ALL successful payments against this order
                var totalPaid = await _paymentRepository.GetTotalPaidForOrderAsync(order.Id);
                if (totalPaid >= order.TotalAmount)
                {
                    order.MarkPaid();
                }
                else if (totalPaid > 0)
                {
                    order.MarkPartiallyPaid(totalPaid);
                }

                await _orderRepository.UpdateAsync(order);
                _logger.LogInformation("Order {OrderId} payment status updated to {PaymentStatus} (TotalPaid: {TotalPaid}/{TotalAmount})",
                    order.Id, order.PaymentStatus, totalPaid, order.TotalAmount);

                // Accounting Integration: Record online receipt exactly once
                await RecordAccountingReceiptAsync(transaction, config, order);
            }
        }
    }

    private async Task RecordAccountingReceiptAsync(PaymentTransaction transaction, PaymentGatewayConfig config, Order order)
    {
        try
        {
            var existingEntries = await _journalEntryRepository.GetAllAsync(transaction.CompanyId);
            var alreadyRecorded = existingEntries.Any(e =>
                e.Reference == transaction.TransactionRef &&
                e.ReferenceType == "ONLINE_PAYMENT");

            if (!alreadyRecorded)
            {
                var clearingAccountId = await _journalEntryRepository.GetOrCreateAccountIdAsync(
                    transaction.CompanyId, "1040", "Online Gateway Clearing", "Asset");
                var revenueAccountId = await _journalEntryRepository.GetOrCreateAccountIdAsync(
                    transaction.CompanyId, "4000", "Sales Revenue", "Income");

                var now = DateTime.UtcNow;
                var debitEntry = new JournalEntry(
                    transaction.CompanyId,
                    now,
                    transaction.TransactionRef,
                    "ONLINE_PAYMENT",
                    $"Online payment {transaction.TransactionRef} via {config.GatewayType} for Order {order.OrderNumber}",
                    transaction.Amount,
                    0,
                    clearingAccountId);
                if (order.LocationId.HasValue)
                    debitEntry.SetLocation(order.LocationId.Value);

                var creditEntry = new JournalEntry(
                    transaction.CompanyId,
                    now,
                    transaction.TransactionRef,
                    "ONLINE_PAYMENT",
                    $"Online payment {transaction.TransactionRef} Revenue for Order {order.OrderNumber}",
                    0,
                    transaction.Amount,
                    revenueAccountId);
                if (order.LocationId.HasValue)
                    creditEntry.SetLocation(order.LocationId.Value);

                await _journalEntryRepository.AddRangeAsync(new[] { debitEntry, creditEntry });
                _logger.LogInformation("Recorded online payment journal entries for transaction {TxRef}", transaction.TransactionRef);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to record accounting journal entries for online payment {TxRef}", transaction.TransactionRef);
        }
    }

    private static PaymentMethod MapGatewayMethodToPaymentMethod(GatewayPaymentMethod? method) => method switch
    {
        GatewayPaymentMethod.UPI => PaymentMethod.Upi,
        GatewayPaymentMethod.Card => PaymentMethod.Card,
        GatewayPaymentMethod.BankTransfer or GatewayPaymentMethod.NetBanking => PaymentMethod.BankTransfer,
        GatewayPaymentMethod.GiftCard => PaymentMethod.GiftCard,
        _ => PaymentMethod.Card
    };

    /// <summary>
    /// Process refund
    /// </summary>
    public async Task<RefundResultDto> RefundAsync(RefundPaymentDto request)
    {
        var companyId = _tenantContext.CompanyId 
            ?? throw new UnauthorizedAccessException("Company context required for refund");

        var transaction = await _transactionRepository.GetByIdAsync(request.TransactionId);
        if (transaction == null || transaction.CompanyId != companyId)
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

            // Durable idempotency check for webhooks
            var idempotencyKey = $"webhook:{gatewayType}:{webhookEvent.PaymentId}";
            if (_idempotencyRecordRepository != null && !string.IsNullOrEmpty(webhookEvent.PaymentId))
            {
                var existingRecord = await _idempotencyRecordRepository.GetByKeyAsync(companyId, idempotencyKey);
                if (existingRecord != null)
                {
                    _logger.LogInformation("Duplicate webhook event {IdempotencyKey} already processed. Skipping.", idempotencyKey);
                    return;
                }
            }

            // Find transaction
            PaymentTransaction? transaction = null;
            
            if (!string.IsNullOrEmpty(webhookEvent.PaymentId))
            {
                transaction = await _transactionRepository.GetByGatewayPaymentIdAsync(companyId, webhookEvent.PaymentId);
            }

            if (transaction == null && !string.IsNullOrEmpty(webhookEvent.OrderId))
            {
                var txns = await _transactionRepository.SearchAsync(companyId);
                transaction = txns.FirstOrDefault(t => t.GatewayOrderId == webhookEvent.OrderId);
            }

            if (transaction != null && webhookEvent.NewStatus.HasValue)
            {
                // Amount check on payment.captured
                if (webhookEvent.NewStatus.Value == GatewayPaymentStatus.Completed)
                {
                    if (webhookEvent.Amount.HasValue && Math.Abs(webhookEvent.Amount.Value - transaction.Amount) > 0.01m)
                    {
                        _logger.LogWarning("Webhook amount mismatch for transaction {TxRef}: Expected {Expected}, Received {Received}",
                            transaction.TransactionRef, transaction.Amount, webhookEvent.Amount.Value);
                        return;
                    }

                    decimal? fee = null;
                    if (webhookEvent.Data != null && webhookEvent.Data.TryGetValue("fee", out var feeObj) && feeObj is decimal feeDec)
                    {
                        fee = feeDec;
                    }

                    await CompleteOrderPaymentAsync(transaction, config, webhookEvent.PaymentId, fee, webhookEvent.Data);
                }
                else
                {
                    switch (webhookEvent.NewStatus.Value)
                    {
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
                }

                _logger.LogInformation("Webhook processed: {EventType} transaction={TransactionRef} newStatus={Status}", 
                    webhookEvent.EventType, transaction.TransactionRef, webhookEvent.NewStatus);

                // Save idempotency record
                if (_idempotencyRecordRepository != null && !string.IsNullOrEmpty(webhookEvent.PaymentId))
                {
                    await _idempotencyRecordRepository.AddAsync(new IdempotencyRecord(
                        companyId,
                        idempotencyKey,
                        $"/api/webhooks/payment/{gatewayType.ToString().ToLowerInvariant()}",
                        "",
                        200,
                        "OK",
                        transaction?.OrderId));
                }
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
        var companyId = _tenantContext.CompanyId;
        if (!companyId.HasValue) return null;

        var transaction = await _transactionRepository.GetByIdAsync(id);
        if (transaction == null || transaction.CompanyId != companyId.Value)
            return null;

        var config = await _configRepository.GetByIdAsync(transaction.PaymentGatewayConfigId);
        return MapToDto(transaction, config?.GatewayType ?? PaymentGatewayType.Stripe);
    }

    /// <summary>
    /// Get transactions for an order
    /// </summary>
    public async Task<IReadOnlyList<PaymentTransactionDto>> GetTransactionsByOrderAsync(Guid orderId)
    {
        var companyId = _tenantContext.CompanyId;
        if (!companyId.HasValue) return Array.Empty<PaymentTransactionDto>();

        var transactions = await _transactionRepository.GetByOrderIdAsync(orderId);
        var result = new List<PaymentTransactionDto>();

        foreach (var txn in transactions)
        {
            if (txn.CompanyId != companyId.Value) continue;
            
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
        var companyId = _tenantContext.CompanyId 
            ?? throw new UnauthorizedAccessException("Company context required");

        var transactions = await _transactionRepository.SearchAsync(
            companyId, status, fromDate, toDate, page, pageSize);
        var count = await _transactionRepository.GetCountAsync(companyId, status);

        var configs = await _configRepository.GetByCompanyAsync(companyId);
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

