
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
    public DbSet<PurchaseOrder> PurchaseOrders => Set<PurchaseOrder>();
    public DbSet<PurchaseOrderItem> PurchaseOrderItems => Set<PurchaseOrderItem>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<OrderItem> OrderItems => Set<OrderItem>();
    public DbSet<StockMovement> StockMovements => Set<StockMovement>();
    public DbSet<Location> Locations => Set<Location>();
    public DbSet<Delivery> Deliveries => Set<Delivery>();
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

    // Production
    public DbSet<FloralRecipe> FloralRecipes => Set<FloralRecipe>();
    public DbSet<RecipeComponent> RecipeComponents => Set<RecipeComponent>();
    public DbSet<FinishedGoodsBatch> FinishedGoodsBatches => Set<FinishedGoodsBatch>();
    public DbSet<ProductionJob> ProductionJobs => Set<ProductionJob>();
    public DbSet<ProductionMaterialUsage> ProductionMaterialUsages => Set<ProductionMaterialUsage>();
    public DbSet<ProductionMaintenanceLog> ProductionMaintenanceLogs => Set<ProductionMaintenanceLog>();
    public DbSet<ProductionWastageLog> ProductionWastageLogs => Set<ProductionWastageLog>();


    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

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

        modelBuilder.Entity<Shift>()
            .HasQueryFilter(s =>
                _tenantContext == null ||
                !_tenantContext.CompanyId.HasValue ||
                s.CompanyId == _tenantContext.CompanyId);

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

        modelBuilder.Entity<PurchaseOrder>()
            .HasIndex(po => new { po.CompanyId, po.OrderNumber })
            .IsUnique();

        modelBuilder.Entity<Order>()
            .HasIndex(o => new { o.CompanyId, o.OrderNumber })
            .IsUnique();

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
            .IsRequired();

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

    }
}
