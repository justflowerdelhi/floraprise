using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Infrastructure.Persistence.Configurations;

public class ShareBrandingSettingsConfiguration : IEntityTypeConfiguration<ShareBrandingSettings>
{
    public void Configure(EntityTypeBuilder<ShareBrandingSettings> builder)
    {
        builder.ToTable("ShareBrandingSettings");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.CompanyId)
               .IsRequired();

        builder.HasIndex(x => x.CompanyId)
               .IsUnique();

        builder.HasOne<Company>()
               .WithMany()
               .HasForeignKey(x => x.CompanyId)
               .OnDelete(DeleteBehavior.Cascade);

        builder.Property(x => x.ShowPrice)
               .HasDefaultValue(true);

        builder.Property(x => x.ShowShopName)
               .HasDefaultValue(true);

        builder.Property(x => x.ShowPhoneNumber)
               .HasDefaultValue(true);

        builder.Property(x => x.ShowWebsite)
               .HasDefaultValue(true);

        builder.Property(x => x.ShowLogo)
               .HasDefaultValue(false);

        builder.Property(x => x.ShowWatermark)
               .HasDefaultValue(true);

        builder.Property(x => x.ShowWatermarkBusinessName)
               .HasDefaultValue(true);

        builder.Property(x => x.ShowWatermarkCity)
               .HasDefaultValue(true);

        builder.Property(x => x.WatermarkOpacity)
               .HasDefaultValue(0.72);

        builder.Property(x => x.WatermarkSize)
               .HasMaxLength(20)
               .HasDefaultValue("medium")
               .IsRequired();

        builder.Property(x => x.WatermarkPosition)
               .HasMaxLength(30)
               .HasDefaultValue("bottomCenter")
               .IsRequired();

        builder.Property(x => x.FooterColorArgb)
               .HasDefaultValue(0xCC1B5E20);

        builder.Property(x => x.CreatedAtUtc)
               .HasColumnType("timestamptz");

        builder.Property(x => x.UpdatedAtUtc)
               .HasColumnType("timestamptz");
    }
}
