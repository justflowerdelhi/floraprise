import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/managers/business_settings_manager.dart';
import 'package:floraprise/managers/onboarding_setup_manager.dart';
import 'package:floraprise/models/fiscal_profile.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    AppDatabase.useInMemoryForTests = true;
  });

  tearDownAll(() async {
    await AppDatabase.instance.close();
    AppDatabase.useInMemoryForTests = false;
  });

  setUp(() async {
    final db = await AppDatabase.instance.database;
    await db.delete('settings');
    await db.delete('business_profile');
  });

  group('BusinessSettingsManager Fiscal Profile Persistence', () {
    test('Defaults to India profile when no fiscal profile is configured', () async {
      final manager = BusinessSettingsManager();
      final profile = await manager.getFiscalProfile();

      expect(profile.countryCode, 'IN');
      expect(profile.currencyCode, 'INR');
      expect(profile.currencySymbol, '₹');
      expect(profile.taxEnabled, isTrue);
      expect(profile.taxLabel, 'GST');
      expect(profile.taxRatePercent, 18.0);
      expect(profile.taxInclusive, isTrue);
      expect(profile.locale, 'en_IN');
      expect(profile.timeZone, 'Asia/Kolkata');
    });

    test('Persists and retrieves UAE FiscalProfile', () async {
      final manager = BusinessSettingsManager();
      final uaeProfile = CountryPresets.uae().copyWith(
        taxIdentifier: '100200300400003',
      );

      await manager.setFiscalProfile(uaeProfile);
      final retrieved = await manager.getFiscalProfile();

      expect(retrieved.countryCode, 'AE');
      expect(retrieved.currencyCode, 'AED');
      expect(retrieved.currencySymbol, 'د.إ');
      expect(retrieved.taxEnabled, isTrue);
      expect(retrieved.taxLabel, 'VAT');
      expect(retrieved.taxRatePercent, 5.0);
      expect(retrieved.taxInclusive, isTrue);
      expect(retrieved.taxIdentifier, '100200300400003');
      expect(retrieved.locale, 'en_AE');
      expect(retrieved.timeZone, 'Asia/Dubai');
    });

    test('Persists and retrieves USA FiscalProfile with customized tax rate and tax ID', () async {
      final manager = BusinessSettingsManager();
      final usaProfile = CountryPresets.usa().copyWith(
        taxRatePercent: 8.25,
        taxInclusive: false,
        taxIdentifier: 'XX-XXXXXXX',
        taxEnabled: true,
      );

      await manager.setFiscalProfile(usaProfile);
      final retrieved = await manager.getFiscalProfile();

      expect(retrieved.countryCode, 'US');
      expect(retrieved.currencyCode, 'USD');
      expect(retrieved.currencySymbol, '\$');
      expect(retrieved.taxEnabled, isTrue);
      expect(retrieved.taxLabel, 'Sales Tax');
      expect(retrieved.taxRatePercent, 8.25);
      expect(retrieved.taxInclusive, isFalse);
      expect(retrieved.taxIdentifier, 'XX-XXXXXXX');
      expect(retrieved.locale, 'en_US');
      expect(retrieved.timeZone, 'America/New_York');
    });

    test('Disabling tax preserves configured tax rate and settings', () async {
      final manager = BusinessSettingsManager();
      final usaProfile = CountryPresets.usa().copyWith(
        taxRatePercent: 9.5,
        taxEnabled: false,
      );

      await manager.setFiscalProfile(usaProfile);
      final retrieved = await manager.getFiscalProfile();

      expect(retrieved.countryCode, 'US');
      expect(retrieved.taxEnabled, isFalse);
      expect(retrieved.taxRatePercent, 9.5);
      expect(retrieved.taxInclusive, isFalse);
    });

    test('Toggling inclusive/exclusive pricing model persists across reload', () async {
      final manager = BusinessSettingsManager();
      final inProfile = CountryPresets.india().copyWith(
        taxInclusive: false,
      );

      await manager.setFiscalProfile(inProfile);
      final retrieved = await manager.getFiscalProfile();

      expect(retrieved.countryCode, 'IN');
      expect(retrieved.taxInclusive, isFalse);
    });

    test('BusinessSettings.load() populates fiscalProfile alongside legacy fields', () async {
      final manager = BusinessSettingsManager();
      final customUae = CountryPresets.uae().copyWith(
        taxIdentifier: 'TRN-123456',
      );
      await manager.setFiscalProfile(customUae);
      await manager.setShopName('Dubai Blooms');
      await manager.setOwnerName('Ahmed');
      await manager.setPhone('971501234567');

      final settings = await manager.load();

      expect(settings.shopName, 'Dubai Blooms');
      expect(settings.ownerName, 'Ahmed');
      expect(settings.phone, '971501234567');
      expect(settings.fiscalProfile, isNotNull);
      expect(settings.resolvedFiscalProfile.countryCode, 'AE');
      expect(settings.resolvedFiscalProfile.currencyCode, 'AED');
      expect(settings.resolvedFiscalProfile.taxIdentifier, 'TRN-123456');
    });
  });

  group('OnboardingSetupManager Fiscal Integration', () {
    test('runSetup configures business settings and persists FiscalProfile', () async {
      final setupManager = OnboardingSetupManager();
      final settingsManager = BusinessSettingsManager();

      const input = BusinessSetupInput(
        shopName: 'Austin Florals',
        mobile: '15125550199',
        ownerName: 'Sarah Connor',
        sameNumberForWhatsApp: true,
        whatsApp: '15125550199',
        gstRegistered: true,
        gstNumber: 'EIN-998877',
        logoPath: '',
        address: '123 Congress Ave',
        city: 'Austin',
        fiscalProfile: FiscalProfile(
          countryCode: 'US',
          currencyCode: 'USD',
          currencySymbol: '\$',
          taxEnabled: true,
          taxLabel: 'Sales Tax',
          taxRatePercent: 7.75,
          taxInclusive: false,
          taxIdentifier: 'EIN-998877',
          locale: 'en_US',
          timeZone: 'America/Chicago',
        ),
      );

      final stagesCompleted = <SetupStage>[];
      await setupManager.runSetup(
        installRecommended: false,
        languageCode: 'en',
        businessInput: input,
        onStageDone: (stage) async {
          stagesCompleted.add(stage);
        },
      );

      expect(stagesCompleted, containsAll([
        SetupStage.categories,
        SetupStage.products,
        SetupStage.staff,
        SetupStage.settings,
        SetupStage.ready,
      ]));

      final savedSettings = await settingsManager.load();
      expect(savedSettings.shopName, 'Austin Florals');
      expect(savedSettings.ownerName, 'Sarah Connor');

      final savedFiscal = await settingsManager.getFiscalProfile();
      expect(savedFiscal.countryCode, 'US');
      expect(savedFiscal.currencyCode, 'USD');
      expect(savedFiscal.currencySymbol, '\$');
      expect(savedFiscal.taxRatePercent, 7.75);
      expect(savedFiscal.taxInclusive, isFalse);
      expect(savedFiscal.taxIdentifier, 'EIN-998877');
    });
  });
}
