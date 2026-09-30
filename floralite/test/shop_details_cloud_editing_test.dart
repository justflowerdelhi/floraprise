import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/business_profile_repository.dart';
import 'package:floraprise/data/repositories/cloud_company_profile_repository.dart';
import 'package:floraprise/managers/business_settings_manager.dart';
import 'package:floraprise/models/storage_mode.dart';
import 'package:floraprise/services/storage_mode_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeCloudStorageModeService extends StorageModeService {
  @override
  Future<bool> isCloud() async => true;
  @override
  Future<StorageMode> getCurrentMode() async => StorageMode.cloud;
}

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

  group('Shop Details Cloud Editing Tests', () {
    test('BusinessProfileRepository in Cloud mode maps ownerName, city, state, pinCode', () async {
      const secureStorage = FlutterSecureStorage();
      final cloudRepo = CloudCompanyProfileRepository(secureStorage: secureStorage);

      final cloudProfile = CloudCompanyProfile(
        id: '11111111-1111-4111-8111-111111111111',
        name: 'Floral Art Studio',
        ownerName: 'Alice Green',
        phone: '9876543210',
        email: 'alice@floralart.com',
        address: '123 Flower Road',
        city: 'Mumbai',
        state: 'Maharashtra',
        pinCode: '400001',
        logoPath: '/uploads/logos/flower.png',
        taxIdentifier: 'GSTIN27AAAAA0000A1Z5',
        region: 'IN',
        timeZone: 'Asia/Kolkata',
        currencyCode: 'INR',
        isActive: true,
        createdAtUtc: DateTime.utc(2026, 1, 1),
      );

      await cloudRepo.saveCachedProfile(cloudProfile);

      final businessRepo = BusinessProfileRepository(
        storageModeService: _FakeCloudStorageModeService(),
        cloudCompanyProfileRepository: cloudRepo,
      );

      final profile = await businessRepo.getBusinessProfile();
      expect(profile, isNotNull);
      expect(profile!.shopName, 'Floral Art Studio');
      expect(profile.ownerName, 'Alice Green');
      expect(profile.mobileNumber, '9876543210');
      expect(profile.email, 'alice@floralart.com');
      expect(profile.address, '123 Flower Road');
      expect(profile.city, 'Mumbai');
      expect(profile.state, 'Maharashtra');
      expect(profile.pinCode, '400001');
      expect(profile.gstRegistered, isTrue);
      expect(profile.gstNumber, 'GSTIN27AAAAA0000A1Z5');
    });

    test('BusinessSettingsManager in Cloud mode loads ownerName and logoPath', () async {
      const secureStorage = FlutterSecureStorage();
      final cloudRepo = CloudCompanyProfileRepository(secureStorage: secureStorage);

      final cloudProfile = CloudCompanyProfile(
        id: '11111111-1111-4111-8111-111111111111',
        name: 'Lotus Blossom POS',
        ownerName: 'Robert Vance',
        phone: '9998887777',
        email: 'bob@lotus.com',
        address: 'Scranton PA',
        city: 'Scranton',
        state: 'Pennsylvania',
        pinCode: '18503',
        logoPath: '/uploads/logos/lotus.png',
        taxIdentifier: 'US12345678',
        region: 'US',
        currencyCode: 'USD',
        timeZone: 'America/New_York',
        isActive: true,
        createdAtUtc: DateTime.utc(2026, 1, 1),
      );

      await cloudRepo.saveCachedProfile(cloudProfile);

      final settingsManager = BusinessSettingsManager(
        storageModeService: _FakeCloudStorageModeService(),
        cloudCompanyProfileRepository: cloudRepo,
      );

      final settings = await settingsManager.load();
      expect(settings.shopName, 'Lotus Blossom POS');
      expect(settings.ownerName, 'Robert Vance');
      expect(settings.logoPath, contains('/uploads/logos/lotus.png'));
      expect(settings.phone, '9998887777');
      expect(settings.address, 'Scranton PA');
    });

    test('BusinessProfileRepository in Local mode saves and loads full profile', () async {
      final storageModeService = StorageModeService();
      await storageModeService.setMode(StorageMode.local);

      final businessRepo = BusinessProfileRepository(
        storageModeService: storageModeService,
      );

      await businessRepo.saveBusinessProfile(
        shopName: 'Garden Fresh Local',
        ownerName: 'Emma Watson',
        mobileNumber: '9123456780',
        email: 'emma@garden.com',
        address: '456 Green Way',
        city: 'Pune',
        state: 'Maharashtra',
        pinCode: '411001',
        gstRegistered: true,
        gstNumber: 'GSTIN27BBBBB1111B2Z6',
      );

      final profile = await businessRepo.getBusinessProfile();
      expect(profile, isNotNull);
      expect(profile!.shopName, 'Garden Fresh Local');
      expect(profile.ownerName, 'Emma Watson');
      expect(profile.mobileNumber, '9123456780');
      expect(profile.email, 'emma@garden.com');
      expect(profile.address, '456 Green Way');
      expect(profile.city, 'Pune');
      expect(profile.state, 'Maharashtra');
      expect(profile.pinCode, '411001');
      expect(profile.gstRegistered, isTrue);
      expect(profile.gstNumber, 'GSTIN27BBBBB1111B2Z6');
    });
  });
}
