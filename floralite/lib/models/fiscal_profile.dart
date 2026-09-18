/// Shared Fiscal Profile and Country Presets for Floraprise.
/// Supports Floraprise Solo (local SQLite), Floraprise Pro (Android cloud),
/// and Floraprise Pro Web (cloud).
class FiscalProfile {
  final String countryCode;
  final String currencyCode;
  final String currencySymbol;
  final bool taxEnabled;
  final String taxLabel;
  final double taxRatePercent;
  final bool taxInclusive;
  final String? taxIdentifier;
  final String locale;
  final String timeZone;

  const FiscalProfile({
    required this.countryCode,
    required this.currencyCode,
    required this.currencySymbol,
    this.taxEnabled = true,
    required this.taxLabel,
    required this.taxRatePercent,
    required this.taxInclusive,
    this.taxIdentifier,
    required this.locale,
    required this.timeZone,
  });

  FiscalProfile copyWith({
    String? countryCode,
    String? currencyCode,
    String? currencySymbol,
    bool? taxEnabled,
    String? taxLabel,
    double? taxRatePercent,
    bool? taxInclusive,
    String? taxIdentifier,
    String? locale,
    String? timeZone,
  }) {
    return FiscalProfile(
      countryCode: countryCode ?? this.countryCode,
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      taxEnabled: taxEnabled ?? this.taxEnabled,
      taxLabel: taxLabel ?? this.taxLabel,
      taxRatePercent: taxRatePercent ?? this.taxRatePercent,
      taxInclusive: taxInclusive ?? this.taxInclusive,
      taxIdentifier: taxIdentifier ?? this.taxIdentifier,
      locale: locale ?? this.locale,
      timeZone: timeZone ?? this.timeZone,
    );
  }

  /// Returns the standard tax identifier label for this country/fiscal profile
  /// (e.g. 'GSTIN' for India, 'TRN' for UAE, 'Tax ID / EIN' for USA).
  String get taxIdentifierLabel {
    switch (countryCode.toUpperCase()) {
      case 'AE':
        return 'TRN';
      case 'US':
        return 'Tax ID / EIN';
      case 'IN':
      default:
        return 'GSTIN';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'country_code': countryCode,
      'currency_code': currencyCode,
      'currency_symbol': currencySymbol,
      'tax_enabled': taxEnabled ? 1 : 0,
      'tax_label': taxLabel,
      'tax_rate_percent': taxRatePercent,
      'tax_inclusive': taxInclusive ? 1 : 0,
      'tax_identifier': taxIdentifier,
      'locale': locale,
      'time_zone': timeZone,
    };
  }

  factory FiscalProfile.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) {
      return CountryPresets.india();
    }

    final rawCountryCode = map['country_code']?.toString().trim();
    final fallbackPreset = CountryPresets.forCountry(rawCountryCode);

    final rawTaxEnabled = map['tax_enabled'];
    final taxEnabled = rawTaxEnabled == null
        ? fallbackPreset.taxEnabled
        : (rawTaxEnabled is bool
            ? rawTaxEnabled
            : (rawTaxEnabled is num
                ? rawTaxEnabled != 0
                : rawTaxEnabled.toString().toLowerCase() == 'true' ||
                    rawTaxEnabled.toString() == '1'));

    final rawTaxInclusive = map['tax_inclusive'];
    final taxInclusive = rawTaxInclusive == null
        ? fallbackPreset.taxInclusive
        : (rawTaxInclusive is bool
            ? rawTaxInclusive
            : (rawTaxInclusive is num
                ? rawTaxInclusive != 0
                : rawTaxInclusive.toString().toLowerCase() == 'true' ||
                    rawTaxInclusive.toString() == '1'));

    final rawTaxRate = map['tax_rate_percent'];
    final double taxRatePercent;
    if (rawTaxRate is num) {
      taxRatePercent = rawTaxRate.toDouble();
    } else if (rawTaxRate != null) {
      taxRatePercent =
          double.tryParse(rawTaxRate.toString()) ?? fallbackPreset.taxRatePercent;
    } else {
      taxRatePercent = fallbackPreset.taxRatePercent;
    }

    return FiscalProfile(
      countryCode: map['country_code']?.toString().trim().isNotEmpty == true
          ? map['country_code'].toString().trim().toUpperCase()
          : fallbackPreset.countryCode,
      currencyCode: map['currency_code']?.toString().trim().isNotEmpty == true
          ? map['currency_code'].toString().trim().toUpperCase()
          : fallbackPreset.currencyCode,
      currencySymbol: map['currency_symbol']?.toString().trim().isNotEmpty == true
          ? map['currency_symbol'].toString().trim()
          : fallbackPreset.currencySymbol,
      taxEnabled: taxEnabled,
      taxLabel: map['tax_label']?.toString().trim().isNotEmpty == true
          ? map['tax_label'].toString().trim()
          : fallbackPreset.taxLabel,
      taxRatePercent: taxRatePercent,
      taxInclusive: taxInclusive,
      taxIdentifier: map['tax_identifier']?.toString().trim(),
      locale: map['locale']?.toString().trim().isNotEmpty == true
          ? map['locale'].toString().trim()
          : fallbackPreset.locale,
      timeZone: map['time_zone']?.toString().trim().isNotEmpty == true
          ? map['time_zone'].toString().trim()
          : fallbackPreset.timeZone,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory FiscalProfile.fromJson(Map<String, dynamic> json) =>
      FiscalProfile.fromMap(json);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FiscalProfile &&
        other.countryCode == countryCode &&
        other.currencyCode == currencyCode &&
        other.currencySymbol == currencySymbol &&
        other.taxEnabled == taxEnabled &&
        other.taxLabel == taxLabel &&
        other.taxRatePercent == taxRatePercent &&
        other.taxInclusive == taxInclusive &&
        other.taxIdentifier == taxIdentifier &&
        other.locale == locale &&
        other.timeZone == timeZone;
  }

  @override
  int get hashCode => Object.hash(
        countryCode,
        currencyCode,
        currencySymbol,
        taxEnabled,
        taxLabel,
        taxRatePercent,
        taxInclusive,
        taxIdentifier,
        locale,
        timeZone,
      );

  @override
  String toString() {
    return 'FiscalProfile(countryCode: $countryCode, currencyCode: $currencyCode, symbol: $currencySymbol, taxEnabled: $taxEnabled, taxLabel: $taxLabel, taxRate: $taxRatePercent%, inclusive: $taxInclusive, taxId: $taxIdentifier, locale: $locale, timeZone: $timeZone)';
  }
}

/// Single source of truth for Country Presets in Floraprise.
class CountryPresets {
  CountryPresets._();

  /// India preset: IN / INR / ₹ / GST / 18% / inclusive / en_IN / Asia/Kolkata
  static FiscalProfile india() {
    return const FiscalProfile(
      countryCode: 'IN',
      currencyCode: 'INR',
      currencySymbol: '₹',
      taxEnabled: true,
      taxLabel: 'GST',
      taxRatePercent: 18.0,
      taxInclusive: true,
      taxIdentifier: null,
      locale: 'en_IN',
      timeZone: 'Asia/Kolkata',
    );
  }

  /// UAE preset: AE / AED / د.إ / VAT / 5% / inclusive / en_AE / Asia/Dubai
  static FiscalProfile uae() {
    return const FiscalProfile(
      countryCode: 'AE',
      currencyCode: 'AED',
      currencySymbol: 'د.إ',
      taxEnabled: true,
      taxLabel: 'VAT',
      taxRatePercent: 5.0,
      taxInclusive: true,
      taxIdentifier: null,
      locale: 'en_AE',
      timeZone: 'Asia/Dubai',
    );
  }

  /// USA preset: US / USD / $ / Sales Tax / 0% (merchant configurable) / exclusive / en_US / America/New_York
  static FiscalProfile usa() {
    return const FiscalProfile(
      countryCode: 'US',
      currencyCode: 'USD',
      currencySymbol: '\$',
      taxEnabled: true,
      taxLabel: 'Sales Tax',
      taxRatePercent: 0.0,
      taxInclusive: false,
      taxIdentifier: null,
      locale: 'en_US',
      timeZone: 'America/New_York',
    );
  }

  /// Resolves the default fiscal preset for a country code.
  /// Falls back to India defaults for backward compatibility.
  static FiscalProfile forCountry(String? code) {
    if (code == null || code.trim().isEmpty) {
      return india();
    }
    final normalized = code.trim().toUpperCase();
    switch (normalized) {
      case 'IN':
      case 'IND':
      case 'INDIA':
        return india();
      case 'AE':
      case 'ARE':
      case 'UAE':
        return uae();
      case 'US':
      case 'USA':
      case 'UNITED STATES':
        return usa();
      default:
        return india();
    }
  }

  /// Resolves the default country code from a currency ISO code.
  static String countryCodeForCurrency(String? currency) {
    if (currency == null || currency.trim().isEmpty) return 'IN';
    switch (currency.trim().toUpperCase()) {
      case 'AED':
        return 'AE';
      case 'USD':
        return 'US';
      case 'INR':
      default:
        return 'IN';
    }
  }

  /// List of supported country presets.
  static List<FiscalProfile> get allPresets => [
        india(),
        uae(),
        usa(),
      ];
}
