import 'dart:convert';

import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/business_profile_repository.dart';
import 'package:floraprise/data/repositories/cloud_company_profile_repository.dart';
import 'package:floraprise/managers/business_settings_manager.dart';
import 'package:floraprise/models/storage_mode.dart';
import 'package:floraprise/services/storage_mode_service.dart';
import 'package:floraprise/services/whatsapp_template_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await AppDatabase.instance.close();
    final path = await getDatabasesPath();
    await deleteDatabase('$path/floraprise.db');
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('Company Name Resolution - Local Mode', () {
    test('defaults to "My Flower Shop" when no local profile or settings are configured', () async {
      final storageModeService = StorageModeService();
      await storageModeService.setMode(StorageMode.local);

      final manager = BusinessSettingsManager();
      final settings = await manager.load();

      expect(settings.shopName, 'My Flower Shop');
    });

    test('returns saved local profile shop name when configured', () async {
      final storageModeService = StorageModeService();
      await storageModeService.setMode(StorageMode.local);

      final manager = BusinessSettingsManager();
      await manager.saveBusinessProfile(
        shopName: 'Blooms & Petals Local',
        ownerName: 'Alice Florist',
        mobileNumber: '9876543210',
        gstRegistered: false,
      );

      final settings = await manager.load();
      expect(settings.shopName, 'Blooms & Petals Local');
      expect(settings.phone, '9876543210');

      final profileRepo = BusinessProfileRepository();
      final profile = await profileRepo.getBusinessProfile();
      expect(profile?.shopName, 'Blooms & Petals Local');
    });
  });

  group('Company Name Resolution - Cloud Mode', () {
    test('resolves company name from mobile_auth_company bootstrap cache and never defaults to "My Flower Shop"', () async {
      final storageModeService = StorageModeService();
      await storageModeService.setMode(StorageMode.cloud);

      const secureStorage = FlutterSecureStorage();
      await secureStorage.write(
        key: 'mobile_auth_company',
        value: jsonEncode({
          'id': 'company-uuid-1',
          'name': 'Orchid Oasis Cloud',
          'taxIdentifier': 'GST12345',
          'currency': 'INR',
          'region': 'IN',
          'timeZone': 'Asia/Kolkata',
        }),
      );

      final repo = CloudCompanyProfileRepository(secureStorage: secureStorage);
      final cachedProfile = await repo.getCachedProfile();
      expect(cachedProfile, isNotNull);
      expect(cachedProfile!.name, 'Orchid Oasis Cloud');
      expect(cachedProfile.taxIdentifier, 'GST12345');

      final manager = BusinessSettingsManager(
        cloudCompanyProfileRepository: repo,
        storageModeService: storageModeService,
      );
      final settings = await manager.load();

      expect(settings.shopName, 'Orchid Oasis Cloud');
      expect(settings.gstNumber, 'GST12345');
      expect(settings.gstRegistered, isTrue);
      expect(settings.shopName, isNot('My Flower Shop'));
    });

    test('resolves full profile from cloud_company_profile cache', () async {
      final storageModeService = StorageModeService();
      await storageModeService.setMode(StorageMode.cloud);

      const secureStorage = FlutterSecureStorage();
      final cloudProfile = CloudCompanyProfile(
        id: 'company-uuid-2',
        name: 'Royal Rose Boutique',
        email: 'contact@royalrose.com',
        phone: '9998887776',
        address: '42 Flower Lane, Garden City',
        timeZone: 'Asia/Kolkata',
        currencyCode: 'INR',
        taxIdentifier: 'GST99988',
        region: 'IN',
        isActive: true,
        createdAtUtc: DateTime.now(),
      );

      await secureStorage.write(
        key: 'cloud_company_profile',
        value: jsonEncode(cloudProfile.toJson()),
      );

      final repo = CloudCompanyProfileRepository(secureStorage: secureStorage);
      final manager = BusinessSettingsManager(
        cloudCompanyProfileRepository: repo,
        storageModeService: storageModeService,
      );
      final settings = await manager.load();

      expect(settings.shopName, 'Royal Rose Boutique');
      expect(settings.phone, '9998887776');
      expect(settings.address, '42 Flower Lane, Garden City');
      expect(settings.gstNumber, 'GST99988');
      expect(settings.gstRegistered, isTrue);

      // BusinessProfileRepository also reflects the Cloud company
      final profileRepo = BusinessProfileRepository(
        storageModeService: storageModeService,
        cloudCompanyProfileRepository: repo,
      );
      final profile = await profileRepo.getBusinessProfile();
      expect(profile, isNotNull);
      expect(profile!.shopName, 'Royal Rose Boutique');
      expect(profile.mobileNumber, '9998887776');
      expect(profile.address, '42 Flower Lane, Garden City');
    });

    test('WhatsAppTemplateService uses the Cloud company name in message headers', () async {
      final storageModeService = StorageModeService();
      await storageModeService.setMode(StorageMode.cloud);

      const secureStorage = FlutterSecureStorage();
      await secureStorage.write(
        key: 'cloud_company_profile',
        value: jsonEncode(CloudCompanyProfile(
          id: 'company-uuid-3',
          name: 'Lotus Petals Co',
          phone: '9123456780',
          timeZone: 'Asia/Kolkata',
          currencyCode: 'INR',
          region: 'IN',
          isActive: true,
          createdAtUtc: DateTime.now(),
        ).toJson()),
      );

      final profileRepo = BusinessProfileRepository(
        storageModeService: storageModeService,
        cloudCompanyProfileRepository: CloudCompanyProfileRepository(
          secureStorage: secureStorage,
        ),
      );

      final service = WhatsAppTemplateService(
        businessProfileRepository: profileRepo,
      );

      final message = await service.orderStatusUpdate(
        customerName: 'Rohit Sharma',
        orderNumber: '101',
        status: 'Confirmed',
        totalPaise: 150000,
        address: 'Mumbai',
      );

      expect(message, contains('🌸 *Lotus Petals Co*'));
      expect(message, isNot(contains('My Flower Shop')));
      expect(message, isNot(contains('🌸 *Floraprise*')));
    });

    test('SettingsChangeNotifier triggers when notifySettingsChanged is called', () {
      int notifications = 0;
      void listener() => notifications++;

      BusinessSettingsManager.changeNotifier.addListener(listener);
      BusinessSettingsManager.notifySettingsChanged();

      expect(notifications, 1);
      BusinessSettingsManager.changeNotifier.removeListener(listener);
    });
  });
}
