using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.EntityFrameworkCore.Storage;
using Sumpooj.API.Controllers.Mobile;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Mobile;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;
using Xunit;

namespace Floraprise.Mobile.Tests;

public sealed class MobileSettingsControllerTests
{
    private readonly Guid _companyId = Guid.NewGuid();
    private readonly Guid _otherCompanyId = Guid.NewGuid();
    private readonly InMemoryDatabaseRoot _databaseRoot = new();

    private SumpoojDbContext CreateDb(Guid? companyId = null)
    {
        var options = new DbContextOptionsBuilder<SumpoojDbContext>()
            .UseInMemoryDatabase($"MobileSettingsTest_{Guid.NewGuid():N}", _databaseRoot)
            .ConfigureWarnings(w => w.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options;

 return new SumpoojDbContext(options, new TestTenantContext(companyId ?? _companyId));
 }

 private MobileSettingsController Controller(SumpoojDbContext db, Guid? companyId = null) =>
 new(db, new TestTenantContext(companyId ?? _companyId));

 [Fact]
 public async Task GetShareBranding_WhenNoRow_ReturnsDefaults()
 {
 await using var db = CreateDb();
 var controller = Controller(db);

 var result = await controller.GetShareBranding(CancellationToken.None);
 var dto = AssertOk<ShareBrandingSettingsDto>(result);

 Assert.Equal(_companyId, dto.CompanyId);
 Assert.True(dto.ShowPrice);
 Assert.True(dto.ShowShopName);
 Assert.True(dto.ShowPhoneNumber);
 Assert.True(dto.ShowWebsite);
 Assert.False(dto.ShowLogo);
 Assert.True(dto.ShowWatermark);
 Assert.True(dto.ShowWatermarkBusinessName);
 Assert.True(dto.ShowWatermarkCity);
 Assert.Equal(0.72, dto.WatermarkOpacity);
 Assert.Equal("medium", dto.WatermarkSize);
 Assert.Equal("bottomCenter", dto.WatermarkPosition);
 Assert.Equal(0xCC1B5E20, dto.FooterColorArgb);
 }

 [Fact]
 public async Task PutShareBranding_PersistsAndReturnsUpdatedDto()
 {
 await using var db = CreateDb();
 var controller = Controller(db);

 var request = new UpdateShareBrandingSettingsRequest(
 ShowPrice: false,
 ShowShopName: true,
 ShowPhoneNumber: false,
 ShowWebsite: true,
 ShowLogo: true,
 ShowWatermark: true,
 ShowWatermarkBusinessName: false,
 ShowWatermarkCity: true,
 WatermarkOpacity: 0.85,
 WatermarkSize: "large",
 WatermarkPosition: "topRight",
 FooterColorArgb: 0xFF336699);

 var putResult = await controller.UpdateShareBranding(request, CancellationToken.None);
 var putDto = AssertOk<ShareBrandingSettingsDto>(putResult);

 Assert.Equal(_companyId, putDto.CompanyId);
 Assert.False(putDto.ShowPrice);
 Assert.True(putDto.ShowLogo);
 Assert.Equal(0.85, putDto.WatermarkOpacity);
 Assert.Equal("large", putDto.WatermarkSize);
 Assert.Equal("topRight", putDto.WatermarkPosition);

 // Subsequent GET returns persisted row
 var getResult = await controller.GetShareBranding(CancellationToken.None);
 var getDto = AssertOk<ShareBrandingSettingsDto>(getResult);

 Assert.False(getDto.ShowPrice);
 Assert.True(getDto.ShowLogo);
 Assert.Equal(0.85, getDto.WatermarkOpacity);
 Assert.Equal("large", getDto.WatermarkSize);
 Assert.Equal("topRight", getDto.WatermarkPosition);
 }

 [Theory]
 [InlineData(0.1, "medium", "bottomCenter")]
 [InlineData(1.5, "medium", "bottomCenter")]
 [InlineData(0.5, "huge", "bottomCenter")]
 [InlineData(0.5, "medium", "invalidCorner")]
 public async Task PutShareBranding_ValidatesRangesAndEnums(double opacity, string size, string position)
 {
 await using var db = CreateDb();
 var controller = Controller(db);

 var request = new UpdateShareBrandingSettingsRequest(
 ShowPrice: true,
 ShowShopName: true,
 ShowPhoneNumber: true,
 ShowWebsite: true,
 ShowLogo: false,
 ShowWatermark: true,
 ShowWatermarkBusinessName: true,
 ShowWatermarkCity: true,
 WatermarkOpacity: opacity,
 WatermarkSize: size,
 WatermarkPosition: position,
 FooterColorArgb: 0xCC1B5E20);

 var result = await controller.UpdateShareBranding(request, CancellationToken.None);
 Assert.IsType<BadRequestObjectResult>(result);
 }

 [Fact]
 public async Task GetRewards_WhenNoRow_ReturnsDefaults()
 {
 await using var db = CreateDb();
 var controller = Controller(db);

 var result = await controller.GetRewards(CancellationToken.None);
 var dto = AssertOk<RewardsSettingsDto>(result);

 Assert.Equal(_companyId, dto.CompanyId);
 Assert.True(dto.Enabled);
 Assert.Equal(10000, dto.EarnSpendPaisePerPoint);
 Assert.Equal(30000, dto.MinimumBillPaise);
 Assert.Equal(100, dto.PointValuePaise);
 Assert.Equal(20, dto.MaximumRedemptionPercent);
 Assert.Equal(365, dto.ExpiryDays);
 }

 [Fact]
 public async Task PutRewards_PersistsAndReturnsUpdatedDto()
 {
 await using var db = CreateDb();
 var controller = Controller(db);

 var request = new UpdateRewardsSettingsRequest(
 Enabled: false,
 EarnSpendPaisePerPoint: 8000,
 MinimumBillPaise: 25000,
 PointValuePaise: 200,
 MaximumRedemptionPercent: 15,
 ExpiryDays: 180);

 var putResult = await controller.UpdateRewards(request, CancellationToken.None);
 var putDto = AssertOk<RewardsSettingsDto>(putResult);

 Assert.Equal(_companyId, putDto.CompanyId);
 Assert.False(putDto.Enabled);
 Assert.Equal(8000, putDto.EarnSpendPaisePerPoint);
 Assert.Equal(25000, putDto.MinimumBillPaise);
 Assert.Equal(200, putDto.PointValuePaise);
 Assert.Equal(15, putDto.MaximumRedemptionPercent);
 Assert.Equal(180, putDto.ExpiryDays);

 // Subsequent GET returns persisted row
 var getResult = await controller.GetRewards(CancellationToken.None);
 var getDto = AssertOk<RewardsSettingsDto>(getResult);

 Assert.False(getDto.Enabled);
 Assert.Equal(8000, getDto.EarnSpendPaisePerPoint);
 Assert.Equal(25000, getDto.MinimumBillPaise);
 Assert.Equal(200, getDto.PointValuePaise);
 }

 [Theory]
 [InlineData(0, 100, 100, 20, 365)]
 [InlineData(-5, 100, 100, 20, 365)]
 [InlineData(100, -1, 100, 20, 365)]
 [InlineData(100, 100, 0, 20, 365)]
 [InlineData(100, 100, 100, -1, 365)]
 [InlineData(100, 100, 100, 101, 365)]
 [InlineData(100, 100, 100, 20, 0)]
 public async Task PutRewards_ValidatesFinancialRanges(
 int earnSpend,
 int minBill,
 int pointValue,
 int maxRedemption,
 int expiryDays)
 {
 await using var db = CreateDb();
 var controller = Controller(db);

 var request = new UpdateRewardsSettingsRequest(
 Enabled: true,
 EarnSpendPaisePerPoint: earnSpend,
 MinimumBillPaise: minBill,
 PointValuePaise: pointValue,
 MaximumRedemptionPercent: maxRedemption,
 ExpiryDays: expiryDays);

 var result = await controller.UpdateRewards(request, CancellationToken.None);
 Assert.IsType<BadRequestObjectResult>(result);
 }

 [Fact]
 public async Task TenantIsolation_CompanyCannotReadOrModifyOtherTenantSettings()
 {
 await using var db = CreateDb();

 // Company A saves custom branding and rewards
 var controllerA = Controller(db, _companyId);
 await controllerA.UpdateShareBranding(new UpdateShareBrandingSettingsRequest(
 ShowPrice: false,
 ShowShopName: false,
 ShowPhoneNumber: false,
 ShowWebsite: false,
 ShowLogo: true,
 ShowWatermark: false,
 ShowWatermarkBusinessName: false,
 ShowWatermarkCity: false,
 WatermarkOpacity: 0.5,
 WatermarkSize: "small",
 WatermarkPosition: "topLeft",
 FooterColorArgb: 0xCC112233), CancellationToken.None);

 await controllerA.UpdateRewards(new UpdateRewardsSettingsRequest(
 Enabled: false,
 EarnSpendPaisePerPoint: 4444,
 MinimumBillPaise: 1111,
 PointValuePaise: 50,
 MaximumRedemptionPercent: 10,
 ExpiryDays: 30), CancellationToken.None);

 // Company B accesses settings via controller scoped to _otherCompanyId
 var controllerB = Controller(db, _otherCompanyId);

 var brandingB = AssertOk<ShareBrandingSettingsDto>(await controllerB.GetShareBranding(CancellationToken.None));
 var rewardsB = AssertOk<RewardsSettingsDto>(await controllerB.GetRewards(CancellationToken.None));

 // Company B sees defaults, NOT Company A custom values!
 Assert.Equal(_otherCompanyId, brandingB.CompanyId);
 Assert.True(brandingB.ShowPrice);
 Assert.Equal("medium", brandingB.WatermarkSize);

 Assert.Equal(_otherCompanyId, rewardsB.CompanyId);
 Assert.True(rewardsB.Enabled);
 Assert.Equal(10000, rewardsB.EarnSpendPaisePerPoint);
 }

 private static T AssertOk<T>(IActionResult result)
 {
 var ok = Assert.IsType<OkObjectResult>(result);
 return Assert.IsType<T>(ok.Value);
 }

 private sealed class TestTenantContext : ITenantContext
 {
 public TestTenantContext(Guid companyId) => CompanyId = companyId;
 public Guid? CompanyId { get; }
 public string? Region => null;
 public bool IsPlatformUser => false;
 }
}
