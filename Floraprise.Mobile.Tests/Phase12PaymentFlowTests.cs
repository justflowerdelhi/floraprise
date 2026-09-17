using System.Net;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Sumpooj.Application.Common;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Payments;
using Sumpooj.Application.Payments.Gateways;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;
using Sumpooj.Infrastructure.Repositories;
using Xunit;

namespace Floraprise.Mobile.Tests;

public class Phase12PaymentFlowTests : IDisposable
{
    private readonly Guid _companyId = Guid.NewGuid();
    private readonly Guid _otherCompanyId = Guid.NewGuid();
    private readonly SumpoojDbContext _db;
    private readonly PaymentGatewayConfigRepository _configRepo;
    private readonly PaymentTransactionRepository _transactionRepo;
    private readonly OrderRepository _orderRepo;
    private readonly PaymentRepository _paymentRepo;
    private readonly JournalEntryRepository _journalRepo;
    private readonly IdempotencyRecordRepository _idempotencyRepo;

    public Phase12PaymentFlowTests()
    {
        BasePaymentGateway.ResetTestingOverrides();
        BasePaymentGateway.SetMasterKeyForTesting("test-master-key-32-chars-long!!");

        var options = new DbContextOptionsBuilder<SumpoojDbContext>()
            .UseInMemoryDatabase($"Phase12Tests_{Guid.NewGuid():N}")
            .Options;

        var tenantCtx = new TestTenantContext(_companyId);
        _db = new SumpoojDbContext(options, tenantCtx);
        _configRepo = new PaymentGatewayConfigRepository(_db);
        _transactionRepo = new PaymentTransactionRepository(_db);
        _orderRepo = new OrderRepository(_db);
        _paymentRepo = new PaymentRepository(_db);
        _journalRepo = new JournalEntryRepository(_db);
        _idempotencyRepo = new IdempotencyRecordRepository(_db);
    }

    public void Dispose()
    {
        BasePaymentGateway.ResetTestingOverrides();
        _db.Dispose();
    }

    private sealed class TestTenantContext : ITenantContext
    {
        public Guid? CompanyId { get; set; }
        public bool IsPlatformUser => false;
        public string? Region => "IN";

        public TestTenantContext(Guid? companyId)
        {
            CompanyId = companyId;
        }
    }

    private sealed class FakePaymentGateway : IPaymentGateway
    {
        public PaymentGatewayType GatewayType => PaymentGatewayType.Razorpay;
        public bool VerifySuccess { get; set; } = true;

        public Task InitializeAsync(PaymentGatewayConfig config) => Task.CompletedTask;

        public Task<CreatePaymentResultDto> CreatePaymentAsync(CreatePaymentDto request, PaymentTransaction transaction)
        {
            return Task.FromResult(new CreatePaymentResultDto(
                TransactionId: transaction.Id,
                TransactionRef: transaction.TransactionRef,
                GatewayOrderId: "order_rzp_123",
                PaymentUrl: null,
                ClientSecret: "order_rzp_123",
                QrCode: null,
                AdditionalData: new Dictionary<string, object> { ["key"] = "rzp_test_key" }
            ));
        }

        public Task<VerifyPaymentResultDto> VerifyPaymentAsync(VerifyPaymentDto request)
        {
            if (VerifySuccess)
            {
                return Task.FromResult(new VerifyPaymentResultDto(
                    Success: true,
                    Status: GatewayPaymentStatus.Completed,
                    Message: "captured",
                    Transaction: null
                ));
            }

            return Task.FromResult(new VerifyPaymentResultDto(
                Success: false,
                Status: GatewayPaymentStatus.Failed,
                Message: "Verification failed",
                Transaction: null
            ));
        }

        public Task<RefundResultDto> RefundAsync(PaymentTransaction transaction, decimal amount, string? reason)
        {
            return Task.FromResult(new RefundResultDto(true, "rfnd_123", amount, "Success"));
        }

        public Task<WebhookEventDto?> ParseWebhookAsync(string payload, string? signature, Dictionary<string, string>? headers)
        {
            if (signature == "invalid_signature")
                return Task.FromResult<WebhookEventDto?>(null);

            var data = JsonSerializer.Deserialize<JsonElement>(payload);
            var eventType = data.GetProperty("event").GetString();
            var paymentEntity = data.GetProperty("payload").GetProperty("payment").GetProperty("entity");

            var webhookData = new Dictionary<string, object>();
            if (paymentEntity.TryGetProperty("fee", out var feeEl) && feeEl.ValueKind == JsonValueKind.Number)
            {
                webhookData["fee"] = feeEl.GetDecimal() / 100m;
            }
            if (paymentEntity.TryGetProperty("method", out var mEl))
                webhookData["method"] = mEl.GetString() ?? "";
            if (paymentEntity.TryGetProperty("vpa", out var vpaEl))
                webhookData["vpa"] = vpaEl.GetString() ?? "";

            var amountInPaise = paymentEntity.GetProperty("amount").GetDecimal();

            return Task.FromResult<WebhookEventDto?>(new WebhookEventDto(
                EventType: eventType ?? "unknown",
                PaymentId: paymentEntity.GetProperty("id").GetString(),
                OrderId: paymentEntity.TryGetProperty("order_id", out var oid) ? oid.GetString() : null,
                NewStatus: eventType == "payment.captured" ? GatewayPaymentStatus.Completed : GatewayPaymentStatus.Pending,
                Amount: amountInPaise / 100m,
                Currency: paymentEntity.GetProperty("currency").GetString(),
                Data: webhookData
            ));
        }

        public Task<PaymentGatewayTestResultDto> TestConnectionAsync() =>
            Task.FromResult(new PaymentGatewayTestResultDto(true, "OK", DateTime.UtcNow));

        public Task<GatewayPaymentStatus> GetPaymentStatusAsync(string gatewayPaymentId) =>
            Task.FromResult(GatewayPaymentStatus.Completed);
    }

    private sealed class FakeGatewayFactory : IPaymentGatewayFactory
    {
        public FakePaymentGateway Gateway { get; } = new();

        public Task<IPaymentGateway> CreateAsync(PaymentGatewayConfig config)
        {
            return Task.FromResult<IPaymentGateway>(Gateway);
        }

        public IEnumerable<PaymentGatewayType> GetSupportedGateways() =>
            new[] { PaymentGatewayType.Razorpay };
    }

    private async Task<(PaymentGatewayConfig config, Order order, PaymentTransaction transaction)> SetupScenarioAsync(
        decimal orderAmount,
        decimal transactionAmount)
    {
        var config = new PaymentGatewayConfig(
            companyId: _companyId,
            gatewayType: PaymentGatewayType.Razorpay,
            name: "Razorpay Primary",
            publicKey: "rzp_test_public_key_123",
            secretKeyEncrypted: BasePaymentGateway.EncryptSecret("rzp_test_secret_key_456"),
            environment: GatewayEnvironment.Sandbox,
            currency: "INR"
        );
        config.UpdateCredentials(
            "rzp_test_public_key_123",
            BasePaymentGateway.EncryptSecret("rzp_test_secret_key_456"),
            BasePaymentGateway.EncryptSecret("rzp_webhook_secret_789")
        );
        config.SetAsDefault();
        await _configRepo.AddAsync(config);

        var order = new Order(
            companyId: _companyId,
            customerId: Guid.NewGuid(),
            deliveryDate: DateTime.UtcNow.AddDays(1),
            deliveryAddress: "123 Flower Street",
            deliveryPincode: "110001",
            recipientName: "Test Recipient",
            recipientPhone: "9876543210"
        );
        order.SetImportedPosFinancials(orderAmount, 0m, 0m, orderAmount, 0m, 0m, 0, 0);
        await _orderRepo.AddAsync(order);

        var transaction = new PaymentTransaction(
            companyId: _companyId,
            paymentGatewayConfigId: config.Id,
            transactionRef: $"TXN-{Guid.NewGuid():N}"[..16],
            amount: transactionAmount,
            currency: "INR",
            orderId: order.Id
        );
        transaction.SetGatewayIds("pay_rzp_test_001", "order_rzp_test_001");
        transaction.MarkProcessing();
        await _transactionRepo.AddAsync(transaction);

        return (config, order, transaction);
    }

    private GatewayPaymentService CreateService(FakeGatewayFactory? gatewayFactory = null, Guid? tenantCompanyId = null)
    {
        var factory = gatewayFactory ?? new FakeGatewayFactory();
        var tenantCtx = new TestTenantContext(tenantCompanyId ?? _companyId);

        return new GatewayPaymentService(
            _configRepo,
            _transactionRepo,
            factory,
            tenantCtx,
            _paymentRepo,
            _orderRepo,
            _journalRepo,
            NullLogger<GatewayPaymentService>.Instance,
            _idempotencyRepo
        );
    }

    [Fact]
    public async Task ScenarioA_SuccessfulPaymentVerification_CompletesTransaction_CreatesApprovedPayment_MarksOrderPaid()
    {
        var (config, order, transaction) = await SetupScenarioAsync(500m, 500m);
        var service = CreateService();

        var verifyDto = new VerifyPaymentDto(
            TransactionRef: transaction.TransactionRef,
            GatewayPaymentId: "pay_rzp_test_001",
            GatewaySignature: "sig_abc",
            AdditionalData: new Dictionary<string, string>
            {
                ["fee"] = "11.80"
            }
        );

        var result = await service.VerifyPaymentAsync(verifyDto);

        Assert.True(result.Success);
        Assert.Equal(GatewayPaymentStatus.Completed, result.Status);

        // Verify PaymentTransaction
        var updatedTx = await _transactionRepo.GetByIdAsync(transaction.Id);
        Assert.NotNull(updatedTx);
        Assert.Equal(GatewayPaymentStatus.Completed, updatedTx.Status);
        Assert.Equal(11.80m, updatedTx.GatewayFee);
        Assert.Equal(488.20m, updatedTx.NetAmount);

        // Verify Payment entity
        var payments = await _paymentRepo.GetByOrderIdAsync(order.Id);
        Assert.Single(payments);
        var payment = payments[0];
        Assert.Equal("Approved", payment.Status);
        Assert.Equal(500m, payment.Amount);
        Assert.Equal("pay_rzp_test_001", payment.TransactionId);

        // Verify Order
        var updatedOrder = await _orderRepo.GetByIdAsync(_companyId, order.Id);
        Assert.NotNull(updatedOrder);
        Assert.Equal(PaymentStatus.Paid, updatedOrder.PaymentStatus);

        // Verify Journal Entries (Double-Entry Online Clearing)
        var journals = await _journalRepo.GetAllAsync(_companyId);
        var orderJournals = journals.Where(j => j.Reference == transaction.TransactionRef).ToList();
        Assert.Equal(2, orderJournals.Count);
        Assert.Contains(orderJournals, j => j.Debit == 500m && j.Credit == 0m);
        Assert.Contains(orderJournals, j => j.Debit == 0m && j.Credit == 500m);
    }

    [Fact]
    public async Task ScenarioB_PartialGatewayPayment_MarksOrderPartiallyPaid()
    {
        var (config, order, transaction) = await SetupScenarioAsync(1000m, 400m);
        var service = CreateService();

        var verifyDto = new VerifyPaymentDto(
            TransactionRef: transaction.TransactionRef,
            GatewayPaymentId: "pay_rzp_partial_001",
            GatewaySignature: "sig_partial",
            AdditionalData: null
        );

        var result = await service.VerifyPaymentAsync(verifyDto);

        Assert.True(result.Success);
        Assert.Equal(GatewayPaymentStatus.Completed, result.Status);

        // Verify Order is marked PartiallyPaid
        var updatedOrder = await _orderRepo.GetByIdAsync(_companyId, order.Id);
        Assert.NotNull(updatedOrder);
        Assert.Equal(PaymentStatus.PartiallyPaid, updatedOrder.PaymentStatus);

        // Verify Payment record
        var payments = await _paymentRepo.GetByOrderIdAsync(order.Id);
        Assert.Single(payments);
        Assert.Equal(400m, payments[0].Amount);
        Assert.Equal("Approved", payments[0].Status);
    }

    [Fact]
    public async Task ScenarioC_RepeatedVerification_IsIdempotent_NoDuplicatePayment()
    {
        var (config, order, transaction) = await SetupScenarioAsync(500m, 500m);
        var service = CreateService();

        var verifyDto = new VerifyPaymentDto(
            TransactionRef: transaction.TransactionRef,
            GatewayPaymentId: "pay_rzp_test_001",
            GatewaySignature: "sig_abc",
            AdditionalData: null
        );

        // First verification
        var result1 = await service.VerifyPaymentAsync(verifyDto);
        Assert.True(result1.Success);

        // Second verification (Retry)
        var result2 = await service.VerifyPaymentAsync(verifyDto);
        Assert.True(result2.Success);

        // Exactly 1 Payment created
        var payments = await _paymentRepo.GetByOrderIdAsync(order.Id);
        Assert.Single(payments);

        // Exactly 2 Journal Entries (1 debit, 1 credit)
        var journals = await _journalRepo.GetAllAsync(_companyId);
        var txJournals = journals.Where(j => j.Reference == transaction.TransactionRef).ToList();
        Assert.Equal(2, txJournals.Count);

        var totalPaid = await _paymentRepo.GetTotalPaidForOrderAsync(order.Id);
        Assert.Equal(500m, totalPaid);
    }

    [Fact]
    public async Task ScenarioD_RazorpayWebhook_PaymentCaptured_CompletesOrder_PopulatesFeeAndMethod()
    {
        var (config, order, transaction) = await SetupScenarioAsync(750m, 750m);
        var service = CreateService();

        var webhookPayload = $$"""
        {
          "event": "payment.captured",
          "payload": {
            "payment": {
              "entity": {
                "id": "{{transaction.GatewayPaymentId}}",
                "order_id": "{{transaction.GatewayOrderId}}",
                "amount": 75000,
                "currency": "INR",
                "fee": 1500,
                "method": "upi",
                "vpa": "florist@okhdfcbank"
              }
            }
          }
        }
        """;

        await service.ProcessWebhookAsync(
            PaymentGatewayType.Razorpay,
            _companyId,
            webhookPayload,
            "valid_sig",
            null
        );

        // Verify Transaction
        var updatedTx = await _transactionRepo.GetByIdAsync(transaction.Id);
        Assert.NotNull(updatedTx);
        Assert.Equal(GatewayPaymentStatus.Completed, updatedTx.Status);
        Assert.Equal(15.00m, updatedTx.GatewayFee);
        Assert.Equal(735.00m, updatedTx.NetAmount);
        Assert.Equal(GatewayPaymentMethod.UPI, updatedTx.PaymentMethod);
        Assert.Equal("florist@okhdfcbank", updatedTx.UpiId);

        // Verify Order
        var updatedOrder = await _orderRepo.GetByIdAsync(_companyId, order.Id);
        Assert.NotNull(updatedOrder);
        Assert.Equal(PaymentStatus.Paid, updatedOrder.PaymentStatus);

        // Verify Payment
        var payments = await _paymentRepo.GetByOrderIdAsync(order.Id);
        Assert.Single(payments);
        Assert.Equal("Upi", payments[0].Method, ignoreCase: true);
        Assert.Equal(750m, payments[0].Amount);
    }

    [Fact]
    public async Task ScenarioE_DuplicateWebhook_IsIdempotent_NoDuplicatePaymentOrAccountingEntry()
    {
        var (config, order, transaction) = await SetupScenarioAsync(750m, 750m);
        var service = CreateService();

        var webhookPayload = $$"""
        {
          "event": "payment.captured",
          "payload": {
            "payment": {
              "entity": {
                "id": "{{transaction.GatewayPaymentId}}",
                "order_id": "{{transaction.GatewayOrderId}}",
                "amount": 75000,
                "currency": "INR",
                "fee": 1500,
                "method": "card"
              }
            }
          }
        }
        """;

        // First webhook delivery
        await service.ProcessWebhookAsync(PaymentGatewayType.Razorpay, _companyId, webhookPayload, "valid_sig", null);

        // Second webhook delivery (duplicate retry)
        await service.ProcessWebhookAsync(PaymentGatewayType.Razorpay, _companyId, webhookPayload, "valid_sig", null);

        // Exactly 1 Payment
        var payments = await _paymentRepo.GetByOrderIdAsync(order.Id);
        Assert.Single(payments);

        // Exactly 2 Journal Entries (Dr 1040, Cr 4000)
        var journals = await _journalRepo.GetAllAsync(_companyId);
        var txJournals = journals.Where(j => j.Reference == transaction.TransactionRef).ToList();
        Assert.Equal(2, txJournals.Count);
    }

    [Fact]
    public async Task ScenarioF_WebhookAmountMismatch_IsRejected()
    {
        var (config, order, transaction) = await SetupScenarioAsync(500m, 500m);
        var service = CreateService();

        var mismatchPayload = $$"""
        {
          "event": "payment.captured",
          "payload": {
            "payment": {
              "entity": {
                "id": "{{transaction.GatewayPaymentId}}",
                "order_id": "{{transaction.GatewayOrderId}}",
                "amount": 30000,
                "currency": "INR"
              }
            }
          }
        }
        """;

        await service.ProcessWebhookAsync(PaymentGatewayType.Razorpay, _companyId, mismatchPayload, "valid_sig", null);

        // Transaction should still be Processing (not marked Completed)
        var updatedTx = await _transactionRepo.GetByIdAsync(transaction.Id);
        Assert.NotNull(updatedTx);
        Assert.Equal(GatewayPaymentStatus.Processing, updatedTx.Status);

        // Order remains Unpaid
        var updatedOrder = await _orderRepo.GetByIdAsync(_companyId, order.Id);
        Assert.NotNull(updatedOrder);
        Assert.Equal(PaymentStatus.Unpaid, updatedOrder.PaymentStatus);

        // No payments created
        var payments = await _paymentRepo.GetByOrderIdAsync(order.Id);
        Assert.Empty(payments);
    }

    [Fact]
    public async Task ScenarioG_TenantMismatch_IsRejected()
    {
        var (config, order, transaction) = await SetupScenarioAsync(500m, 500m);
        // Tenant context belongs to a different company
        var service = CreateService(tenantCompanyId: _otherCompanyId);

        var verifyDto = new VerifyPaymentDto(
            TransactionRef: transaction.TransactionRef,
            GatewayPaymentId: "pay_rzp_test_001",
            GatewaySignature: "sig_abc",
            AdditionalData: null
        );

        var result = await service.VerifyPaymentAsync(verifyDto);

        Assert.False(result.Success);
        Assert.Equal(GatewayPaymentStatus.Failed, result.Status);
        Assert.Contains("mismatch", result.Message, StringComparison.OrdinalIgnoreCase);

        // Transaction was not modified
        var updatedTx = await _transactionRepo.GetByIdAsync(transaction.Id);
        Assert.NotNull(updatedTx);
        Assert.Equal(GatewayPaymentStatus.Processing, updatedTx.Status);
    }

    [Theory]
    [InlineData(10.555, 1056)]
    [InlineData(10.554, 1055)]
    [InlineData(10.005, 1001)]
    [InlineData(10.004, 1000)]
    [InlineData(999.00, 99900)]
    [InlineData(0.01, 1)]
    [InlineData(1499.99, 149999)]
    [InlineData(0.005, 1)]
    public void ScenarioH_PaiseRounding_MidpointRoundingAwayFromZero_CalculatesAccurately(decimal amount, long expectedPaise)
    {
        var calculatedPaise = (long)Math.Round(amount * 100, MidpointRounding.AwayFromZero);
        Assert.Equal(expectedPaise, calculatedPaise);
    }

    [Fact]
    public async Task ScenarioI_GatewayFeeAndNetAmount_PopulatedCorrectly()
    {
        var (config, order, transaction) = await SetupScenarioAsync(1200m, 1200m);
        var service = CreateService();

        var verifyDto = new VerifyPaymentDto(
            TransactionRef: transaction.TransactionRef,
            GatewayPaymentId: "pay_rzp_fee_test",
            GatewaySignature: "sig_fee",
            AdditionalData: new Dictionary<string, string>
            {
                ["fee"] = "28.32"
            }
        );

        var result = await service.VerifyPaymentAsync(verifyDto);

        Assert.True(result.Success);
        var updatedTx = await _transactionRepo.GetByIdAsync(transaction.Id);
        Assert.NotNull(updatedTx);
        Assert.Equal(1200m, updatedTx.Amount);
        Assert.Equal(28.32m, updatedTx.GatewayFee);
        Assert.Equal(1171.68m, updatedTx.NetAmount);
    }

    [Fact]
    public async Task ScenarioJ_SplitPayments_CashAndGateway_IntegrityMaintained()
    {
        var (config, order, transaction) = await SetupScenarioAsync(1000m, 600m);

        // Step 1: Florist takes 400 INR in cash at POS counter first
        var cashPayment = new Payment(
            _companyId,
            order.Id,
            PaymentMethod.Cash,
            400m
        );
        cashPayment.Approve("CASH-REF-001", null);
        await _paymentRepo.AddAsync(cashPayment);

        var totalPaidBeforeGateway = await _paymentRepo.GetTotalPaidForOrderAsync(order.Id);
        Assert.Equal(400m, totalPaidBeforeGateway);
        order.MarkPartiallyPaid(totalPaidBeforeGateway);
        await _orderRepo.UpdateAsync(order);

        Assert.Equal(PaymentStatus.PartiallyPaid, order.PaymentStatus);

        // Step 2: Customer pays remaining 600 INR via online gateway
        var service = CreateService();
        var verifyDto = new VerifyPaymentDto(
            TransactionRef: transaction.TransactionRef,
            GatewayPaymentId: "pay_rzp_split_002",
            GatewaySignature: "sig_split",
            AdditionalData: null
        );

        var result = await service.VerifyPaymentAsync(verifyDto);
        Assert.True(result.Success);

        // Assert both payments exist
        var allPayments = await _paymentRepo.GetByOrderIdAsync(order.Id);
        Assert.Equal(2, allPayments.Count);
        Assert.Contains(allPayments, p => p.Method.Equals("Cash", StringComparison.OrdinalIgnoreCase) && p.Amount == 400m && p.Status == "Approved");
        Assert.Contains(allPayments, p => p.Method.Equals("Card", StringComparison.OrdinalIgnoreCase) && p.Amount == 600m && p.Status == "Approved");

        // Total paid is 1000 INR
        var finalTotalPaid = await _paymentRepo.GetTotalPaidForOrderAsync(order.Id);
        Assert.Equal(1000m, finalTotalPaid);

        // Order is now fully Paid
        var finalOrder = await _orderRepo.GetByIdAsync(_companyId, order.Id);
        Assert.NotNull(finalOrder);
        Assert.Equal(PaymentStatus.Paid, finalOrder.PaymentStatus);
    }

    [Fact]
    public async Task ScenarioK_InvalidWebhookSignature_IsRejected()
    {
        var (config, order, transaction) = await SetupScenarioAsync(500m, 500m);
        var service = CreateService();

        var webhookPayload = $$"""
        {
          "event": "payment.captured",
          "payload": {
            "payment": {
              "entity": {
                "id": "{{transaction.GatewayPaymentId}}",
                "order_id": "{{transaction.GatewayOrderId}}",
                "amount": 50000,
                "currency": "INR"
              }
            }
          }
        }
        """;

        // Signature is invalid
        await service.ProcessWebhookAsync(
            PaymentGatewayType.Razorpay,
            _companyId,
            webhookPayload,
            "invalid_signature",
            null
        );

        // Transaction is unchanged
        var updatedTx = await _transactionRepo.GetByIdAsync(transaction.Id);
        Assert.NotNull(updatedTx);
        Assert.Equal(GatewayPaymentStatus.Processing, updatedTx.Status);

        // Order is unchanged
        var updatedOrder = await _orderRepo.GetByIdAsync(_companyId, order.Id);
        Assert.NotNull(updatedOrder);
        Assert.Equal(PaymentStatus.Unpaid, updatedOrder.PaymentStatus);

        // No payments recorded
        var payments = await _paymentRepo.GetByOrderIdAsync(order.Id);
        Assert.Empty(payments);
    }

    [Fact]
    public async Task ScenarioL_AccountingTrialBalance_NoDuplicateRevenue_SplitPayment()
    {
        var (config, order, transaction) = await SetupScenarioAsync(1000m, 600m);

        // 1. Physical POS Cash sale of 400 INR records journal entries
        var cashAccountId = await _journalRepo.GetOrCreateAccountIdAsync(_companyId, "1000", "Cash", "Asset");
        var revenueAccountId = await _journalRepo.GetOrCreateAccountIdAsync(_companyId, "4000", "Sales Revenue", "Income");

        var posEntries = new[]
        {
            new JournalEntry(_companyId, DateTime.UtcNow, order.OrderNumber, "SALE", "POS Sale Cash", 400m, 0m, cashAccountId),
            new JournalEntry(_companyId, DateTime.UtcNow, order.OrderNumber, "SALE", "POS Sale Revenue", 0m, 400m, revenueAccountId),
        };
        await _journalRepo.AddRangeAsync(posEntries);

        // 2. Gateway Online payment of 600 INR
        var service = CreateService();
        var verifyDto = new VerifyPaymentDto(
            TransactionRef: transaction.TransactionRef,
            GatewayPaymentId: "pay_rzp_split_acc_001",
            GatewaySignature: "sig_acc",
            AdditionalData: null
        );
        var result = await service.VerifyPaymentAsync(verifyDto);
        Assert.True(result.Success);

        // 3. Query Accounting Trial Balance & Balance Sheet
        var accountRepo = new AccountRepository(_db);
        var accountingService = new Sumpooj.Application.UseCases.AccountingService(_journalRepo, accountRepo);

        var trialBalance = await accountingService.GetTrialBalanceAsync(_companyId);

        // Assert Trial Balance totals
        var totalDebit = trialBalance.Sum(r => r.Debit);
        var totalCredit = trialBalance.Sum(r => r.Credit);
        Assert.Equal(1000m, totalDebit);
        Assert.Equal(1000m, totalCredit);

        // Assert specific accounts:
        // Cash (1000) = Dr 400
        var cashRow = trialBalance.Single(r => r.Code == "1000");
        Assert.Equal(400m, cashRow.Debit);
        Assert.Equal(0m, cashRow.Credit);

        // Online Gateway Clearing (1040) = Dr 600
        var clearingRow = trialBalance.Single(r => r.Code == "1040");
        Assert.Equal(600m, clearingRow.Debit);
        Assert.Equal(0m, clearingRow.Credit);

        // Sales Revenue (4000) = Cr 1000 (Exactly 1000 INR, zero double counting)
        var revenueRow = trialBalance.Single(r => r.Code == "4000");
        Assert.Equal(0m, revenueRow.Debit);
        Assert.Equal(1000m, revenueRow.Credit);

        // Balance sheet: Total Assets (1000) == Total Equity / Retained Earnings (1000)
        var balanceSheet = await accountingService.GetBalanceSheetAsync(_companyId);
        Assert.Equal(1000m, balanceSheet.TotalAssets);
        Assert.Equal(0m, balanceSheet.TotalLiabilities);
        Assert.Equal(1000m, balanceSheet.TotalEquity);
    }
}
