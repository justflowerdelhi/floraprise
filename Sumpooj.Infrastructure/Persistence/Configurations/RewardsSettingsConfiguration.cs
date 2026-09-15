using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Infrastructure.Persistence.Configurations;

public class RewardsSettingsConfiguration : IEntityTypeConfiguration<RewardsSettings>
{
    public void Configure(EntityTypeBuilder<RewardsSettings> builder)
    {
        builder.ToTable("RewardsSettings");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.CompanyId)
               .IsRequired();

        builder.HasIndex(x => x.CompanyId)
               .IsUnique();

        builder.HasOne<Company>()
               .WithMany()
               .HasForeignKey(x => x.CompanyId)
               .OnDelete(DeleteBehavior.Cascade);

        builder.Property(x => x.Enabled)
               .HasDefaultValue(true);

        builder.Property(x => x.EarnSpendPaisePerPoint)
               .HasDefaultValue(10000);

        builder.Property(x => x.MinimumBillPaise)
               .HasDefaultValue(30000);

        builder.Property(x => x.PointValuePaise)
               .HasDefaultValue(100);

        builder.Property(x => x.MaximumRedemptionPercent)
               .HasDefaultValue(20);

        builder.Property(x => x.ExpiryDays)
               .HasDefaultValue(365);

        builder.Property(x => x.CreatedAtUtc)
               .HasColumnType("timestamptz");

        builder.Property(x => x.UpdatedAtUtc)
               .HasColumnType("timestamptz");
    }
}
