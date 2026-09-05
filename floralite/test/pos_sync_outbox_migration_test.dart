import 'dart:io';

import 'package:floraprise/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await AppDatabase.instance.close();
    AppDatabase.useInMemoryForTests = false;
    AppDatabase.testDatabaseName = 'pos_outbox_v41_upgrade_test.db';
  });

  tearDown(() async {
    await AppDatabase.instance.close();
    final databasePath = path.join(
      await getDatabasesPath(),
      AppDatabase.testDatabaseName!,
    );
    await deleteDatabase(databasePath);
    AppDatabase.testDatabaseName = null;
    AppDatabase.useInMemoryForTests = false;
  });

  test('version 41 database upgrades to version 44 without changing existing sales', () async {
    final databasePath = path.join(
      await getDatabasesPath(),
      AppDatabase.testDatabaseName!,
    );

    final current = await AppDatabase.instance.database;
    final customerId = await current.insert('customers', {
      'phone': '9876543210',
      'name': 'Existing Customer',
      'created_at': '2026-09-01T10:00:00.000Z',
      'updated_at': '2026-09-01T10:00:00.000Z',
    });
    final orderId = await current.insert('orders', {
      'order_no': 'ORD-EXISTING-41',
      'fulfilment_type': 'take_away',
      'status': 'confirmed',
      'customer_id': customerId,
      'customer_phone': '9876543210',
      'customer_name': 'Existing Customer',
      'is_paid': 1,
      'subtotal_paise': 12500,
      'gst_total_paise': 0,
      'discount_total_paise': 0,
      'round_off_paise': 0,
      'grand_total_paise': 12500,
      'created_at': '2026-09-01T10:00:00.000Z',
      'updated_at': '2026-09-01T10:00:00.000Z',
      'confirmed_at': '2026-09-01T10:01:00.000Z',
    });
    final lineId = await current.insert('order_lines', {
      'order_id': orderId,
      'description': 'Existing Sale Line',
      'qty': 1,
      'unit_price_paise': 12500,
      'gst_percent': 0,
      'line_subtotal_paise': 12500,
      'line_gst_paise': 0,
      'line_total_paise': 12500,
      'source': 'manual',
    });
    final paymentId = await current.insert('order_payments', {
      'order_id': orderId,
      'method': 'cash',
      'amount_paise': 12500,
      'reference': 'EXISTING-REF',
      'created_at': '2026-09-01T10:01:00.000Z',
    });
    await current.execute('DROP TABLE pos_sync_outbox');
    await current.execute('PRAGMA user_version = 41');
    await AppDatabase.instance.close();

    final upgraded = await AppDatabase.instance.database;
    final version = await upgraded.rawQuery('PRAGMA user_version');
    final tables = await upgraded.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'pos_sync_outbox'",
    );
    final order = await upgraded.query('orders', where: 'id = ?', whereArgs: [orderId]);
    final lines = await upgraded.query('order_lines', where: 'id = ?', whereArgs: [lineId]);
    final payments = await upgraded.query('order_payments', where: 'id = ?', whereArgs: [paymentId]);
    final outbox = await upgraded.query('pos_sync_outbox', where: 'local_order_id = ?', whereArgs: [orderId]);

    expect(File(databasePath).existsSync(), isTrue);
    expect(version.single['user_version'], 44);
    expect(tables, hasLength(1));
    expect(order.single['order_no'], 'ORD-EXISTING-41');
    expect(order.single['status'], 'confirmed');
    expect(order.single['grand_total_paise'], 12500);
    expect(lines.single['description'], 'Existing Sale Line');
    expect(lines.single['line_total_paise'], 12500);
    expect(payments.single['method'], 'cash');
    expect(payments.single['amount_paise'], 12500);
    expect(payments.single['reference'], 'EXISTING-REF');
    expect(outbox, isEmpty);
  });
}
