import 'dart:ui';

enum DesignShareVariant {
  brandedPreview,
  quotation,
}

enum WatermarkSize { small, medium, large }

enum WatermarkPosition {
  topLeft,
  topCenter,
  topRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

class ShareBrandingSettings {
  const ShareBrandingSettings({
    required this.showPrice,
    required this.showShopName,
    required this.showPhoneNumber,
    required this.showLogo,
    required this.showWatermark,
    required this.showWatermarkBusinessName,
    required this.showWatermarkCity,
    required this.watermarkOpacity,
    required this.watermarkSize,
    required this.watermarkPosition,
    required this.showWebsite,
    required this.footerColor,
  });

  final bool showPrice;
  final bool showShopName;
  final bool showPhoneNumber;
  final bool showLogo;
  final bool showWatermark;
  final bool showWatermarkBusinessName;
  final bool showWatermarkCity;
  final double watermarkOpacity;
  final WatermarkSize watermarkSize;
  final WatermarkPosition watermarkPosition;
  final bool showWebsite;
  final Color footerColor;

  ShareBrandingSettings copyWith({
    bool? showPrice,
    bool? showShopName,
    bool? showPhoneNumber,
    bool? showLogo,
    bool? showWatermark,
    bool? showWatermarkBusinessName,
    bool? showWatermarkCity,
    double? watermarkOpacity,
    WatermarkSize? watermarkSize,
    WatermarkPosition? watermarkPosition,
    bool? showWebsite,
    Color? footerColor,
  }) {
    return ShareBrandingSettings(
      showPrice: showPrice ?? this.showPrice,
      showShopName: showShopName ?? this.showShopName,
      showPhoneNumber: showPhoneNumber ?? this.showPhoneNumber,
      showLogo: showLogo ?? this.showLogo,
      showWatermark: showWatermark ?? this.showWatermark,
      showWatermarkBusinessName:
          showWatermarkBusinessName ?? this.showWatermarkBusinessName,
      showWatermarkCity: showWatermarkCity ?? this.showWatermarkCity,
      watermarkOpacity: watermarkOpacity ?? this.watermarkOpacity,
      watermarkSize: watermarkSize ?? this.watermarkSize,
      watermarkPosition: watermarkPosition ?? this.watermarkPosition,
      showWebsite: showWebsite ?? this.showWebsite,
      footerColor: footerColor ?? this.footerColor,
    );
  }
}

class ShareBrandingIdentity {
  const ShareBrandingIdentity({
    required this.shopName,
    required this.phoneNumber,
    required this.logoPath,
    required this.website,
    required this.instagram,
    required this.facebook,
    required this.address,
    required this.city,
  });

  final String shopName;
  final String phoneNumber;
  final String logoPath;
  final String website;
  final String instagram;
  final String facebook;
  final String address;
  final String city;

  String get watermarkText => shopName;
}
