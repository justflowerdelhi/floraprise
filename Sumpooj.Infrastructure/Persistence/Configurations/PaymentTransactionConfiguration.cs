using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Infrastructure.Persistence.Configurations;

public class PaymentTransactionConfiguration : IEntityTypeConfiguration<PaymentTransaction>
{
    public void Configure(EntityTypeBuilder<PaymentTransaction> builder)
    {
        builder.ToTable("PaymentTransactions");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.TransactionRef)
               .HasMaxLength(50)
               .IsRequired();

        builder.Property(x => x.GatewayPaymentId)
               .HasMaxLength(200);

        builder.Property(x => x.GatewayOrderId)
               .HasMaxLength(200);

        builder.Property(x => x.Amount)
               .HasColumnType("decimal(18,2)")
               .IsRequired();

        builder.Property(x => x.Currency)
               .HasMaxLength(3)
               .IsRequired();

        builder.Property(x => x.CardLast4)
               .HasMaxLength(4);

        builder.Property(x => x.CardBrand)
               .HasMaxLength(20);

        builder.Property(x => x.BankName)
               .HasMaxLength(100);

        builder.Property(x => x.UpiId)
               .HasMaxLength(100);

        builder.Property(x => x.WalletName)
               .HasMaxLength(50);

        builder.Property(x => x.CustomerEmail)
               .HasMaxLength(200);

        builder.Property(x => x.CustomerPhone)
               .HasMaxLength(20);

        builder.Property(x => x.FailureReason)
               .HasMaxLength(500);

        builder.Property(x => x.ErrorCode)
               .HasMaxLength(50);

        builder.Property(x => x.RefundedAmount)
               .HasColumnType("decimal(18,2)")
               .HasDefaultValue(0);

        builder.Property(x => x.GatewayResponse)
               .HasColumnType("jsonb");

        builder.Property(x => x.GatewayFee)
               .HasColumnType("decimal(18,4)");

        builder.Property(x => x.NetAmount)
               .HasColumnType("decimal(18,2)");

        builder.Property(x => x.Metadata)
               .HasColumnType("jsonb");

        builder.Property(x => x.AuthorizedAt)
               .HasColumnType("timestamptz");

        builder.Property(x => x.CapturedAt)
               .HasColumnType("timestamptz");

        builder.Property(x => x.CompletedAt)
               .HasColumnType("timestamptz");

        builder.Property(x => x.FailedAt)
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

        builder.HasOne(x => x.PaymentGatewayConfig)
               .WithMany()
               .HasForeignKey(x => x.PaymentGatewayConfigId)
               .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(x => x.Order)
               .WithMany()
               .HasForeignKey(x => x.OrderId)
               .OnDelete(DeleteBehavior.SetNull);

        // Indexes
        builder.HasIndex(x => x.CompanyId);
        builder.HasIndex(x => x.TransactionRef).IsUnique();
        builder.HasIndex(x => x.OrderId);
        builder.HasIndex(x => new { x.CompanyId, x.GatewayPaymentId });
        builder.HasIndex(x => new { x.CompanyId, x.Status });
        builder.HasIndex(x => new { x.CompanyId, x.CreatedAtUtc });
    }
}
