using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Infrastructure.Persistence.Configurations;

public class LibraryTutorialConfiguration : IEntityTypeConfiguration<LibraryTutorial>
{
    public void Configure(EntityTypeBuilder<LibraryTutorial> builder)
    {
        builder.ToTable("LibraryTutorials");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.Title)
               .HasMaxLength(200)
               .IsRequired();

        builder.Property(x => x.Slug)
               .HasMaxLength(200)
               .IsRequired();

        builder.Property(x => x.Summary)
               .HasColumnType("text");

        builder.Property(x => x.ContentMarkdown)
               .HasColumnType("text")
               .IsRequired();

        builder.Property(x => x.VideoUrl)
               .HasMaxLength(1000);

        builder.Property(x => x.ThumbnailUrl)
               .HasMaxLength(1000);

        builder.Property(x => x.DifficultyLevel)
               .HasMaxLength(50)
               .HasDefaultValue("Beginner");

        builder.Property(x => x.EstimatedReadingMinutes)
               .HasDefaultValue(5);

        builder.Property(x => x.Tags)
               .HasMaxLength(500);

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
        builder.HasIndex(x => x.DifficultyLevel);
        builder.HasIndex(x => x.IsActive);
        builder.HasIndex(x => x.SortOrder);
        builder.HasIndex(x => x.UpdatedAtUtc);
    }
}
