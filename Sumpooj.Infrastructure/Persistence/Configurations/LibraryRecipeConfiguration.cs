using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Infrastructure.Persistence.Configurations;

public class LibraryRecipeConfiguration : IEntityTypeConfiguration<LibraryRecipe>
{
    public void Configure(EntityTypeBuilder<LibraryRecipe> builder)
    {
        builder.ToTable("LibraryRecipes");

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

        builder.Property(x => x.YieldQuantity)
               .HasPrecision(18, 4)
               .HasDefaultValue(1m);

        builder.Property(x => x.YieldUnit)
               .HasMaxLength(50);

        builder.Property(x => x.Instructions)
               .HasColumnType("text");

        builder.Property(x => x.PreparationNotes)
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

        builder.HasMany(x => x.Items)
               .WithOne(i => i.Recipe)
               .HasForeignKey(i => i.RecipeId)
               .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(x => x.Slug)
               .IsUnique();

        builder.HasIndex(x => x.CategoryId);
        builder.HasIndex(x => x.IsActive);
        builder.HasIndex(x => x.SortOrder);
        builder.HasIndex(x => x.UpdatedAtUtc);
    }
}
