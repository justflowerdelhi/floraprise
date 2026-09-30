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

  group('GST Default and Persistence - Solo SQLite Mode', () {
    test('1. NEW SHOP: GST Number is empty, GST Enabled is OFF', () async {
      final storageModeService = StorageModeService();
      await storageModeService.setMode(StorageMode.local);

      final manager = BusinessSettingsManager(
        storageModeService: storageModeService,
      );

      final settings = await manager.load();
      expect(settings.gstRegistered, isFalse);
      expect(settings.gstNumber, isEmpty);

      final fiscal = await manager.getFiscalProfile();
      expect(fiscal.taxEnabled, isFalse);
      expect(fiscal.taxIdentifier, isNull);
    });

    test('2. SAVE VALID GST NUMBER: GST Number is saved, GST Enabled is ON', () async {
      final storageModeService = StorageModeService();
      await storageModeService.setMode(StorageMode.local);

      final manager = BusinessSettingsManager(
        storageModeService: storageModeService,
      );

      await manager.saveBusinessProfile(
        shopName: 'Rose Boutique',
        ownerName: 'Rahul',
        mobileNumber: '9876543210',
        gstRegistered: true,
        gstNumber: '29ABCDE1234F1Z5',
      );

      final settings = await manager.load();
      expect(settings.gstRegistered, isTrue);
      expect(settings.gstNumber, '29ABCDE1234F1Z5');

      final fiscal = await manager.getFiscalProfile();
      expect(fiscal.taxEnabled, isTrue);
      expect(fiscal.taxIdentifier, '29ABCDE1234F1Z5');
    });

    test('3. REMOVE GST NUMBER: GST Number is empty, GST Enabled is OFF', () async {
      final storageModeService = StorageModeService();
      await storageModeService.setMode(StorageMode.local);

      final manager = BusinessSettingsManager(
        storageModeService: storageModeService,
      );

      // Save initial profile with GST
      await manager.saveBusinessProfile(
        shopName: 'Rose Boutique',
        ownerName: 'Rahul',
        mobileNumber: '9876543210',
        gstRegistered: true,
        gstNumber: '29ABCDE1234F1Z5',
      );

      // Now remove GST number
      await manager.saveBusinessProfile(
        shopName: 'Rose Boutique',
        ownerName: 'Rahul',
        mobileNumber: '9876543210',
        gstRegistered: false,
        gstNumber: '',
      );

      final settings = await manager.load();
      expect(settings.gstRegistered, isFalse);
      expect(settings.gstNumber, isEmpty);

      final fiscal = await manager.getFiscalProfile();
      expect(fiscal.taxEnabled, isFalse);
      expect(fiscal.taxIdentifier, isNull);
    });

    test('4. MANUALLY TURN GST OFF: GST Enabled is OFF and GST Number is cleared', () async {
      final storageModeService = StorageModeService();
      await storageModeService.setMode(StorageMode.local);

      final manager = BusinessSettingsManager(
        storageModeService: storageModeService,
      );

      // Save initial profile with GST
      await manager.saveBusinessProfile(
        shopName: 'Rose Boutique',
        ownerName: 'Rahul',
        mobileNumber: '9876543210',
        gstRegistered: true,
        gstNumber: '29ABCDE1234F1Z5',
      );

      // Manually disable GST via setFiscalProfile
      final activeFiscal = await manager.getFiscalProfile();
      await manager.setFiscalProfile(
        activeFiscal.copyWith(
          taxEnabled: false,
          taxIdentifier: null,
        ),
      );

      final fiscal = await manager.getFiscalProfile();
      expect(fiscal.taxEnabled, isFalse);
      expect(fiscal.taxIdentifier, isNull);

      final settings = await manager.load();
      expect(settings.gstRegistered, isFalse);
    });
  });

  group('GST Default and Persistence - Cloud Mode', () {
    test('1. NEW SHOP: Cloud profile without TaxIdentifier defaults GST Enabled = OFF', () async {
      final storageModeService = StorageModeService();
      await storageModeService.setMode(StorageMode.cloud);

      const secureStorage = FlutterSecureStorage();
      final newShopCloudProfile = CloudCompanyProfile(
        id: 'new-cloud-company',
        name: 'Fresh Petals',
        timeZone: 'Asia/Kolkata',
        currencyCode: 'INR',
        taxIdentifier: null,
        region: 'IN',
        isActive: true,
        createdAtUtc: DateTime.now(),
      );

      await secureStorage.write(
        key: 'cloud_company_profile',
        value: jsonEncode(newShopCloudProfile.toJson()),
      );

      final cloudRepo = CloudCompanyProfileRepository(secureStorage: secureStorage);
      final manager = BusinessSettingsManager(
        cloudCompanyProfileRepository: cloudRepo,
        storageModeService: storageModeService,
      );

      final settings = await manager.load();
      expect(settings.gstRegistered, isFalse);
      expect(settings.gstNumber, isEmpty);

      final fiscal = await manager.getFiscalProfile();
      expect(fiscal.taxEnabled, isFalse);
      expect(fiscal.taxIdentifier, isNull);
    });

    test('2. SAVE VALID GST NUMBER: Cloud profile with TaxIdentifier enables GST', () async {
      final storageModeService = StorageModeService();
      await storageModeService.setMode(StorageMode.cloud);

      const secureStorage = FlutterSecureStorage();
      final cloudRepo = CloudCompanyProfileRepository(
        secureStorage: secureStorage,
        sender: (method, uri, {body}) async {
          return {
            'id': 'cloud-company-1',
            'name': 'Fresh Petals',
            'timeZone': 'Asia/Kolkata',
            'currencyCode': 'INR',
            'taxIdentifier': '27AAPFU0939F1ZV',
            'region': 'IN',
            'isActive': true,
            'createdAtUtc': '2026-01-01T00:00:00Z',
          };
        },
      );

      await cloudRepo.updateCompanyProfile(
        baseUrl: 'https://api.test.floraprise.local',
        accessToken: 'valid-token',
        name: 'Fresh Petals',
        taxIdentifier: '27AAPFU0939F1ZV',
        taxEnabled: true,
      );

      final manager = BusinessSettingsManager(
        cloudCompanyProfileRepository: cloudRepo,
        storageModeService: storageModeService,
      );

      final settings = await manager.load();
      expect(settings.gstRegistered, isTrue);
      expect(settings.gstNumber, '27AAPFU0939F1ZV');

      final fiscal = await manager.getFiscalProfile();
      expect(fiscal.taxEnabled, isTrue);
      expect(fiscal.taxIdentifier, '27AAPFU0939F1ZV');
    });

    test('3. REMOVE GST NUMBER / TURN GST OFF: Clears TaxIdentifier and disables GST', () async {
      final storageModeService = StorageModeService();
      await storageModeService.setMode(StorageMode.cloud);

      const secureStorage = FlutterSecureStorage();
      final cloudRepo = CloudCompanyProfileRepository(
        secureStorage: secureStorage,
        sender: (method, uri, {body}) async {
          return {
            'id': 'cloud-company-1',
            'name': 'Fresh Petals',
            'timeZone': 'Asia/Kolkata',
            'currencyCode': 'INR',
            'taxIdentifier': '',
            'region': 'IN',
            'isActive': true,
            'createdAtUtc': '2026-01-01T00:00:00Z',
          };
        },
      );

      // Disable GST / clear taxIdentifier
      await cloudRepo.updateCompanyProfile(
        baseUrl: 'https://api.test.floraprise.local',
        accessToken: 'valid-token',
        name: 'Fresh Petals',
        taxIdentifier: '',
        taxEnabled: false,
      );

      final manager = BusinessSettingsManager(
        cloudCompanyProfileRepository: cloudRepo,
        storageModeService: storageModeService,
      );

      final settings = await manager.load();
      expect(settings.gstRegistered, isFalse);
      expect(settings.gstNumber, isEmpty);

      final fiscal = await manager.getFiscalProfile();
      expect(fiscal.taxEnabled, isFalse);
      expect(fiscal.taxIdentifier, isNull);
    });
  });
}
