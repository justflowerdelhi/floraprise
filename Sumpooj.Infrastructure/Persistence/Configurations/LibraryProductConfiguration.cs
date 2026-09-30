using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Infrastructure.Persistence.Configurations;

public class LibraryProductConfiguration : IEntityTypeConfiguration<LibraryProduct>
{
    public void Configure(EntityTypeBuilder<LibraryProduct> builder)
    {
        builder.ToTable("LibraryProducts");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.Name)
               .HasMaxLength(200)
               .IsRequired();

        builder.Property(x => x.Slug)
               .HasMaxLength(200)
               .IsRequired();

        builder.Property(x => x.ProductType)
               .HasConversion<string>()
               .HasMaxLength(50)
               .IsRequired();

        builder.Property(x => x.StandardUnit)
               .HasConversion<string>()
               .HasMaxLength(50)
               .IsRequired();

        builder.Property(x => x.StandardSku)
               .HasMaxLength(100);

        builder.Property(x => x.Description)
               .HasColumnType("text");

        builder.Property(x => x.ReferenceImageUrl)
               .HasMaxLength(1000);

        builder.Property(x => x.ThumbnailUrl)
               .HasMaxLength(1000);

        builder.Property(x => x.SearchKeywords)
               .HasColumnType("text");

        builder.Property(x => x.SortOrder)
               .HasDefaultValue(0);

        builder.Property(x => x.IsActive)
               .HasDefaultValue(true);

        builder.Property(x => x.Version)
               .HasDefaultValue(1);

        builder.Property(x => x.CreatedAtUtc)
               .HasColumnType("timestamptz");

        builder.Property(x => x.UpdatedAtUtc)
               .HasColumnType("timestamptz");

        builder.HasOne(x => x.Category)
               .WithMany()
               .HasForeignKey(x => x.CategoryId)
               .OnDelete(DeleteBehavior.Restrict);

        builder.HasIndex(x => x.Slug)
               .IsUnique();

        builder.HasIndex(x => x.CategoryId);
        builder.HasIndex(x => x.IsActive);
        builder.HasIndex(x => x.SortOrder);
        builder.HasIndex(x => x.UpdatedAtUtc);
    }
}
