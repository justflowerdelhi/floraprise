import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/cloud_company_profile_repository.dart';
import 'package:floraprise/managers/business_settings_manager.dart';
import 'package:floraprise/models/fiscal_profile.dart';
import 'package:floraprise/models/storage_mode.dart';
import 'package:floraprise/services/storage_mode_service.dart';
import 'package:floraprise/utils/locale_formatter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    AppDatabase.useInMemoryForTests = true;
  });

  tearDownAll(() async {
    await AppDatabase.instance.close();
    AppDatabase.useInMemoryForTests = false;
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    final db = await AppDatabase.instance.database;
    await db.delete('settings');
    await db.delete('business_profile');
    BusinessSettingsManager.activeFiscalProfile = CountryPresets.india();
  });

  group('Country and Currency Mapping & Resolution Tests', () {
    test('A: India with no currencyCode (null) resolves to INR / ₹', () async {
      final storageModeService = StorageModeService();
      await storageModeService.setMode(StorageMode.cloud);

      const secureStorage = FlutterSecureStorage();
      final cloudRepo = CloudCompanyProfileRepository(
        secureStorage: secureStorage,
      );

      final profile = CloudCompanyProfile(
        id: 'company-in-1',
        name: 'Lotus Flowers Mumbai',
        timeZone: 'Asia/Kolkata',
        region: 'IN',
        currencyCode: null, // No explicit currency
        isActive: true,
        createdAtUtc: DateTime.now(),
      );
      await cloudRepo.saveCachedProfile(profile);

      final manager = BusinessSettingsManager(
        cloudCompanyProfileRepository: cloudRepo,
        storageModeService: storageModeService,
      );

      final fiscal = await manager.getFiscalProfile();
      expect(fiscal.countryCode, 'IN');
      expect(fiscal.currencyCode, 'INR');
      expect(fiscal.currencySymbol, '₹');
    });

    test('B: US with no currencyCode (null) resolves to USD / \$', () async {
      final storageModeService = StorageModeService();
      await storageModeService.setMode(StorageMode.cloud);

      const secureStorage = FlutterSecureStorage();
      final cloudRepo = CloudCompanyProfileRepository(
        secureStorage: secureStorage,
      );

      final profile = CloudCompanyProfile(
        id: 'company-us-1',
        name: 'Seattle Blooms',
        timeZone: 'America/Los_Angeles',
        region: 'US',
        currencyCode: null,
        isActive: true,
        createdAtUtc: DateTime.now(),
      );
      await cloudRepo.saveCachedProfile(profile);

      final manager = BusinessSettingsManager(
        cloudCompanyProfileRepository: cloudRepo,
        storageModeService: storageModeService,
      );

      final fiscal = await manager.getFiscalProfile();
      expect(fiscal.countryCode, 'US');
      expect(fiscal.currencyCode, 'USD');
      expect(fiscal.currencySymbol, r'$');
    });

    test('C: UAE with no currencyCode (null) resolves to AED / د.إ', () async {
      final storageModeService = StorageModeService();
      await storageModeService.setMode(StorageMode.cloud);

      const secureStorage = FlutterSecureStorage();
      final cloudRepo = CloudCompanyProfileRepository(
        secureStorage: secureStorage,
      );

      final profile = CloudCompanyProfile(
        id: 'company-ae-1',
        name: 'Dubai Orchid Florist',
        timeZone: 'Asia/Dubai',
        region: 'AE',
        currencyCode: null,
        isActive: true,
        createdAtUtc: DateTime.now(),
      );
      await cloudRepo.saveCachedProfile(profile);

      final manager = BusinessSettingsManager(
        cloudCompanyProfileRepository: cloudRepo,
        storageModeService: storageModeService,
      );

      final fiscal = await manager.getFiscalProfile();
      expect(fiscal.countryCode, 'AE');
      expect(fiscal.currencyCode, 'AED');
      expect(fiscal.currencySymbol, 'د.إ');
    });

    test('D: Explicit currency (IN + USD) is preserved and not overwritten', () async {
      final storageModeService = StorageModeService();
      await storageModeService.setMode(StorageMode.cloud);

      const secureStorage = FlutterSecureStorage();
      final cloudRepo = CloudCompanyProfileRepository(
        secureStorage: secureStorage,
      );

      // Merchant intentionally set USD for their Indian export business
      final profile = CloudCompanyProfile(
        id: 'company-in-custom-1',
        name: 'Global Blooms India',
        timeZone: 'Asia/Kolkata',
        region: 'IN',
        currencyCode: 'USD',
        isActive: true,
        createdAtUtc: DateTime.now(),
      );
      await cloudRepo.saveCachedProfile(profile);

      final manager = BusinessSettingsManager(
        cloudCompanyProfileRepository: cloudRepo,
        storageModeService: storageModeService,
      );

      final fiscal = await manager.getFiscalProfile();
      expect(fiscal.countryCode, 'IN');
      expect(fiscal.currencyCode, 'USD');
      expect(fiscal.currencySymbol, r'$');
    });

    test('E: Empty string currencyCode ("") resolves to country default INR / ₹', () async {
      final storageModeService = StorageModeService();
      await storageModeService.setMode(StorageMode.cloud);

      const secureStorage = FlutterSecureStorage();
      final cloudRepo = CloudCompanyProfileRepository(
        secureStorage: secureStorage,
      );

      final profile = CloudCompanyProfile(
        id: 'company-in-empty-curr',
        name: 'Green Petals Delhi',
        timeZone: 'Asia/Kolkata',
        region: 'IN',
        currencyCode: '',
        isActive: true,
        createdAtUtc: DateTime.now(),
      );
      await cloudRepo.saveCachedProfile(profile);

      final manager = BusinessSettingsManager(
        cloudCompanyProfileRepository: cloudRepo,
        storageModeService: storageModeService,
      );

      final fiscal = await manager.getFiscalProfile();
      expect(fiscal.countryCode, 'IN');
      expect(fiscal.currencyCode, 'INR');
      expect(fiscal.currencySymbol, '₹');
    });

    test('F: CountryPresets maps countries to their correct default currencies', () {
      expect(CountryPresets.defaultCurrencyForCountry('IN').code, 'INR');
      expect(CountryPresets.defaultCurrencyForCountry('IN').symbol, '₹');

      expect(CountryPresets.defaultCurrencyForCountry('US').code, 'USD');
      expect(CountryPresets.defaultCurrencyForCountry('US').symbol, r'$');

      expect(CountryPresets.defaultCurrencyForCountry('AE').code, 'AED');
      expect(CountryPresets.defaultCurrencyForCountry('AE').symbol, 'د.إ');

      expect(CountryPresets.defaultCurrencyForCountry('GB').code, 'GBP');
      expect(CountryPresets.defaultCurrencyForCountry('GB').symbol, '£');

      expect(CountryPresets.defaultCurrencyForCountry('DE').code, 'EUR');
      expect(CountryPresets.defaultCurrencyForCountry('DE').symbol, '€');

      expect(CountryPresets.defaultCurrencyForCountry('CA').code, 'CAD');
      expect(CountryPresets.defaultCurrencyForCountry('CA').symbol, r'CA$');

      expect(CountryPresets.defaultCurrencyForCountry('AU').code, 'AUD');
      expect(CountryPresets.defaultCurrencyForCountry('AU').symbol, r'A$');
    });

    test('G: CloudCompanyProfile.fromJson does not inject unsafe USD default', () {
      final jsonWithoutCurrency = {
        'id': 'comp-100',
        'name': 'Test Shop',
        'timeZone': 'Asia/Kolkata',
        'region': 'IN',
      };
      final profile = CloudCompanyProfile.fromJson(jsonWithoutCurrency);
      expect(profile.currencyCode, isNull);
    });

    test('H: Local SQLite mode resolution honors country default and explicit override', () async {
      final storageModeService = StorageModeService();
      await storageModeService.setMode(StorageMode.local);

      final manager = BusinessSettingsManager(
        storageModeService: storageModeService,
      );

      // 1. Initial default without settings
      final initialFiscal = await manager.getFiscalProfile();
      expect(initialFiscal.countryCode, 'IN');
      expect(initialFiscal.currencyCode, 'INR');
      expect(initialFiscal.currencySymbol, '₹');

      // 2. Set to US preset
      await manager.setFiscalProfile(CountryPresets.usa());
      final usFiscal = await manager.getFiscalProfile();
      expect(usFiscal.countryCode, 'US');
      expect(usFiscal.currencyCode, 'USD');
      expect(usFiscal.currencySymbol, r'$');

      // 3. Set to UK preset
      await manager.setFiscalProfile(CountryPresets.unitedKingdom());
      final ukFiscal = await manager.getFiscalProfile();
      expect(ukFiscal.countryCode, 'GB');
      expect(ukFiscal.currencyCode, 'GBP');
      expect(ukFiscal.currencySymbol, '£');

      // 4. Set India with explicit EUR currency
      final customFiscal = CountryPresets.india().copyWith(
        currencyCode: 'EUR',
        currencySymbol: '€',
      );
      await manager.setFiscalProfile(customFiscal);
      final customLoaded = await manager.getFiscalProfile();
      expect(customLoaded.countryCode, 'IN');
      expect(customLoaded.currencyCode, 'EUR');
      expect(customLoaded.currencySymbol, '€');
    });

    test('I: LocaleFormatter reflects the active fiscal profile currency', () {
      // With INR profile
      final inrProfile = CountryPresets.india();
      final inrFormatted = LocaleFormatter.formatCurrencyWithProfile(
        15000,
        profile: inrProfile,
      );
      expect(inrFormatted, contains('150'));
      expect(inrFormatted, contains('₹'));

      // With USD profile
      final usdProfile = CountryPresets.usa();
      final usdFormatted = LocaleFormatter.formatCurrencyWithProfile(
        15000,
        profile: usdProfile,
      );
      expect(usdFormatted, contains('150'));
      expect(usdFormatted, contains(r'$'));

      // With GBP profile
      final gbpProfile = CountryPresets.unitedKingdom();
      final gbpFormatted = LocaleFormatter.formatCurrencyWithProfile(
        15000,
        profile: gbpProfile,
      );
      expect(gbpFormatted, contains('150'));
      expect(gbpFormatted, contains('£'));
    });
  });
}
