using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Infrastructure.Persistence.Configurations;

public class LibraryWeddingDateConfiguration : IEntityTypeConfiguration<LibraryWeddingDate>
{
    public void Configure(EntityTypeBuilder<LibraryWeddingDate> builder)
    {
        builder.ToTable("LibraryWeddingDates");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.Title)
               .HasMaxLength(200)
               .IsRequired();

        builder.Property(x => x.Slug)
               .HasMaxLength(200)
               .IsRequired();

        builder.Property(x => x.WeddingDate)
               .HasColumnType("timestamptz")
               .IsRequired();

        builder.Property(x => x.Tithi)
               .HasMaxLength(200);

        builder.Property(x => x.Nakshatra)
               .HasMaxLength(200);

        builder.Property(x => x.Notes)
               .HasColumnType("text");

        builder.Property(x => x.Season)
               .HasMaxLength(100);

        builder.Property(x => x.DemandLevel)
               .HasMaxLength(50)
               .HasDefaultValue("High");

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

        builder.HasIndex(x => x.Slug)
               .IsUnique();

        builder.HasIndex(x => x.WeddingDate);
        builder.HasIndex(x => x.DemandLevel);
        builder.HasIndex(x => x.Season);
        builder.HasIndex(x => x.IsActive);
        builder.HasIndex(x => x.SortOrder);
        builder.HasIndex(x => x.UpdatedAtUtc);
    }
}
