using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;
using Xunit;

namespace Floraprise.Mobile.Tests;

public sealed class ProductionCompatibilityTests
{
    [Fact]
    public void SubscriptionPlan_IncludedModulesJson_MapsStringToText()
    {
        var options = new DbContextOptionsBuilder<SumpoojDbContext>()
            .UseNpgsql("Host=localhost;Database=model_metadata_only")
            .Options;
        using var context = new SumpoojDbContext(options);

        var property = context.Model.FindEntityType(typeof(SubscriptionPlan))!
            .FindProperty(nameof(SubscriptionPlan.IncludedModulesJson))!;

        Assert.Equal(typeof(string), property.ClrType);
        Assert.Equal("text", property.GetColumnType());
    }

    [Fact]
    public void Delivery_DestinationCoordinates_MapToProductionColumns()
    {
        var options = new DbContextOptionsBuilder<SumpoojDbContext>()
            .UseNpgsql("Host=localhost;Database=model_metadata_only")
            .Options;
        using var context = new SumpoojDbContext(options);

        var delivery = context.Model.FindEntityType(typeof(Delivery))!;
        var table = StoreObjectIdentifier.Table("Deliveries", null);
        var latitudeColumn = delivery
            .FindProperty(nameof(Delivery.DeliveryAddressLatitude))!
            .GetColumnName(table);
        var longitudeColumn = delivery
            .FindProperty(nameof(Delivery.DeliveryAddressLongitude))!
            .GetColumnName(table);

        Assert.Equal("DeliveryLatitude", latitudeColumn);
        Assert.Equal("DeliveryLongitude", longitudeColumn);
        Assert.NotEqual(nameof(Delivery.DeliveryAddressLatitude), latitudeColumn);
        Assert.NotEqual(nameof(Delivery.DeliveryAddressLongitude), longitudeColumn);
    }

    [Fact]
    public void NewMobileDevice_PopulatesModernAndLegacyCompatibilityValues()
    {
        var companyId = Guid.NewGuid();
        var mobileUserId = Guid.NewGuid();
        var identityUserId = Guid.NewGuid();

        var device = new MobileDevice(
            companyId,
            mobileUserId,
            identityUserId,
            " device-123 ",
            null,
            null,
            " android ",
            "14",
            "1.0.0",
            null);

        Assert.Equal(companyId, device.CompanyId);
        Assert.Equal(mobileUserId, device.MobileUserId);
        Assert.Equal(identityUserId, device.LegacyUserId);
        Assert.NotEqual(device.MobileUserId, device.LegacyUserId);
        Assert.Equal("device-123", device.DeviceId);
        Assert.Equal(device.DeviceId, device.DeviceFingerprintHash);
        Assert.Equal("android", device.DeviceName);
    }
}