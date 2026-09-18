import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/models/fiscal_profile.dart';
import 'package:floraprise/models/gst_calculation_type.dart';
import 'package:floraprise/services/tax_calculation_engine.dart';
import 'package:floraprise/managers/business_settings_manager.dart';

void main() {
  group('CountryPresets', () {
    test('India preset contains correct fiscal defaults', () {
      final preset = CountryPresets.india();
      expect(preset.countryCode, 'IN');
      expect(preset.currencyCode, 'INR');
      expect(preset.currencySymbol, '₹');
      expect(preset.taxEnabled, isTrue);
      expect(preset.taxLabel, 'GST');
      expect(preset.taxRatePercent, 18.0);
      expect(preset.taxInclusive, isTrue);
      expect(preset.taxIdentifier, isNull);
      expect(preset.locale, 'en_IN');
      expect(preset.timeZone, 'Asia/Kolkata');
    });

    test('UAE preset contains correct fiscal defaults', () {
      final preset = CountryPresets.uae();
      expect(preset.countryCode, 'AE');
      expect(preset.currencyCode, 'AED');
      expect(preset.currencySymbol, 'د.إ');
      expect(preset.taxEnabled, isTrue);
      expect(preset.taxLabel, 'VAT');
      expect(preset.taxRatePercent, 5.0);
      expect(preset.taxInclusive, isTrue);
      expect(preset.taxIdentifier, isNull);
      expect(preset.locale, 'en_AE');
      expect(preset.timeZone, 'Asia/Dubai');
    });

    test('USA preset contains correct fiscal defaults and 0% configurable tax', () {
      final preset = CountryPresets.usa();
      expect(preset.countryCode, 'US');
      expect(preset.currencyCode, 'USD');
      expect(preset.currencySymbol, '\$');
      expect(preset.taxEnabled, isTrue);
      expect(preset.taxLabel, 'Sales Tax');
      expect(preset.taxRatePercent, 0.0);
      expect(preset.taxInclusive, isFalse);
      expect(preset.taxIdentifier, isNull);
      expect(preset.locale, 'en_US');
      expect(preset.timeZone, 'America/New_York');
    });

    test('forCountry resolves known country codes and falls back to India', () {
      expect(CountryPresets.forCountry('IN').countryCode, 'IN');
      expect(CountryPresets.forCountry('IND').countryCode, 'IN');
      expect(CountryPresets.forCountry('india').countryCode, 'IN');

      expect(CountryPresets.forCountry('AE').countryCode, 'AE');
      expect(CountryPresets.forCountry('ARE').countryCode, 'AE');
      expect(CountryPresets.forCountry('uae').countryCode, 'AE');

      expect(CountryPresets.forCountry('US').countryCode, 'US');
      expect(CountryPresets.forCountry('USA').countryCode, 'US');
      expect(CountryPresets.forCountry('United States').countryCode, 'US');

      // Backward compatibility fallbacks
      expect(CountryPresets.forCountry(null).countryCode, 'IN');
      expect(CountryPresets.forCountry('').countryCode, 'IN');
      expect(CountryPresets.forCountry('UNKNOWN_COUNTRY').countryCode, 'IN');
    });

    test('allPresets returns all supported presets', () {
      final list = CountryPresets.allPresets;
      expect(list.length, 3);
      expect(list.map((p) => p.countryCode), containsAll(['IN', 'AE', 'US']));
    });
  });

  group('FiscalProfile Serialization & Backwards Compatibility', () {
    test('fromMap with null or empty map returns India defaults', () {
      final defaultFromNull = FiscalProfile.fromMap(null);
      expect(defaultFromNull.countryCode, 'IN');
      expect(defaultFromNull.currencyCode, 'INR');
      expect(defaultFromNull.currencySymbol, '₹');
      expect(defaultFromNull.taxLabel, 'GST');
      expect(defaultFromNull.taxRatePercent, 18.0);
      expect(defaultFromNull.taxInclusive, isTrue);

      final defaultFromEmpty = FiscalProfile.fromMap({});
      expect(defaultFromEmpty.countryCode, 'IN');
      expect(defaultFromEmpty.currencyCode, 'INR');
    });

    test('toMap and fromMap round-trip preserves all values', () {
      const profile = FiscalProfile(
        countryCode: 'US',
        currencyCode: 'USD',
        currencySymbol: '\$',
        taxEnabled: true,
        taxLabel: 'Sales Tax',
        taxRatePercent: 8.25,
        taxInclusive: false,
        taxIdentifier: '12-3456789',
        locale: 'en_US',
        timeZone: 'America/Chicago',
      );

      final map = profile.toMap();
      final restored = FiscalProfile.fromMap(map);

      expect(restored, equals(profile));
      expect(restored.countryCode, 'US');
      expect(restored.taxRatePercent, 8.25);
      expect(restored.taxInclusive, isFalse);
      expect(restored.taxIdentifier, '12-3456789');
      expect(restored.timeZone, 'America/Chicago');
    });
  });

  group('TaxCalculationEngine - Tax Exclusive Math', () {
    test('1000 at 18% exclusive => tax 180, total 1180, net 1000', () {
      final result = TaxCalculationEngine.calculate(
        amountPaise: 1000,
        taxRatePercent: 18.0,
        isTaxInclusive: false,
      );

      expect(result.netAmountPaise, 1000);
      expect(result.taxAmountPaise, 180);
      expect(result.totalAmountPaise, 1180);
      expect(result.taxRatePercent, 18.0);
      expect(result.taxInclusive, isFalse);
    });

    test('1000 at 5% exclusive => tax 50, total 1050, net 1000', () {
      final result = TaxCalculationEngine.calculate(
        amountPaise: 1000,
        taxRatePercent: 5.0,
        isTaxInclusive: false,
      );

      expect(result.netAmountPaise, 1000);
      expect(result.taxAmountPaise, 50);
      expect(result.totalAmountPaise, 1050);
      expect(result.taxInclusive, isFalse);
    });
  });

  group('TaxCalculationEngine - Tax Inclusive Math', () {
    test('1180 at 18% inclusive => net 1000, tax 180, total 1180', () {
      final result = TaxCalculationEngine.calculate(
        amountPaise: 1180,
        taxRatePercent: 18.0,
        isTaxInclusive: true,
      );

      expect(result.netAmountPaise, 1000);
      expect(result.taxAmountPaise, 180);
      expect(result.totalAmountPaise, 1180);
      expect(result.taxRatePercent, 18.0);
      expect(result.taxInclusive, isTrue);
    });

    test('1050 at 5% inclusive => net 1000, tax 50, total 1050', () {
      final result = TaxCalculationEngine.calculate(
        amountPaise: 1050,
        taxRatePercent: 5.0,
        isTaxInclusive: true,
      );

      expect(result.netAmountPaise, 1000);
      expect(result.taxAmountPaise, 50);
      expect(result.totalAmountPaise, 1050);
      expect(result.taxInclusive, isTrue);
    });
  });

  group('TaxCalculationEngine - Tax Disabled & Zero Tax', () {
    test('taxEnabled false produces zero tax and unchanged total', () {
      final inclusiveDisabled = TaxCalculationEngine.calculate(
        amountPaise: 1500,
        taxRatePercent: 18.0,
        isTaxInclusive: true,
        taxEnabled: false,
      );
      expect(inclusiveDisabled.netAmountPaise, 1500);
      expect(inclusiveDisabled.taxAmountPaise, 0);
      expect(inclusiveDisabled.totalAmountPaise, 1500);

      final exclusiveDisabled = TaxCalculationEngine.calculate(
        amountPaise: 1500,
        taxRatePercent: 18.0,
        isTaxInclusive: false,
        taxEnabled: false,
      );
      expect(exclusiveDisabled.netAmountPaise, 1500);
      expect(exclusiveDisabled.taxAmountPaise, 0);
      expect(exclusiveDisabled.totalAmountPaise, 1500);
    });

    test('0% tax rate produces zero tax and unchanged total', () {
      final result = TaxCalculationEngine.calculate(
        amountPaise: 2500,
        taxRatePercent: 0.0,
        isTaxInclusive: false,
      );
      expect(result.netAmountPaise, 2500);
      expect(result.taxAmountPaise, 0);
      expect(result.totalAmountPaise, 2500);
    });

    test('zero or negative amount handles cleanly', () {
      final zeroResult = TaxCalculationEngine.calculate(
        amountPaise: 0,
        taxRatePercent: 18.0,
        isTaxInclusive: true,
      );
      expect(zeroResult.netAmountPaise, 0);
      expect(zeroResult.taxAmountPaise, 0);
      expect(zeroResult.totalAmountPaise, 0);

      final negativeResult = TaxCalculationEngine.calculate(
        amountPaise: -100,
        taxRatePercent: 18.0,
        isTaxInclusive: false,
      );
      expect(negativeResult.netAmountPaise, 0);
      expect(negativeResult.taxAmountPaise, 0);
      expect(negativeResult.totalAmountPaise, 0);
    });
  });

  group('TaxCalculationEngine - Monetary Rounding Conventions', () {
    test('inclusive fractional tax rounds to nearest minor unit', () {
      // 100 paise at 18% inclusive:
      // tax = 100 * 18 / 118 = 15.2542... -> rounds to 15
      // net = 100 - 15 = 85
      final result = TaxCalculationEngine.calculate(
        amountPaise: 100,
        taxRatePercent: 18.0,
        isTaxInclusive: true,
      );
      expect(result.taxAmountPaise, 15);
      expect(result.netAmountPaise, 85);
      expect(result.totalAmountPaise, 100);
    });

    test('exclusive fractional tax rounds to nearest minor unit', () {
      // 105 cents at 8.25% exclusive:
      // tax = 105 * 8.25 / 100 = 8.6625 -> rounds to 9
      // total = 105 + 9 = 114
      final result = TaxCalculationEngine.calculate(
        amountPaise: 105,
        taxRatePercent: 8.25,
        isTaxInclusive: false,
      );
      expect(result.taxAmountPaise, 9);
      expect(result.netAmountPaise, 105);
      expect(result.totalAmountPaise, 114);
    });
  });

  group('Legacy GstLineBreakup Interoperability', () {
    test('calculateGstLineBreakup delegates to TaxCalculationEngine accurately', () {
      final inclusiveBreakup = calculateGstLineBreakup(
        amountPaise: 11200,
        gstPercent: 12,
        calculationType: GstCalculationType.inclusive,
      );
      expect(inclusiveBreakup.basicAmountPaise, 10000);
      expect(inclusiveBreakup.gstAmountPaise, 1200);
      expect(inclusiveBreakup.totalAmountPaise, 11200);

      final exclusiveBreakup = calculateGstLineBreakup(
        amountPaise: 10000,
        gstPercent: 12,
        calculationType: GstCalculationType.exclusive,
      );
      expect(exclusiveBreakup.basicAmountPaise, 10000);
      expect(exclusiveBreakup.gstAmountPaise, 1200);
      expect(exclusiveBreakup.totalAmountPaise, 11200);
    });
  });

  group('BusinessSettings Model Fiscal Integration', () {
    test('BusinessSettings provides resolvedFiscalProfile with India fallback', () {
      const settings = BusinessSettings(
        shopName: 'Test Florist',
        ownerName: 'Owner',
        phone: '9876543210',
        address: 'Delhi',
        gstRegistered: true,
        gstNumber: '07AAAAA0000A1Z5',
        defaultDeliveryChargePaise: 0,
        minimumPreparationBufferMinutes: 60,
      );

      final profile = settings.resolvedFiscalProfile;
      expect(profile.countryCode, 'IN');
      expect(profile.currencyCode, 'INR');
      expect(profile.currencySymbol, '₹');
      expect(profile.taxLabel, 'GST');
      expect(profile.taxRatePercent, 18.0);
      expect(profile.taxInclusive, isTrue);
      expect(profile.taxEnabled, isTrue);
      expect(profile.taxIdentifier, '07AAAAA0000A1Z5');
    });
  });
}
