
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Identity;


namespace Sumpooj.Infrastructure.Persistence;

public class SumpoojDbContext
    : IdentityDbContext<ApplicationUser, IdentityRole<Guid>, Guid>
{
    private readonly ITenantContext _tenantContext;

    public SumpoojDbContext(
    DbContextOptions<SumpoojDbContext> options,
    ITenantContext? tenantContext = null)
    : base(options)
    {
        _tenantContext = tenantContext!;
    }


    public DbSet<Customer> Customers => Set<Customer>();
    public DbSet<Company> Companies => Set<Company>();
    public DbSet<Product> Products => Set<Product>();
    public DbSet<Supplier> Suppliers => Set<Supplier>();
    public DbSet<ProductBatch> ProductBatches => Set<ProductBatch>();
    public DbSet<InventoryAdjustment> InventoryAdjustments => Set<InventoryAdjustment>();
    public DbSet<InventoryReservation> InventoryReservations => Set<InventoryReservation>();
    public DbSet<InventoryLedger> InventoryLedgers { get; set; }
    public DbSet<PosSaleSyncReceipt> PosSaleSyncReceipts => Set<PosSaleSyncReceipt>();
    public DbSet<PosSaleSyncInventoryTransaction> PosSaleSyncInventoryTransactions => Set<PosSaleSyncInventoryTransaction>();
    public DbSet<PurchaseOrder> PurchaseOrders => Set<PurchaseOrder>();
    public DbSet<PurchaseOrderItem> PurchaseOrderItems => Set<PurchaseOrderItem>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<OrderItem> OrderItems => Set<OrderItem>();
    public DbSet<StockMovement> StockMovements => Set<StockMovement>();
    public DbSet<Location> Locations => Set<Location>();
    public DbSet<Delivery> Deliveries => Set<Delivery>();
    public DbSet<DriverLocation> DriverLocations => Set<DriverLocation>();
    public DbSet<DeliverySettings> DeliverySettings => Set<DeliverySettings>();
    public DbSet<DriverAnalytics> DriverAnalytics => Set<DriverAnalytics>();
    public DbSet<Staff> Staff => Set<Staff>();
    public DbSet<Event> Events => Set<Event>();
    public DbSet<Payment> Payments => Set<Payment>();
    public DbSet<StaffTask> Tasks => Set<StaffTask>();
    public DbSet<Refund> Refunds => Set<Refund>();
    public DbSet<RefundItem> RefundItems => Set<RefundItem>();
    public DbSet<GiftCard> GiftCards => Set<GiftCard>();
    public DbSet<DayClose> DayCloses => Set<DayClose>();
    public DbSet<Shift> Shifts => Set<Shift>();
    public DbSet<AuditLog> AuditLogs => Set<AuditLog>();

    public DbSet<ProductCategoryEntity> ProductCategories => Set<ProductCategoryEntity>();
    public DbSet<Barcode> Barcodes => Set<Barcode>();

    // New entities
    public DbSet<DeliveryZone> DeliveryZones => Set<DeliveryZone>();
    public DbSet<WireOrder> WireOrders => Set<WireOrder>();
    public DbSet<Proposal> Proposals => Set<Proposal>();
    public DbSet<ProposalItem> ProposalItems => Set<ProposalItem>();
    public DbSet<TaxRule> TaxRules => Set<TaxRule>();

    // Payment Gateway entities
    public DbSet<PaymentGatewayConfig> PaymentGatewayConfigs => Set<PaymentGatewayConfig>();
    public DbSet<PaymentTransaction> PaymentTransactions => Set<PaymentTransaction>();

    // User preferences
    public DbSet<UserDashboardPreference> UserDashboardPreferences => Set<UserDashboardPreference>();

    // Sales Orders
    public DbSet<SalesOrder> SalesOrders => Set<SalesOrder>();
    public DbSet<SalesOrderItem> SalesOrderItems => Set<SalesOrderItem>();

    // Delivery Routes
    public DbSet<DeliveryRoute> DeliveryRoutes => Set<DeliveryRoute>();

    // Delivery Tracking
    public DbSet<DeliveryLocation> DeliveryLocations => Set<DeliveryLocation>();
    public DbSet<DeliveryTimeline> DeliveryTimelines => Set<DeliveryTimeline>();
    public DbSet<DeliveryProof> DeliveryProofs => Set<DeliveryProof>();

    // Production
    public DbSet<FloralRecipe> FloralRecipes => Set<FloralRecipe>();
    public DbSet<RecipeComponent> RecipeComponents => Set<RecipeComponent>();
    public DbSet<FinishedGoodsBatch> FinishedGoodsBatches => Set<FinishedGoodsBatch>();
    public DbSet<ProductionJob> ProductionJobs => Set<ProductionJob>();
    public DbSet<ProductionMaterialUsage> ProductionMaterialUsages => Set<ProductionMaterialUsage>();
    public DbSet<ProductionMaintenanceLog> ProductionMaintenanceLogs => Set<ProductionMaintenanceLog>();
    public DbSet<ProductionWastageLog> ProductionWastageLogs => Set<ProductionWastageLog>();

    // Auth
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();

    // AI Usage Tracking
    public DbSet<AIUsageRecord> AIUsageRecords => Set<AIUsageRecord>();

    // Accounting
    public DbSet<Account> Accounts => Set<Account>();
    public DbSet<Expense> Expenses => Set<Expense>();
    public DbSet<ExpenseCategory> ExpenseCategories => Set<ExpenseCategory>();
    public DbSet<OpeningCash> OpeningCashEntries => Set<OpeningCash>();
    public DbSet<CashBookEntry> CashBookEntries => Set<CashBookEntry>();
    public DbSet<JournalEntry> JournalEntries => Set<JournalEntry>();

    // Staff Attendance
    public DbSet<StaffAttendanceRecord> StaffAttendanceRecords => Set<StaffAttendanceRecord>();

    // Mobile operational parity
    public DbSet<MorningPurchaseListItem> MorningPurchaseListItems => Set<MorningPurchaseListItem>();
    public DbSet<Associate> Associates => Set<Associate>();
    public DbSet<OccasionContact> OccasionContacts => Set<OccasionContact>();
    public DbSet<OccasionFollowUpAction> OccasionFollowUpActions => Set<OccasionFollowUpAction>();
    public DbSet<SchedulerRecord> SchedulerRecords => Set<SchedulerRecord>();
    public DbSet<CloudDesign> CloudDesigns => Set<CloudDesign>();
    public DbSet<ReadyBouquetRecord> ReadyBouquetRecords => Set<ReadyBouquetRecord>();
    public DbSet<ReadyBouquetRefreshEvent> ReadyBouquetRefreshEvents => Set<ReadyBouquetRefreshEvent>();

    // Marketing
    public DbSet<DemoRequest> DemoRequests => Set<DemoRequest>();

    // Corporate clients
    public DbSet<CorporateClient> CorporateClients => Set<CorporateClient>();
    public DbSet<CorporateEmployee> CorporateEmployees => Set<CorporateEmployee>();
    public DbSet<CorporateOrderMeta> CorporateOrderMetas => Set<CorporateOrderMeta>();
    public DbSet<CorporateInvoice> CorporateInvoices => Set<CorporateInvoice>();
    public DbSet<CorporateInvoiceLine> CorporateInvoiceLines => Set<CorporateInvoiceLine>();

    // Mobile license and subscription management
    public DbSet<MobileCustomer> MobileCustomers => Set<MobileCustomer>();
    public DbSet<MobileUser> MobileUsers => Set<MobileUser>();
    public DbSet<MobileDevice> MobileDevices => Set<MobileDevice>();
    public DbSet<SubscriptionPlan> SubscriptionPlans => Set<SubscriptionPlan>();
    public DbSet<MobileSubscription> MobileSubscriptions => Set<MobileSubscription>();
    public DbSet<MobileLicense> MobileLicenses => Set<MobileLicense>();
    public DbSet<DeviceSession> DeviceSessions => Set<DeviceSession>();
    public DbSet<MobilePaymentTransaction> MobilePaymentTransactions => Set<MobilePaymentTransaction>();
    public DbSet<FeatureEntitlement> FeatureEntitlements => Set<FeatureEntitlement>();
    public DbSet<TrialHistory> TrialHistories => Set<TrialHistory>();

    // WhatsApp Business API
    public DbSet<WhatsAppAccount> WhatsAppAccounts => Set<WhatsAppAccount>();


    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // ===============================
        // Column mappings
        // ===============================
        modelBuilder.Entity<Order>(entity =>
        {
            entity.HasOne<Staff>()
                .WithMany()
                .HasForeignKey(o => o.DeliveryPersonId)
                .HasConstraintName("FK_Orders_DeliveryPerson")
                .OnDelete(DeleteBehavior.SetNull);
        });

        modelBuilder.Entity<Delivery>(entity =>
        {
            entity.Property(d => d.SalesOrderId).HasColumnName("OrderId");
            entity.Property(d => d.DeliveryDate).HasColumnName("ScheduledDateTime");
            entity.Property(d => d.DeliveryAddressLatitude).HasColumnName("DeliveryLatitude");
            entity.Property(d => d.DeliveryAddressLongitude).HasColumnName("DeliveryLongitude");

            entity.HasOne<Staff>()
                .WithMany()
                .HasForeignKey(d => d.DeliveryPersonId)
                .OnDelete(DeleteBehavior.SetNull);

            entity.HasIndex(d => d.CompanyId);
            entity.HasIndex(d => d.TrackingToken).IsUnique();
            entity.HasIndex(d => d.DeliveryPersonId);
            entity.Property(d => d.TrackingToken).HasMaxLength(256);
            entity.Property(d => d.CustomerPhone).HasMaxLength(50);
            entity.Property(d => d.CustomerEmail).HasMaxLength(256);
        });

        // ===============================
        // DriverLocation configuration
        // ===============================
        modelBuilder.Entity<DriverLocation>(entity =>
        {
            entity.ToTable("DriverLocations");
            entity.HasKey(d => d.Id);
            entity.HasOne(d => d.Delivery)
                .WithMany()
                .HasForeignKey(d => d.DeliveryId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasIndex(d => d.DriverId);
            entity.HasIndex(d => d.DeliveryId);
            entity.HasIndex(d => d.RecordedAt);
            entity.HasIndex(d => d.CreatedAtUtc);
            entity.HasIndex(d => new { d.DriverId, d.DeliveryId });
            entity.HasIndex(d => new { d.DriverId, d.RecordedAt });
        });

        // ===============================
        // DeliverySettings configuration
        // ===============================
        modelBuilder.Entity<DeliverySettings>(entity =>
        {
            entity.ToTable("DeliverySettings");
            entity.HasKey(d => d.Id);
            entity.HasIndex(d => d.CompanyId).IsUnique();
        });

        // ===============================
        // DriverAnalytics configuration
        // ===============================
        modelBuilder.Entity<DriverAnalytics>(entity =>
        {
            entity.ToTable("DriverAnalytics");
            entity.HasKey(d => d.Id);
            entity.HasIndex(d => d.DriverId);
            entity.HasIndex(d => d.Date);
            entity.HasIndex(d => new { d.DriverId, d.Date });
        });

        // ===============================
        // RefreshToken configuration
        // ===============================
        modelBuilder.Entity<RefreshToken>(entity =>
        {
            entity.ToTable("RefreshTokens");
            entity.HasKey(r => r.Id);
            entity.HasIndex(r => r.Token).IsUnique();
            entity.HasIndex(r => r.UserId);
            entity.Property(r => r.Token).HasMaxLength(256).IsRequired();
        });

        // ===============================
        // Identity composite keys (REQUIRED)
        // ===============================

       

        modelBuilder.Entity<IdentityUserLogin<Guid>>()
            .HasKey(x => new { x.LoginProvider, x.ProviderKey });

        modelBuilder.Entity<IdentityUserRole<Guid>>()
            .HasKey(x => new { x.UserId, x.RoleId });

        modelBuilder.Entity<IdentityUserToken<Guid>>()
            .HasKey(x => new { x.UserId, x.LoginProvider, x.Name });

        // ===============================
        // Ignore Identity Passkeys (WebAuthn)
        // ===============================
        modelBuilder.Ignore<IdentityPasskeyData>();

        // ===============================
        // Global Tenant Query Filter
        // ===============================
        modelBuilder.Entity<Customer>()
            .HasQueryFilter(c =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                c.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<Product>()
            .HasQueryFilter(p =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                p.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<Supplier>()
            .HasQueryFilter(s =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                s.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<ProductBatch>()
            .HasQueryFilter(b =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                b.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<InventoryAdjustment>()
            .HasQueryFilter(a =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                a.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<InventoryReservation>()
            .HasIndex(r => new { r.SalesOrderId, r.ProductBatchId, r.Status });

        modelBuilder.Entity<InventoryLedger>()
            .HasQueryFilter(l =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                l.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<PosSaleSyncReceipt>()
            .HasQueryFilter(r => _tenantContext == null || !_tenantContext.CompanyId.HasValue || r.CompanyId == _tenantContext.CompanyId);
        modelBuilder.Entity<PosSaleSyncInventoryTransaction>()
            .HasQueryFilter(t => _tenantContext == null || !_tenantContext.CompanyId.HasValue || t.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<PurchaseOrder>()
            .HasQueryFilter(po =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                po.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<Order>()
            .HasQueryFilter(o =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                o.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<StockMovement>()
            .HasQueryFilter(sm =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                sm.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<Location>()
            .HasQueryFilter(l =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                l.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<ProductCategoryEntity>()
            .HasQueryFilter(c =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                c.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<Barcode>()
            .HasQueryFilter(b =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                b.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<CorporateClient>()
            .HasQueryFilter(c =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                c.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<CorporateEmployee>()
            .HasQueryFilter(e =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                e.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<CorporateOrderMeta>()
            .HasQueryFilter(m =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                m.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<CorporateInvoice>()
            .HasQueryFilter(i =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                i.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<CorporateInvoiceLine>()
            .HasQueryFilter(l =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                l.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<MobileCustomer>()
            .HasQueryFilter(x =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                x.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<MobileUser>()
            .HasQueryFilter(x =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                x.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<MobileDevice>()
            .HasQueryFilter(x =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                x.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<MobileSubscription>()
            .HasQueryFilter(x =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                x.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<MobileLicense>()
            .HasQueryFilter(x =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                x.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<DeviceSession>()
            .HasQueryFilter(x =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                x.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<MobilePaymentTransaction>()
            .HasQueryFilter(x =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                x.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<FeatureEntitlement>()
            .HasQueryFilter(x =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                x.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<TrialHistory>()
            .HasQueryFilter(x =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                x.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<Shift>()
            .HasQueryFilter(s =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                s.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<StaffAttendanceRecord>()
            .HasQueryFilter(a =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                a.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<StaffAttendanceRecord>()
            .HasIndex(a => new { a.CompanyId, a.StaffId, a.AttendanceDate })
            .IsUnique();

        modelBuilder.Entity<Expense>()
            .HasQueryFilter(e =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                e.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<ExpenseCategory>()
            .HasQueryFilter(e =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                e.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<ExpenseCategory>()
            .HasIndex(e => new { e.CompanyId, e.Name })
            .IsUnique();

        modelBuilder.Entity<OpeningCash>()
            .HasQueryFilter(o =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                o.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<OpeningCash>()
            .HasIndex(o => new { o.CompanyId, o.Date })
            .IsUnique();

        modelBuilder.Entity<CashBookEntry>()
            .HasQueryFilter(e =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                e.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<CashBookEntry>()
            .HasIndex(e => new { e.CompanyId, e.Date, e.CreatedAtUtc });

        modelBuilder.Entity<MorningPurchaseListItem>()
            .HasQueryFilter(i =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                i.CompanyId == _tenantContext.CompanyId);
        modelBuilder.Entity<MorningPurchaseListItem>()
            .HasIndex(i => new { i.CompanyId, i.ListDate, i.ProductId })
            .IsUnique();

        modelBuilder.Entity<Associate>()
            .HasQueryFilter(a =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                a.CompanyId == _tenantContext.CompanyId);
        modelBuilder.Entity<Associate>()
            .HasIndex(a => new { a.CompanyId, a.AssociateCode })
            .IsUnique();
        modelBuilder.Entity<Associate>()
            .HasIndex(a => new { a.CompanyId, a.BusinessName, a.Phone })
            .IsUnique();

        modelBuilder.Entity<OccasionContact>()
            .HasQueryFilter(x => _tenantContext == null || !_tenantContext.CompanyId.HasValue || x.CompanyId == _tenantContext.CompanyId);
        modelBuilder.Entity<OccasionContact>()
            .HasIndex(x => new { x.CompanyId, x.CustomerId, x.RecipientName, x.Occasion })
            .IsUnique();
        modelBuilder.Entity<OccasionFollowUpAction>()
            .HasQueryFilter(x => _tenantContext == null || !_tenantContext.CompanyId.HasValue || x.CompanyId == _tenantContext.CompanyId);
        modelBuilder.Entity<OccasionFollowUpAction>()
            .HasIndex(x => new { x.CompanyId, x.SourceType, x.SourceId, x.OccurrenceDate })
            .IsUnique();
        modelBuilder.Entity<SchedulerRecord>()
            .HasQueryFilter(x => _tenantContext == null || !_tenantContext.CompanyId.HasValue || x.CompanyId == _tenantContext.CompanyId);
        modelBuilder.Entity<SchedulerRecord>()
            .HasIndex(x => new { x.CompanyId, x.Producer, x.SourceRef })
            .IsUnique();
        modelBuilder.Entity<CloudDesign>()
            .HasQueryFilter(x => _tenantContext == null || !_tenantContext.CompanyId.HasValue || x.CompanyId == _tenantContext.CompanyId);
        modelBuilder.Entity<CloudDesign>()
            .HasIndex(x => new { x.CompanyId, x.BouquetId })
            .IsUnique();
        modelBuilder.Entity<ReadyBouquetRecord>()
            .HasQueryFilter(x => _tenantContext == null || !_tenantContext.CompanyId.HasValue || x.CompanyId == _tenantContext.CompanyId);
        modelBuilder.Entity<ReadyBouquetRecord>()
            .HasIndex(x => new { x.CompanyId, x.FinishedProductId, x.ProducedAt });
        modelBuilder.Entity<ReadyBouquetRefreshEvent>()
            .HasQueryFilter(x => _tenantContext == null || !_tenantContext.CompanyId.HasValue || x.CompanyId == _tenantContext.CompanyId);
        modelBuilder.Entity<ReadyBouquetRefreshEvent>()
            .HasIndex(x => new { x.CompanyId, x.BatchId, x.CreatedAtUtc });

        modelBuilder.Entity<TaxRule>()
            .HasQueryFilter(t =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                t.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<PaymentGatewayConfig>()
            .HasQueryFilter(p =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                p.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<PaymentTransaction>()
            .HasQueryFilter(p =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                p.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<UserDashboardPreference>()
            .HasQueryFilter(u =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                u.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<FloralRecipe>()
            .HasQueryFilter(r =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                r.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<FinishedGoodsBatch>()
            .HasQueryFilter(b =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                b.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<ProductionJob>()
            .HasQueryFilter(j =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                j.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<ProductionMaintenanceLog>()
            .HasQueryFilter(l =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                l.CompanyId == _tenantContext.CompanyId);

        modelBuilder.Entity<ProductionWastageLog>()
            .HasQueryFilter(l =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                l.CompanyId == _tenantContext.CompanyId);

        // Delivery Tracking entities
        modelBuilder.Entity<DeliveryLocation>()
            .HasQueryFilter(l =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                !l.DeliveryId.Equals(Guid.Empty));

        modelBuilder.Entity<DeliveryTimeline>()
            .HasQueryFilter(t =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                !t.DeliveryId.Equals(Guid.Empty));

        modelBuilder.Entity<DeliveryProof>()
            .HasQueryFilter(p =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                !p.DeliveryId.Equals(Guid.Empty));

        // Apply entity type configurations from assembly
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(SumpoojDbContext).Assembly);

        // ===============================
        // Entity Configurations
        // ===============================
        modelBuilder.Entity<Product>()
            .HasIndex(p => new { p.CompanyId, p.Sku })
            .IsUnique();

        modelBuilder.Entity<ProductBatch>()
            .HasIndex(b => new { b.CompanyId, b.BatchNumber });

        modelBuilder.Entity<ProductBatch>()
            .HasIndex(b => new { b.ProductId, b.BatchNumber })
            .IsUnique();

        modelBuilder.Entity<PurchaseOrder>()
            .HasIndex(po => new { po.CompanyId, po.OrderNumber })
            .IsUnique();

        modelBuilder.Entity<Order>()
            .HasIndex(o => new { o.CompanyId, o.OrderNumber })
            .IsUnique();

        modelBuilder.Entity<Order>()
            .Property(o => o.PosRoundOffAmount)
            .HasColumnType("numeric(18,2)")
            .HasDefaultValue(0m);
        modelBuilder.Entity<Order>()
            .Property(o => o.RewardDiscountAmount)
            .HasColumnType("numeric(18,2)")
            .HasDefaultValue(0m);

        modelBuilder.Entity<OrderItem>()
            .Property(i => i.TaxRatePercent)
            .HasColumnType("numeric(8,4)");
        modelBuilder.Entity<OrderItem>()
            .Property(i => i.DiscountValue)
            .HasColumnType("numeric(18,2)");
        modelBuilder.Entity<OrderItem>()
            .Property(i => i.DiscountAmount)
            .HasColumnType("numeric(18,2)")
            .HasDefaultValue(0m);
        modelBuilder.Entity<OrderItem>()
            .Property(i => i.LineSubtotal)
            .HasColumnType("numeric(18,2)");
        modelBuilder.Entity<OrderItem>()
            .Property(i => i.LineTaxAmount)
            .HasColumnType("numeric(18,2)");
        modelBuilder.Entity<OrderItem>()
            .HasIndex("OrderId");
        modelBuilder.Entity<OrderItem>()
            .HasIndex("OrderId", nameof(OrderItem.ClientOrderLineId))
            .IsUnique()
            .HasFilter("\"ClientOrderLineId\" IS NOT NULL");

        modelBuilder.Entity<Payment>()
            .Property(p => p.Reference)
            .HasMaxLength(256);
        modelBuilder.Entity<Payment>()
            .HasIndex(p => new { p.OrderId, p.ClientPaymentId })
            .IsUnique()
            .HasFilter("\"ClientPaymentId\" IS NOT NULL");

        modelBuilder.Entity<PosSaleSyncReceipt>()
            .HasIndex(r => new { r.CompanyId, r.ClientSyncId })
            .IsUnique();
        modelBuilder.Entity<PosSaleSyncReceipt>()
            .HasIndex(r => new { r.CompanyId, r.DeviceId, r.LocalOrderId })
            .IsUnique();
        modelBuilder.Entity<PosSaleSyncReceipt>()
            .HasOne<Order>()
            .WithMany()
            .HasForeignKey(r => r.CloudOrderId)
            .OnDelete(DeleteBehavior.Restrict);
        modelBuilder.Entity<PosSaleSyncReceipt>()
            .HasOne<Customer>()
            .WithMany()
            .HasForeignKey(r => r.CloudCustomerId)
            .OnDelete(DeleteBehavior.SetNull);

        modelBuilder.Entity<PosSaleSyncInventoryTransaction>()
            .HasIndex(t => new { t.CompanyId, t.ClientInventoryTransactionId })
            .IsUnique();
        modelBuilder.Entity<PosSaleSyncInventoryTransaction>()
            .HasIndex(t => new { t.PosSaleSyncReceiptId, t.CreatedAtUtc });
        modelBuilder.Entity<PosSaleSyncInventoryTransaction>()
            .HasOne<PosSaleSyncReceipt>()
            .WithMany()
            .HasForeignKey(t => t.PosSaleSyncReceiptId)
            .OnDelete(DeleteBehavior.Cascade);
        modelBuilder.Entity<PosSaleSyncInventoryTransaction>()
            .HasOne<Order>()
            .WithMany()
            .HasForeignKey(t => t.CloudOrderId)
            .OnDelete(DeleteBehavior.Restrict);
        modelBuilder.Entity<PosSaleSyncInventoryTransaction>()
            .HasOne<Product>()
            .WithMany()
            .HasForeignKey(t => t.ProductId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<PurchaseOrder>()
            .HasMany(po => po.Items)
            .WithOne()
            .HasForeignKey("PurchaseOrderId")
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<Order>()
            .HasMany(o => o.Items)
            .WithOne()
            .HasForeignKey("OrderId")
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<Order>()
            .HasOne(o => o.Location)
            .WithMany()
            .HasForeignKey(o => o.LocationId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<Order>()
            .Property(o => o.LocationId)
            .IsRequired(false);

        modelBuilder.Entity<Order>()
            .Property(o => o.OrderType)
            .HasDefaultValue(OrderType.Standard);

        modelBuilder.Entity<Order>()
            .Property(o => o.CustomerType)
            .HasDefaultValue(CustomerType.Retail);

        modelBuilder.Entity<CorporateClient>()
            .HasIndex(c => new { c.CompanyId, c.Name });

        modelBuilder.Entity<CorporateClient>()
            .HasOne(c => c.Customer)
            .WithMany()
            .HasForeignKey(c => c.CustomerId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<CorporateEmployee>()
            .HasOne(e => e.Client)
            .WithMany()
            .HasForeignKey(e => e.ClientId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<CorporateOrderMeta>()
            .HasIndex(m => new { m.CompanyId, m.OrderId })
            .IsUnique();

        modelBuilder.Entity<CorporateOrderMeta>()
            .HasOne(m => m.Order)
            .WithMany()
            .HasForeignKey(m => m.OrderId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<CorporateOrderMeta>()
            .HasOne(m => m.Client)
            .WithMany()
            .HasForeignKey(m => m.ClientId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<CorporateOrderMeta>()
            .HasOne(m => m.Employee)
            .WithMany()
            .HasForeignKey(m => m.EmployeeId)
            .OnDelete(DeleteBehavior.SetNull);

        modelBuilder.Entity<CorporateInvoice>()
            .HasOne(i => i.Client)
            .WithMany()
            .HasForeignKey(i => i.ClientId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<CorporateInvoice>()
            .HasMany(i => i.Lines)
            .WithOne(l => l.Invoice)
            .HasForeignKey(l => l.InvoiceId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<Order>()
            .Property(o => o.InvoiceNumber)
            .IsRequired(false);

        // ProductCategoryEntity: unique name per company
        modelBuilder.Entity<ProductCategoryEntity>()
            .HasIndex(c => new { c.CompanyId, c.Name })
            .IsUnique();

        // Product → ProductCategoryEntity (optional FK)
        modelBuilder.Entity<Product>()
            .HasOne(p => p.ProductCategoryRef)
            .WithMany()
            .HasForeignKey(p => p.CategoryId)
            .OnDelete(DeleteBehavior.SetNull);

        // Barcode: unique per company (Company A + "X" and Company B + "X" may
        // coexist, but Company A cannot have "X" twice), and at most one
        // barcode per (Product, Type) - a product can't have two Manufacturer
        // barcodes or two Internal barcodes simultaneously.
        modelBuilder.Entity<Barcode>()
            .HasIndex(b => new { b.CompanyId, b.Value })
            .IsUnique();

        modelBuilder.Entity<Barcode>()
            .HasIndex(b => new { b.ProductId, b.Type })
            .IsUnique();

        modelBuilder.Entity<Barcode>()
            .HasOne(b => b.Product)
            .WithMany()
            .HasForeignKey(b => b.ProductId)
            .OnDelete(DeleteBehavior.Cascade);

        // Product → TaxRule (optional FK)
        modelBuilder.Entity<Product>()
            .HasOne(p => p.TaxRule)
            .WithMany()
            .HasForeignKey(p => p.TaxRuleId)
            .OnDelete(DeleteBehavior.SetNull);

        // UserDashboardPreference: one per user per company
        modelBuilder.Entity<UserDashboardPreference>()
            .HasIndex(u => new { u.CompanyId, u.UserId })
            .IsUnique();

        // ===============================
        // Production entities
        // ===============================
        modelBuilder.Entity<FloralRecipe>()
            .HasMany(r => r.Components)
            .WithOne()
            .HasForeignKey(c => c.RecipeId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<ProductionJob>()
            .HasMany(j => j.MaterialUsages)
            .WithOne()
            .HasForeignKey(m => m.JobId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<FinishedGoodsBatch>()
            .HasIndex(b => new { b.CompanyId, b.BatchCode })
            .IsUnique();

        // ===============================
        // Staff → ApplicationUser (optional login)
        // ===============================
        modelBuilder.Entity<Staff>()
            .HasOne<ApplicationUser>()
            .WithMany()
            .HasForeignKey(s => s.IdentityUserId)
            .OnDelete(DeleteBehavior.Restrict);

        // ===============================
        // WhatsApp Account
        // ===============================
        modelBuilder.Entity<WhatsAppAccount>()
            .HasIndex(w => w.MemberId)
            .IsUnique();

        modelBuilder.Entity<WhatsAppAccount>()
            .HasIndex(w => w.PhoneNumberId)
            .IsUnique();

    }
}
