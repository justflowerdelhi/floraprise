using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Infrastructure.Persistence.Configurations;

public class TaxRuleConfiguration : IEntityTypeConfiguration<TaxRule>
{
    public void Configure(EntityTypeBuilder<TaxRule> builder)
    {
        builder.ToTable("tax_rules");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.CountryCode)
            .HasMaxLength(10)
            .IsRequired();

        builder.Property(x => x.Name)
            .HasMaxLength(200)
            .IsRequired();

        builder.Property(x => x.Rate)
            .HasColumnType("numeric(8,4)")
            .IsRequired();

        builder.Property(x => x.IsInclusive)
            .HasDefaultValue(false);

        builder.Property(x => x.IsActive)
            .HasDefaultValue(true);

        builder.Property(x => x.CreatedAtUtc)
            .HasColumnType("timestamptz");

        builder.Property(x => x.UpdatedAtUtc)
            .HasColumnType("timestamptz");

        // Indexes
        builder.HasIndex(x => new { x.CompanyId, x.CountryCode });
        builder.HasIndex(x => x.IsActive);
    }
}
