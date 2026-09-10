import 'dart:convert';

import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/cloud_company_profile_repository.dart';
import 'package:floraprise/data/repositories/job_repository.dart';
import 'package:floraprise/data/repositories/order_repository.dart';
import 'package:floraprise/managers/business_settings_manager.dart';
import 'package:floraprise/managers/order_manager.dart';
import 'package:floraprise/models/storage_mode.dart';
import 'package:floraprise/services/order_print_service.dart';
import 'package:floraprise/services/storage_mode_service.dart';
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

  group('WhatsApp Bill and Receipt Company Name', () {
    test('Cloud mode WhatsApp bill header uses authenticated company name', () async {
      final storageModeService = StorageModeService();
      await storageModeService.setMode(StorageMode.cloud);

      const secureStorage = FlutterSecureStorage();
      await secureStorage.write(
        key: 'cloud_company_profile',
        value: jsonEncode({
          'id': 'cloud-company-1',
          'name': 'Flora Elegance Studio',
          'phone': '9876501234',
          'address': 'Connaught Place, New Delhi',
          'timeZone': 'Asia/Kolkata',
          'currencyCode': 'INR',
          'region': 'IN',
          'isActive': true,
          'createdAtUtc': DateTime.now().toIso8601String(),
        }),
      );

      final manager = BusinessSettingsManager(
        cloudCompanyProfileRepository: CloudCompanyProfileRepository(
          secureStorage: secureStorage,
        ),
        storageModeService: storageModeService,
      );

      final settings = await manager.load();

      // Simulate POS bill message lines constructed in take_away / pickup_later / delivery screens
      final lines = <String>[
        if (settings.shopName.isNotEmpty) settings.shopName,
        if (settings.phone.isNotEmpty) 'Phone: ${settings.phone}',
        if (settings.address.isNotEmpty) settings.address,
        'Receipt',
        'Order Number: #1001',
      ];

      final receiptText = lines.join('\n');

      expect(receiptText, contains('Flora Elegance Studio'));
      expect(receiptText, contains('Phone: 9876501234'));
      expect(receiptText, contains('Connaught Place, New Delhi'));
      expect(receiptText, isNot(contains('My Flower Shop')));
    });

    test('Local mode WhatsApp bill header uses local shop name', () async {
      final storageModeService = StorageModeService();
      await storageModeService.setMode(StorageMode.local);

      final manager = BusinessSettingsManager();
      await manager.saveBusinessProfile(
        shopName: 'Delhi Floral Hub',
        ownerName: 'Sunil Kumar',
        mobileNumber: '9811122233',
        address: 'Karol Bagh, Delhi',
        gstRegistered: false,
      );

      final settings = await manager.load();

      final lines = <String>[
        if (settings.shopName.isNotEmpty) settings.shopName,
        if (settings.phone.isNotEmpty) 'Phone: ${settings.phone}',
        if (settings.address.isNotEmpty) settings.address,
        'Receipt',
        'Order Number: #2002',
      ];

      final receiptText = lines.join('\n');

      expect(receiptText, contains('Delhi Floral Hub'));
      expect(receiptText, contains('Phone: 9811122233'));
      expect(receiptText, contains('Karol Bagh, Delhi'));
      expect(receiptText, isNot(contains('My Flower Shop')));
    });

    test('OrderPrintService.buildReceiptText uses resolved company name instead of hardcoded default', () async {
      final storageModeService = StorageModeService();
      await storageModeService.setMode(StorageMode.cloud);

      const secureStorage = FlutterSecureStorage();
      await secureStorage.write(
        key: 'cloud_company_profile',
        value: jsonEncode({
          'id': 'cloud-company-2',
          'name': 'Blossom Heaven',
          'timeZone': 'Asia/Kolkata',
          'currencyCode': 'INR',
          'region': 'IN',
          'isActive': true,
          'createdAtUtc': DateTime.now().toIso8601String(),
        }),
      );

      // Insert an order into database for OrderPrintService
      final db = await AppDatabase.instance.database;
      final now = DateTime.now().toIso8601String();
      final orderId = await db.insert('orders', {
        'order_no': 'ORD-999',
        'fulfilment_type': 'delivery',
        'status': 'confirmed',
        'customer_name': 'Pooja Verma',
        'customer_phone': '9876543210',
        'grand_total_paise': 50000,
        'created_at': now,
        'updated_at': now,
      });

      final orderRepo = OrderRepository();
      final jobRepo = JobRepository();
      final orderManager = OrderManager(orderRepo, jobRepo);
      final printService = OrderPrintService(orderManager: orderManager);

      final text = await printService.buildReceiptText(orderId);

      expect(text, startsWith('Blossom Heaven\n'));
      expect(text, isNot(startsWith('FLORAPRISE\nOrder:')));
    });
  });
}
