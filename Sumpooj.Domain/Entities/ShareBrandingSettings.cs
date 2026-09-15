namespace Sumpooj.Domain.Entities;

public class ShareBrandingSettings : BaseEntity
{
    private ShareBrandingSettings() { }

    public ShareBrandingSettings(
        Guid companyId,
        bool showPrice = true,
        bool showShopName = true,
        bool showPhoneNumber = true,
        bool showWebsite = true,
        bool showLogo = false,
        bool showWatermark = true,
        bool showWatermarkBusinessName = true,
        bool showWatermarkCity = true,
        double watermarkOpacity = 0.72,
        string watermarkSize = "medium",
        string watermarkPosition = "bottomCenter",
        long footerColorArgb = 0xCC1B5E20)
    {
        if (companyId == Guid.Empty)
            throw new ArgumentException("CompanyId is required.", nameof(companyId));

        CompanyId = companyId;
        Update(
            showPrice,
            showShopName,
            showPhoneNumber,
            showWebsite,
            showLogo,
            showWatermark,
            showWatermarkBusinessName,
            showWatermarkCity,
            watermarkOpacity,
            watermarkSize,
            watermarkPosition,
            footerColorArgb);
    }

    public Guid CompanyId { get; private set; }

    public bool ShowPrice { get; private set; } = true;
    public bool ShowShopName { get; private set; } = true;
    public bool ShowPhoneNumber { get; private set; } = true;
    public bool ShowWebsite { get; private set; } = true;
    public bool ShowLogo { get; private set; } = false;
    public bool ShowWatermark { get; private set; } = true;
    public bool ShowWatermarkBusinessName { get; private set; } = true;
    public bool ShowWatermarkCity { get; private set; } = true;
    public double WatermarkOpacity { get; private set; } = 0.72;
    public string WatermarkSize { get; private set; } = "medium";
    public string WatermarkPosition { get; private set; } = "bottomCenter";
    public long FooterColorArgb { get; private set; } = 0xCC1B5E20;

    public void Update(
        bool showPrice,
        bool showShopName,
        bool showPhoneNumber,
        bool showWebsite,
        bool showLogo,
        bool showWatermark,
        bool showWatermarkBusinessName,
        bool showWatermarkCity,
        double watermarkOpacity,
        string watermarkSize,
        string watermarkPosition,
        long footerColorArgb)
    {
        ShowPrice = showPrice;
        ShowShopName = showShopName;
        ShowPhoneNumber = showPhoneNumber;
        ShowWebsite = showWebsite;
        ShowLogo = showLogo;
        ShowWatermark = showWatermark;
        ShowWatermarkBusinessName = showWatermarkBusinessName;
        ShowWatermarkCity = showWatermarkCity;
        WatermarkOpacity = watermarkOpacity;
        WatermarkSize = watermarkSize;
        WatermarkPosition = watermarkPosition;
        FooterColorArgb = footerColorArgb;
        MarkUpdated();
    }
}
