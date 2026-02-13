using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Infrastructure.Persistence.Configurations;

public class CompanyConfiguration : IEntityTypeConfiguration<Company>
{
    public void Configure(EntityTypeBuilder<Company> builder)
    {
        builder.ToTable("companies");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.Name)
               .HasMaxLength(200)
               .IsRequired();

        builder.Property(x => x.Region)
               .HasMaxLength(50)
               .IsRequired();

        builder.Property(x => x.Email)
               .HasMaxLength(200);

        builder.Property(x => x.Phone)
               .HasMaxLength(50);

        builder.Property(x => x.Address)
               .HasColumnType("text");

        builder.Property(x => x.ShortDescription)
               .HasColumnType("text");

        builder.Property(x => x.LogoPath)
               .HasMaxLength(500);

        builder.Property(x => x.TimeZone)
               .HasMaxLength(100)
               .IsRequired();

        builder.Property(x => x.CurrencyCode)
               .HasMaxLength(10)
               .IsRequired();

        builder.Property(x => x.TaxIdentifier)
               .HasMaxLength(100);

        builder.Property(x => x.IsActive)
               .HasDefaultValue(true);

        builder.Property(x => x.CreatedAtUtc)
               .HasColumnType("timestamptz");

        builder.Property(x => x.UpdatedAtUtc)
               .HasColumnType("timestamptz");

        builder.HasIndex(x => x.Region);
        builder.HasIndex(x => x.IsActive);
    }
}
