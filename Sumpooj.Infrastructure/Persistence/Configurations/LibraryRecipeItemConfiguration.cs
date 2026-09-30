using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Infrastructure.Persistence.Configurations;

public class LibraryRecipeItemConfiguration : IEntityTypeConfiguration<LibraryRecipeItem>
{
    public void Configure(EntityTypeBuilder<LibraryRecipeItem> builder)
    {
        builder.ToTable("LibraryRecipeItems");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.ProductNameSnapshot)
               .HasMaxLength(200)
               .IsRequired();

        builder.Property(x => x.Quantity)
               .HasPrecision(18, 4)
               .IsRequired();

        builder.Property(x => x.Unit)
               .HasMaxLength(50)
               .IsRequired();

        builder.Property(x => x.Notes)
               .HasMaxLength(500);

        builder.Property(x => x.SortOrder)
               .HasDefaultValue(0);

        builder.Property(x => x.CreatedAtUtc)
               .HasColumnType("timestamptz");

        builder.Property(x => x.UpdatedAtUtc)
               .HasColumnType("timestamptz");

        builder.HasOne(x => x.LibraryProduct)
               .WithMany()
               .HasForeignKey(x => x.LibraryProductId)
               .OnDelete(DeleteBehavior.Restrict);

        builder.HasIndex(x => x.RecipeId);
        builder.HasIndex(x => x.LibraryProductId);
    }
}
