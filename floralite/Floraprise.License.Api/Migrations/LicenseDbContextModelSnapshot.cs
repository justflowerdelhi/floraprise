using System;
using Floraprise.License.Api.Data;
using Floraprise.License.Api.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;

#nullable disable

namespace Floraprise.License.Api.Migrations;

[DbContext(typeof(LicenseDbContext))]
partial class LicenseDbContextModelSnapshot : ModelSnapshot
{
    protected override void BuildModel(ModelBuilder modelBuilder)
    {
        modelBuilder.HasAnnotation("ProductVersion", "10.0.0");

        modelBuilder.Entity("Floraprise.License.Api.Entities.Customer", entity =>
        {
            entity.Property<Guid>("Id").ValueGeneratedOnAdd().HasColumnType("uuid");
            entity.Property<string>("BusinessName").IsRequired().HasMaxLength(160).HasColumnType("character varying(160)");
            entity.Property<string>("City").HasMaxLength(100).HasColumnType("character varying(100)");
            entity.Property<string>("Country").IsRequired().HasMaxLength(100).HasColumnType("character varying(100)");
            entity.Property<DateTime>("CreatedAt").HasColumnType("timestamp with time zone");
            entity.Property<string>("Email").HasMaxLength(160).HasColumnType("character varying(160)");
            entity.Property<string>("Mobile").IsRequired().HasMaxLength(32).HasColumnType("character varying(32)");
            entity.Property<string>("OwnerName").IsRequired().HasMaxLength(120).HasColumnType("character varying(120)");
            entity.Property<string>("State").IsRequired().HasMaxLength(100).HasColumnType("character varying(100)");
            entity.HasKey("Id");
            entity.HasIndex("Mobile").IsUnique();
            entity.ToTable("Customers");
        });

        modelBuilder.Entity("Floraprise.License.Api.Entities.Device", entity =>
        {
            entity.Property<Guid>("Id").ValueGeneratedOnAdd().HasColumnType("uuid");
            entity.Property<string>("AndroidVersion").HasMaxLength(80).HasColumnType("character varying(80)");
            entity.Property<string>("AppVersion").IsRequired().HasMaxLength(40).HasColumnType("character varying(40)");
            entity.Property<Guid>("CustomerId").HasColumnType("uuid");
            entity.Property<string>("DeviceId").IsRequired().HasMaxLength(120).HasColumnType("character varying(120)");
            entity.Property<DateTime>("LastSeen").HasColumnType("timestamp with time zone");
            entity.Property<string>("Model").HasMaxLength(120).HasColumnType("character varying(120)");
            entity.Property<string>("Platform").IsRequired().HasMaxLength(40).HasColumnType("character varying(40)");
            entity.Property<DateTime>("RegisteredAt").HasColumnType("timestamp with time zone");
            entity.HasKey("Id");
            entity.HasIndex("CustomerId", "DeviceId").IsUnique();
            entity.ToTable("Devices");
        });

        modelBuilder.Entity("Floraprise.License.Api.Entities.License", entity =>
        {
            entity.Property<Guid>("Id").ValueGeneratedOnAdd().HasColumnType("uuid");
            entity.Property<DateTime>("CreatedAt").HasColumnType("timestamp with time zone");
            entity.Property<Guid>("CustomerId").HasColumnType("uuid");
            entity.Property<DateTime?>("LicenseEnd").HasColumnType("timestamp with time zone");
            entity.Property<DateTime?>("LicenseStart").HasColumnType("timestamp with time zone");
            entity.Property<LicensePlan>("Plan").HasMaxLength(40).HasColumnType("character varying(40)").HasConversion<string>();
            entity.Property<LicenseStatus>("Status").HasMaxLength(40).HasColumnType("character varying(40)").HasConversion<string>();
            entity.Property<DateTime>("TrialEnd").HasColumnType("timestamp with time zone");
            entity.Property<DateTime>("TrialStart").HasColumnType("timestamp with time zone");
            entity.HasKey("Id");
            entity.HasIndex("CustomerId").IsUnique();
            entity.ToTable("Licenses");
        });

        modelBuilder.Entity("Floraprise.License.Api.Entities.Device", entity =>
        {
            entity.HasOne("Floraprise.License.Api.Entities.Customer", "Customer")
                .WithMany("Devices")
                .HasForeignKey("CustomerId")
                .OnDelete(DeleteBehavior.Cascade)
                .IsRequired();
            entity.Navigation("Customer");
        });

        modelBuilder.Entity("Floraprise.License.Api.Entities.License", entity =>
        {
            entity.HasOne("Floraprise.License.Api.Entities.Customer", "Customer")
                .WithOne("License")
                .HasForeignKey("Floraprise.License.Api.Entities.License", "CustomerId")
                .OnDelete(DeleteBehavior.Cascade)
                .IsRequired();
            entity.Navigation("Customer");
        });

        modelBuilder.Entity("Floraprise.License.Api.Entities.Customer", entity =>
        {
            entity.Navigation("Devices");
            entity.Navigation("License");
        });
    }
}