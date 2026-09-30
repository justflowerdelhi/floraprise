using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Infrastructure.Persistence.Configurations;

public class LibraryCardTemplateConfiguration : IEntityTypeConfiguration<LibraryCardTemplate>
{
    public void Configure(EntityTypeBuilder<LibraryCardTemplate> builder)
    {
        builder.ToTable("LibraryCardTemplates");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.Title)
               .HasMaxLength(200)
               .IsRequired();

        builder.Property(x => x.Slug)
               .HasMaxLength(200)
               .IsRequired();

        builder.Property(x => x.Content)
               .HasColumnType("text")
               .IsRequired();

        builder.Property(x => x.Occasion)
               .HasMaxLength(100);

        builder.Property(x => x.Tone)
               .HasMaxLength(100);

        builder.Property(x => x.Language)
               .HasMaxLength(20)
               .HasDefaultValue("en");

        builder.Property(x => x.ImageUrl)
               .HasMaxLength(1000);

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

        builder.HasIndex(x => x.Slug)
               .IsUnique();

        builder.HasIndex(x => x.CategoryId);
        builder.HasIndex(x => x.Occasion);
        builder.HasIndex(x => x.Tone);
        builder.HasIndex(x => x.Language);
        builder.HasIndex(x => x.IsActive);
        builder.HasIndex(x => x.SortOrder);
        builder.HasIndex(x => x.UpdatedAtUtc);
    }
}
