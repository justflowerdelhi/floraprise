using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Infrastructure.Persistence.Configurations;

public class IdempotencyRecordConfiguration : IEntityTypeConfiguration<IdempotencyRecord>
{
    public void Configure(EntityTypeBuilder<IdempotencyRecord> builder)
    {
        builder.ToTable("IdempotencyRecords");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.CompanyId)
               .IsRequired();

        builder.Property(x => x.IdempotencyKey)
               .HasMaxLength(128)
               .IsRequired();

        builder.Property(x => x.RequestPath)
               .HasMaxLength(256)
               .IsRequired();

        builder.Property(x => x.RequestHash)
               .HasMaxLength(64)
               .IsRequired();

        builder.Property(x => x.ResponseStatusCode)
               .IsRequired();

        builder.Property(x => x.ResponsePayload)
               .HasColumnType("text")
               .IsRequired();

        builder.Property(x => x.OrderId);

        builder.Property(x => x.CreatedAtUtc)
               .HasColumnName("CreatedAt")
               .HasColumnType("timestamp with time zone")
               .IsRequired();

        builder.Property(x => x.ExpiresAtUtc)
               .HasColumnName("ExpiresAt")
               .HasColumnType("timestamp with time zone");

        builder.HasIndex(x => new { x.CompanyId, x.IdempotencyKey })
               .IsUnique();
    }
}
