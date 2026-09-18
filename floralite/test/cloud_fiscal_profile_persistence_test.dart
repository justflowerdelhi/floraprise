import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/cloud_company_profile_repository.dart';
import 'package:floraprise/managers/business_settings_manager.dart';
import 'package:floraprise/models/storage_mode.dart';
import 'package:floraprise/services/storage_mode_service.dart';
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
  });

  group('Cloud Fiscal Profile Persistence & Hardening', () {
    test('1 & 2: Save complete UAE FiscalProfile to cloud representation and reload identical values', () async {
      final storageModeService = StorageModeService();
      await storageModeService.setMode(StorageMode.cloud);

      const secureStorage = FlutterSecureStorage();
      final cloudRepo = CloudCompanyProfileRepository(
        secureStorage: secureStorage,
        sender: (method, uri, {body}) async {
          return {
            'id': 'uae-company-id-1',
            'name': 'Dubai Blooms LLC',
            'timeZone': 'Asia/Dubai',
            'currencyCode': 'AED',
            'taxIdentifier': '100200300400003',
            'region': 'AE',
            'isActive': true,
            'createdAtUtc': '2026-01-01T00:00:00Z',
          };
        },
      );

      final updatedCloudProfile = await cloudRepo.updateCompanyProfile(
        baseUrl: 'https://api.test.floraprise.local',
        accessToken: 'test-token',
        name: 'Dubai Blooms LLC',
        currencyCode: 'AED',
        timeZone: 'Asia/Dubai',
        taxIdentifier: '100200300400003',
        region: 'AE',
        taxEnabled: true,
        taxLabel: 'VAT',
        taxRatePercent: 5.0,
        taxInclusive: true,
      );

      expect(updatedCloudProfile.currencyCode, 'AED');
      expect(updatedCloudProfile.region, 'AE');
      expect(updatedCloudProfile.taxRatePercent, 5.0);
      expect(updatedCloudProfile.taxInclusive, isTrue);

      final manager = BusinessSettingsManager(
        cloudCompanyProfileRepository: cloudRepo,
        storageModeService: storageModeService,
      );

      final fiscal = await manager.getFiscalProfile();
      expect(fiscal.countryCode, 'AE');
      expect(fiscal.currencyCode, 'AED');
      expect(fiscal.currencySymbol, 'د.إ');
      expect(fiscal.taxEnabled, isTrue);
      expect(fiscal.taxLabel, 'VAT');
      expect(fiscal.taxRatePercent, 5.0);
      expect(fiscal.taxInclusive, isTrue);
      expect(fiscal.taxIdentifier, '100200300400003');
      expect(fiscal.locale, 'en_AE');
      expect(fiscal.timeZone, 'Asia/Dubai');
    });

    test('3 & 4: Save USA with taxRate=8.25, taxInclusive=false, taxEnabled=true, custom taxIdentifier and verify values survive reload', () async {
      final storageModeService = StorageModeService();
      await storageModeService.setMode(StorageMode.cloud);

      const secureStorage = FlutterSecureStorage();
      final cloudRepo = CloudCompanyProfileRepository(
        secureStorage: secureStorage,
        sender: (method, uri, {body}) async {
          return {
            'id': 'us-company-id-1',
            'name': 'Austin Floral Co',
            'timeZone': 'America/Chicago',
            'currencyCode': 'USD',
            'taxIdentifier': 'TX-EIN-12345678',
            'region': 'US',
            'isActive': true,
            'createdAtUtc': '2026-01-01T00:00:00Z',
          };
        },
      );

      await cloudRepo.updateCompanyProfile(
        baseUrl: 'https://api.test.floraprise.local',
        accessToken: 'test-token',
        name: 'Austin Floral Co',
        currencyCode: 'USD',
        timeZone: 'America/Chicago',
        taxIdentifier: 'TX-EIN-12345678',
        region: 'US',
        taxEnabled: true,
        taxLabel: 'Sales Tax',
        taxRatePercent: 8.25,
        taxInclusive: false,
      );

      final manager = BusinessSettingsManager(
        cloudCompanyProfileRepository: cloudRepo,
        storageModeService: storageModeService,
      );

      final fiscal = await manager.getFiscalProfile();
      expect(fiscal.countryCode, 'US');
      expect(fiscal.currencyCode, 'USD');
      expect(fiscal.currencySymbol, '\$');
      expect(fiscal.taxEnabled, isTrue);
      expect(fiscal.taxLabel, 'Sales Tax');
      expect(fiscal.taxRatePercent, 8.25);
      expect(fiscal.taxInclusive, isFalse);
      expect(fiscal.taxIdentifier, 'TX-EIN-12345678');
      expect(fiscal.timeZone, 'America/Chicago');
    });

    test('5: Change USA tax rate to 8.875 and verify previous value is replaced', () async {
      final storageModeService = StorageModeService();
      await storageModeService.setMode(StorageMode.cloud);

      const secureStorage = FlutterSecureStorage();
      final cloudRepo = CloudCompanyProfileRepository(
        secureStorage: secureStorage,
        sender: (method, uri, {body}) async {
          return {
            'id': 'nyc-company-id-1',
            'name': 'Manhattan Blooms',
            'timeZone': 'America/New_York',
            'currencyCode': 'USD',
            'taxIdentifier': 'NY-EIN-999',
            'region': 'US',
            'isActive': true,
            'createdAtUtc': '2026-01-01T00:00:00Z',
          };
        },
      );

      // Initial save at 8.25%
      await cloudRepo.updateCompanyProfile(
        baseUrl: 'https://api.test.floraprise.local',
        accessToken: 'test-token',
        currencyCode: 'USD',
        timeZone: 'America/New_York',
        taxIdentifier: 'NY-EIN-999',
        region: 'US',
        taxRatePercent: 8.25,
        taxInclusive: false,
      );

      final manager = BusinessSettingsManager(
        cloudCompanyProfileRepository: cloudRepo,
        storageModeService: storageModeService,
      );

      var fiscal = await manager.getFiscalProfile();
      expect(fiscal.taxRatePercent, 8.25);

      // Update to 8.875% (NYC rate)
      await cloudRepo.updateCompanyProfile(
        baseUrl: 'https://api.test.floraprise.local',
        accessToken: 'test-token',
        currencyCode: 'USD',
        timeZone: 'America/New_York',
        taxIdentifier: 'NY-EIN-999',
        region: 'US',
        taxRatePercent: 8.875,
        taxInclusive: false,
      );

      fiscal = await manager.getFiscalProfile();
      expect(fiscal.taxRatePercent, 8.875);
    });

    test('6: Verify country preset defaults do not overwrite customized values', () async {
      final storageModeService = StorageModeService();
      await storageModeService.setMode(StorageMode.cloud);

      const secureStorage = FlutterSecureStorage();
      final customUsaProfile = CloudCompanyProfile(
        id: 'company-custom-1',
        name: 'Custom USA Shop',
        timeZone: 'America/Los_Angeles',
        currencyCode: 'USD',
        region: 'US',
        taxEnabled: true,
        taxLabel: 'State & Local Tax',
        taxRatePercent: 9.25,
        taxInclusive: false,
        taxIdentifier: 'CA-TAX-101',
        isActive: true,
        createdAtUtc: DateTime.now(),
      );

      await secureStorage.write(
        key: 'cloud_company_profile',
        value: jsonEncode(customUsaProfile.toJson()),
      );

      final cloudRepo = CloudCompanyProfileRepository(secureStorage: secureStorage);
      final manager = BusinessSettingsManager(
        cloudCompanyProfileRepository: cloudRepo,
        storageModeService: storageModeService,
      );

      final fiscal = await manager.getFiscalProfile();
      // Preset default for USA is 0.0% and label is "Sales Tax".
      // Customized 9.25% and "State & Local Tax" must not be overwritten by preset defaults.
      expect(fiscal.taxRatePercent, 9.25);
      expect(fiscal.taxLabel, 'State & Local Tax');
      expect(fiscal.taxInclusive, isFalse);
      expect(fiscal.taxIdentifier, 'CA-TAX-101');
      expect(fiscal.currencySymbol, '\$');
    });

    test('7: Verify missing legacy cloud fiscal information remains backward compatible with India defaults', () async {
      final storageModeService = StorageModeService();
      await storageModeService.setMode(StorageMode.cloud);

      const secureStorage = FlutterSecureStorage();
      // Legacy profile with no region, no taxRatePercent, no taxInclusive
      final legacyProfile = CloudCompanyProfile(
        id: 'legacy-company-1',
        name: 'Classic Flower Mart',
        timeZone: 'Asia/Kolkata',
        currencyCode: 'INR',
        taxIdentifier: '07AAAAA0000A1Z5',
        region: '',
        isActive: true,
        createdAtUtc: DateTime.now(),
      );

      await secureStorage.write(
        key: 'cloud_company_profile',
        value: jsonEncode(legacyProfile.toJson()),
      );

      final cloudRepo = CloudCompanyProfileRepository(secureStorage: secureStorage);
      final manager = BusinessSettingsManager(
        cloudCompanyProfileRepository: cloudRepo,
        storageModeService: storageModeService,
      );

      final fiscal = await manager.getFiscalProfile();
      expect(fiscal.countryCode, 'IN');
      expect(fiscal.currencyCode, 'INR');
      expect(fiscal.currencySymbol, '₹');
      expect(fiscal.taxEnabled, isTrue);
      expect(fiscal.taxLabel, 'GST');
      expect(fiscal.taxRatePercent, 18.0);
      expect(fiscal.taxInclusive, isTrue);
      expect(fiscal.taxIdentifier, '07AAAAA0000A1Z5');
      expect(fiscal.timeZone, 'Asia/Kolkata');
    });

    test('8: Verify Android/Web use the same cloud representation where repository architecture permits', () async {
      const secureStorage = FlutterSecureStorage();
      final cloudRepo = CloudCompanyProfileRepository(
        secureStorage: secureStorage,
        sender: (method, uri, {body}) async {
          return {
            'id': 'shared-cloud-id',
            'name': 'Shared Florist',
            'timeZone': 'Asia/Dubai',
            'currencyCode': 'AED',
            'taxIdentifier': 'TRN-778899',
            'region': 'AE',
            'isActive': true,
            'createdAtUtc': '2026-01-01T00:00:00Z',
          };
        },
      );

      // Save from client
      await cloudRepo.updateCompanyProfile(
        baseUrl: 'https://api.test.floraprise.local',
        accessToken: 'shared-token',
        name: 'Shared Florist',
        currencyCode: 'AED',
        timeZone: 'Asia/Dubai',
        taxIdentifier: 'TRN-778899',
        region: 'AE',
        taxRatePercent: 5.0,
        taxInclusive: true,
        taxEnabled: true,
      );

      // Verify Cloud Storage Mode representation
      final storageModeService = StorageModeService();
      await storageModeService.setMode(StorageMode.cloud);

      final cloudModeManager = BusinessSettingsManager(
        cloudCompanyProfileRepository: cloudRepo,
        storageModeService: storageModeService,
      );

      final cloudFiscal = await cloudModeManager.getFiscalProfile();
      expect(cloudFiscal.countryCode, 'AE');
      expect(cloudFiscal.currencyCode, 'AED');
      expect(cloudFiscal.taxRatePercent, 5.0);
      expect(cloudFiscal.taxInclusive, isTrue);
      expect(cloudFiscal.taxIdentifier, 'TRN-778899');

      // Verify cached profile retrieved by Web or Android returns identical structured fields
      final reloadedProfile = await cloudRepo.getCachedProfile();
      expect(reloadedProfile, isNotNull);
      expect(reloadedProfile!.region, 'AE');
      expect(reloadedProfile.currencyCode, 'AED');
      expect(reloadedProfile.taxRatePercent, 5.0);
      expect(reloadedProfile.taxInclusive, isTrue);
      expect(reloadedProfile.taxIdentifier, 'TRN-778899');
    });
  });
}
