using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Infrastructure.Persistence.Configurations;

public class PaymentGatewayConfigConfiguration : IEntityTypeConfiguration<PaymentGatewayConfig>
{
    public void Configure(EntityTypeBuilder<PaymentGatewayConfig> builder)
    {
        builder.ToTable("PaymentGatewayConfigs");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.Name)
               .HasMaxLength(100)
               .IsRequired();

        builder.Property(x => x.PublicKey)
               .HasMaxLength(500)
               .IsRequired();

        builder.Property(x => x.SecretKeyEncrypted)
               .HasMaxLength(1000)
               .IsRequired();

        builder.Property(x => x.WebhookSecretEncrypted)
               .HasMaxLength(500);

        builder.Property(x => x.MerchantId)
               .HasMaxLength(200);

        builder.Property(x => x.Currency)
               .HasMaxLength(3)
               .IsRequired();

        builder.Property(x => x.SupportedCurrencies)
               .HasMaxLength(100);

        builder.Property(x => x.WebhookUrl)
               .HasMaxLength(500);

        builder.Property(x => x.AdditionalConfig)
               .HasColumnType("jsonb");

        builder.Property(x => x.LastTestedAt)
               .HasColumnType("timestamptz");

        // Map CreatedAtUtc to CreatedAt column in database
        builder.Property(x => x.CreatedAtUtc)
               .HasColumnName("CreatedAt")
               .HasColumnType("timestamptz");

        // Map UpdatedAtUtc to UpdatedAt column in database
        builder.Property(x => x.UpdatedAtUtc)
               .HasColumnName("UpdatedAt")
               .HasColumnType("timestamptz");

        // Relationships
        builder.HasOne(x => x.Company)
               .WithMany()
               .HasForeignKey(x => x.CompanyId)
               .OnDelete(DeleteBehavior.Cascade);

        // Indexes
        builder.HasIndex(x => x.CompanyId);
        builder.HasIndex(x => new { x.CompanyId, x.GatewayType }).IsUnique();
        builder.HasIndex(x => new { x.CompanyId, x.IsDefault })
               .HasFilter("\"IsDefault\" = TRUE");
    }
}
