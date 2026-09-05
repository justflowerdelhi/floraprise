using System.Collections.Concurrent;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using Sumpooj.Application.Mobile;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.API.Services.Mobile;

public sealed class PosSaleSyncService : IPosSaleSyncService
{
    private static readonly ConcurrentDictionary<string, SemaphoreSlim> SyncLocks = new();
    private readonly SumpoojDbContext _db;
    private readonly bool _useInProcessLock;
    private readonly int _idempotencyRetryAttempts;
    private readonly TimeSpan _idempotencyRetryDelay;

    public PosSaleSyncService(SumpoojDbContext db)
        : this(db, useInProcessLock: true, idempotencyRetryAttempts: 5, idempotencyRetryDelay: TimeSpan.FromMilliseconds(40))
    {
    }

    internal PosSaleSyncService(
        SumpoojDbContext db,
        bool useInProcessLock,
        int idempotencyRetryAttempts,
        TimeSpan idempotencyRetryDelay)
    {
        _db = db;
        _useInProcessLock = useInProcessLock;
        _idempotencyRetryAttempts = idempotencyRetryAttempts;
        _idempotencyRetryDelay = idempotencyRetryDelay;
    }

    public async Task<PosSaleSyncResponse> SyncAsync(
        Guid companyId,
        Guid mobileUserId,
        Guid identityUserId,
        string deviceId,
        PosSaleSyncRequest request,
        string payloadHash,
        CancellationToken cancellationToken = default)
    {
        _ = mobileUserId;
        ValidateEnvelope(request, deviceId, payloadHash);
        ValidateFinancials(request);

        if (!_useInProcessLock)
            return await SyncLockedAsync(companyId, identityUserId, deviceId, request, payloadHash, cancellationToken);

        var lockKey = $"{companyId:N}:{request.ClientSyncId}";
        var syncLock = SyncLocks.GetOrAdd(lockKey, _ => new SemaphoreSlim(1, 1));
        await syncLock.WaitAsync(cancellationToken);
        try
        {
            return await SyncLockedAsync(companyId, identityUserId, deviceId, request, payloadHash, cancellationToken);
        }
        finally
        {
            syncLock.Release();
        }
    }

    private async Task<PosSaleSyncResponse> SyncLockedAsync(
        Guid companyId,
        Guid identityUserId,
        string deviceId,
        PosSaleSyncRequest request,
        string payloadHash,
        CancellationToken cancellationToken)
    {

        var existing = await _db.PosSaleSyncReceipts.AsNoTracking()
            .FirstOrDefaultAsync(r => r.CompanyId == companyId && r.ClientSyncId == request.ClientSyncId, cancellationToken);
        if (existing != null)
            return ExistingResponse(existing, request.ClientSyncId, payloadHash);

        var strategy = _db.Database.CreateExecutionStrategy();
        return await strategy.ExecuteAsync(async () =>
        {
            await using var transaction = await _db.Database.BeginTransactionAsync(cancellationToken);
            try
            {
                existing = await _db.PosSaleSyncReceipts
                    .FirstOrDefaultAsync(r => r.CompanyId == companyId && r.ClientSyncId == request.ClientSyncId, cancellationToken);
                if (existing != null)
                {
                    await transaction.CommitAsync(cancellationToken);
                    return ExistingResponse(existing, request.ClientSyncId, payloadHash);
                }

                if (await _db.PosSaleSyncReceipts.AnyAsync(r => r.CompanyId == companyId && r.DeviceId == deviceId && r.LocalOrderId == request.LocalOrderId, cancellationToken))
                    throw new InvalidOperationException("LocalOrderId has already been synced for this device.");

                var customer = await ResolveCustomerAsync(companyId, request.Order, cancellationToken);
                var order = CreateOrder(companyId, customer.OrderCustomerId, request);
                _db.Orders.Add(order);

                var productIds = request.Lines
                    .Where(l => l.ProductId.HasValue)
                    .Select(l => l.CloudProductId ?? Guid.Empty)
                    .Concat(request.InventoryTransactions.Select(t => t.CloudProductId ?? Guid.Empty))
                    .Where(id => id != Guid.Empty)
                    .Distinct()
                    .ToList();
                var products = await _db.Products
                    .Where(p => p.CompanyId == companyId && productIds.Contains(p.Id))
                    .ToDictionaryAsync(p => p.Id, cancellationToken);

                foreach (var line in request.Lines.Where(l => l.ProductId.HasValue))
                {
                    var cloudProductId = line.CloudProductId ?? throw new ArgumentException("Product-backed line is missing cloudProductId.");
                    if (!products.TryGetValue(cloudProductId, out var product))
                        throw new KeyNotFoundException("Referenced product is unavailable.");
                    if (!product.IsActive)
                        throw new KeyNotFoundException("Referenced product is unavailable.");

                    order.AddItem(cloudProductId, line.Description?.Trim() is { Length: > 0 } name ? name : product.Name, line.Qty, PaiseToDecimal(line.UnitPricePaise));
                    order.Items.Last().SetPosFinancialDetails(
                        ClientLineId(line),
                        line.GstPercent,
                        line.DiscountType,
                        line.DiscountValue.HasValue ? PaiseToDecimal(line.DiscountValue.Value) : null,
                        PaiseToDecimal(line.DiscountPaise),
                        PaiseToDecimal(line.LineSubtotalPaise),
                        PaiseToDecimal(line.LineGstPaise));
                }

                order.SetImportedPosFinancials(
                    PaiseToDecimal(request.Order.SubtotalPaise),
                    PaiseToDecimal(request.Order.GstTotalPaise),
                    PaiseToDecimal(request.Order.DiscountTotalPaise),
                    PaiseToDecimal(request.Order.GrandTotalPaise),
                    PaiseToDecimal(request.Order.RoundOffPaise),
                    PaiseToDecimal(request.Order.RewardDiscountAmountPaise),
                    request.Order.RewardPointsEarned,
                    request.Order.RewardPointsRedeemed);
                if (request.Order.IsPaid == 1)
                    order.MarkPaid();

                foreach (var paymentSnapshot in request.Payments)
                {
                    var payment = new Payment(companyId, order.Id, ParsePaymentMethod(paymentSnapshot.Method), PaiseToDecimal(paymentSnapshot.AmountPaise));
                    payment.SetPosReference(ClientPaymentId(paymentSnapshot), paymentSnapshot.Reference);
                    payment.SetProcessedBy(identityUserId);
                    payment.Approve(null, null);
                    _db.Payments.Add(payment);
                }

                var receipt = new PosSaleSyncReceipt(companyId, request.ClientSyncId, request.LocalOrderId, deviceId, order.Id, customer.ReceiptCustomerId, payloadHash, DateTime.UtcNow);
                _db.PosSaleSyncReceipts.Add(receipt);

                foreach (var line in request.Lines)
                {
                    var cloudProductId = line.ProductId.HasValue ? line.CloudProductId : null;
                    _db.PosSaleSyncOrderLines.Add(new PosSaleSyncOrderLine(
                        companyId,
                        receipt.Id,
                        order.Id,
                        ClientLineId(line),
                        line.Id!.Value,
                        line.LocalProductId ?? line.ProductId,
                        cloudProductId,
                        line.Source,
                        line.DesignRef,
                        line.Description?.Trim() is { Length: > 0 } description ? description : "POS Line",
                        line.Qty,
                        PaiseToDecimal(line.UnitPricePaise),
                        line.GstPercent,
                        line.DiscountType,
                        line.DiscountValue.HasValue ? PaiseToDecimal(line.DiscountValue.Value) : null,
                        PaiseToDecimal(line.DiscountPaise),
                        PaiseToDecimal(line.LineSubtotalPaise),
                        PaiseToDecimal(line.LineGstPaise),
                        PaiseToDecimal(line.LineTotalPaise)));
                }

                foreach (var auditSnapshot in request.InventoryTransactions)
                {
                    var cloudProductId = auditSnapshot.CloudProductId ?? throw new ArgumentException("Inventory audit record is missing cloudProductId.");
                    if (!products.TryGetValue(cloudProductId, out var product) || !product.IsActive)
                        throw new KeyNotFoundException("Referenced product is unavailable.");

                    if (product.TrackInventory)
                    {
                        if (product.StockQuantity - auditSnapshot.Qty < 0)
                            throw new InvalidOperationException("Stock cannot go negative.");

                        product.AdjustStock(-auditSnapshot.Qty);
                        _db.InventoryLedgers.Add(new InventoryLedger(
                            companyId,
                            cloudProductId,
                            order.Id.ToString(),
                            "SALE",
                            -auditSnapshot.Qty,
                            product.StockQuantity,
                            $"POS sale sync {request.ClientSyncId}"));
                    }

                    _db.PosSaleSyncInventoryTransactions.Add(new PosSaleSyncInventoryTransaction(
                        companyId,
                        receipt.Id,
                        ClientInventoryTransactionId(auditSnapshot),
                        order.Id,
                        cloudProductId,
                        auditSnapshot.Qty,
                        auditSnapshot.CreatedAt ?? DateTime.UtcNow));
                }

                await _db.SaveChangesAsync(cancellationToken);
                await transaction.CommitAsync(cancellationToken);
                return ToResponse(receipt, request.ClientSyncId, "completed");
            }
            catch (DbUpdateException ex) when (IsUniqueViolation(ex))
            {
                await transaction.RollbackAsync(cancellationToken);
                _db.ChangeTracker.Clear();
                return await RecoverFromUniqueViolationAsync(ex, companyId, request.ClientSyncId, payloadHash, cancellationToken);
            }
        });
    }

    private async Task<ResolvedCustomer> ResolveCustomerAsync(Guid companyId, PosSaleOrderSnapshot order, CancellationToken cancellationToken)
    {
        if (order.CloudCustomerId.HasValue)
        {
            var existing = await _db.Customers.AsNoTracking()
                .FirstOrDefaultAsync(c => c.CompanyId == companyId && c.Id == order.CloudCustomerId.Value && c.IsActive, cancellationToken);
            if (existing == null)
                throw new KeyNotFoundException("Referenced customer is unavailable.");
            return new ResolvedCustomer(existing.Id, existing.Id);
        }

        var normalizedPhone = Digits(order.CustomerPhone);
        var customerName = order.CustomerName?.Trim();
        if (string.IsNullOrWhiteSpace(normalizedPhone) && string.IsNullOrWhiteSpace(customerName))
        {
            var walkIn = await _db.Customers.FirstOrDefaultAsync(c => c.CompanyId == companyId && c.Name == "Walk-In Customer", cancellationToken);
            if (walkIn != null) return new ResolvedCustomer(walkIn.Id, null);
            walkIn = new Customer(companyId, "Walk-In Customer", null, null);
            _db.Customers.Add(walkIn);
            return new ResolvedCustomer(walkIn.Id, null);
        }

        Customer? matched = null;
        if (!string.IsNullOrWhiteSpace(normalizedPhone))
        {
            var candidates = await _db.Customers.Where(c => c.CompanyId == companyId && c.IsActive && c.Phone != null).ToListAsync(cancellationToken);
            matched = candidates.FirstOrDefault(c => Digits(c.Phone) == normalizedPhone);
        }
        if (matched == null && !string.IsNullOrWhiteSpace(customerName))
        {
            matched = await _db.Customers.FirstOrDefaultAsync(c => c.CompanyId == companyId && c.IsActive && c.Name.ToLower() == customerName.ToLower(), cancellationToken);
        }
        if (matched != null) return new ResolvedCustomer(matched.Id, matched.Id);

        var customer = new Customer(companyId, string.IsNullOrWhiteSpace(customerName) ? "POS Customer" : customerName, null, order.CustomerPhone?.Trim());
        _db.Customers.Add(customer);
        return new ResolvedCustomer(customer.Id, customer.Id);
    }

    private static Order CreateOrder(Guid companyId, Guid customerId, PosSaleSyncRequest request)
    {
        var deliveryDate = request.Order.ScheduledAt ?? request.Order.ConfirmedAt ?? DateTime.UtcNow;
        var order = new Order(companyId, customerId, deliveryDate, request.Order.DeliveryAddress, request.Order.DeliveryPincode, request.Order.RecipientName, request.Order.RecipientPhone);
        if (!string.IsNullOrWhiteSpace(request.Order.OrderNo)) order.SetImportedOrderNumber(request.Order.OrderNo);
        if (!string.IsNullOrWhiteSpace(request.Order.CardMessage)) order.SetCardMessage(request.Order.CardMessage);
        if (!string.IsNullOrWhiteSpace(request.Order.DeliverySlot)) order.SetTimeSlot(request.Order.DeliverySlot);
        order.Confirm();
        return order;
    }

    private static void ValidateEnvelope(PosSaleSyncRequest request, string deviceId, string payloadHash)
    {
        if (string.IsNullOrWhiteSpace(deviceId)) throw new UnauthorizedAccessException("Device claim is missing.");
        if (string.IsNullOrWhiteSpace(request.ClientSyncId)) throw new ArgumentException("clientSyncId is required.");
        if (request.LocalOrderId <= 0) throw new ArgumentException("localOrderId is required.");
        if (string.IsNullOrWhiteSpace(payloadHash)) throw new ArgumentException("Payload hash is required.");
        if (request.Lines.Count == 0) throw new ArgumentException("At least one order line is required.");
        if (request.Payments.Count == 0) throw new ArgumentException("At least one payment is required.");
        if (request.Lines.Any(l => !l.Id.HasValue)) throw new ArgumentException("ClientOrderLineId is required for every POS line.");
        var duplicateLine = request.Lines.GroupBy(ClientLineId).Any(g => g.Count() > 1);
        if (duplicateLine) throw new ArgumentException("Duplicate ClientOrderLineId is not allowed.");
        var duplicatePayment = request.Payments.Where(p => p.Id.HasValue).GroupBy(ClientPaymentId).Any(g => g.Count() > 1);
        if (duplicatePayment) throw new ArgumentException("Duplicate ClientPaymentId is not allowed.");
        var duplicateInventory = request.InventoryTransactions.Where(t => t.Id.HasValue).GroupBy(ClientInventoryTransactionId).Any(g => g.Count() > 1);
        if (duplicateInventory) throw new ArgumentException("Duplicate ClientInventoryTransactionId is not allowed.");
        foreach (var line in request.Lines.Where(l => l.ProductId.HasValue))
        {
            if (!line.CloudProductId.HasValue || line.CloudProductId == Guid.Empty)
                throw new ArgumentException("Product-backed line is missing cloudProductId.");
        }
    }

    private static void ValidateFinancials(PosSaleSyncRequest request)
    {
        var grossLineTotal = request.Lines.Sum(l => checked(l.UnitPricePaise * l.Qty));
        var lineDiscountTotal = request.Lines.Sum(l => l.DiscountPaise);
        var lineTotal = request.Lines.Sum(l => l.LineTotalPaise);
        if (request.Lines.Any(l => l.LineTotalPaise != l.LineSubtotalPaise + l.LineGstPaise)) throw new ArgumentException("Line totals are inconsistent.");
        if (lineTotal != grossLineTotal - lineDiscountTotal) throw new ArgumentException("Line totals do not match line prices and discounts.");
        if (request.Order.DiscountTotalPaise < lineDiscountTotal) throw new ArgumentException("Discount total is inconsistent.");
        var billDiscount = request.Order.DiscountTotalPaise - lineDiscountTotal;
        if (request.Order.SubtotalPaise + request.Order.GstTotalPaise != lineTotal - billDiscount) throw new ArgumentException("Line totals do not match order totals.");
        var expectedGrand = request.Order.SubtotalPaise + request.Order.GstTotalPaise - request.Order.RewardDiscountAmountPaise + request.Order.RoundOffPaise;
        if (expectedGrand != request.Order.GrandTotalPaise) throw new ArgumentException("Order totals are inconsistent.");
        if (request.Payments.Sum(p => p.AmountPaise) != request.Order.GrandTotalPaise) throw new ArgumentException("Payment total does not match grand total.");
    }

    private static PosSaleSyncResponse ExistingResponse(PosSaleSyncReceipt receipt, string clientSyncId, string payloadHash)
    {
        if (!string.Equals(receipt.PayloadHash, payloadHash, StringComparison.Ordinal))
            throw new InvalidOperationException("ClientSyncId was already used with a different payload.");
        return ToResponse(receipt, clientSyncId, "completed");
    }

    private static PosSaleSyncResponse ToResponse(PosSaleSyncReceipt receipt, string clientSyncId, string status) =>
        new(clientSyncId, receipt.CloudOrderId, receipt.CloudCustomerId, status,
            new PosSaleSyncReceiptResponse(receipt.Id, receipt.LocalOrderId, receipt.DeviceId, receipt.PayloadHash, receipt.CompletedAtUtc));

    internal async Task<PosSaleSyncResponse> RecoverFromUniqueViolationAsync(
        DbUpdateException ex,
        Guid companyId,
        string clientSyncId,
        string payloadHash,
        CancellationToken cancellationToken)
    {
        if (IsClientSyncIdConflict(ex))
        {
            var existing = await WaitForReceiptAsync(companyId, clientSyncId, cancellationToken);
            if (existing != null)
                return ExistingResponse(existing, clientSyncId, payloadHash);

            throw new InvalidOperationException("POS sync idempotency conflict. Retry with the same payload.");
        }

        throw new InvalidOperationException("POS sync duplicate business identity.");
    }

    private async Task<PosSaleSyncReceipt?> WaitForReceiptAsync(Guid companyId, string clientSyncId, CancellationToken cancellationToken)
    {
        for (var attempt = 0; attempt < _idempotencyRetryAttempts; attempt++)
        {
            var receipt = await _db.PosSaleSyncReceipts.AsNoTracking()
                .FirstOrDefaultAsync(r => r.CompanyId == companyId && r.ClientSyncId == clientSyncId, cancellationToken);
            if (receipt != null) return receipt;
            await Task.Delay(TimeSpan.FromMilliseconds(_idempotencyRetryDelay.TotalMilliseconds * (attempt + 1)), cancellationToken);
        }
        return null;
    }

    internal static bool IsUniqueViolation(DbUpdateException ex) =>
        ex.InnerException is PostgresException { SqlState: PostgresErrorCodes.UniqueViolation };

    internal static bool IsClientSyncIdConflict(DbUpdateException ex) =>
        ex.InnerException is PostgresException { ConstraintName: "IX_PosSaleSyncReceipts_CompanyId_ClientSyncId" };

    private static decimal PaiseToDecimal(int paise) => paise / 100m;
    private static string Digits(string? value) => string.IsNullOrWhiteSpace(value) ? string.Empty : new string(value.Where(char.IsDigit).ToArray());
    private static string ClientLineId(PosSaleLineSnapshot line) => (line.Id?.ToString() ?? string.Empty).Trim();
    private static string ClientPaymentId(PosSalePaymentSnapshot payment) => (payment.Id?.ToString() ?? payment.Reference ?? string.Empty).Trim();
    private static string ClientInventoryTransactionId(PosSaleInventoryTransactionSnapshot transaction) => (transaction.Id?.ToString() ?? string.Empty).Trim();
    private static PaymentMethod ParsePaymentMethod(string? value) => Enum.TryParse<PaymentMethod>(NormalizeMethod(value), true, out var method) ? method : PaymentMethod.Cash;
    private static string NormalizeMethod(string? value) => (value ?? string.Empty).Trim().Replace("_", string.Empty).Replace("-", string.Empty) switch
    {
        "upi" => nameof(PaymentMethod.Upi),
        "bank" or "banktransfer" => nameof(PaymentMethod.BankTransfer),
        "card" => nameof(PaymentMethod.Card),
        "giftcard" => nameof(PaymentMethod.GiftCard),
        "externalterminal" => nameof(PaymentMethod.ExternalTerminal),
        _ => nameof(PaymentMethod.Cash)
    };

    private sealed record ResolvedCustomer(Guid OrderCustomerId, Guid? ReceiptCustomerId);
}