using Floraprise.License.Api.Entities;
using Microsoft.EntityFrameworkCore;

namespace Floraprise.License.Api.Data;

public sealed class LicenseDbContext : DbContext
{
    public LicenseDbContext(DbContextOptions<LicenseDbContext> options)
        : base(options)
    {
    }

    public DbSet<Customer> Customers => Set<Customer>();
    public DbSet<Device> Devices => Set<Device>();
    public DbSet<Entities.License> Licenses => Set<Entities.License>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Customer>(entity =>
        {
            entity.ToTable("Customers");
            entity.HasKey(customer => customer.Id);
            entity.HasIndex(customer => customer.Mobile).IsUnique();
            entity.Property(customer => customer.BusinessName).HasMaxLength(160).IsRequired();
            entity.Property(customer => customer.OwnerName).HasMaxLength(120).IsRequired();
            entity.Property(customer => customer.Mobile).HasMaxLength(32).IsRequired();
            entity.Property(customer => customer.Email).HasMaxLength(160);
            entity.Property(customer => customer.City).HasMaxLength(100);
            entity.Property(customer => customer.State).HasMaxLength(100).IsRequired();
            entity.Property(customer => customer.Country).HasMaxLength(100).IsRequired();
            entity.Property(customer => customer.CreatedAt).IsRequired();
        });

        modelBuilder.Entity<Device>(entity =>
        {
            entity.ToTable("Devices");
            entity.HasKey(device => device.Id);
            entity.HasIndex(device => new { device.CustomerId, device.DeviceId }).IsUnique();
            entity.Property(device => device.DeviceId).HasMaxLength(120).IsRequired();
            entity.Property(device => device.Platform).HasMaxLength(40).IsRequired();
            entity.Property(device => device.Model).HasMaxLength(120);
            entity.Property(device => device.AndroidVersion).HasMaxLength(80);
            entity.Property(device => device.AppVersion).HasMaxLength(40).IsRequired();
            entity.Property(device => device.RegisteredAt).IsRequired();
            entity.Property(device => device.LastSeen).IsRequired();
            entity.HasOne(device => device.Customer)
                .WithMany(customer => customer.Devices)
                .HasForeignKey(device => device.CustomerId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Entities.License>(entity =>
        {
            entity.ToTable("Licenses");
            entity.HasKey(license => license.Id);
            entity.HasIndex(license => license.CustomerId).IsUnique();
            entity.Property(license => license.Plan)
                .HasConversion<string>()
                .HasMaxLength(40)
                .IsRequired();
            entity.Property(license => license.Status)
                .HasConversion<string>()
                .HasMaxLength(40)
                .IsRequired();
            entity.Property(license => license.TrialStart).IsRequired();
            entity.Property(license => license.TrialEnd).IsRequired();
            entity.Property(license => license.CreatedAt).IsRequired();
            entity.HasOne(license => license.Customer)
                .WithOne(customer => customer.License)
                .HasForeignKey<Entities.License>(license => license.CustomerId)
                .OnDelete(DeleteBehavior.Cascade);
        });
    }
}