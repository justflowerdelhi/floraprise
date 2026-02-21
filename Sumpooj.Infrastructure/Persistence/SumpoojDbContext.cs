
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
    public DbSet<AuditLog> AuditLogs => Set<AuditLog>();


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

    }
}
