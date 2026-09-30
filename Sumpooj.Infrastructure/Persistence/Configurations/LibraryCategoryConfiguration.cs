using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Infrastructure.Persistence.Configurations;

public class LibraryCategoryConfiguration : IEntityTypeConfiguration<LibraryCategory>
{
    public void Configure(EntityTypeBuilder<LibraryCategory> builder)
    {
        builder.ToTable("LibraryCategories");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.Name)
               .HasMaxLength(200)
               .IsRequired();

        builder.Property(x => x.Slug)
               .HasMaxLength(200)
               .IsRequired();

        builder.Property(x => x.Description)
               .HasColumnType("text");

        builder.Property(x => x.ImageUrl)
               .HasMaxLength(1000);

        builder.Property(x => x.IconKey)
               .HasMaxLength(100);

        builder.Property(x => x.SortOrder)
               .HasDefaultValue(0);

        builder.Property(x => x.IsActive)
               .HasDefaultValue(true);

        builder.Property(x => x.CreatedAtUtc)
               .HasColumnType("timestamptz");

        builder.Property(x => x.UpdatedAtUtc)
               .HasColumnType("timestamptz");

        builder.HasOne(x => x.ParentCategory)
               .WithMany(x => x.SubCategories)
               .HasForeignKey(x => x.ParentCategoryId)
               .OnDelete(DeleteBehavior.Restrict);

        builder.HasIndex(x => x.Slug)
               .IsUnique();

        builder.HasIndex(x => x.ParentCategoryId);
        builder.HasIndex(x => x.IsActive);
        builder.HasIndex(x => x.SortOrder);
    }
}
