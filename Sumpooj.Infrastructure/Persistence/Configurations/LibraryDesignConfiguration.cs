using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Infrastructure.Persistence.Configurations;

public class LibraryDesignConfiguration : IEntityTypeConfiguration<LibraryDesign>
{
    public void Configure(EntityTypeBuilder<LibraryDesign> builder)
    {
        builder.ToTable("LibraryDesigns");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.Title)
               .HasMaxLength(200)
               .IsRequired();

        builder.Property(x => x.Slug)
               .HasMaxLength(200)
               .IsRequired();

        builder.Property(x => x.Description)
               .HasColumnType("text");

        builder.Property(x => x.ImageUrl)
               .HasMaxLength(1000);

        builder.Property(x => x.HighResImageUrl)
               .HasMaxLength(1000);

        builder.Property(x => x.ThumbnailUrl)
               .HasMaxLength(1000);

        builder.Property(x => x.Occasion)
               .HasMaxLength(100);

        builder.Property(x => x.Style)
               .HasMaxLength(100);

        builder.Property(x => x.ColorPalette)
               .HasMaxLength(200);

        builder.Property(x => x.FlowerTypes)
               .HasMaxLength(500);

        builder.Property(x => x.SearchKeywords)
               .HasMaxLength(1000);

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

        builder.HasOne(x => x.Recipe)
               .WithMany()
               .HasForeignKey(x => x.RecipeId)
               .OnDelete(DeleteBehavior.SetNull);

        builder.HasIndex(x => x.Slug)
               .IsUnique();

        builder.HasIndex(x => x.CategoryId);
        builder.HasIndex(x => x.RecipeId);
        builder.HasIndex(x => x.Occasion);
        builder.HasIndex(x => x.Style);
        builder.HasIndex(x => x.IsActive);
        builder.HasIndex(x => x.SortOrder);
        builder.HasIndex(x => x.UpdatedAtUtc);
    }
}
