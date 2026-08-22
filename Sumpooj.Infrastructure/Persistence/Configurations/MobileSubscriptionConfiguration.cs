using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Infrastructure.Persistence.Configurations;

public sealed class MobileCustomerConfiguration : IEntityTypeConfiguration<MobileCustomer>
{
    public void Configure(EntityTypeBuilder<MobileCustomer> builder)
    {
        builder.ToTable("MobileCustomers");
        builder.HasKey(x => x.Id);

        builder.Property(x => x.BusinessName).HasMaxLength(160).IsRequired();
        builder.Property(x => x.OwnerName).HasMaxLength(120).IsRequired();
        builder.Property(x => x.Mobile).HasMaxLength(32).IsRequired();
        builder.Property(x => x.Email).HasMaxLength(160);
        builder.Property(x => x.City).HasMaxLength(100);
        builder.Property(x => x.State).HasMaxLength(100);
        builder.Property(x => x.Country).HasMaxLength(100);

        builder.Property(x => x.RowVersion).IsRowVersion();
        builder.Property(x => x.CreatedAtUtc).HasColumnType("timestamptz");
        builder.Property(x => x.UpdatedAtUtc).HasColumnType("timestamptz");
        builder.Property(x => x.DeletedAtUtc).HasColumnType("timestamptz");

        builder.HasIndex(x => new { x.CompanyId, x.Mobile }).IsUnique();
        builder.HasIndex(x => new { x.CompanyId, x.IsDeleted });
    }
}

public sealed class MobileUserConfiguration : IEntityTypeConfiguration<MobileUser>
{
    public void Configure(EntityTypeBuilder<MobileUser> builder)
    {
        builder.ToTable("MobileUsers");
        builder.HasKey(x => x.Id);

        builder.Property(x => x.FullName).HasMaxLength(120).IsRequired();
        builder.Property(x => x.Mobile).HasMaxLength(32).IsRequired();
        builder.Property(x => x.Email).HasMaxLength(160);
        builder.Property(x => x.PreferredLanguage).HasMaxLength(16).IsRequired();
        builder.Property(x => x.PreferredTheme).HasMaxLength(32).IsRequired();
        builder.Property(x => x.Status).HasConversion<string>().HasMaxLength(24).IsRequired();

        builder.Property(x => x.RowVersion).IsRowVersion();
        builder.Property(x => x.CreatedAtUtc).HasColumnType("timestamptz");
        builder.Property(x => x.UpdatedAtUtc).HasColumnType("timestamptz");
        builder.Property(x => x.DeletedAtUtc).HasColumnType("timestamptz");

        builder.HasOne(x => x.MobileCustomer)
            .WithMany(x => x.MobileUsers)
            .HasForeignKey(x => x.MobileCustomerId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(x => x.Company)
            .WithMany()
            .HasForeignKey(x => x.CompanyId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(x => new { x.CompanyId, x.Mobile }).IsUnique();
        builder.HasIndex(x => new { x.CompanyId, x.Status });
    }
}

public sealed class MobileDeviceConfiguration : IEntityTypeConfiguration<MobileDevice>
{
    public void Configure(EntityTypeBuilder<MobileDevice> builder)
    {
        builder.ToTable("MobileDevices");
        builder.HasKey(x => x.Id);

        builder.Property(x => x.LegacyUserId).HasColumnName("UserId").IsRequired();
        builder.Property(x => x.DeviceId).HasMaxLength(120).IsRequired();
        builder.Property(x => x.DeviceFingerprintHash).IsRequired();
        builder.Property(x => x.DeviceName).IsRequired();
        builder.Property(x => x.Manufacturer).HasMaxLength(80);
        builder.Property(x => x.Model).HasMaxLength(120);
        builder.Property(x => x.Platform).HasMaxLength(24).IsRequired();
        builder.Property(x => x.OsVersion).HasMaxLength(80);
        builder.Property(x => x.AppVersion).HasMaxLength(40).IsRequired();
        builder.Property(x => x.PushToken).HasMaxLength(512);
        builder.Property(x => x.LastIpAddress).HasMaxLength(64);
        builder.Property(x => x.Status).HasConversion<string>().HasMaxLength(24).IsRequired();

        builder.Property(x => x.LastLoginAtUtc).HasColumnType("timestamptz");
        builder.Property(x => x.LastHeartbeatAtUtc).HasColumnType("timestamptz");
        builder.Property(x => x.LastSyncAtUtc).HasColumnType("timestamptz");

        builder.Property(x => x.RowVersion).IsRowVersion();
        builder.Property(x => x.CreatedAtUtc).HasColumnType("timestamptz");
        builder.Property(x => x.UpdatedAtUtc).HasColumnType("timestamptz");
        builder.Property(x => x.DeletedAtUtc).HasColumnType("timestamptz");

        builder.HasOne(x => x.MobileUser)
            .WithMany(x => x.Devices)
            .HasForeignKey(x => x.MobileUserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(x => x.Company)
            .WithMany()
            .HasForeignKey(x => x.CompanyId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(x => new { x.CompanyId, x.MobileUserId, x.DeviceId }).IsUnique();
        builder.HasIndex(x => new { x.CompanyId, x.Status });
    }
}

public sealed class SubscriptionPlanConfiguration : IEntityTypeConfiguration<SubscriptionPlan>
{
    public void Configure(EntityTypeBuilder<SubscriptionPlan> builder)
    {
        builder.ToTable("SubscriptionPlans");
        builder.HasKey(x => x.Id);

        builder.Property(x => x.Code).HasMaxLength(40).IsRequired();
        builder.Property(x => x.Name).HasMaxLength(100).IsRequired();
        builder.Property(x => x.PlanType).HasConversion<string>().HasMaxLength(24).IsRequired();
        builder.Property(x => x.MonthlyPrice).HasColumnType("decimal(18,2)");
        builder.Property(x => x.AnnualPrice).HasColumnType("decimal(18,2)");
        builder.Property(x => x.LifetimePrice).HasColumnType("decimal(18,2)");
        builder.Property(x => x.IncludedModulesJson).HasColumnType("text");

        builder.Property(x => x.RowVersion).IsRowVersion();
        builder.Property(x => x.CreatedAtUtc).HasColumnType("timestamptz");
        builder.Property(x => x.UpdatedAtUtc).HasColumnType("timestamptz");
        builder.Property(x => x.DeletedAtUtc).HasColumnType("timestamptz");

        builder.HasIndex(x => x.Code).IsUnique();
        builder.HasIndex(x => new { x.IsActive, x.IsDeleted });
    }
}

public sealed class MobileSubscriptionConfiguration : IEntityTypeConfiguration<MobileSubscription>
{
    public void Configure(EntityTypeBuilder<MobileSubscription> builder)
    {
        builder.ToTable("MobileSubscriptions");
        builder.HasKey(x => x.Id);

        builder.Property(x => x.Status).HasConversion<string>().HasMaxLength(24).IsRequired();
        builder.Property(x => x.TrialStartUtc).HasColumnType("timestamptz").IsRequired();
        builder.Property(x => x.TrialEndUtc).HasColumnType("timestamptz").IsRequired();
        builder.Property(x => x.StartUtc).HasColumnType("timestamptz");
        builder.Property(x => x.EndUtc).HasColumnType("timestamptz");
        builder.Property(x => x.GraceEndUtc).HasColumnType("timestamptz");
        builder.Property(x => x.LastValidatedUtc).HasColumnType("timestamptz");

        builder.Property(x => x.RowVersion).IsRowVersion();
        builder.Property(x => x.CreatedAtUtc).HasColumnType("timestamptz");
        builder.Property(x => x.UpdatedAtUtc).HasColumnType("timestamptz");
        builder.Property(x => x.DeletedAtUtc).HasColumnType("timestamptz");

        builder.HasOne(x => x.MobileUser)
            .WithOne(x => x.Subscription)
            .HasForeignKey<MobileSubscription>(x => x.MobileUserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(x => x.SubscriptionPlan)
            .WithMany(x => x.Subscriptions)
            .HasForeignKey(x => x.SubscriptionPlanId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.Company)
            .WithMany()
            .HasForeignKey(x => x.CompanyId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(x => new { x.CompanyId, x.Status });
    }
}

public sealed class MobileLicenseConfiguration : IEntityTypeConfiguration<MobileLicense>
{
    public void Configure(EntityTypeBuilder<MobileLicense> builder)
    {
        builder.ToTable("MobileLicenses");
        builder.HasKey(x => x.Id);

        builder.Property(x => x.Status).HasConversion<string>().HasMaxLength(24).IsRequired();
        builder.Property(x => x.IssuedAtUtc).HasColumnType("timestamptz").IsRequired();
        builder.Property(x => x.ExpiryUtc).HasColumnType("timestamptz");
        builder.Property(x => x.RevokedAtUtc).HasColumnType("timestamptz");

        builder.Property(x => x.RowVersion).IsRowVersion();
        builder.Property(x => x.CreatedAtUtc).HasColumnType("timestamptz");
        builder.Property(x => x.UpdatedAtUtc).HasColumnType("timestamptz");
        builder.Property(x => x.DeletedAtUtc).HasColumnType("timestamptz");

        builder.HasOne(x => x.MobileDevice)
            .WithOne(x => x.License)
            .HasForeignKey<MobileLicense>(x => x.MobileDeviceId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(x => x.MobileSubscription)
            .WithMany()
            .HasForeignKey(x => x.MobileSubscriptionId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(x => x.Company)
            .WithMany()
            .HasForeignKey(x => x.CompanyId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(x => new { x.CompanyId, x.Status });
    }
}

public sealed class DeviceSessionConfiguration : IEntityTypeConfiguration<DeviceSession>
{
    public void Configure(EntityTypeBuilder<DeviceSession> builder)
    {
        builder.ToTable("DeviceSessions");
        builder.HasKey(x => x.Id);

        builder.Property(x => x.RefreshToken).HasMaxLength(512).IsRequired();
        builder.Property(x => x.ExpiresAtUtc).HasColumnType("timestamptz").IsRequired();
        builder.Property(x => x.LastSeenAtUtc).HasColumnType("timestamptz").IsRequired();
        builder.Property(x => x.Status).HasConversion<string>().HasMaxLength(24).IsRequired();

        builder.Property(x => x.RowVersion).IsRowVersion();
        builder.Property(x => x.CreatedAtUtc).HasColumnType("timestamptz");
        builder.Property(x => x.UpdatedAtUtc).HasColumnType("timestamptz");
        builder.Property(x => x.DeletedAtUtc).HasColumnType("timestamptz");

        builder.HasOne(x => x.MobileDevice)
            .WithMany(x => x.Sessions)
            .HasForeignKey(x => x.MobileDeviceId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(x => x.Company)
            .WithMany()
            .HasForeignKey(x => x.CompanyId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(x => x.RefreshToken).IsUnique();
        builder.HasIndex(x => new { x.CompanyId, x.MobileDeviceId, x.Status });
    }
}

public sealed class MobilePaymentTransactionConfiguration : IEntityTypeConfiguration<MobilePaymentTransaction>
{
    public void Configure(EntityTypeBuilder<MobilePaymentTransaction> builder)
    {
        builder.ToTable("MobilePaymentTransactions");
        builder.HasKey(x => x.Id);

        builder.Property(x => x.PaymentType).HasConversion<string>().HasMaxLength(24).IsRequired();
        builder.Property(x => x.PaymentStatus).HasConversion<string>().HasMaxLength(24).IsRequired();
        builder.Property(x => x.TransactionRef).HasMaxLength(100).IsRequired();
        builder.Property(x => x.GatewayOrderId).HasMaxLength(200);
        builder.Property(x => x.GatewayPaymentId).HasMaxLength(200);
        builder.Property(x => x.Amount).HasColumnType("decimal(18,2)").IsRequired();
        builder.Property(x => x.Currency).HasMaxLength(8).IsRequired();
        builder.Property(x => x.PaidAtUtc).HasColumnType("timestamptz");
        builder.Property(x => x.FailedAtUtc).HasColumnType("timestamptz");
        builder.Property(x => x.RefundedAtUtc).HasColumnType("timestamptz");
        builder.Property(x => x.FailureReason).HasMaxLength(400);

        builder.Property(x => x.RowVersion).IsRowVersion();
        builder.Property(x => x.CreatedAtUtc).HasColumnType("timestamptz");
        builder.Property(x => x.UpdatedAtUtc).HasColumnType("timestamptz");
        builder.Property(x => x.DeletedAtUtc).HasColumnType("timestamptz");

        builder.HasOne(x => x.MobileSubscription)
            .WithMany(x => x.PaymentTransactions)
            .HasForeignKey(x => x.MobileSubscriptionId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(x => x.Company)
            .WithMany()
            .HasForeignKey(x => x.CompanyId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(x => x.TransactionRef).IsUnique();
        builder.HasIndex(x => new { x.CompanyId, x.PaymentStatus });
    }
}

public sealed class FeatureEntitlementConfiguration : IEntityTypeConfiguration<FeatureEntitlement>
{
    public void Configure(EntityTypeBuilder<FeatureEntitlement> builder)
    {
        builder.ToTable("FeatureEntitlements");
        builder.HasKey(x => x.Id);

        builder.Property(x => x.FeatureKey).HasMaxLength(120).IsRequired();

        builder.Property(x => x.RowVersion).IsRowVersion();
        builder.Property(x => x.CreatedAtUtc).HasColumnType("timestamptz");
        builder.Property(x => x.UpdatedAtUtc).HasColumnType("timestamptz");
        builder.Property(x => x.DeletedAtUtc).HasColumnType("timestamptz");

        builder.HasOne(x => x.MobileSubscription)
            .WithMany(x => x.FeatureEntitlements)
            .HasForeignKey(x => x.MobileSubscriptionId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(x => x.Company)
            .WithMany()
            .HasForeignKey(x => x.CompanyId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(x => new { x.CompanyId, x.MobileSubscriptionId, x.FeatureKey }).IsUnique();
    }
}

public sealed class TrialHistoryConfiguration : IEntityTypeConfiguration<TrialHistory>
{
    public void Configure(EntityTypeBuilder<TrialHistory> builder)
    {
        builder.ToTable("TrialHistory");
        builder.HasKey(x => x.Id);

        builder.Property(x => x.ActionType).HasConversion<string>().HasMaxLength(24).IsRequired();
        builder.Property(x => x.ActionAtUtc).HasColumnType("timestamptz").IsRequired();
        builder.Property(x => x.Notes).HasMaxLength(500);

        builder.Property(x => x.RowVersion).IsRowVersion();
        builder.Property(x => x.CreatedAtUtc).HasColumnType("timestamptz");
        builder.Property(x => x.UpdatedAtUtc).HasColumnType("timestamptz");
        builder.Property(x => x.DeletedAtUtc).HasColumnType("timestamptz");

        builder.HasOne(x => x.MobileSubscription)
            .WithMany(x => x.TrialHistoryEntries)
            .HasForeignKey(x => x.MobileSubscriptionId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(x => x.Company)
            .WithMany()
            .HasForeignKey(x => x.CompanyId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(x => new { x.CompanyId, x.MobileSubscriptionId, x.ActionAtUtc });
    }
}