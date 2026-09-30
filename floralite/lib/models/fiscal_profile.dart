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
    this.taxEnabled = false,
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
    bool clearTaxIdentifier = false,
    String? locale,
    String? timeZone,
  }) {
    String? resolvedTaxIdentifier;
    if (clearTaxIdentifier) {
      resolvedTaxIdentifier = null;
    } else if (taxIdentifier != null) {
      resolvedTaxIdentifier =
          taxIdentifier.trim().isEmpty ? null : taxIdentifier.trim();
    } else {
      resolvedTaxIdentifier = this.taxIdentifier;
    }

    return FiscalProfile(
      countryCode: countryCode ?? this.countryCode,
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      taxEnabled: taxEnabled ?? this.taxEnabled,
      taxLabel: taxLabel ?? this.taxLabel,
      taxRatePercent: taxRatePercent ?? this.taxRatePercent,
      taxInclusive: taxInclusive ?? this.taxInclusive,
      taxIdentifier: resolvedTaxIdentifier,
      locale: locale ?? this.locale,
      timeZone: timeZone ?? this.timeZone,
    );
  }

  /// Returns the standard tax identifier label for this country/fiscal profile
  /// (e.g. 'GSTIN' for India, 'TRN' for UAE, 'Tax ID / EIN' for USA, 'VAT Reg No' for UK).
  String get taxIdentifierLabel {
    switch (countryCode.toUpperCase()) {
      case 'AE':
      case 'SA':
      case 'BH':
      case 'OM':
        return 'TRN';
      case 'US':
        return 'Tax ID / EIN';
      case 'GB':
        return 'VAT Reg No';
      case 'CA':
        return 'BN / GST No';
      case 'AU':
        return 'ABN';
      case 'DE':
      case 'FR':
      case 'IT':
      case 'ES':
      case 'NL':
      case 'EU':
        return 'VAT / Tax ID';
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
/// Descriptor for supported currencies in Floraprise.
class CurrencyDescriptor {
  final String code;
  final String name;
  final String symbol;

  const CurrencyDescriptor({
    required this.code,
    required this.name,
    required this.symbol,
  });

  String get displayLabel => '$name ($code - $symbol)';
  String get shortLabel => '$code ($symbol)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurrencyDescriptor &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

/// Descriptor for supported countries in Floraprise.
class CountryDescriptor {
  final String code;
  final String name;
  final String flag;
  final String defaultCurrencyCode;
  final String defaultCurrencySymbol;

  const CountryDescriptor({
    required this.code,
    required this.name,
    required this.flag,
    required this.defaultCurrencyCode,
    required this.defaultCurrencySymbol,
  });

  String get displayName => '$flag  $name ($defaultCurrencyCode - $defaultCurrencySymbol)';
  String get nameWithFlag => '$name $flag';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CountryDescriptor &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

/// Single source of truth for Country Presets and Currencies in Floraprise.
class CountryPresets {
  CountryPresets._();

  /// Supported currencies catalog
  static const List<CurrencyDescriptor> supportedCurrencies = [
    CurrencyDescriptor(code: 'INR', name: 'Indian Rupee', symbol: '₹'),
    CurrencyDescriptor(code: 'USD', name: 'US Dollar', symbol: r'$'),
    CurrencyDescriptor(code: 'AED', name: 'UAE Dirham', symbol: 'د.إ'),
    CurrencyDescriptor(code: 'GBP', name: 'British Pound', symbol: '£'),
    CurrencyDescriptor(code: 'EUR', name: 'Euro', symbol: '€'),
    CurrencyDescriptor(code: 'CAD', name: 'Canadian Dollar', symbol: r'CA$'),
    CurrencyDescriptor(code: 'AUD', name: 'Australian Dollar', symbol: r'A$'),
    CurrencyDescriptor(code: 'SGD', name: 'Singapore Dollar', symbol: r'S$'),
    CurrencyDescriptor(code: 'NZD', name: 'New Zealand Dollar', symbol: r'NZ$'),
    CurrencyDescriptor(code: 'SAR', name: 'Saudi Riyal', symbol: 'SAR'),
    CurrencyDescriptor(code: 'QAR', name: 'Qatari Riyal', symbol: 'QAR'),
    CurrencyDescriptor(code: 'KWD', name: 'Kuwaiti Dinar', symbol: 'KD'),
    CurrencyDescriptor(code: 'BHD', name: 'Bahraini Dinar', symbol: 'BD'),
    CurrencyDescriptor(code: 'OMR', name: 'Omani Rial', symbol: 'OMR'),
  ];

  /// Supported countries catalog with flags and default currency pairings
  static const List<CountryDescriptor> supportedCountries = [
    CountryDescriptor(
      code: 'IN',
      name: 'India',
      flag: '🇮🇳',
      defaultCurrencyCode: 'INR',
      defaultCurrencySymbol: '₹',
    ),
    CountryDescriptor(
      code: 'US',
      name: 'United States',
      flag: '🇺🇸',
      defaultCurrencyCode: 'USD',
      defaultCurrencySymbol: r'$',
    ),
    CountryDescriptor(
      code: 'AE',
      name: 'United Arab Emirates',
      flag: '🇦🇪',
      defaultCurrencyCode: 'AED',
      defaultCurrencySymbol: 'د.إ',
    ),
    CountryDescriptor(
      code: 'GB',
      name: 'United Kingdom',
      flag: '🇬🇧',
      defaultCurrencyCode: 'GBP',
      defaultCurrencySymbol: '£',
    ),
    CountryDescriptor(
      code: 'DE',
      name: 'Germany (EU)',
      flag: '🇩🇪',
      defaultCurrencyCode: 'EUR',
      defaultCurrencySymbol: '€',
    ),
    CountryDescriptor(
      code: 'FR',
      name: 'France (EU)',
      flag: '🇫🇷',
      defaultCurrencyCode: 'EUR',
      defaultCurrencySymbol: '€',
    ),
    CountryDescriptor(
      code: 'IT',
      name: 'Italy (EU)',
      flag: '🇮🇹',
      defaultCurrencyCode: 'EUR',
      defaultCurrencySymbol: '€',
    ),
    CountryDescriptor(
      code: 'ES',
      name: 'Spain (EU)',
      flag: '🇪🇸',
      defaultCurrencyCode: 'EUR',
      defaultCurrencySymbol: '€',
    ),
    CountryDescriptor(
      code: 'NL',
      name: 'Netherlands (EU)',
      flag: '🇳🇱',
      defaultCurrencyCode: 'EUR',
      defaultCurrencySymbol: '€',
    ),
    CountryDescriptor(
      code: 'CA',
      name: 'Canada',
      flag: '🇨🇦',
      defaultCurrencyCode: 'CAD',
      defaultCurrencySymbol: r'CA$',
    ),
    CountryDescriptor(
      code: 'AU',
      name: 'Australia',
      flag: '🇦🇺',
      defaultCurrencyCode: 'AUD',
      defaultCurrencySymbol: r'A$',
    ),
    CountryDescriptor(
      code: 'SG',
      name: 'Singapore',
      flag: '🇸🇬',
      defaultCurrencyCode: 'SGD',
      defaultCurrencySymbol: r'S$',
    ),
    CountryDescriptor(
      code: 'NZ',
      name: 'New Zealand',
      flag: '🇳🇿',
      defaultCurrencyCode: 'NZD',
      defaultCurrencySymbol: r'NZ$',
    ),
    CountryDescriptor(
      code: 'SA',
      name: 'Saudi Arabia',
      flag: '🇸🇦',
      defaultCurrencyCode: 'SAR',
      defaultCurrencySymbol: 'SAR',
    ),
    CountryDescriptor(
      code: 'QA',
      name: 'Qatar',
      flag: '🇶🇦',
      defaultCurrencyCode: 'QAR',
      defaultCurrencySymbol: 'QAR',
    ),
    CountryDescriptor(
      code: 'KW',
      name: 'Kuwait',
      flag: '🇰🇼',
      defaultCurrencyCode: 'KWD',
      defaultCurrencySymbol: 'KD',
    ),
    CountryDescriptor(
      code: 'BH',
      name: 'Bahrain',
      flag: '🇧🇭',
      defaultCurrencyCode: 'BHD',
      defaultCurrencySymbol: 'BD',
    ),
    CountryDescriptor(
      code: 'OM',
      name: 'Oman',
      flag: '🇴🇲',
      defaultCurrencyCode: 'OMR',
      defaultCurrencySymbol: 'OMR',
    ),
  ];

  /// Find CurrencyDescriptor by code (case-insensitive)
  static CurrencyDescriptor? currencyForCode(String? code) {
    if (code == null || code.trim().isEmpty) return null;
    final normalized = code.trim().toUpperCase();
    try {
      return supportedCurrencies.firstWhere(
        (c) => c.code.toUpperCase() == normalized,
      );
    } catch (_) {
      return null;
    }
  }

  /// Find CountryDescriptor by country code (case-insensitive)
  static CountryDescriptor? countryForCode(String? code) {
    if (code == null || code.trim().isEmpty) return null;
    final normalized = code.trim().toUpperCase();
    try {
      return supportedCountries.firstWhere(
        (c) => c.code.toUpperCase() == normalized,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get the default currency descriptor for a country code
  static CurrencyDescriptor defaultCurrencyForCountry(String? countryCode) {
    final preset = forCountry(countryCode);
    return currencyForCode(preset.currencyCode) ??
        const CurrencyDescriptor(code: 'INR', name: 'Indian Rupee', symbol: '₹');
  }

  /// India preset: IN / INR / ₹ / GST / 18% / inclusive / en_IN / Asia/Kolkata
  static FiscalProfile india() {
    return const FiscalProfile(
      countryCode: 'IN',
      currencyCode: 'INR',
      currencySymbol: '₹',
      taxEnabled: false,
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
      taxEnabled: false,
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
      currencySymbol: r'$',
      taxEnabled: false,
      taxLabel: 'Sales Tax',
      taxRatePercent: 0.0,
      taxInclusive: false,
      taxIdentifier: null,
      locale: 'en_US',
      timeZone: 'America/New_York',
    );
  }

  /// UK preset: GB / GBP / £ / VAT / 20% / inclusive / en_GB / Europe/London
  static FiscalProfile unitedKingdom() {
    return const FiscalProfile(
      countryCode: 'GB',
      currencyCode: 'GBP',
      currencySymbol: '£',
      taxEnabled: false,
      taxLabel: 'VAT',
      taxRatePercent: 20.0,
      taxInclusive: true,
      taxIdentifier: null,
      locale: 'en_GB',
      timeZone: 'Europe/London',
    );
  }

  /// Eurozone / Germany preset: DE / EUR / € / VAT / 19% / inclusive / de_DE / Europe/Berlin
  static FiscalProfile eurozone({String countryCode = 'DE', String locale = 'de_DE'}) {
    return FiscalProfile(
      countryCode: countryCode,
      currencyCode: 'EUR',
      currencySymbol: '€',
      taxEnabled: false,
      taxLabel: 'VAT',
      taxRatePercent: 19.0,
      taxInclusive: true,
      taxIdentifier: null,
      locale: locale,
      timeZone: 'Europe/Berlin',
    );
  }

  /// Canada preset: CA / CAD / CA$ / GST/HST / 5% / exclusive / en_CA / America/Toronto
  static FiscalProfile canada() {
    return const FiscalProfile(
      countryCode: 'CA',
      currencyCode: 'CAD',
      currencySymbol: r'CA$',
      taxEnabled: false,
      taxLabel: 'GST/HST',
      taxRatePercent: 5.0,
      taxInclusive: false,
      taxIdentifier: null,
      locale: 'en_CA',
      timeZone: 'America/Toronto',
    );
  }

  /// Australia preset: AU / AUD / A$ / GST / 10% / inclusive / en_AU / Australia/Sydney
  static FiscalProfile australia() {
    return const FiscalProfile(
      countryCode: 'AU',
      currencyCode: 'AUD',
      currencySymbol: r'A$',
      taxEnabled: false,
      taxLabel: 'GST',
      taxRatePercent: 10.0,
      taxInclusive: true,
      taxIdentifier: null,
      locale: 'en_AU',
      timeZone: 'Australia/Sydney',
    );
  }

  /// Singapore preset: SG / SGD / S$ / GST / 9% / inclusive / en_SG / Asia/Singapore
  static FiscalProfile singapore() {
    return const FiscalProfile(
      countryCode: 'SG',
      currencyCode: 'SGD',
      currencySymbol: r'S$',
      taxEnabled: false,
      taxLabel: 'GST',
      taxRatePercent: 9.0,
      taxInclusive: true,
      taxIdentifier: null,
      locale: 'en_SG',
      timeZone: 'Asia/Singapore',
    );
  }

  /// New Zealand preset: NZ / NZD / NZ$ / GST / 15% / inclusive / en_NZ / Pacific/Auckland
  static FiscalProfile newZealand() {
    return const FiscalProfile(
      countryCode: 'NZ',
      currencyCode: 'NZD',
      currencySymbol: r'NZ$',
      taxEnabled: false,
      taxLabel: 'GST',
      taxRatePercent: 15.0,
      taxInclusive: true,
      taxIdentifier: null,
      locale: 'en_NZ',
      timeZone: 'Pacific/Auckland',
    );
  }

  /// Saudi Arabia preset: SA / SAR / SAR / VAT / 15% / inclusive / ar_SA / Asia/Riyadh
  static FiscalProfile saudiArabia() {
    return const FiscalProfile(
      countryCode: 'SA',
      currencyCode: 'SAR',
      currencySymbol: 'SAR',
      taxEnabled: false,
      taxLabel: 'VAT',
      taxRatePercent: 15.0,
      taxInclusive: true,
      taxIdentifier: null,
      locale: 'en_SA',
      timeZone: 'Asia/Riyadh',
    );
  }

  /// Qatar preset: QA / QAR / QAR / 0% / en_QA / Asia/Qatar
  static FiscalProfile qatar() {
    return const FiscalProfile(
      countryCode: 'QA',
      currencyCode: 'QAR',
      currencySymbol: 'QAR',
      taxEnabled: false,
      taxLabel: 'VAT',
      taxRatePercent: 0.0,
      taxInclusive: true,
      taxIdentifier: null,
      locale: 'en_QA',
      timeZone: 'Asia/Qatar',
    );
  }

  /// Kuwait preset: KW / KWD / KD / 0% / en_KW / Asia/Kuwait
  static FiscalProfile kuwait() {
    return const FiscalProfile(
      countryCode: 'KW',
      currencyCode: 'KWD',
      currencySymbol: 'KD',
      taxEnabled: false,
      taxLabel: 'VAT',
      taxRatePercent: 0.0,
      taxInclusive: true,
      taxIdentifier: null,
      locale: 'en_KW',
      timeZone: 'Asia/Kuwait',
    );
  }

  /// Bahrain preset: BH / BHD / BD / VAT / 10% / inclusive / en_BH / Asia/Bahrain
  static FiscalProfile bahrain() {
    return const FiscalProfile(
      countryCode: 'BH',
      currencyCode: 'BHD',
      currencySymbol: 'BD',
      taxEnabled: false,
      taxLabel: 'VAT',
      taxRatePercent: 10.0,
      taxInclusive: true,
      taxIdentifier: null,
      locale: 'en_BH',
      timeZone: 'Asia/Bahrain',
    );
  }

  /// Oman preset: OM / OMR / OMR / VAT / 5% / inclusive / en_OM / Asia/Muscat
  static FiscalProfile oman() {
    return const FiscalProfile(
      countryCode: 'OM',
      currencyCode: 'OMR',
      currencySymbol: 'OMR',
      taxEnabled: false,
      taxLabel: 'VAT',
      taxRatePercent: 5.0,
      taxInclusive: true,
      taxIdentifier: null,
      locale: 'en_OM',
      timeZone: 'Asia/Muscat',
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
      case 'UNITED ARAB EMIRATES':
        return uae();
      case 'US':
      case 'USA':
      case 'UNITED STATES':
        return usa();
      case 'GB':
      case 'GBR':
      case 'UK':
      case 'UNITED KINGDOM':
        return unitedKingdom();
      case 'DE':
      case 'DEU':
      case 'GERMANY':
        return eurozone(countryCode: 'DE', locale: 'de_DE');
      case 'FR':
      case 'FRA':
      case 'FRANCE':
        return eurozone(countryCode: 'FR', locale: 'fr_FR');
      case 'IT':
      case 'ITA':
      case 'ITALY':
        return eurozone(countryCode: 'IT', locale: 'it_IT');
      case 'ES':
      case 'ESP':
      case 'SPAIN':
        return eurozone(countryCode: 'ES', locale: 'es_ES');
      case 'NL':
      case 'NLD':
      case 'NETHERLANDS':
        return eurozone(countryCode: 'NL', locale: 'nl_NL');
      case 'EU':
      case 'EUR':
      case 'EUROPE':
        return eurozone();
      case 'CA':
      case 'CAN':
      case 'CANADA':
        return canada();
      case 'AU':
      case 'AUS':
      case 'AUSTRALIA':
        return australia();
      case 'SG':
      case 'SGP':
      case 'SINGAPORE':
        return singapore();
      case 'NZ':
      case 'NZL':
      case 'NEW ZEALAND':
        return newZealand();
      case 'SA':
      case 'SAU':
      case 'SAUDI ARABIA':
        return saudiArabia();
      case 'QA':
      case 'QAT':
      case 'QATAR':
        return qatar();
      case 'KW':
      case 'KWT':
      case 'KUWAIT':
        return kuwait();
      case 'BH':
      case 'BHR':
      case 'BAHRAIN':
        return bahrain();
      case 'OM':
      case 'OMN':
      case 'OMAN':
        return oman();
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
      case 'GBP':
        return 'GB';
      case 'EUR':
        return 'DE';
      case 'CAD':
        return 'CA';
      case 'AUD':
        return 'AU';
      case 'SGD':
        return 'SG';
      case 'NZD':
        return 'NZ';
      case 'SAR':
        return 'SA';
      case 'QAR':
        return 'QA';
      case 'KWD':
        return 'KW';
      case 'BHD':
        return 'BH';
      case 'OMR':
        return 'OM';
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
        unitedKingdom(),
        eurozone(),
        canada(),
        australia(),
        singapore(),
        newZealand(),
        saudiArabia(),
        qatar(),
        kuwait(),
        bahrain(),
        oman(),
      ];
}
