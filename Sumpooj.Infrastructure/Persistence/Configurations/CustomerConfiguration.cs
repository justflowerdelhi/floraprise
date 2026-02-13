using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Infrastructure.Persistence.Configurations;

public class CustomerConfiguration : IEntityTypeConfiguration<Customer>
{
    public void Configure(EntityTypeBuilder<Customer> builder)
    {
        builder.ToTable("customers");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.Name)
               .HasMaxLength(200)
               .IsRequired();

        builder.Property(x => x.Email)
               .HasMaxLength(200);

        builder.Property(x => x.Phone)
               .HasMaxLength(50);

        builder.Property(x => x.DefaultCardMessage)
               .HasColumnType("text");

        builder.Property(x => x.IsActive)
               .HasDefaultValue(true);

        builder.Property(x => x.TotalOrders)
               .HasDefaultValue(0);

        builder.Property(x => x.CreatedAtUtc)
               .HasColumnType("timestamptz");

        builder.Property(x => x.UpdatedAtUtc)
               .HasColumnType("timestamptz");

        builder.HasIndex(x => x.IsActive);
    }
}
