using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Infrastructure.Persistence.Configurations;

public class LibraryFestivalConfiguration : IEntityTypeConfiguration<LibraryFestival>
{
    public void Configure(EntityTypeBuilder<LibraryFestival> builder)
    {
        builder.ToTable("LibraryFestivals");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.Name)
               .HasMaxLength(200)
               .IsRequired();

        builder.Property(x => x.Slug)
               .HasMaxLength(200)
               .IsRequired();

        builder.Property(x => x.FestivalDate)
               .HasColumnType("timestamptz")
               .IsRequired();

        builder.Property(x => x.Month)
               .IsRequired();

        builder.Property(x => x.Day)
               .IsRequired();

        builder.Property(x => x.Description)
               .HasColumnType("text");

        builder.Property(x => x.IsRecurring)
               .HasDefaultValue(true);

        builder.Property(x => x.FlowerDemands)
               .HasMaxLength(500);

        builder.Property(x => x.SearchKeywords)
               .HasMaxLength(1000);

        builder.Property(x => x.ImageUrl)
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

        builder.HasIndex(x => x.FestivalDate);
        builder.HasIndex(x => x.Month);
        builder.HasIndex(x => x.IsActive);
        builder.HasIndex(x => x.SortOrder);
        builder.HasIndex(x => x.UpdatedAtUtc);
    }
}
