
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

    }
}
